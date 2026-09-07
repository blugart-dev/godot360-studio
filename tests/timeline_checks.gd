extends SceneTree
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = load("res://addons/umbral360/examples/timeline.tscn").instantiate()
	scene.play_sync_audio = false
	var job := {"fps": 30, "frames": 180, "warmup_frames": 2}
	scene.prepare_360_capture(job)
	root.add_child(scene)
	var initialized: bool = scene.begin_360_capture(job).is_empty()
	check(initialized, "Editable example initializes its capture timeline")
	if not initialized:
		# A missing library is a useful compatibility failure, not a null-access
		# crash that leaves the headless test waiting forever.
		scene.free()
		print("TIMELINE CHECKS: %d checks, %d failures" % [checks, failures])
		quit(1)
		return
	var player: AnimationPlayer = scene.get_node("AnimationPlayer")
	check(player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL, "Capture owns animation sampling instead of idle time")
	var camera: Camera3D = scene.get_node("CameraPath/Follow/Camera3D")
	scene.sample_360_frame(0, 0.0, job)
	var start := camera.global_position
	check(start.is_equal_approx(Vector3(-0.4, 0, 0)), "Frame zero samples the start of the camera path")
	check(not scene.get_node("SyncFlash").visible and scene.get_node("Title").visible, "Initial discrete visibility tracks are applied")
	scene.sample_360_frame(30, 1.0, job)
	check(scene.get_node("SyncFlash").visible, "A discrete cue activates on its exact frame")
	check(camera.global_position.distance_to(start) > 0.05, "PathFollow3D moves the capture camera")
	scene.sample_360_frame(33, 1.1, job)
	check(not scene.get_node("SyncFlash").visible, "A discrete cue ends on its exact frame")
	scene.sample_360_frame(90, 3.0, job)
	check(not scene.get_node("Title").visible, "A world-space title follows the authored timeline")
	check(absf(scene.get_node("HorizontalOrbit").rotation.y + PI) < 0.00001, "Absolute sampling reaches the rear seam at three seconds")
	scene.sample_360_frame(45, 1.5, job)
	check(absf(scene.get_node("VerticalOrbit").rotation.x - PI) < 0.00001, "The vertical orbit follows its keyed phase")
	check(scene.get_node("Title").visible, "Seeking backward restores authored property state")
	var sampled := camera.global_transform
	await process_frame
	await process_frame
	check(camera.global_transform.is_equal_approx(sampled), "Unrelated idle frames do not advance a captured timeline")
	for fps in [24, 30, 60]:
		scene.sample_360_frame(fps * 3, 3.0, {"fps": fps})
		check(absf(scene.get_node("HorizontalOrbit").rotation.y + PI) < 0.00001, "Authored timing is consistent at %d FPS" % fps)
	check(not scene.begin_360_capture({"fps": 30, "frames": 211}).is_empty(), "An export beyond the animation is rejected")
	var animation := player.get_animation("film")
	animation.loop_mode = Animation.LOOP_LINEAR
	check(not scene.begin_360_capture(job).is_empty(), "Looping timelines are rejected explicitly")
	animation.loop_mode = Animation.LOOP_NONE
	for kind in [Animation.TYPE_METHOD, Animation.TYPE_AUDIO, Animation.TYPE_ANIMATION]:
		var track := animation.add_track(kind)
		check(not scene.begin_360_capture(job).is_empty(), "Unsupported event track %d fails instead of being skipped silently" % kind)
		animation.remove_track(track)
	var discrete_track: int = animation.find_track(NodePath("Title:visible"), Animation.TYPE_VALUE)
	animation.track_set_key_time(discrete_track, 0, 0.1)
	check(not scene.begin_360_capture(job).is_empty(), "Discrete tracks require a defined state at time zero")
	animation.track_set_key_time(discrete_track, 0, 0.0)
	animation.value_track_set_update_mode(discrete_track, Animation.UPDATE_CAPTURE)
	check(not scene.begin_360_capture(job).is_empty(), "Live-state Capture update mode is rejected")
	animation.value_track_set_update_mode(discrete_track, Animation.UPDATE_DISCRETE)
	scene.animation_name = &"missing"
	check(not scene.begin_360_capture(job).is_empty(), "Missing animation fails before capture")
	scene.animation_player_path = NodePath("MissingPlayer")
	check(not scene.begin_360_capture(job).is_empty(), "Missing animation player fails before capture")
	scene.get_node("Audio").stop()
	await create_timer(0.05).timeout
	scene.free()
	print("TIMELINE CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
