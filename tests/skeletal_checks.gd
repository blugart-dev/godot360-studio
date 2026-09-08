extends SceneTree
const Rig = preload("res://addons/godot360/capture_rig.gd")
var checks := 0
var failures := 0
var sampled := -1
var expected: Transform3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for external in [false, true]:
		var job := {"fps": 30, "frames": 60, "external_skeleton": external}
		var scene = load("res://tests/fixtures/skeletal_scene.tscn").instantiate()
		scene.prepare_360_capture(job)
		root.add_child(scene)
		check(scene.begin_360_capture(job).is_empty(), "Bone timeline initializes")
		var camera: Camera3D = scene.camera
		var rig := Rig.new()
		root.add_child(rig)
		rig.build(camera, 32, Vector2i(64, 32))
		sampled = -1
		rig.before_sync = func():
			sampled += 1
			var seconds := (sampled % 60) / 30.0
			scene.sample_360_frame(sampled % 60, seconds, job)
			var x := 1.4 * seconds if seconds < 0.5 else (1.4 - 1.4 * seconds if seconds < 1.5 else 1.4 * seconds - 2.8)
			expected = Transform3D(Basis(Vector3.UP, 0.55 if seconds >= 1 else 0.0), Vector3(x, 0, 0)) * camera.transform
		while sampled < 62:
			await process_frame
			if sampled < 0:
				continue
			var matches := true
			for i in range(6):
				var face: Transform3D = rig.cameras[i].global_transform
				var basis: Basis = expected.basis * Basis.looking_at(rig.DIRECTIONS[i], rig.UP_VECTORS[i])
				matches = matches and face.origin.distance_to(expected.origin) < 0.00001 and face.basis.is_equal_approx(basis)
			check(matches, "Same-frame bone camera, external=%s, sample=%d" % [external, sampled])
		rig.before_sync = Callable()
		rig.set_process(false)
		# Source removal between scheduling and synchronization must be harmless.
		rig.sync_camera.call_deferred()
		scene.free()
		await process_frame
		rig.free()
	print("SKELETAL CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
