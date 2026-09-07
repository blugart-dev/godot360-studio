extends SceneTree
## Exit immediately after starting an independent coordinator, like closing an editor.
const IO = preload("res://addons/umbral360/job_io.gd")


func _initialize() -> void:
	var job_path := IO.argument("job")
	var folder := job_path.get_base_dir()
	var pid := OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--log-file", folder.path_join("pipeline.log"), "--script", "res://addons/umbral360/pipeline.gd", "--", "--job=" + job_path])
	# Keep launcher evidence outside the fresh job folder.
	IO.write_json(folder + "-launcher.json", {"pid": pid})
	quit(0 if pid > 0 else 1)
