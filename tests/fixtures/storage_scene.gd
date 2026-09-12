extends Node3D
## Controlled write/space faults inside a disposable capture worker.
var job: Dictionary


func prepare_360_capture(settings: Dictionary) -> void:
	job = settings
	var folder := str(job.output_dir)
	var scenario := folder.get_file()
	if scenario == "capture-result-write":
		DirAccess.make_dir_recursive_absolute(folder.path_join("capture-result.json.tmp"))
	elif scenario == "capture-progress-write":
		DirAccess.make_dir_recursive_absolute(folder.path_join("render-progress.json.tmp"))


func _ready() -> void:
	if str(job.output_dir).get_file() == "capture-space":
		get_tree().storage.sample_interval_msec = 0
		get_tree().storage.space_reader = func() -> int: return 0 if get_tree().rendered >= 12 else 1000000000000
