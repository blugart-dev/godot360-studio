extends RefCounted
## Working headroom, not a reservation or an estimate of the whole render.
const RESERVE = 256 * 1024 * 1024
var folder: String
var space_reader: Callable
var sampled_at := -1000
var sample_interval_msec := 250
var available := -1
var minimum_available := -1
var latest: Dictionary = {}


func _init(path: String = "") -> void:
	folder = path


static func frame_bound(job: Dictionary) -> int:
	# RGBA8 plus PNG/deflate overhead, independent of scene compressibility.
	return ceili(int(job.width) * int(job.height) * 4.0 * 1.01) + 65536


static func capture_headroom(job: Dictionary) -> int:
	# Own image, pipe/encoder image, current/previous Movie Maker scratch images,
	# plus conservatively budgeted stereo 32-bit PCM for the full capture duration.
	return frame_bound(job) * 4 + ceili((int(job.frames) + int(job.get("warmup_frames", 2))) * 48000.0 * 8 / int(job.fps)) + 65536


func check(working_bytes: int, stage: String, force: bool = false) -> Dictionary:
	if force or Time.get_ticks_msec() - sampled_at >= sample_interval_msec:
		sampled_at = Time.get_ticks_msec()
		if space_reader.is_valid():
			available = int(space_reader.call())
		else:
			var directory := DirAccess.open(folder)
			available = directory.get_space_left() if directory != null else -1
		if available >= 0:
			minimum_available = available if minimum_available < 0 else mini(minimum_available, available)
	var required := RESERVE + maxi(0, working_bytes)
	var error := ""
	if available < 0:
		error = "Cannot determine available disk space in the output folder. Check the drive and folder access."
	elif available < required:
		error = "Insufficient disk space during %s: %.1f MiB available; %.1f MiB working headroom required. Free space or choose another output drive." % [stage, available / 1048576.0, required / 1048576.0]
	latest = {"stage": stage, "available_bytes": available, "required_bytes": required,
		"reserve_bytes": RESERVE, "working_bytes": working_bytes, "minimum_available_bytes": minimum_available, "error": error}
	return latest
