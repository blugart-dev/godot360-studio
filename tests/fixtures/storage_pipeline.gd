extends "res://addons/godot360/pipeline.gd"
## Disposable fault injection; never fills a real disk or changes permissions.
var metadata_reads := 0
var rendering_status_writes := 0


func _status(stage: String, progress: float, error: String = "") -> bool:
	if IO.argument("case") == "status-write" and stage == "Rendering":
		rendering_status_writes += 1
		if rendering_status_writes == 2:
			# Inject from the coordinator between its own writes. Doing this in
			# the capture worker raced an already-open status.json.tmp file.
			DirAccess.make_dir_recursive_absolute(folder.path_join("status.json.tmp"))
	return super._status(stage, progress, error)


func _make_storage_guard() -> RefCounted:
	var guard := Storage.new(folder)
	guard.sample_interval_msec = 0
	var scenario := IO.argument("case")
	if scenario in ["report-write", "preview-write"]:
		DirAccess.make_dir_recursive_absolute(folder.path_join("report.json.tmp" if scenario == "report-write" else "preview.png"))
	if scenario == "process-log-write":
		DirAccess.make_dir_recursive_absolute(folder.path_join("ffmpeg-check.log"))
	guard.space_reader = func() -> int:
		if scenario == "preflight-space":
			return 0
		if scenario == "encode-space" and phase == "Encoding H.264 + AAC" and runner != null:
			return 0
		if phase == "Writing spherical metadata" and scenario == "metadata-space":
			metadata_reads += 1
			if metadata_reads >= 3:
				return 0
		return 1000000000000
	return guard
