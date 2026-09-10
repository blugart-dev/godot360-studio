extends SceneTree
const IO = preload("res://addons/godot360/job_io.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var folder := IO.argument("output")
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1440, 900)
	root.content_scale_size = root.size
	var scene = load("res://scenes/films/Afterglow.tscn").instantiate()
	scene.prepare_360_capture({})
	root.add_child(scene)
	scene.set_process(false)
	for time in [2.0, 12.0, 25.0, 34.0, 43.0, 49.0]:
		scene.sample_360_frame(roundi(time * 30), time, {})
		for direction in [0, 1, 2]:
			scene.camera.rotation = Vector3(-.12 if direction == 0 else .22, direction * TAU / 3, 0)
			for i in range(5):
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("view-%02d-%d.png" % [time, direction]))
		print("STORYBOARD ", time)
	quit()
