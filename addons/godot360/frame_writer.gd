extends RefCounted
## Lossless PNG storage. A blocking pipe applies backpressure without queuing frames.

var backend: String = "png"
var process_id: int = -1
var settings: Dictionary
var input_pipe: FileAccess
var error_reader: Thread
var image_format: int = -1
var frame_count: int = 0
var last_error: String = ""


func configure(job: Dictionary) -> void:
	settings = job
	backend = str(job.get("frame_writer", "png"))


func write_frame(frame: Image) -> bool:
	if frame.get_size() != Vector2i(int(settings.width), int(settings.height)):
		last_error = "Frame dimensions changed during capture."
		return false
	if backend == "png":
		if frame.save_png(str(settings.output_dir).path_join("frames/frame%08d.png" % frame_count)) != OK:
			last_error = "Cannot save PNG. Check the output folder and available disk space."
			return false
	else:
		if image_format < 0 and not _start_pipe(frame.get_format()):
			return false
		if frame.get_format() != image_format:
			last_error = "Frame pixel format changed during capture."
			return false
		if not OS.is_process_running(process_id):
			last_error = "The PNG writer stopped unexpectedly. See frame-writer.log."
			return false
		input_pipe.store_buffer(frame.get_data())
		if input_pipe.get_error() != OK:
			last_error = "Cannot send a frame to FFmpeg. See frame-writer.log."
			return false
	frame_count += 1
	return true


func _start_pipe(format: int) -> bool:
	if not format in [Image.FORMAT_RGB8, Image.FORMAT_RGBA8]:
		last_error = "Fast PNG requires RGB8 or RGBA8 capture pixels."
		return false
	var folder: String = str(settings.output_dir)
	var log := FileAccess.open(folder.path_join("frame-writer.log"), FileAccess.WRITE)
	if log == null:
		last_error = "Cannot create the PNG writer log."
		return false
	var child := OS.execute_with_pipe(str(settings.ffmpeg), PackedStringArray([
		"-hide_banner", "-loglevel", "error", "-nostdin", "-n",
		"-f", "rawvideo", "-pixel_format", "rgb24" if format == Image.FORMAT_RGB8 else "rgba",
		"-video_size", "%dx%d" % [int(settings.width), int(settings.height)],
		"-framerate", str(int(settings.fps)), "-i", "pipe:0", "-an",
		"-c:v", "png", "-compression_level", "1", "-pred", "sub", "-threads", "1",
		"-start_number", "0", folder.path_join("frames/frame%08d.png")]), true)
	if child.is_empty():
		last_error = "Could not start the fast PNG writer. Check FFmpeg or select Compact PNG."
		return false
	process_id = int(child.pid)
	input_pipe = child.stdio
	image_format = format
	# Drain stderr concurrently: even a failing encoder must never fill its pipe.
	# Only this thread owns the error pipe and log while the encoder is running.
	var error_pipe: FileAccess = child.stderr
	error_reader = Thread.new()
	var reader_error := error_reader.start(func() -> bool:
		var written := true
		while true:
			var bytes := error_pipe.get_buffer(4096)
			if bytes.is_empty():
				break
			log.store_buffer(bytes)
			written = written and log.get_error() == OK
		error_pipe.close()
		log.flush()
		written = written and log.get_error() == OK
		log.close()
		return written)
	if reader_error != OK:
		last_error = "Cannot start the PNG writer log reader."
		error_pipe.close()
		abort()
		return false
	return last_error.is_empty()


func finish() -> bool:
	if process_id <= 0:
		return last_error.is_empty()
	input_pipe.close()
	var deadline: int = Time.get_ticks_msec() + 30000
	while OS.is_process_running(process_id) and Time.get_ticks_msec() < deadline:
		if FileAccess.file_exists(str(settings.output_dir).path_join("cancel.request")):
			last_error = "Cancelled while finishing PNG storage."
			abort()
			return false
		OS.delay_msec(10)
	if OS.is_process_running(process_id):
		last_error = "PNG writer did not finish within 30 seconds. See frame-writer.log."
		abort()
		return false
	var exit_code: int = OS.get_process_exit_code(process_id)
	_join_error_reader()
	process_id = -1
	if exit_code != 0:
		last_error = "PNG writer failed (exit %d). See frame-writer.log." % exit_code
		return false
	return last_error.is_empty()


func abort() -> void:
	if process_id > 0 and OS.is_process_running(process_id):
		OS.kill(process_id)
	if input_pipe != null and input_pipe.is_open():
		input_pipe.close()
	_join_error_reader()
	process_id = -1


func _join_error_reader() -> void:
	if error_reader != null and error_reader.is_started():
		if not bool(error_reader.wait_to_finish()) and last_error.is_empty():
			last_error = "Cannot write the PNG writer log. Check output folder access and disk space."
	error_reader = null
