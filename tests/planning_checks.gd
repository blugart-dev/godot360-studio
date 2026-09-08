extends SceneTree
const Planner = preload("res://addons/godot360/job_planner.gd")
const IO = preload("res://addons/godot360/job_io.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var root_folder := ProjectSettings.globalize_path("res://.godot360/planning-checks-" + str(Time.get_ticks_usec()))
	var target: Dictionary = preload("res://addons/godot360/export_profile.gd").new().to_dictionary()
	target.merge({"frames": 300, "output_dir": root_folder, "ffmpeg": "ffmpeg", "ffprobe": "ffprobe"}, true)
	var sample := Planner.test_job(target)
	check(sample.frames == 30 and sample.target_frames == 300 and target.frames == 300, "Test clamps capture to one second without changing the full recipe")
	check(IO.validate(sample).is_empty(), "The generated sample is a valid job")
	var short := target.duplicate()
	short.frames = 3
	check(Planner.test_job(short).frames == 3, "A test does not extend a shorter film")
	var report := {"ok": true, "capture_timings": {"elapsed_usec": 3200000},
		"pipeline_timings": {"stages_seconds": {"Rendering": 5.2, "Encoding H.264 + AAC": 1.0,
			"Verifying output": 0.5, "Checking tools": 0.2, "Writing spherical metadata": 0.1}}}
	var sizes := {"png_bytes": 32000, "png_count": 32, "wav_bytes": 3200, "encoded_bytes": 1000, "preview_bytes": 1000}
	var estimate := Planner.estimate(sample, report, sizes, target)
	check(is_equal_approx(float(estimate.estimated_capture_seconds), 32.2), "Capture estimate keeps startup fixed and scales warmup frames correctly")
	check(is_equal_approx(float(estimate.estimated_total_seconds), 47.5), "Total estimate includes encoding and verification")
	check(estimate.estimated_retained_bytes == 353200, "Storage estimate includes PNGs, WAV, preview, and both MP4 copies")
	check(estimate.suggested_free_bytes > estimate.estimated_retained_bytes, "Suggested free space includes explicit headroom")
	check(estimate.suggested_free_bytes >= estimate.estimated_retained_bytes + preload("res://addons/godot360/storage_guard.gd").capture_headroom(target) + 256 * 1024 * 1024, "Planning includes the capture guard's working floor as well as retained files")
	var longer := target.duplicate()
	longer.frames = 600
	check(Planner.estimate(sample, report, sizes, longer).estimated_total_seconds > estimate.estimated_total_seconds, "Duration can be rescaled without repeating the sample")
	for change in [{"width": 4096}, {"crf": 28}, {"frame_writer": "png"}, {"scene_path": "res://other.tscn"}, {"fps": 60}]:
		var changed := target.duplicate()
		changed.merge(change, true)
		check(Planner.estimate(sample, report, sizes, changed).is_empty(), "Changed production settings invalidate the sample: " + str(change))
	check(Planner.estimate(sample, {"ok": false}, sizes, target).is_empty(), "A failed test cannot produce an estimate")
	check(Planner.estimate(sample, report, {}, target).is_empty(), "Missing storage evidence cannot produce a disk estimate")
	var parsed := Planner.encoding_progress("frame=10\nprogress=continue\nframe=40\nprogress=continue\nframe=99\n")
	check(int(parsed.frame) == 40, "A partial progress record does not replace the last complete record")
	check(Planner.encoding_progress("frame=10\n").is_empty(), "An incomplete first progress record is ignored")
	check(Planner.encoding_progress("frame=300\nprogress=end\n").progress == "end", "The final encoder progress record is accepted")
	var capture_folder := root_folder.path_join("capture")
	DirAccess.make_dir_recursive_absolute(root_folder)
	var empty_storage := Planner.storage(root_folder)
	check(empty_storage.png_count == 0 and empty_storage.png_bytes == 0 and empty_storage.wav_bytes == 0, "Re-encode storage allows an output folder without captured frames")
	DirAccess.make_dir_recursive_absolute(capture_folder.path_join("frames"))
	var source := target.duplicate()
	source.merge({"width": 256, "height": 128, "frames": 1, "warmup_frames": 0,
		"scene_path": "res://scene-no-longer-installed.tscn", "output_dir": capture_folder}, true)
	IO.write_json(capture_folder.path_join("job.json"), source)
	IO.write_json(capture_folder.path_join("capture-result.json"), {"ok": true, "rendered": 1})
	var request := {"source_dir": capture_folder, "output_dir": root_folder.path_join("reencode"),
		"ffmpeg": "ffmpeg", "ffprobe": "ffprobe", "crf": 25, "width": 2048, "fps": 60}
	var resolved := Planner.resolve_reencode(request)
	check(resolved.error.is_empty(), "Completed capture can be re-encoded after its scene is unavailable")
	check(resolved.job.width == 256 and resolved.job.fps == 30 and resolved.job.crf == 25, "Re-encoding locks captured dimensions/timing and applies only requested encoding quality")
	request.rendering_method = "forward_plus"
	check(Planner.resolve_reencode(request).error.contains("new render"), "Re-encoding cannot relabel captured pixels with a different renderer")
	request.erase("rendering_method")
	check(resolved.job.rendering_method == source.rendering_method, "Re-encoding retains the original renderer selection")
	request.capture_border_percent = 12.5
	check(Planner.resolve_reencode(request).error.contains("new render"), "Re-encoding rejects a change to the captured border")
	request.capture_border_percent = "invalid"
	check(not Planner.resolve_reencode(request).error.is_empty(), "Malformed re-encode border requests cannot become zero silently")
	request.erase("capture_border_percent")
	source.capture_border_percent = 12.5
	IO.write_json(capture_folder.path_join("job.json"), source)
	check(Planner.resolve_reencode(request).job.capture_border_percent == 12.5, "Re-encoding preserves a retained nonzero border without a request override")
	request.capture_border_percent = 12.5
	check(Planner.resolve_reencode(request).error.is_empty(), "An explicitly unchanged capture border is allowed for re-encoding")
	for invalid in [{}, [], "invalid", null]:
		var corrupt_source := source.duplicate(true)
		corrupt_source.capture_border_percent = invalid
		IO.write_json(capture_folder.path_join("job.json"), corrupt_source)
		check(Planner.resolve_reencode(request).error.begins_with("Saved capture:"), "Malformed saved borders produce an actionable re-encode error")
	IO.write_json(capture_folder.path_join("job.json"), source)
	request.erase("capture_border_percent")
	request.output_dir = capture_folder.path_join("nested-output")
	check(not Planner.resolve_reencode(request).error.is_empty(), "Re-encode output cannot write inside its source capture")
	check(not Planner.validate_frames(capture_folder, source).is_empty(), "A missing sequence is rejected")
	var image := Image.create(256, 128, false, Image.FORMAT_RGB8)
	image.save_png(capture_folder.path_join("frames/frame00000000.png"))
	check(not Planner.validate_frames(capture_folder, source).is_empty(), "Missing source WAV is rejected")
	check(not Planner.recovery(capture_folder).can_reencode, "Recovery rejects a completed marker without its WAV")
	var wav := FileAccess.open(capture_folder.path_join("frames/frame.wav"), FileAccess.WRITE)
	wav.store_buffer("RIFF".to_ascii_buffer())
	wav.store_32(40)
	wav.store_buffer("WAVEfmt ".to_ascii_buffer())
	wav.store_32(16)
	wav.store_16(1)
	wav.store_16(2)
	wav.store_32(48000)
	wav.store_32(192000)
	wav.store_16(4)
	wav.store_16(16)
	wav.store_buffer("data".to_ascii_buffer())
	wav.store_32(4)
	wav.store_32(0)
	wav.close()
	check(Planner.validate_frames(capture_folder, source).is_empty(), "A correctly named PNG sequence and WAV header are accepted")
	check(Planner.recovery(capture_folder).can_reencode, "Recovery recognizes a reusable capture after its scene is removed")
	IO.write_json(capture_folder.path_join("capture-result.json"), {"ok": false, "rendered": 1})
	check(not Planner.recovery(capture_folder).can_reencode, "A full-looking but interrupted capture cannot resume")
	IO.write_json(capture_folder.path_join("capture-result.json"), {"ok": true, "rendered": 1})
	Image.create(128, 128, false, Image.FORMAT_RGB8).save_png(capture_folder.path_join("frames/frame00000000.png"))
	check(Planner.validate_frames(capture_folder, source).contains("dimensions"), "Mismatched source PNG dimensions fail before encoding")
	check(not Planner.recovery(capture_folder).can_reencode, "Recovery rejects frames with the wrong dimensions")
	image.save_png(capture_folder.path_join("frames/frame00000001.png"))
	check(Planner.validate_frames(capture_folder, source).contains("expected"), "Extra PNG files cannot silently alter the sequence")
	print("PLANNING CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
