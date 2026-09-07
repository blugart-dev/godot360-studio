extends SceneTree
## Real GPU storyboard from the same absolute-time scene used by the film exporter.
const IO = preload("res://addons/umbral360/job_io.gd")
var scene: Node3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var folder := IO.argument("output")
	if folder.is_empty():
		folder = ProjectSettings.globalize_path("res://.umbral360/threshold-storyboard")
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1280, 800)
	root.content_scale_size = root.size
	scene = load("res://scenes/films/Threshold.tscn").instantiate()
	scene.prepare_360_capture({})
	root.add_child(scene)
	scene.set_process(false)
	for sample in [[0.0, "opening"], [7.0, "archive"], [21.0, "desert"], [36.0, "garden"], [51.0, "engine"], [56.5, "ending"]]:
		scene.sample_360_frame(roundi(sample[0] * 30), sample[0], {})
		for direction in [0, 1]:
			scene.camera.rotation = Vector3(0.0, PI if direction else 0.0, 0)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join(sample[1] + ("-back" if direction else "-front") + ".png"))
	root.disable_3d = true
	root.size = Vector2i(960, 480)
	root.content_scale_size = Vector2i(2048, 1024)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	var rig := preload("res://addons/umbral360/capture_rig.gd").new()
	root.add_child(rig)
	rig.build(scene.camera, 1024, Vector2i(2048, 1024))
	rig.set_process(false)
	var records := []
	for t in [0.0, 7.0, 12.8, 13.5, 14.0, 14.5, 21.0, 28.5, 29.0, 36.0, 43.5, 44.0, 51.0, 56.5, 59.966667]:
		scene.sample_360_frame(roundi(t * 30), t, {})
		rig.sync_camera()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := folder.path_join("panorama-%05.2f.png" % t)
		var saved := image.save_png(path)
		records.append({"time": t, "chapter": scene.chapter_at(t), "transition": scene.transition_at(t), "path": path,
			"saved": saved == OK, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
		print("STORYBOARD ", t, " ", scene.CHAPTERS[scene.chapter_at(t)])
	IO.write_json(folder.path_join("storyboard.json"), {"frames": records, "node_count": scene.find_children("*", "", true, false).size()})
	quit()
