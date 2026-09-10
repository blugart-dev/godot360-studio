extends SceneTree
## Headless coordinator; starts a separate GPU Movie Maker worker.
## godot --headless --path PROJECT --script res://addons/godot360/pipeline.gd -- --job=ABSOLUTE_JSON

const IO = preload("job_io.gd")
const Metadata = preload("spherical_metadata.gd")
const Planner = preload("job_planner.gd")
const Audio = preload("audio_plan.gd")
const Session = preload("job_session.gd")
const Storage = preload("storage_guard.gd")
const Tools = preload("tool_paths.gd")
const Renderer = preload("renderer_policy.gd")
var storage: RefCounted
var job_error := ""
var storage_stage := ""
var session: RefCounted
var session_poll := 0.0
var job: Dictionary
var folder: String
var job_path: String
var runner: RefCounted
var source_folder: String
var encode_state: Dictionary = {}
var process_id: int = -1
var phase: String = ""
var phase_started_usec: int
var started_usec: int
var stage_seconds: Dictionary = {}
var soundtrack_info: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	started_usec = Time.get_ticks_usec()
	job_path = IO.argument("job")
	job = IO.read_json(job_path)
	if job.get("mode") == "reencode":
		var resolved := Planner.resolve_reencode(job)
		if not str(resolved.get("error", "")).is_empty():
			push_error(str(resolved.error))
			quit(1)
			return
		job = resolved.job
	var error: String = IO.validate(job)
	if not error.is_empty():
		push_error(error)
		quit(1)
		return
	folder = str(job.output_dir)
	source_folder = str(job.get("source_dir", folder)) if job.get("mode") == "reencode" else folder
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		push_error("Cannot create output directory.")
		quit(1)
		return
	# A job owns a fresh folder. Never mix frames with an earlier render.
	var existing := DirAccess.get_files_at(folder)
	for allowed in ["job.json", "pipeline.log"]:
		existing.erase(allowed)
	if not existing.is_empty() or not DirAccess.get_directories_at(folder).is_empty():
		push_error("Output folder already contains a job. Choose a new folder.")
		quit(1)
		return
	session = Session.new()
	if not session.start(folder):
		push_error("Cannot save coordinator identity in the output folder.")
		quit(1)
		return
	storage = _make_storage_guard()
	if not _check_storage(0 if job.get("mode") == "reencode" else Storage.capture_headroom(job), "Preparing export", true):
		_fail(job_error)
		return
	if job.get("mode") != "reencode":
		job.scene_modified_time = FileAccess.get_modified_time(str(job.scene_path))
		Renderer.stamp(job)
	if Audio.uses_soundtrack(job):
		job.soundtrack_resolved_path = Audio.resolved_path(job)
	job.audio_signature = Audio.signature(job)
	if not _required_json("job.json", job) or not _required_json("quality-checks.json", {
		"source_columns_per_90_degrees": int(job.width) / 4,
		"warnings": IO.quality_advice(job)}):
		_fail(job_error)
		return
	_status("Checking tools", 0.0)
	for key in ["ffmpeg", "ffprobe"]:
		var executable := Tools.find_executable(str(job[key]))
		if executable.is_empty():
			_fail(Tools.missing_message("FFmpeg" if key == "ffmpeg" else "FFprobe"))
			return
		job[key] = executable
	if not _required_json("job.json", job):
		_fail(job_error)
		return
	var preflight := await _execute(str(job.ffmpeg), ["-hide_banner", "-encoders"], "ffmpeg-check.log")
	if _cancelled():
		return
	if preflight.code != 0 or not str(preflight.output).contains("libx264") or not str(preflight.output).contains(" aac "):
		_fail("FFmpeg must provide libx264 and AAC encoders. See ffmpeg-check.log.")
		return
	if job.get("mode") != "reencode" and job.get("frame_writer", "png") == "fast_png" and not str(preflight.output).contains(" png "):
		_fail("FFmpeg must provide the PNG encoder for Fast PNG. Select Compact PNG or another FFmpeg build.")
		return
	var filters := await _execute(str(job.ffmpeg), ["-hide_banner", "-filters"], "ffmpeg-filters.log")
	if _cancelled():
		return
	if filters.code != 0 or not str(filters.output).contains(" colorspace ") or not str(filters.output).contains(" scale "):
		_fail("FFmpeg must provide scale and colorspace filters.")
		return
	var probe_check := await _execute(str(job.ffprobe), ["-version"], "ffprobe-check.log")
	if _cancelled():
		return
	if probe_check.code != 0:
		_fail("FFprobe could not start. Check its executable path.")
		return
	if not await _prepare_audio(str(filters.output)):
		return
	if _cancelled():
		return
	if job.get("mode") != "reencode":
		if not await _capture():
			return
	_status("Checking saved frames", 0.76)
	error = Planner.validate_frames(source_folder, job)
	if not error.is_empty():
		_fail(error)
		return
	if _cancelled():
		return
	if not _soundtrack_unchanged():
		return
	var warmup: int = int(job.get("warmup_frames", 2))
	_status("Encoding H.264 + AAC", 0.78)
	var duration: float = float(job.frames) / float(job.fps)
	var audio_plan := Audio.encoding(job, source_folder)
	var encoded: String = folder.path_join("encoded.mp4")
	# The first scale converts RGB to BT.709 YUV. colorspace then transforms
	# the sRGB transfer curve to BT.709, rather than merely relabeling the pixels.
	var color_filter := "scale=in_range=full:out_range=tv:out_color_matrix=bt709,format=yuv444p,colorspace=iall=bt709:itrc=srgb:irange=tv:all=bt709:range=tv:format=yuv420p"
	var encode_args := PackedStringArray(["-hide_banner", "-nostdin", "-nostats", "-n",
		"-stats_period", "0.2", "-progress", folder.path_join("encode-progress.txt"), "-framerate", str(int(job.fps)),
		"-start_number", str(warmup), "-i", source_folder.path_join("frames/frame%08d.png")])
	encode_args.append_array(audio_plan.inputs)
	encode_args.append_array(["-map", "0:v:0", "-vf", color_filter])
	encode_args.append_array(audio_plan.options)
	encode_args.append_array([
		"-t", "%.9f" % duration, "-c:v", "libx264", "-preset", "medium", "-crf", str(int(job.get("crf", 18))),
		"-pix_fmt", "yuv420p", "-color_primaries", "bt709", "-color_trc", "bt709", "-colorspace", "bt709",
		"-color_range", "tv", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2", encoded])
	var encode := await _execute(str(job.ffmpeg), encode_args, "encode.log")
	if _cancelled():
		return
	if encode.code != 0:
		_fail("Encoding failed. See encode.log.")
		return
	if not _soundtrack_unchanged():
		return
	if _cancelled():
		return
	_status("Writing spherical metadata", 0.9)
	if not _check_storage(Planner.file_size(encoded) + Metadata.MAX_MOOV + Storage.frame_bound(job), "Writing spherical metadata", true):
		_fail(job_error)
		return
	if _cancelled():
		return
	var final_path: String = folder.path_join("video-360.mp4")
	var staged_path: String = folder.path_join("staged-360.mp4")
	error = Metadata.inject(encoded, staged_path, int(job.width), int(job.height),
		func() -> bool:
			_service_session()
			return not _check_storage(0, "Copying spherical metadata") or FileAccess.file_exists(folder.path_join("cancel.request")))
	if not error.is_empty():
		_fail(job_error if not job_error.is_empty() else error)
		return
	_status("Verifying output", 0.95)
	var verification := await _execute(str(job.ffprobe), ["-v", "error", "-count_frames", "-show_streams", "-show_format", "-of", "json", staged_path], "probe.json")
	if _cancelled():
		return
	var data = JSON.parse_string(str(verification.output))
	if verification.code != 0 or not data is Dictionary:
		_fail("FFprobe could not read the final MP4.")
		return
	var checks: Dictionary = verify(data, job)
	var delivery := Metadata.inspect(staged_path)
	for key in ["fast_start", "spherical_v2", "spherical_v1", "chunk_offsets"]:
		checks[key] = delivery.get("error", "").is_empty() and bool(delivery.get(key, false))
	var passed := true
	for value in checks.values():
		passed = passed and bool(value)
	var report: Dictionary = {"ok": passed, "checks": checks,
		"video": final_path, "godot_version": Engine.get_version_info().string,
		"scene_checks": IO.read_json(source_folder.path_join("scene-checks.json")),
		"quality_checks": IO.read_json(folder.path_join("quality-checks.json")),
		"capture_timings": IO.read_json(source_folder.path_join("capture-timings.json")),
		"capture_settings": IO.read_json(source_folder.path_join("capture-settings.json")),
		"capture_reused": job.get("mode") == "reencode", "capture_source": source_folder,
		"audio": {"settings": Audio.settings(job), "soundtrack_source": soundtrack_info,
			"legacy_scene_audio": audio_plan.legacy, "mix_limiter": "0.95 peak, latency compensated" if job.get("audio_mode") == "mix" else "none",
			"timing": "Offsets are relative to delivered frame zero; positive delays, negative advances. Short sources are padded with silence."},
		"pipeline_timings": _timings(),
		"storage_guard": storage.latest,
		"youtube_playback_tested": false, "fast_start": checks.fast_start,
		"spherical_metadata_versions": [1, 2], "delivery_checks": delivery,
		"notes": ["Mono 360, SDR BT.709, stereo audio. No gaze interaction is carried into the video.",
			"Equivalent mono Spherical Video V1/V2 metadata. Fast-start moov precedes media; chunk offsets are relocated.",
			"A manual YouTube playback check is still required."]}
	if not passed:
		IO.write_json(folder.path_join("report.json"), report)
		_fail("Output validation failed. See report.json and probe.json.")
		return
	if _cancelled():
		return
	if DirAccess.copy_absolute(source_folder.path_join("frames/frame%08d.png" % warmup), folder.path_join("preview.png")) != OK:
		_fail("Cannot save the preview image. Check output folder access and disk space.")
		return
	var sizes := Planner.storage(folder)
	if not _required_json("storage.json", sizes):
		_fail(job_error)
		return
	if job.get("mode") == "test":
		var target := job.duplicate()
		target.frames = int(job.target_frames)
		var estimate := Planner.estimate(job, report, sizes, target)
		report.planning = estimate
		if not _required_json("planning.json", estimate):
			_fail(job_error)
			return
	# Persist the successful report before committing the verified media filename.
	if not _required_json("report.json", report):
		_fail(job_error)
		return
	if _cancelled():
		return
	if DirAccess.rename_absolute(staged_path, final_path) != OK:
		_fail("Could not publish the verified MP4.")
		return
	_status("Complete", 1.0)
	print("360 EXPORT COMPLETE: " + final_path)
	quit()


func _capture() -> bool:
	if DirAccess.make_dir_recursive_absolute(folder.path_join("frames")) != OK or DirAccess.make_dir_recursive_absolute(folder.path_join("movie")) != OK:
		_fail("Cannot create capture directories. Check output folder access.")
		return false
	if not _status("Rendering", 0.05):
		_fail(job_error)
		return false
	var arguments := PackedStringArray(["--path", ProjectSettings.globalize_path("res://"),
		"--rendering-method", str(job.renderer_selection.resolved_method),
		"--rendering-driver", str(job.renderer_selection.resolved_driver), "--fixed-fps", str(int(job.fps)),
		"--quit-after", str(int(job.frames) + int(job.get("warmup_frames", 2))),
		"--write-movie", folder.path_join("movie/audio.png"), "--disable-vsync",
		"--log-file", folder.path_join("capture.log"),
		"--script", "res://addons/godot360/capture.gd", "--", "--job=" + folder.path_join("job.json")])
	process_id = OS.create_process(OS.get_executable_path(), arguments)
	if process_id <= 0:
		_fail("Could not start the Godot rendering worker.")
		return false
	while OS.is_process_running(process_id):
		var progress: Dictionary = IO.read_json(folder.path_join("render-progress.json"))
		var fraction: float = float(progress.get("frame", 0)) / maxf(1.0, float(progress.get("total", 1)))
		_status("Rendering", 0.05 + 0.7 * fraction)
		if not _check_storage(Storage.capture_headroom(job), "Rendering") or not job_error.is_empty():
			# This is our own live worker handle, not a PID recovered from disk.
			if not IO.write_text(folder.path_join("cancel.request"), job_error):
				OS.kill(process_id)
		await create_timer(0.3).timeout
	var worker_exit: int = OS.get_process_exit_code(process_id)
	_required_json("worker-exit.json", {"pid": process_id, "exit_code": worker_exit})
	process_id = -1
	if _cancelled():
		return false
	var capture := IO.read_json(folder.path_join("capture-result.json"))
	# A PackedScene can instantiate even when its attached script fails to parse.
	# Such a render is missing authored behavior, despite a complete PNG count.
	var capture_log := FileAccess.get_file_as_string(folder.path_join("capture.log"))
	var log_error := preload("renderer_policy.gd").capture_log_error(capture_log)
	if capture.get("ok", false) and not log_error.is_empty():
		capture.ok = false
		capture.error = log_error
		_required_json("capture-result.json", capture)
	if not capture.get("ok", false):
		_fail(str(capture.get("error", "Rendering worker exited (exit %d) before completing capture. See capture.log." % worker_exit)))
		return false
	if worker_exit != 0:
		_fail("Rendering worker exited with exit code %d after capture. See capture.log." % worker_exit)
		return false
	if int(capture.get("rendered", -1)) != int(job.frames) + int(job.get("warmup_frames", 2)):
		_fail("Capture reported an incomplete frame count. See capture-result.json.")
		return false
	# Only move our own finalized WAV. Re-encoding never writes to this source.
	if DirAccess.rename_absolute(folder.path_join("movie/audio.wav"), folder.path_join("frames/frame.wav")) != OK:
		_fail("Movie Maker did not produce a finalized WAV file.")
		return false
	for scratch in DirAccess.get_files_at(folder.path_join("movie")):
		if scratch.begins_with("audio") and scratch.ends_with(".png"):
			DirAccess.remove_absolute(folder.path_join("movie").path_join(scratch))
	return true


static func verify(data: Dictionary, recipe: Dictionary) -> Dictionary:
	var video: Dictionary = {}
	var audio: Dictionary = {}
	for stream in data.get("streams", []):
		if stream.get("codec_type") == "video":
			video = stream
		if stream.get("codec_type") == "audio":
			audio = stream
	var spherical := false
	for side in video.get("side_data_list", []):
		if side.get("side_data_type") == "Spherical Mapping" and side.get("projection") == "equirectangular":
			spherical = true
	return {"dimensions": int(video.get("width", 0)) == int(recipe.width) and int(video.get("height", 0)) == int(recipe.height),
		"frame_count": int(video.get("nb_read_frames", 0)) == int(recipe.frames),
		"fps": str(video.get("r_frame_rate", "")) == "%d/1" % int(recipe.fps),
		"duration": absf(float(video.get("duration", 0)) - float(recipe.frames) / float(recipe.fps)) < 1.0 / float(recipe.fps),
		"h264_yuv420p": video.get("codec_name") == "h264" and video.get("pix_fmt") == "yuv420p",
		"bt709": video.get("color_space") == "bt709" and video.get("color_transfer") == "bt709" and video.get("color_primaries") == "bt709" and video.get("color_range") == "tv",
		"aac_stereo_48k": audio.get("codec_name") == "aac" and int(audio.get("channels", 0)) == 2 and int(audio.get("sample_rate", 0)) == 48000,
		"audio_duration": absf(float(audio.get("duration", -1)) - float(recipe.frames) / float(recipe.fps)) <= 1.0 / Audio.RATE + 0.000001,
		"spherical_metadata": spherical}


func _prepare_audio(filters: String) -> bool:
	for required in Audio.required_filters(job):
		if not filters.contains(" " + required + " "):
			_fail("FFmpeg must provide the %s audio filter." % required)
			return false
	if not Audio.uses_soundtrack(job):
		return true
	var path := Audio.resolved_path(job)
	var probe := await _execute(str(job.ffprobe), ["-v", "error", "-show_streams", "-show_format", "-of", "json", path], "soundtrack-probe.json")
	if _cancelled():
		return false
	var data = JSON.parse_string(str(probe.output))
	var error := "Cannot read soundtrack audio. See soundtrack-probe.json." if probe.code != 0 or not data is Dictionary else Audio.validate_probe(data, job)
	if not error.is_empty():
		_fail(error)
		return false
	soundtrack_info = {"path": path, "sha256": FileAccess.get_sha256(path), "probe": data}
	if str(soundtrack_info.sha256).is_empty():
		_fail("Cannot read the complete soundtrack file.")
		return false
	return true


func _soundtrack_unchanged() -> bool:
	if not soundtrack_info.is_empty() and FileAccess.get_sha256(str(soundtrack_info.path)) != str(soundtrack_info.sha256):
		_fail("Soundtrack file changed during the job. Run a new export with the intended file.")
		return false
	return true


func _execute(executable: String, arguments: PackedStringArray, log_name: String) -> Dictionary:
	if not job_error.is_empty() or not _check_storage(0, phase):
		return {"code": -1, "output": job_error}
	runner = preload("process_runner.gd").new()
	var error: String = runner.start(executable, arguments, folder.path_join(log_name))
	if not error.is_empty():
		job_error = error
		runner = null
		var log := FileAccess.open(folder.path_join(log_name), FileAccess.WRITE)
		if log != null:
			log.store_string(error)
		return {"code": -1, "output": error}
	while runner.is_running():
		if not _check_storage(0, phase) or not job_error.is_empty():
			runner.cancel()
			break
		if FileAccess.file_exists(folder.path_join("cancel.request")):
			runner.cancel()
			break
		if log_name == "encode.log":
			_update_encoding_progress()
		await create_timer(0.2).timeout
	var result: Dictionary = runner.finish()
	runner = null
	if not str(result.get("error", "")).is_empty() and job_error.is_empty():
		job_error = str(result.error)
	if log_name == "encode.log":
		_update_encoding_progress()
	return result


func _update_encoding_progress() -> void:
	var path := folder.path_join("encode-progress.txt")
	if not FileAccess.file_exists(path):
		return
	var latest := Planner.encoding_progress(FileAccess.get_file_as_string(path))
	if latest.is_empty():
		return
	var frames: int = clampi(int(latest.get("frame", 0)), 0, int(job.frames))
	var elapsed: float = (Time.get_ticks_usec() - phase_started_usec) / 1000000.0
	encode_state = {"frames": frames, "total": int(job.frames), "elapsed_seconds": elapsed,
		"remaining_seconds": elapsed / frames * (int(job.frames) - frames) if frames > 0 else -1.0}
	_status("Encoding H.264 + AAC", 0.78 + 0.11 * float(frames) / int(job.frames))


func _status(stage: String, progress: float, error: String = "") -> bool:
	if stage != phase:
		if not phase.is_empty():
			stage_seconds[phase] = (Time.get_ticks_usec() - phase_started_usec) / 1000000.0
		phase = stage
		phase_started_usec = Time.get_ticks_usec()
	var written := _required_json("status.json", {"stage": stage, "progress": progress,
		"session_id": session.identity.session_id if session != null else "",
		"error": error, "pid": OS.get_process_id(), "worker_pid": process_id,
		"process_pid": runner.pid if runner != null else -1,
		"encoding": encode_state if stage == "Encoding H.264 + AAC" else {}})
	_service_session()
	return written


func _make_storage_guard() -> RefCounted:
	return Storage.new(folder)


func _required_json(name: String, data: Dictionary) -> bool:
	if IO.write_json(folder.path_join(name), data):
		return true
	if job_error.is_empty():
		job_error = "Cannot save %s. Check output folder access and disk space. Logs and intermediate files have been retained." % name
	push_error(job_error)
	return false


func _check_storage(working_bytes: int, stage: String, force: bool = false) -> bool:
	var sample: Dictionary = storage.check(working_bytes, stage, force)
	if not str(sample.error).is_empty() and job_error.is_empty():
		job_error = str(sample.error)
	if force or storage_stage != stage or not str(sample.error).is_empty():
		storage_stage = stage
		_required_json("storage-checks.json", sample)
	return job_error.is_empty()


func _process(delta: float) -> bool:
	session_poll += delta
	if session_poll >= 0.2:
		session_poll = 0.0
		_service_session()
	return false


func _service_session() -> void:
	if session != null and not session.identity.is_empty():
		session.serve(IO.read_json(folder.path_join("status.json")))


func _timings() -> Dictionary:
	var stages := stage_seconds.duplicate()
	stages[phase] = (Time.get_ticks_usec() - phase_started_usec) / 1000000.0
	return {"elapsed_seconds": (Time.get_ticks_usec() - started_usec) / 1000000.0,
		"stages_seconds": stages}


func _cancelled() -> bool:
	if not job_error.is_empty():
		_fail(job_error)
		return true
	if FileAccess.file_exists(folder.path_join("cancel.request")):
		_fail("Cancelled. Intermediate files have been retained.")
		return true
	return false


func _fail(message: String) -> void:
	if not IO.write_json(folder.path_join("recovery.json"), Planner.recovery(source_folder)):
		push_error("Could not save recovery.json. Reopen this job to inspect retained sources.")
	_status("Cancelled" if message.begins_with("Cancelled") else "Failed", 0.0, message)
	push_error(message)
	quit(1)


func _finalize() -> void:
	if runner != null:
		runner.cancel()
		runner.finish()
