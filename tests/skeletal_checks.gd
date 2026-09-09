extends SceneTree
const Rig = preload("res://addons/godot360/capture_rig.gd")
var checks := 0
var failures := 0
var sampled := -1
var expected: Transform3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for setup in [{"external": false, "depth": 0}, {"external": true, "depth": 0},
		{"external": false, "depth": 1}, {"external": true, "depth": 1},
		{"external": false, "depth": 2}, {"external": true, "depth": 2}]:
		var external: bool = setup.external
		var job := {"fps": 30, "frames": 60, "external_skeleton": external}
		var scene = load("res://tests/fixtures/skeletal_scene.tscn").instantiate()
		scene.prepare_360_capture(job)
		root.add_child(scene)
		check(scene.begin_360_capture(job).is_empty(), "Bone timeline initializes")
		var camera: Camera3D = scene.camera
		var upstream: Skeleton3D = scene.skeleton
		for depth in range(setup.depth):
			var parent := camera.get_parent()
			parent.remove_child(camera)
			var nested := Skeleton3D.new()
			parent.add_child(nested)
			nested.position = Vector3(0.2, 0.1, 0)
			nested.add_bone("mount")
			var mount := BoneAttachment3D.new()
			mount.bone_name = "mount"
			nested.add_child(mount)
			mount.add_child(camera)
			upstream.skeleton_updated.connect(func():
				nested.set_bone_pose_rotation(0, Quaternion(Vector3.UP, 0.2 * sin((sampled % 60) * 0.31))))
			upstream = nested
		var rig := Rig.new()
		root.add_child(rig)
		rig.build(camera, 32, Vector2i(64, 32))
		sampled = -1
		rig.before_sync = func():
			sampled += 1
			var seconds := (sampled % 60) / 30.0
			scene.sample_360_frame(sampled % 60, seconds, job)
			var x := 1.4 * seconds if seconds < 0.5 else (1.4 - 1.4 * seconds if seconds < 1.5 else 1.4 * seconds - 2.8)
			expected = Transform3D(Basis(Vector3.UP, 0.55 if seconds >= 1 else 0.0), Vector3(x, 0, 0))
			for depth in range(setup.depth):
				expected *= Transform3D(Basis(Vector3.UP, 0.2 * sin((sampled % 60) * 0.31)), Vector3(0.2, 0.1, 0))
			expected *= camera.transform
		while sampled < 62:
			await process_frame
			if sampled < 0:
				continue
			var matches := true
			for i in range(6):
				var face: Transform3D = rig.cameras[i].global_transform
				var basis: Basis = expected.basis * Basis.looking_at(rig.DIRECTIONS[i], rig.UP_VECTORS[i])
				matches = matches and face.origin.distance_to(expected.origin) < 0.00001 and face.basis.is_equal_approx(basis)
			check(matches, "Same-frame bone camera, external=%s, depth=%d, sample=%d" % [external, setup.depth, sampled])
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
