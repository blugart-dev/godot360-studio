extends RefCounted


static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var value = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}


static func write_json(path: String, value: Dictionary) -> bool:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(value, "\t"))
	file.flush()
	var written := file.get_error() == OK
	file.close()
	if not written:
		return false
	# Windows readers can briefly prevent replacing an open status file. Retry
	# the atomic rename for at most 500 ms. Concurrent native renderer reviews
	# exposed a reader/share lock lasting beyond the old 50 ms window.
	for attempt in range(51):
		if DirAccess.rename_absolute(path + ".tmp", path) == OK:
			return true
		if attempt < 50:
			OS.delay_msec(10)
	return false


static func write_text(path: String, value: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(value)
	file.flush()
	return file.get_error() == OK


static func argument(name: String) -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with("--" + name + "="):
			return value.substr(name.length() + 3)
	return ""


static func validate(job: Dictionary) -> String:
	for key in ["scene_path", "camera_path", "width", "height", "face_size", "fps", "frames", "output_dir", "ffmpeg", "ffprobe"]:
		if not job.has(key):
			return "Missing job field: " + key
	if not str(job.get("mode", "render")) in ["render", "test", "reencode"]:
		return "Choose render, test, or reencode for job mode."
	if job.get("mode") != "reencode" and not ResourceLoader.exists(str(job.scene_path), "PackedScene"):
		return "Scene does not exist: " + str(job.scene_path)
	if int(job.width) != int(job.height) * 2 or int(job.width) % 4 != 0 or int(job.width) < 256 or int(job.width) > 7680:
		return "Output must be a 2:1 image, 256–7680 pixels wide, divisible by four."
	if not int(job.fps) in [24, 25, 30, 50, 60] or int(job.frames) < 1 or int(job.frames) > int(job.fps) * 3600:
		return "Choose 24, 25, 30, 50 or 60 fps and a duration up to one hour."
	if int(job.face_size) < 128 or int(job.face_size) > 4096:
		return "Face size must be between 128 and 4096 pixels."
	if int(job.get("warmup_frames", 2)) < 0 or int(job.get("warmup_frames", 2)) > 10:
		return "Warmup must be between zero and ten frames."
	if int(job.get("crf", 18)) < 12 or int(job.get("crf", 18)) > 28:
		return "CRF must be between 12 and 28."
	if not str(job.get("frame_writer", "png")) in ["png", "fast_png"]:
		return "Choose fast_png or png for frame storage."
	if job.get("mode") != "reencode":
		var renderer_error := preload("renderer_policy.gd").validate(job)
		if not renderer_error.is_empty():
			return renderer_error
	if not str(job.output_dir).is_absolute_path():
		return "Output directory must be absolute."
	if job.get("mode") == "test" and (int(job.get("target_frames", 0)) < int(job.frames) or int(job.get("target_frames", 0)) > int(job.fps) * 3600 or int(job.frames) > int(job.fps)):
		return "A test uses up to one second and requires a valid full-job frame count."
	return preload("audio_plan.gd").validate(job)


static func quality_advice(job: Dictionary) -> Array[String]:
	var messages: Array[String] = []
	var width: int = int(job.get("width", 0))
	var face_size: int = int(job.get("face_size", 0))
	if width <= 0 or face_size <= 0:
		return messages
	if width < 4096:
		messages.append("Draft resolution: a 90-degree view spans only about %d source columns. Use 4K or 8K for a sharper viewing window." % (width / 4))
	# At a face center, a square 90-degree camera supplies face_size / 2
	# samples per radian; equirectangular output needs width / TAU.
	var minimum_face: int = ceili(float(width) / PI)
	if face_size < minimum_face:
		messages.append("Cube faces limit detail near their centers. Use at least %d pixels per face for this output, or choose a quality preset." % minimum_face)
	return messages
