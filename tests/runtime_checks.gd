extends SceneTree
## Integration tests against the real scene, physics rays and signal connections.
## godot --headless --path . --fixed-fps 60 --script res://tests/runtime_checks.gd

var scene: Node3D
var player: PlayerLook
var detector: GazeDetector
var core: GazeTarget
var rear: GazeTarget
var witness: GazeTarget
var right: GazeTarget
var counts: Dictionary = {}
var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	scene = load("res://scenes/Main.tscn").instantiate()
	scene.get_node("Player").auto_capture = false
	root.add_child(scene)
	current_scene = scene
	player = scene.get_node("Player")
	detector = scene.get_node("Player/GazeDetector")
	core = scene.get_node("World/GazeTargets/Core")
	rear = scene.get_node("World/GazeTargets/RearBloom")
	witness = scene.get_node("World/GazeTargets/Witness")
	right = scene.get_node("World/GazeTargets/RightSignal")
	for target in [core, rear, witness, right]:
		counts[target.name] = 0
		target.gaze_activated.connect(func(): counts[target.name] += 1)
	player.set_process(false)
	detector.set_input_enabled(true)
	await wait_seconds(0.15)
	check(detector.current_target == null and not core.enabled, "0 s: core hidden and inactive")
	check(get_nodes_in_group("gaze_targets").size() == 4, "Four targets registered")
	await _test_camera()
	await _test_controls()
	detector.set_input_enabled(true)
	aim(Vector3(0, 12, -5))
	await wait_seconds(2.05)
	check(core.enabled and scene.get_node("SequenceController").stage >= 1, "2 s: core appears")
	await _test_core()
	await _test_occlusion()
	await _test_context()
	await _test_rear()
	await _test_repeatable()
	await _test_removal()
	await _test_panorama()
	check(scene.get_node("SequenceController").stage == 3, "Automatic sequence completes at 8 s")
	check(scene.get_node("World/Props").rear_trail[13].visible, "Spatial cue toward the rear is visible")
	check(scene.get_node("UI/HUD").discoveries == 4, "HUD: four unique discoveries")
	check(scene.get_node("UI/HUD/MessagePanel/Message").text.contains("Four traces"), "Narrative ending is visible")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_camera() -> void:
	var initial_position: Vector3 = player.position
	player.apply_mouse_motion(Vector2(720.0 / player.mouse_sensitivity, -100000))
	check(is_equal_approx(player.target_yaw, -TAU * 2.0), "Yaw allows multiple turns")
	check(is_equal_approx(rad_to_deg(player.target_pitch), 85.0), "Upper pitch is limited to 85°")
	player.apply_mouse_motion(Vector2(0, 200000))
	check(is_equal_approx(rad_to_deg(player.target_pitch), -85.0), "Lower pitch is limited to -85°")
	player.target_yaw = 1.0
	player.target_pitch = 0.5
	player._process(1.0 / 60.0)
	check(player.rotation.y > 0.0 and player.rotation.y < 1.0, "Smoothing interpolates the camera")
	player.recenter()
	for frame in range(120):
		player._process(1.0 / 60.0)
	check(absf(player.rotation.y) < 0.001 and absf(player.camera.rotation.x) < 0.001, "R recenters smoothly")
	check(player.position == initial_position, "Player position remains fixed")


func _test_core() -> void:
	aim(core.global_position)
	await wait_seconds(0.45)
	check(detector.current_target == core and detector.gaze_seconds > 0.3, "A real physics ray detects the core")
	check(counts[core.name] == 0, "A brief gaze does not activate the target")
	check(scene.get_node("UI/HUD/Crosshair").progress > 0.0, "Crosshair displays progress")
	aim(Vector3(0, 12, -5))
	await wait_seconds(0.1)
	check(detector.gaze_seconds == 0.0 and detector.current_target == null, "Looking away resets the timer")
	aim(core.global_position)
	await wait_seconds(0.5)
	detector.set_input_enabled(false)
	check(detector.gaze_seconds == 0.0 and not core.is_gazing, "Releasing input cancels the gaze")
	await wait_seconds(1.1)
	check(counts[core.name] == 0, "Released input prevents accidental activation")
	detector.set_input_enabled(true)
	await wait_seconds(1.2)
	check(counts[core.name] == 1 and core.get_node("Visual").awakened, "One second triggers appearance and animation")
	await wait_seconds(0.8)
	check(core.get_node("Visual").orb_material.albedo_color.is_equal_approx(Color("b0efd3")), "Material transition completes")
	check(scene.get_node("UI/HUD/MessagePanel/Message").text.contains("You found"), "Activation displays its message")
	aim(Vector3(0, 12, -5))
	await wait_seconds(0.1)
	aim(core.global_position)
	await wait_seconds(1.2)
	check(counts[core.name] == 1, "A one-shot target cannot reactivate")


func _test_controls() -> void:
	await press_key(KEY_ESCAPE)
	check(player.captured and detector.input_enabled, "Esc captures the mouse and enables interaction")
	var old_yaw: float = player.target_yaw
	var motion := InputEventMouseMotion.new()
	motion.screen_relative = Vector2(50, 20)
	Input.parse_input_event(motion)
	await wait_seconds(0.05)
	check(player.target_yaw < old_yaw, "A real mouse event changes yaw")
	await press_key(KEY_ESCAPE)
	check(not player.captured and not detector.input_enabled, "Esc releases the mouse and suspends interaction")
	old_yaw = player.target_yaw
	Input.parse_input_event(motion)
	await wait_seconds(0.05)
	check(player.target_yaw == old_yaw, "Released mouse motion does not move the camera")
	await press_key(KEY_R)
	check(is_zero_approx(player.target_pitch), "A real R key event recenters pitch")
	await press_key(KEY_F3)
	check(scene.get_node("UI/HUD").debug_enabled, "F3 enables FPS, target and gaze time")
	await press_key(KEY_F3)
	check(not scene.get_node("UI/HUD").debug_enabled, "F3 hides debug information")


func press_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await wait_seconds(0.03)
	event.pressed = false
	Input.parse_input_event(event)


func _test_occlusion() -> void:
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 3, 0.3)
	shape.shape = box
	wall.add_child(shape)
	scene.add_child(wall)
	wall.global_position = player.camera.global_position.lerp(core.global_position, 0.5)
	aim(core.global_position)
	await wait_seconds(0.1)
	check(detector.current_target == null, "An opaque body blocks the gaze")
	wall.queue_free()
	await wait_seconds(0.1)
	check(detector.current_target == core, "Removing the obstacle restores detection")


func _test_context() -> void:
	var before: Vector3 = witness.position
	aim(core.global_position)
	await wait_seconds(0.6)
	check(witness.position.distance_to(before) > 0.1, "The witness moves while watching the core")
	aim(witness.global_position)
	await wait_seconds(0.1)
	var stopped_at: Vector3 = witness.position
	await wait_seconds(1.2)
	check(witness.position.is_equal_approx(stopped_at), "Looking at the witness stops it")
	check(counts[witness.name] == 1 and not witness.walking, "The witness responds with its own event")


func _test_rear() -> void:
	var before: Vector3 = rear.position
	aim(rear.global_position)
	await wait_seconds(1.2)
	check(counts[rear.name] == 1 and rear.get_node("Visual").opened, "The object behind the viewer can be discovered")
	await wait_seconds(1.8)
	check(rear.position.y > before.y + 0.8, "The bloom rises with its collision")
	check(rear.get_node("Visual").petals[0].position.length() > 1.0, "The bloom opens its petals")


func _test_repeatable() -> void:
	check(right.get_node("Visual").pulses >= 1, "5 s: animated cue on the right")
	aim(right.global_position)
	await wait_seconds(1.2)
	check(counts[right.name] == 1, "Repeatable target: first activation")
	await wait_seconds(1.5)
	check(counts[right.name] == 1, "Holding gaze does not emit an event every frame")
	aim(Vector3(0, 12, -5))
	await wait_seconds(0.1)
	aim(right.global_position)
	await wait_seconds(1.2)
	check(counts[right.name] == 2, "Repeatable target rearms after looking away")


func _test_removal() -> void:
	var temporary := GazeTarget.new()
	temporary.collision_layer = 2
	temporary.dwell_time = 5.0
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	temporary.add_child(shape)
	scene.add_child(temporary)
	temporary.position = Vector3(0, 3, -3)
	aim(temporary.global_position)
	await wait_seconds(0.3)
	check(detector.current_target == temporary, "A dynamically added target is detected")
	temporary.queue_free()
	aim(Vector3(0, 12, -5))
	await wait_seconds(0.1)
	check(not is_instance_valid(detector.current_target) and detector.gaze_seconds == 0.0,
		"Removing the watched target clears its state")
	var completed_target := GazeTarget.new()
	completed_target.collision_layer = 2
	completed_target.has_activated = true
	var completed_shape := CollisionShape3D.new()
	completed_shape.shape = SphereShape3D.new()
	completed_target.add_child(completed_shape)
	scene.add_child(completed_target)
	completed_target.position = Vector3(0, 3, -3)
	aim(completed_target.global_position)
	await wait_seconds(0.1)
	check(detector.current_target == completed_target and detector.gaze_seconds == 0.0,
		"A completed target is recognized without accumulating time")
	completed_target.queue_free()
	aim(Vector3(0, 12, -5))
	await wait_seconds(0.1)
	check(not scene.get_node("UI/HUD/Crosshair").active,
		"Removing a completed target clears the crosshair")


func _test_panorama() -> void:
	var background: WorldEnvironment = scene.get_node("World/Environment")
	var placeholder := GradientTexture2D.new()
	placeholder.gradient = Gradient.new()
	placeholder.width = 128
	placeholder.height = 64
	background.panorama_texture = placeholder
	background.apply_background()
	check(background.environment.sky.sky_material is PanoramaSkyMaterial, "A 2:1 texture activates PanoramaSkyMaterial")
	background.panorama_texture = null
	background.apply_background()
	check(background.environment.sky.sky_material is ProceduralSkyMaterial, "Removing the texture restores the procedural sky")


func aim(at: Vector3) -> void:
	var direction: Vector3 = (at - player.camera.global_position).normalized()
	player.rotation.y = atan2(-direction.x, -direction.z)
	player.camera.rotation.x = asin(direction.y)
	player.target_yaw = player.rotation.y
	player.target_pitch = player.camera.rotation.x


func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
	await physics_frame
	await process_frame


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
