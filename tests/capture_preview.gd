extends SceneTree
## Optional render check. Use with --fixed-fps 60 -- --output-dir=/absolute/path
## A real rendering backend is required; do not pass --headless.

var scene: Node3D
var player: PlayerLook
var detector: GazeDetector
var output_dir: String = "user://previews"


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1280, 800)
	scene = load("res://scenes/Main.tscn").instantiate()
	scene.get_node("Player").auto_capture = false
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	player.set_process(false)
	detector = scene.get_node("Player/GazeDetector")
	scene.get_node("UI/HUD")._on_capture_changed(true)
	await wait_seconds(2.7)
	await save_view("01-front")
	detector.set_input_enabled(true)
	await wait_seconds(1.8)
	await save_view("02-awakened")
	aim(scene.get_node("World/GazeTargets/RightSignal").global_position)
	await wait_seconds(1.4)
	await save_view("03-right")
	aim(scene.get_node("World/GazeTargets/RearBloom").global_position)
	await wait_seconds(2.8)
	await save_view("04-rear")
	aim(scene.get_node("World/GazeTargets/Witness").global_position)
	await wait_seconds(1.5)
	await save_view("05-witness")
	aim(Vector3(0, 6.0, -1.8))
	await wait_seconds(0.2)
	await save_view("06-ceiling")
	print("PREVIEWS: " + output_dir)
	quit()


func aim(at: Vector3) -> void:
	var direction: Vector3 = (at - player.camera.global_position).normalized()
	player.rotation.y = atan2(-direction.x, -direction.z)
	player.camera.rotation.x = asin(direction.y)


func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame


func save_view(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var frame: Image = root.get_texture().get_image()
	var error: Error = frame.save_png(output_dir.path_join(filename + ".png"))
	if error != OK:
		push_error("Could not save " + filename)
		quit(1)
