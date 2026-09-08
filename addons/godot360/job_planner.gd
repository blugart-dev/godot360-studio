extends RefCounted
const IO = preload("job_io.gd")
const Audio = preload("audio_plan.gd")
const Storage = preload("storage_guard.gd")
const Renderer = preload("renderer_policy.gd")
const CaptureProjection = preload("capture_projection.gd")
const Exposure = preload("capture_exposure.gd")
const MATCH_KEYS = ["scene_path", "camera_path", "width", "height", "face_size", "fps",
	"random_seed", "warmup_frames", "frame_writer", "crf", "ffmpeg", "ffprobe"]


static func test_job(recipe: Dictionary) -> Dictionary:
	var job := recipe.duplicate(true)
	Renderer.stamp(job)
	job.mode = "test"
	job.target_frames = int(recipe.frames)
	job.frames = mini(int(recipe.frames), int(recipe.fps))
	return job


static func storage(folder: String) -> Dictionary:
	var png_bytes: int = 0
	var count: int = 0
	var frames := folder.path_join("frames")
	var names := DirAccess.get_files_at(frames) if DirAccess.dir_exists_absolute(frames) else PackedStringArray()
	for name in names:
		if name.ends_with(".png"):
			png_bytes += file_size(frames.path_join(name))
			count += 1
	return {"png_bytes": png_bytes, "png_count": count,
		"wav_bytes": file_size(folder.path_join("frames/frame.wav")),
		"encoded_bytes": file_size(folder.path_join("encoded.mp4")),
		"preview_bytes": file_size(folder.path_join("preview.png"))}


static func file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_length() if file != null else 0


static func matches(sample: Dictionary, target: Dictionary) -> bool:
	# Old samples predate project-renderer capture and cannot predict this pipeline.
	if str(sample.get("rendering_signature", "")) != Renderer.signature(target):
		return false
	if not CaptureProjection.validate(sample).is_empty() or not CaptureProjection.validate(target).is_empty():
		return false
	if float(sample.get("capture_border_percent", 0.0)) != float(target.get("capture_border_percent", 0.0)):
		return false
	if not Exposure.validate(sample).is_empty() or not Exposure.validate(target).is_empty():
		return false
	if sample.get("capture_exposure_mode", "scene") != target.get("capture_exposure_mode", "scene"):
		return false
	for key in MATCH_KEYS:
		if str(sample.get(key, "")) != str(target.get(key, "")):
			# JSON numbers may be floats while an editor recipe contains integers.
			if not (sample.get(key) is float or sample.get(key) is int) or not (target.get(key) is float or target.get(key) is int) or float(sample[key]) != float(target[key]):
				return false
	return sample.get("audio_signature", Audio.signature(sample)) == Audio.signature(target)


static func estimate(sample: Dictionary, report: Dictionary, sizes: Dictionary, target: Dictionary) -> Dictionary:
	if not report.get("ok", false) or not matches(sample, target):
		return {}
	var sample_frames: int = int(sample.get("frames", 0))
	var target_frames: int = int(target.get("frames", 0))
	var warmup: int = int(sample.get("warmup_frames", 2))
	var capture: Dictionary = report.get("capture_timings", {})
	if sample_frames <= 0 or target_frames <= 0 or float(capture.get("elapsed_usec", 0)) <= 0:
		return {}
	if int(sizes.get("png_count", 0)) != sample_frames + warmup or int(sizes.get("png_bytes", 0)) <= 0:
		return {}
	var frame_ratio: float = float(target_frames) / sample_frames
	var capture_ratio: float = float(target_frames + warmup) / (sample_frames + warmup)
	var stages: Dictionary = report.get("pipeline_timings", {}).get("stages_seconds", {})
	var measured_capture: float = float(capture.elapsed_usec) / 1000000.0
	var startup: float = maxf(0.0, float(stages.get("Rendering", measured_capture)) - measured_capture)
	var capture_seconds: float = startup + measured_capture * capture_ratio
	var encoding_seconds: float = float(stages.get("Encoding H.264 + AAC", 0)) * frame_ratio
	var verification_seconds: float = float(stages.get("Verifying output", 0)) * frame_ratio
	var fixed_seconds: float = float(stages.get("Checking tools", 0)) + float(stages.get("Writing spherical metadata", 0))
	var disk_bytes: int = ceili(float(sizes.png_bytes + sizes.get("wav_bytes", 0)) * capture_ratio +
		2.0 * float(sizes.get("encoded_bytes", 0)) * frame_ratio + float(sizes.get("preview_bytes", 0)))
	return {"sample_frames": sample_frames, "target_frames": target_frames,
		"estimated_capture_seconds": capture_seconds, "estimated_encoding_seconds": encoding_seconds,
		"estimated_total_seconds": capture_seconds + encoding_seconds + verification_seconds + fixed_seconds,
		"estimated_retained_bytes": disk_bytes,
		"suggested_free_bytes": ceili(disk_bytes * 1.25) + Storage.RESERVE + Storage.capture_headroom(target),
		"note": "Extrapolated from the first second. Suggested free space includes 25%, a 256 MiB reserve and capture working headroom. Later scene complexity and file sizes can change; space is not reserved."}


static func load_sample(folder: String) -> Dictionary:
	var job := IO.read_json(folder.path_join("job.json"))
	var report := IO.read_json(folder.path_join("report.json"))
	if job.get("mode") != "test" or not report.get("ok", false):
		return {}
	return {"folder": folder, "job": job, "report": report,
		"storage": IO.read_json(folder.path_join("storage.json"))}


static func resolve_reencode(request: Dictionary) -> Dictionary:
	var source: String = str(request.get("source_dir", ""))
	if not source.is_absolute_path():
		return {"error": "Select an absolute source capture folder."}
	var recipe := IO.read_json(source.path_join("job.json"))
	var capture := IO.read_json(source.path_join("capture-result.json"))
	if recipe.is_empty() or not capture.get("ok", false) or not DirAccess.dir_exists_absolute(source.path_join("frames")):
		return {"error": "Select an original capture folder with completed PNG frames and WAV audio."}
	var saved_border_error := CaptureProjection.validate(recipe)
	if not saved_border_error.is_empty():
		return {"error": "Saved capture: " + saved_border_error}
	var saved_exposure_error := Exposure.validate(recipe)
	if not saved_exposure_error.is_empty():
		return {"error": "Saved capture: " + saved_exposure_error}
	if request.has("capture_exposure_mode"):
		var exposure_error := Exposure.validate(request)
		if not exposure_error.is_empty():
			return {"error": exposure_error}
		if request.capture_exposure_mode != recipe.get("capture_exposure_mode", "scene"):
			return {"error": "Re-encoding preserves captured exposure and pixels. Start a new render to change capture exposure."}
	for key in ["rendering_method", "rendering_driver"]:
		if request.has(key) and str(request[key]) != str(recipe.get(key, "project")):
			return {"error": "Re-encoding preserves the captured renderer and pixels. Start a new render to change the renderer or graphics driver."}
	if request.has("capture_border_percent"):
		var border_error := CaptureProjection.validate(request)
		if not border_error.is_empty():
			return {"error": border_error}
		if float(request.capture_border_percent) != float(recipe.get("capture_border_percent", 0.0)):
			return {"error": "Re-encoding preserves the original capture border and pixels. Start a new render to change the capture border."}
	var destination: String = str(request.get("output_dir", ""))
	var normalized_source := source.replace("\\", "/").simplify_path().trim_suffix("/").to_lower()
	var normalized_output := destination.replace("\\", "/").simplify_path().trim_suffix("/").to_lower()
	if normalized_output == normalized_source or normalized_output.begins_with(normalized_source + "/"):
		return {"error": "Re-encode output must be outside the original capture folder."}
	recipe.mode = "reencode"
	recipe.source_dir = source
	recipe.output_dir = destination
	recipe.ffmpeg = request.get("ffmpeg", "ffmpeg")
	recipe.ffprobe = request.get("ffprobe", "ffprobe")
	recipe.crf = request.get("crf", recipe.get("crf", 18))
	for key in Audio.DEFAULTS:
		if request.has(key):
			recipe[key] = request[key]
	if request.has("soundtrack_path"):
		recipe.erase("soundtrack_resolved_path")
	recipe.erase("audio_signature")
	recipe.erase("target_frames")
	var error := IO.validate(recipe)
	return {"job": recipe, "error": error}


static func validate_frames(source: String, recipe: Dictionary) -> String:
	var frames := source.path_join("frames")
	var total: int = int(recipe.frames) + int(recipe.get("warmup_frames", 2))
	var png_count: int = 0
	for name in DirAccess.get_files_at(frames):
		if name.ends_with(".png"):
			png_count += 1
	if png_count != total:
		return "Source sequence has %d PNG files; expected %d." % [png_count, total]
	for index in range(total):
		var file := FileAccess.open(frames.path_join("frame%08d.png" % index), FileAccess.READ)
		if file == null or file.get_length() < 33:
			return "Missing or incomplete source frame %d." % index
		if file.get_buffer(8) != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]):
			return "Invalid PNG signature in source frame %d." % index
		file.big_endian = true
		if file.get_32() != 13 or file.get_buffer(4).get_string_from_ascii() != "IHDR":
			return "Invalid PNG header in source frame %d." % index
		if file.get_32() != int(recipe.width) or file.get_32() != int(recipe.height):
			return "Source frame %d has different dimensions from its recipe." % index
	if file_size(frames.path_join("frame.wav")) <= 44:
		return "Source capture has no finalized WAV audio."
	var wav := FileAccess.open(frames.path_join("frame.wav"), FileAccess.READ)
	if wav.get_buffer(4).get_string_from_ascii() != "RIFF":
		return "Source audio is not a RIFF WAV file."
	wav.seek(8)
	if wav.get_buffer(4).get_string_from_ascii() != "WAVE":
		return "Source audio is not a WAVE stream."
	return ""


static func recovery(source: String) -> Dictionary:
	var recipe := IO.read_json(source.path_join("job.json"))
	var capture := IO.read_json(source.path_join("capture-result.json"))
	var error := "Capture did not complete."
	if capture.get("ok", false) and recipe.has("frames") and recipe.has("width") and recipe.has("height"):
		error = validate_frames(source, recipe)
	return {"source_dir": source, "can_reencode": error.is_empty(), "source_error": error,
		"next_step": "Fix the reported issue, then use Re-encode saved on the original capture folder." if error.is_empty()
		else "Restore a complete PNG/WAV capture or start a new render. Partial captures cannot resume."}


static func encoding_progress(contents: String) -> Dictionary:
	var current: Dictionary = {}
	var completed: Dictionary = {}
	for line in contents.split("\n"):
		var parts := line.strip_edges().split("=", true, 1)
		if parts.size() != 2:
			continue
		current[parts[0]] = parts[1].strip_edges()
		if parts[0] == "progress" and parts[1] in ["continue", "end"]:
			completed = current
			current = {}
	return completed
