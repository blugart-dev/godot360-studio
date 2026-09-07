extends SceneTree
## Real FFmpeg round trips, frame ordering, rejected input, and child-process cleanup.
const Writer = preload("res://addons/umbral360/frame_writer.gd")
const IO = preload("res://addons/umbral360/job_io.gd")
var checks: int = 0
var failures: int = 0
var base: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	base = ProjectSettings.globalize_path("res://.umbral360/frame-writer-checks-" + str(Time.get_ticks_usec()))
	for format in [Image.FORMAT_RGB8, Image.FORMAT_RGBA8]:
		var settings := _settings("roundtrip-" + str(format))
		var writer = Writer.new()
		writer.configure(settings)
		var frames: Array[Image] = []
		for index in range(3):
			var frame := Image.create(256, 128, false, format)
			frame.fill(Color(0.13 * (index + 1), 0.41, 0.79, 0.27 * (index + 1)))
			frame.fill_rect(Rect2i(9 + index * 13, 7, 23, 41), Color(0.8, 0.2, 0.37, 0.5))
			frames.append(frame)
			check(writer.write_frame(frame), "Frame is accepted by the real PNG pipe")
		var child_pid: int = writer.process_id
		check(writer.finish(), "PNG writer flushes and exits successfully")
		check(not OS.is_process_running(child_pid), "Completed writer leaves no running encoder")
		var names := DirAccess.get_files_at(str(settings.output_dir).path_join("frames"))
		check(names.size() == frames.size(), "Only the requested frames are stored")
		for index in range(frames.size()):
			var restored := Image.load_from_file(str(settings.output_dir).path_join("frames/frame%08d.png" % index))
			check(restored != null and restored.get_data() == frames[index].get_data(), "Frame order and every RGB/RGBA byte survive compression")
	var failed = Writer.new()
	failed.configure(_settings("terminated"))
	var frame := Image.create(256, 128, false, Image.FORMAT_RGBA8)
	frame.fill(Color.CORNFLOWER_BLUE)
	check(failed.write_frame(frame), "Writer starts before the interruption test")
	var child_pid: int = failed.process_id
	OS.kill(child_pid)
	check(not failed.write_frame(frame), "An interrupted encoder is reported as a write failure")
	failed.abort()
	check(not OS.is_process_running(child_pid), "Aborted writer leaves no running encoder")
	var mismatch = Writer.new()
	mismatch.configure(_settings("wrong-size"))
	check(not mismatch.write_frame(Image.create(128, 128, false, Image.FORMAT_RGBA8)), "Wrong dimensions fail before launching an encoder")
	check(mismatch.process_id <= 0, "Invalid input starts no child process")
	var invalid_path = Writer.new()
	var invalid_settings := _settings("invalid-executable")
	invalid_settings.ffmpeg = base.path_join("does-not-exist.exe")
	invalid_path.configure(invalid_settings)
	check(not invalid_path.write_frame(frame), "Missing FFmpeg is reported without leaving a job running")
	invalid_path.abort()
	var cancelled = Writer.new()
	var cancelled_settings := _settings("cancelled")
	cancelled.configure(cancelled_settings)
	check(cancelled.write_frame(frame), "Writer starts before cancellation")
	child_pid = cancelled.process_id
	cancelled.abort()
	check(not OS.is_process_running(child_pid), "Cancellation closes a live writer and joins its log reader")
	print("FRAME WRITER CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _settings(name: String) -> Dictionary:
	var folder := base.path_join(name)
	DirAccess.make_dir_recursive_absolute(folder.path_join("frames"))
	return {"frame_writer": "fast_png", "width": 256, "height": 128, "fps": 30,
		"ffmpeg": IO.argument("ffmpeg"), "output_dir": folder}


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
