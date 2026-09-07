extends SceneTree
## Checks the film's absolute-time contract, including backwards seeks.
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)

func fingerprint(scene: Node3D, t: float) -> String:
	scene.sample_360_frame(roundi(t * 30), t, {})
	var state := [scene.camera.transform, scene.guide.transform, scene.veil.visible,
		scene.veil_material.get_shader_parameter("coverage"), scene.sky_material.get_shader_parameter("clock")]
	var current: Node3D = scene.worlds[scene.chapter_at(t)]
	for node in current.find_children("*", "Node3D", true, false):
		state.append(node.transform)
		if node is MultiMeshInstance3D:
			state.append(node.multimesh.buffer)
	return var_to_str(state).sha256_text()

func _run() -> void:
	var scene: Node3D = load("res://scenes/films/Threshold.tscn").instantiate()
	scene.prepare_360_capture({})
	root.add_child(scene)
	expect(scene.begin_360_capture({"frames": 1800, "fps": 30}).is_empty(), "Sixty seconds accepted")
	expect(not scene.begin_360_capture({"frames": 1801, "fps": 30}).is_empty(), "Overrun rejected")
	expect(not scene.begin_360_capture({"frames": 60, "fps": 30, "threshold_offset": 59}).is_empty(), "Offset overrun rejected")
	for cut in scene.CUTS:
		expect(scene.transition_at(cut) == 1.0, "Map cut fully occluded at " + str(cut))
		expect(scene.transition_at(cut - 1.25) == 0 and scene.transition_at(cut + 1.25) == 0, "Transition duration " + str(cut))
	for t in [0.0, 7.0, 13.9666667, 14.0, 21.0, 28.9666667, 29.0, 36.0, 43.9666667, 44.0, 51.0, 59.9666667]:
		var before := fingerprint(scene, t)
		fingerprint(scene, 60.0 - t)
		expect(before == fingerprint(scene, t), "Backwards seek deterministic at " + str(t))
		var visible := 0
		for world in scene.worlds:
			visible += int(world.visible)
		expect(visible == 1, "Exactly one map visible at " + str(t))
		expect(scene.camera.rotation.is_equal_approx(Vector3.ZERO), "Capture orientation stable")
		expect(scene.camera.position.is_finite(), "Camera transform finite")
	scene.sample_360_frame(0, 0, {"threshold_offset": 36})
	expect(scene.sky_material.get_shader_parameter("clock") == 36.0 and scene.worlds[2].visible, "Sample offset applied")
	scene.sample_360_frame(1800, 60, {})
	expect(scene.veil_material.get_shader_parameter("darkness") == 1.0, "Ending fully fades")
	expect(not scene.guide.visible, "Guide retires before ending")
	var output := preload("res://addons/umbral360/job_io.gd").argument("report")
	var result := {"ok": failures.is_empty(), "checks": checks, "failures": failures}
	if not output.is_empty():
		preload("res://addons/umbral360/job_io.gd").write_json(output, result)
	print(JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
