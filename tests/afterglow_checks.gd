extends SceneTree
## Check the scene's musical clock, seeking, and preserved viewer orientation.
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures.append(label)

func _run() -> void:
	var scene = load("res://scenes/films/Afterglow.tscn").instantiate()
	scene.prepare_360_capture({})
	root.add_child(scene)
	scene.set_process(false)
	check(scene.audio == null, "Capture must not play live soundtrack")
	check(scene.cues.duration == 60 and scene.cues.bpm == 116, "Music timeline metadata")
	for section in scene.cues.sections:
		check(absf(float(section.time) - float(section.bar) * 4 * 60 / 116) < .00001, "Section follows bar clock")
	for time in [0.0, 8.28, 24.83, 33.1, 43.0, 49.0, 59.9]:
		scene.sample_360_frame(roundi(time * 30), time, {})
		var original: Transform3D = scene.crystal.transform
		var petal: Transform3D = scene.petals[0].transform
		var camera: Transform3D = scene.camera.transform
		var pulse: float = scene.surfaces.tiles.get_shader_parameter("bass")
		var dancers: Array = [scene.pillars[3], scene.ribs[3], scene.outer_arches[2], scene.lanterns[3], scene.satellites[2], scene.ribbons[1], scene.beams[4]]
		var poses: Array[Transform3D] = []
		for dancer in dancers:
			poses.append(dancer.transform)
		scene.sample_360_frame(1700, 56.0, {})
		scene.sample_360_frame(roundi(time * 30), time, {})
		check(scene.crystal.transform.is_equal_approx(original), "Backward seek crystal %.2f" % time)
		check(scene.petals[0].transform.is_equal_approx(petal), "Backward seek petal %.2f" % time)
		check(scene.camera.transform.is_equal_approx(camera), "Backward seek camera %.2f" % time)
		check(is_equal_approx(scene.surfaces.tiles.get_shader_parameter("bass"), pulse), "Backward seek music %.2f" % time)
		check(scene.camera.rotation.is_zero_approx(), "Capture keeps viewer orientation %.2f" % time)
		for i in range(dancers.size()):
			check(dancers[i].transform.is_equal_approx(poses[i]), "Backward seek dancer %d at %.2f" % [i, time])
		check(scene.surfaces.tiles.get_shader_parameter("core_position").is_equal_approx(scene.crystal.position), "Reflection follows moving crown")
	scene.sample_360_frame(1440, 48.0, {})
	var pillar_position: Vector3 = scene.pillars[0].position
	var lantern_position: Vector3 = scene.lanterns[0].position
	var satellite_position: Vector3 = scene.satellites[0].position
	scene.sample_360_frame(1470, 49.0, {})
	check(scene.pillars[0].position.distance_to(pillar_position) > .5, "Architecture travels with the groove")
	check(scene.lanterns[0].position.distance_to(lantern_position) > 1.0, "Lantern dance is visible beyond floor")
	check(scene.satellites[0].position.distance_to(satellite_position) > 2.0, "Satellites travel around the viewer")
	var onset: float = scene.cues.tracks.bass[16].time
	var hit: Vector2 = scene.note_at("bass", onset)
	check(hit.x > .9, "Bass light attacks on recorded note onset")
	check(scene.note_at("bass", onset + .12).x < hit.x, "Bass light decays between notes")
	scene.prepare_360_capture({"afterglow_offset": 30.0})
	scene.sample_360_frame(0, 0, {})
	check(is_equal_approx(scene.surfaces.tiles.get_shader_parameter("clock"), 30.0), "Late preview offset")
	print(JSON.stringify({"ok": failures.is_empty(), "checks": checks, "failures": failures}))
	scene.queue_free()
	quit(0 if failures.is_empty() else 1)
