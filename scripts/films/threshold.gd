extends Node3D
## THRESHOLD: a sixty-second, absolute-time journey through four original worlds.
const G = preload("threshold_geometry.gd")
const CUTS := [14.0, 29.0, 44.0]
const CHAPTERS := ["THE TIDAL ARCHIVE", "THE GLASS DESERT", "THE SKY GARDEN", "THE STAR ENGINE"]
var capture_mode := false
var elapsed := 0.0
var look := Vector2.ZERO
var worlds: Array[Node3D] = []
var camera: Camera3D
var environment: Environment
var key_light: DirectionalLight3D
var sky: MeshInstance3D
var sky_material: ShaderMaterial
var veil: MeshInstance3D
var veil_material: ShaderMaterial
var ground_materials: Array[ShaderMaterial] = []
var waterfall_material: ShaderMaterial
var dust_clouds: Array[Node3D] = []
var archive_gate: Node3D
var leviathan: Node3D
var leviathan_body: MultiMeshInstance3D
var swimmers: MultiMeshInstance3D
var sun_rings: Array[MeshInstance3D] = []
var islands: Array[Node3D] = []
var island_origins: Array[Vector3] = []
var flock: MultiMeshInstance3D
var engine: Node3D
var engine_rings: Array[MeshInstance3D] = []
var satellites: Array[MeshInstance3D] = []
var engine_core: MeshInstance3D
var guide: Node3D
var guide_surface: StandardMaterial3D
var guide_halo: MeshInstance3D
var intro: Node3D
var chapter_labels: Array[Label3D] = []
var chapter_numbers: Array[Label3D] = []
var ending: Node3D
var materials := {}
var rng := RandomNumberGenerator.new()


func prepare_360_capture(_job: Dictionary) -> void:
	capture_mode = true


func begin_360_capture(job: Dictionary) -> String:
	if float(job.get("frames", 0)) / float(job.get("fps", 30)) + float(job.get("threshold_offset", 0)) > 60.001:
		return "Threshold is authored for exactly sixty seconds."
	camera.rotation = Vector3.ZERO
	return ""


func _ready() -> void:
	rng.seed = 731904
	for pair in [["stone", "163b46"], ["light_stone", "376271"], ["cyan", "82eadb"], ["gold", "efbd72"],
		["sand", "b98065"], ["obsidian", "22283b"], ["green", "437a72"], ["grass", "72ae8a"],
		["ivory", "f0dfbb"], ["plum", "2c244c"], ["dark", "060b18"], ["white", "ffffff"]]:
		materials[pair[0]] = G.material(pair[1], pair[0] in ["cyan", "gold", "ivory", "dark"], 0.25 if pair[0] in ["obsidian", "stone", "plum"] else 0.0)
	camera = $Camera3D
	camera.near = 0.06
	camera.far = 600.0
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("091626")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_energy = 0.32
	environment.fog_enabled = true
	environment.fog_sky_affect = 0.0
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-38, -35, 0)
	key_light.light_energy = 1.1
	key_light.shadow_enabled = false
	add_child(key_light)
	sky_material = ShaderMaterial.new()
	sky_material.shader = preload("res://assets/films/threshold/sky.gdshader")
	sky = G.sphere(self, 350, sky_material, Vector3.ZERO, Vector3.ONE, 64)
	for i in range(4):
		var world := Node3D.new()
		world.name = CHAPTERS[i].to_pascal_case()
		add_child(world)
		worlds.append(world)
	_build_archive(worlds[0])
	_build_desert(worlds[1])
	_build_garden(worlds[2])
	_build_engine(worlds[3])
	_build_titles()
	guide = Node3D.new()
	guide.name = "TheThread"
	add_child(guide)
	guide_surface = G.material("fff0cc", true)
	G.sphere(guide, 0.065, guide_surface)
	guide_halo = _halo(guide, Vector3.ZERO, Color("ffe9a9"), 1.0)
	veil_material = ShaderMaterial.new()
	veil_material.shader = preload("res://assets/films/threshold/veil.gdshader")
	veil_material.render_priority = 127
	veil = G.sphere(self, 0.4, veil_material, Vector3.ZERO, Vector3.ONE, 32)
	sample_360_frame(0, 0.0, {})
	if not capture_mode and FileAccess.file_exists("res://assets/audio/threshold-score.wav"):
		var audio := AudioStreamPlayer.new()
		audio.stream = AudioStreamWAV.load_from_file(ProjectSettings.globalize_path("res://assets/audio/threshold-score.wav"))
		add_child(audio)
		audio.play()


func _process(delta: float) -> void:
	if not capture_mode:
		elapsed = minf(60.0, elapsed + delta)
		sample_360_frame(roundi(elapsed * 30), elapsed, {})


func _unhandled_input(event: InputEvent) -> void:
	if capture_mode:
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		look.x -= event.relative.x * 0.003
		look.y = clampf(look.y - event.relative.y * 0.003, -1.45, 1.45)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()


func chapter_at(time: float) -> int:
	return 0 if time < CUTS[0] else 1 if time < CUTS[1] else 2 if time < CUTS[2] else 3


func transition_at(time: float) -> float:
	var cover := 0.0
	for cut in CUTS:
		cover = maxf(cover, 1.0 - smoothstep(0.0, 1.25, absf(time - cut)))
	return cover


func sample_360_frame(_frame_index: int, time_seconds: float, job: Dictionary) -> String:
	var t := clampf(time_seconds + float(job.get("threshold_offset", 0.0)), 0.0, 60.0)
	var chapter := chapter_at(t)
	var local := t - ([0.0, 14.0, 29.0, 44.0][chapter] as float)
	for i in range(4):
		worlds[i].visible = i == chapter
		var label_time := local - 3.1 if i == 0 else local
		chapter_labels[i].visible = i == chapter and label_time > 1.5 and label_time < 5.5
		chapter_numbers[i].visible = chapter_labels[i].visible
		var opacity := smoothstep(1.5, 2.3, label_time) * (1.0 - smoothstep(4.3, 5.5, label_time))
		chapter_labels[i].modulate.a = opacity
		chapter_numbers[i].modulate.a = opacity
	var travel := smoothstep(0.0, 14.0, local)
	camera.position = [Vector3(sin(t * 0.12) * 0.55, 0.1 + travel * 1.4, -travel * 1.8),
		Vector3(sin(local * 0.16) * 0.7, 0.5 + travel * 0.5, -travel * 2.8),
		Vector3(sin(local * 0.1) * 1.0, 1.0 + travel * 1.5, -travel * 1.4),
		Vector3(sin(local * 0.12) * 0.5, travel * 2.0, -travel * 1.0)][chapter]
	camera.rotation = Vector3.ZERO if capture_mode else Vector3(look.y, look.x, 0)
	sky.position = camera.position
	veil.position = camera.position
	sky_material.set_shader_parameter("clock", t)
	sky_material.set_shader_parameter("world", float(chapter))
	var skies := [["071726", "155165", "061623"], ["28233d", "c48768", "291e31"], ["577998", "e9bf9f", "476c87"], ["070c22", "332646", "0a142a"]]
	sky_material.set_shader_parameter("zenith", Color(skies[chapter][0]))
	sky_material.set_shader_parameter("horizon", Color(skies[chapter][1]))
	sky_material.set_shader_parameter("nadir", Color(skies[chapter][2]))
	environment.ambient_light_color = [Color("88bbcf"), Color("d6afa6"), Color("dbedeb"), Color("9a92c7")][chapter]
	environment.fog_light_color = [Color("164655"), Color("b48178"), Color("b1c1b6"), Color("17132b")][chapter]
	environment.fog_density = [0.009, 0.003, 0.004, 0.0008][chapter]
	key_light.light_color = [Color("90e8d6"), Color("ffe4ae"), Color("ffe4b8"), Color("a5cfe9")][chapter]
	for mat in ground_materials:
		mat.set_shader_parameter("clock", t)
	waterfall_material.set_shader_parameter("clock", t)
	veil_material.set_shader_parameter("coverage", transition_at(t))
	veil_material.set_shader_parameter("darkness", smoothstep(58.8, 60.0, t))
	veil_material.set_shader_parameter("clock", t)
	veil_material.set_shader_parameter("tint", [Color("b2eddf"), Color("ffe2ab"), Color("e2e6ed"), Color("e7c6ff")][chapter])
	veil.visible = transition_at(t) > 0.0001 or t > 58.8
	intro.visible = t < 4.4
	_fade_labels(intro, 1.0 - smoothstep(2.6, 4.4, t))
	ending.visible = t > 55.2
	_fade_labels(ending, smoothstep(55.2, 56.3, t) * (1.0 - smoothstep(58.3, 59.6, t)))
	guide.position = camera.position + Vector3(sin(t * 0.24) * 3.5, 0.4 + sin(t * 0.19) * 1.6, -7.5 + cos(t * 0.17))
	guide.visible = t < 55.0
	guide_halo.look_at(camera.position, Vector3.UP, true)
	if chapter == 0:
		archive_gate.rotation.z = sin(t * 0.12) * 0.12
		leviathan.position = Vector3(-12 + t * 1.7, 5.6 + sin(t * 0.2) * 1.4, -13 + sin(t * 0.17) * 3)
		leviathan.rotation.y = -0.25 + t * 0.065
		for i in range(48):
			var u := float(i) / 47.0
			var r := 0.12 + pow(sin(u * PI), 0.6) * 0.6
			leviathan_body.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(0.36, r * 0.52, r)), Vector3((u - 0.5) * 13, sin(u * TAU * 1.2 - t * 0.7) * 0.5, sin(u * TAU - t * 0.65) * 0.85)))
		for i in range(160):
			var a := float(i) * 2.399963 + t * (0.06 + float(i % 5) * 0.012)
			var r := 8.0 + float(i % 23) * 0.55
			var at := Vector3(cos(a) * r, 1.2 + sin(i * 1.7 + t * 0.22) * 4.5, sin(a) * r)
			swimmers.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, -a).scaled(Vector3(0.09, 0.045, 0.26)), at))
	elif chapter == 1:
		for i in range(sun_rings.size()):
			sun_rings[i].rotation = Vector3(PI / 2 + sin(local * 0.12 + i) * 0.09, 0, local * 0.025 * (1 if i % 2 else -1))
	elif chapter == 2:
		for i in range(islands.size()):
			islands[i].position = island_origins[i] + Vector3(0, sin(local * 0.22 + i * 1.9) * 0.3, 0)
		for i in range(100):
			var a := local * 0.085 + float(i) * 0.087
			var radius := 12.0 + float(i % 11) * 0.42
			var at := Vector3(sin(a) * radius, 5 + sin(a * 1.7 + i * 0.3) * 2.0, -cos(a) * radius)
			var basis := Basis(Vector3.UP, -a).rotated(Vector3.FORWARD, sin(local * 3.5 + i) * 0.18)
			flock.multimesh.set_instance_transform(i, Transform3D(basis.scaled(Vector3.ONE * (0.14 + float(i % 4) * 0.025)), at))
	else:
		var awakening := smoothstep(1.0, 12.0, local)
		for i in range(engine_rings.size()):
			var direction := 1.0 if i % 2 else -1.0
			engine_rings[i].rotation = Vector3(PI / 2 + i * 0.42 + local * 0.07 * direction, i * 0.77 + local * 0.035, i * 0.33)
			engine_rings[i].scale = Vector3.ONE * (0.88 + awakening * 0.12)
		for i in range(satellites.size()):
			var a := float(i) * 2.399963 + local * 0.1 * (1 if i % 2 else -1)
			var radius := 6.3 + i * 0.45
			satellites[i].position = Vector3(cos(a) * radius, sin(a * 1.3 + i) * 5.0, sin(a) * radius)
		engine_core.scale = Vector3.ONE * (1.0 - smoothstep(10.0, 14.5, local) * 0.66)
	for i in range(dust_clouds.size()):
		dust_clouds[i].rotation.y = t * (0.009 + i * 0.003)
	return ""


func _build_archive(parent: Node3D) -> void:
	_ground(parent, "17424b", "66dfc8", 0)
	for ring_index in range(2):
		var radius := 17.0 + ring_index * 14.0
		for i in range(20):
			var a := (float(i) + 0.5) / 20 * TAU
			var at := Vector3(sin(a) * radius, 2.0 + ring_index * 1.0, cos(a) * radius)
			G.cylinder(parent, 0.75, 0.48, 14 + ring_index * 4, materials.stone, at)
			G.cylinder(parent, 1.0, 1.0, 0.45, materials.light_stone, at + Vector3(0, 6.6 + ring_index * 2, 0))
			G.ring(parent, 0.58, 0.035, materials.cyan, at + Vector3(0, 4.5, 0), 32)
			G.cylinder(parent, 1.25, 1.1, 0.65, materials.light_stone, at - Vector3(0, 6.5 + ring_index * 2, 0))
			for line in range(6):
				var angle := line * TAU / 6.0
				G.box(parent, Vector3(0.06, 8.0, 0.06), materials.light_stone, at + Vector3(sin(angle) * 0.6, 0, cos(angle) * 0.6))
	for i in range(8):
		var points := PackedVector3Array()
		var a := (float(i) + 0.5) / 8.0 * PI
		for step in range(49):
			var arc := float(step) / 48 * PI
			points.append(Vector3(cos(arc) * 17 * cos(a), -4.0 + sin(arc) * 23, cos(arc) * 17 * sin(a)))
		G.tube(parent, points, 0.15, materials.light_stone)
		var light_path := PackedVector3Array()
		for point in points:
			light_path.append(point + Vector3(0, -0.2, 0))
		G.tube(parent, light_path, 0.026, materials.cyan, 4)
	for radius in [4.0, 6.0, 10.0, 14.0]:
		G.ring(parent, radius, 0.025, materials.cyan, Vector3(0, -4.5, 0))
	archive_gate = Node3D.new()
	archive_gate.position = Vector3(0, 1.0, -22)
	parent.add_child(archive_gate)
	for radius in [4.0, 4.4, 5.4]:
		var ring := G.ring(archive_gate, radius, 0.055, materials.gold)
		ring.rotation.x = PI / 2
	for i in range(72):
		var a := i * TAU / 72.0
		var glyph := G.box(archive_gate, Vector3(0.055, 0.4 if i % 3 == 0 else 0.16, 0.05), materials.gold, Vector3(sin(a) * 4.9, cos(a) * 4.9, 0))
		glyph.rotation.z = -a
	G.sphere(archive_gate, 2.8, materials.obsidian, Vector3.ZERO, Vector3(0.20, 1.1, 0.20), 8)
	_halo(parent, Vector3(0, 2, -24), Color("47d7c7"), 15)
	leviathan = Node3D.new()
	leviathan.name = "TheArchivist"
	parent.add_child(leviathan)
	var shape := SphereMesh.new()
	shape.radius = 1.0
	shape.height = 2.0
	shape.radial_segments = 12
	shape.rings = 6
	var poses: Array[Transform3D] = []
	var colors: Array[Color] = []
	for i in range(48):
		poses.append(Transform3D.IDENTITY)
		colors.append(Color("a4f5de") if i % 4 == 0 else Color("397f82"))
	leviathan_body = G.batch(leviathan, shape, G.material("ffffff", true), poses, colors)
	poses = []
	for i in range(160):
		poses.append(Transform3D.IDENTITY)
	swimmers = G.batch(parent, shape, materials.cyan, poses)
	var coral_shape := CylinderMesh.new()
	coral_shape.top_radius = 0.0
	coral_shape.bottom_radius = 0.12
	coral_shape.height = 1.0
	coral_shape.radial_segments = 5
	poses = []
	colors = []
	for i in range(360):
		var a := rng.randf() * TAU
		var radius := rng.randf_range(7, 37)
		var at := Vector3(sin(a) * radius, -4.3, cos(a) * radius)
		var size := Vector3(1, rng.randf_range(0.5, 2.8), 1)
		poses.append(Transform3D(Basis(Vector3.FORWARD, rng.randf_range(-0.35, 0.35)).scaled(size), at))
		colors.append(Color("83d7b7").lerp(Color("447888"), rng.randf()))
	G.batch(parent, coral_shape, materials.white, poses, colors)
	_dust(parent, Color("78dcce"), 260, 36.0, 0.035)


func _build_desert(parent: Node3D) -> void:
	_ground(parent, "b98065", "eec586", 1)
	for i in range(32):
		var a := float(i) * 2.399963
		if cos(a) < -0.80 and absf(sin(a)) < 0.6:
			a += 0.65
		var radius := 15.0 + float(i % 7) * 5.5
		var height := rng.randf_range(7, 24)
		var shard := Node3D.new()
		shard.position = Vector3(sin(a) * radius, G.height_at(sin(a) * radius, cos(a) * radius, 1) + height * 0.45, cos(a) * radius)
		shard.rotation = Vector3(rng.randf_range(-0.2, 0.2), a, rng.randf_range(-0.24, 0.24))
		parent.add_child(shard)
		G.cylinder(shard, 1.3, 0.02, height, materials.obsidian, Vector3.ZERO, 5)
		var path := PackedVector3Array([Vector3(-0.4, -height * 0.5, 0.9), Vector3(0.0, height * 0.5, 0)])
		G.tube(shard, path, 0.026, materials.gold, 4)
	var eclipse := Vector3(0, 18, -62)
	_halo(parent, eclipse + Vector3(0, 0, -1), Color("ffab68"), 63)
	G.sphere(parent, 10.8, materials.dark, eclipse, Vector3(1, 1, 0.20), 64)
	for i in range(5):
		var ring := G.ring(parent, 11.0 + float(i) * 1.6, 0.12 if i == 0 else 0.027, materials.gold, eclipse)
		ring.rotation.x = PI / 2
		sun_rings.append(ring)
	for i in range(5):
		var path := PackedVector3Array()
		for j in range(97):
			var a := float(j) / 96 * TAU
			path.append(Vector3(sin(a) * (30 + i * 7), 8 + cos(a * 2 + i) * 3, cos(a) * (30 + i * 7)))
		G.tube(parent, path, 0.018, materials.gold, 4)
	for radius in [3.0, 4.2]:
		G.ring(parent, radius, 0.055, materials.gold, Vector3(0, -4.7, 0))
	_dust(parent, Color("f8cd8f"), 300, 43, 0.034)


func _build_garden(parent: Node3D) -> void:
	waterfall_material = ShaderMaterial.new()
	waterfall_material.shader = preload("res://assets/films/threshold/waterfall.gdshader")
	for i in range(13):
		var a := float(i) * 2.399963
		var radius := 21.0 + float(i % 3) * 15.0
		var origin := Vector3(sin(a) * radius, -8 + float(i % 4) * 2.5, -cos(a) * radius)
		var island := Node3D.new()
		island.position = origin
		parent.add_child(island)
		islands.append(island)
		island_origins.append(origin)
		var size := 8.0 if i == 0 else rng.randf_range(3.5, 6.5)
		G.sphere(island, size, materials.grass, Vector3.ZERO, Vector3(1, 0.12, 1), 24)
		G.rock(island, size, materials.green, Vector3(0, -size * 1.15, 0), Vector3(1.1, 1.15, 1.0), i + 1)
		for rock in range(16):
			var theta := rock * 2.399963
			var pos := Vector3(sin(theta) * size * 0.83, -0.6, cos(theta) * size * 0.83)
			G.rock(island, size * rng.randf_range(0.14, 0.24), materials.light_stone, pos, Vector3(1.0, 1.4, 1.0), rock + i * 17)
		G.ring(island, size * 0.91, 0.035, materials.gold, Vector3(0, 0.4, 0), 64)
		_tree(island, Vector3.ZERO, 1.45 if i == 0 else size / 6.3)
		for side in [-1, 1]:
			var plane := QuadMesh.new()
			plane.size = Vector2(1.2, size * 3.0)
			G.node(island, plane, waterfall_material, Vector3(side * size * 0.68, -size * 1.45, size * 0.50))
	for i in range(4):
		var path := PackedVector3Array()
		for j in range(97):
			var a := float(j) / 96 * TAU
			path.append(Vector3(sin(a) * (18 + i * 7), 11 + sin(a * 2 + i) * 3.5, cos(a) * (18 + i * 7)))
		G.tube(parent, path, 0.026, materials.ivory, 4)
	var bird := SurfaceTool.new()
	bird.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [Vector3(-1, 0.15, 0.35), Vector3(0, 0, -0.4), Vector3(0, 0, 0.4), Vector3(1, 0.15, 0.35), Vector3(0, 0, 0.4), Vector3(0, 0, -0.4)]:
		bird.set_normal(Vector3.UP)
		bird.add_vertex(point)
	var poses: Array[Transform3D] = []
	for i in range(100):
		poses.append(Transform3D.IDENTITY)
	var bird_surface := G.material("f8e6b2", true)
	bird_surface.cull_mode = BaseMaterial3D.CULL_DISABLED
	flock = G.batch(parent, bird.commit(), bird_surface, poses)
	_dust(parent, Color("f7e7b9"), 210, 36, 0.045)
	G.ring(parent, 3.3, 0.05, materials.gold, Vector3(0, -3.0, 0))


func _tree(parent: Node3D, at: Vector3, scale_value: float) -> void:
	var tree := Node3D.new()
	parent.add_child(tree)
	tree.position = at
	tree.scale = Vector3.ONE * scale_value
	G.tube(tree, PackedVector3Array([Vector3(0, -0.1, 0), Vector3(0.3, 1.4, 0.1), Vector3(-0.2, 3.0, 0.1), Vector3(0.4, 4.6, -0.1), Vector3(0, 6.0, 0)]), 0.38, materials.light_stone, 9)
	var leaf_shape := SphereMesh.new()
	leaf_shape.radius = 1.0
	leaf_shape.height = 2.0
	leaf_shape.radial_segments = 8
	leaf_shape.rings = 4
	var leaves: Array[Transform3D] = []
	var colors: Array[Color] = []
	for i in range(7):
		var a := float(i) / 7 * TAU
		var branch_end := Vector3(cos(a) * 2.5, 5.5 + sin(i * 1.7), sin(a) * 2.5)
		var path := PackedVector3Array([Vector3(0, 2.0, 0), Vector3(cos(a) * 0.8, 4, sin(a) * 0.8), branch_end])
		G.tube(tree, path, 0.14, materials.light_stone)
		for leaf in range(140):
			var azimuth := rng.randf() * TAU
			var distance := sqrt(rng.randf()) * 2.7
			var leaf_at := branch_end + Vector3(sin(azimuth) * distance, rng.randf_range(-0.3, 0.65) + (1.0 - distance / 2.7) * 0.55, cos(azimuth) * distance)
			var leaf_scale := Vector3(rng.randf_range(0.25, 0.6), rng.randf_range(0.15, 0.3), rng.randf_range(0.25, 0.55))
			leaves.append(Transform3D(Basis(Vector3.UP, azimuth).scaled(leaf_scale), leaf_at))
			colors.append(Color("afcf9b").lerp(Color("397f79"), rng.randf()) if i % 3 else Color("edc983").lerp(Color("b58462"), rng.randf()))
		G.sphere(tree, 0.09, materials.ivory, branch_end - Vector3(0, 1.5, 0), Vector3.ONE, 8)
	G.batch(tree, leaf_shape, materials.white, leaves, colors)


func _build_engine(parent: Node3D) -> void:
	engine = Node3D.new()
	engine.name = "TheCelestialMachine"
	engine.position = Vector3(0, 3, -20)
	parent.add_child(engine)
	_halo(parent, Vector3(0, 3, -23), Color("b090e3"), 36)
	engine_core = G.sphere(engine, 3.7, materials.dark, Vector3.ZERO, Vector3.ONE, 64)
	for i in range(7):
		var ring := G.ring(engine, 4.6 + i * 0.72, 0.068 if i % 2 else 0.11, materials.gold if i % 3 else materials.cyan)
		engine_rings.append(ring)
		for tick in range(32):
			var a := tick * TAU / 32.0
			var radius := 4.6 + i * 0.72
			var mark := G.box(ring, Vector3(0.05, 0.07, 0.45 if tick % 4 == 0 else 0.18), materials.gold if i % 3 else materials.cyan, Vector3(sin(a) * radius, 0, cos(a) * radius))
			mark.rotation.y = a
	for i in range(15):
		var orb := G.sphere(engine, 0.12 + float(i % 4) * 0.10, materials.ivory if i % 3 else materials.cyan, Vector3.ZERO, Vector3.ONE, 16)
		satellites.append(orb)
	for i in range(7):
		var at := Vector3(sin(i * 2.399963) * 37, -6 + float(i % 4) * 9, cos(i * 2.399963) * 37)
		G.sphere(parent, 1.4 + float(i % 3) * 0.8, materials.plum, at, Vector3.ONE, 32)
		var ring := G.ring(parent, 3.2 + float(i % 3) * 0.8, 0.042, materials.gold, at)
		ring.rotation = Vector3(i * 0.4, i * 0.7, 0.5)
	for i in range(6):
		var path := PackedVector3Array()
		for j in range(145):
			var a := float(j) / 144 * TAU
			var r := 28.0 + i * 5
			path.append(Vector3(sin(a) * r, sin(a * 2.0 + i * 0.7) * 12, cos(a) * r))
		G.tube(parent, path, 0.025 + float(i % 2) * 0.02, materials.cyan if i % 2 else materials.gold, 4)
	for radius in [3.5, 5.0, 10.0, 17.0, 27.0]:
		G.ring(parent, radius, 0.028, materials.gold, Vector3(0, -5, 0))
	_dust(parent, Color("d6d4f8"), 580, 70.0, 0.055)


func _ground(parent: Node3D, base: String, accent: String, mode: int) -> void:
	var surface := ShaderMaterial.new()
	surface.shader = preload("res://assets/films/threshold/ground.gdshader")
	surface.set_shader_parameter("sand", Color(base))
	surface.set_shader_parameter("accent", Color(accent))
	surface.set_shader_parameter("world", float(mode))
	ground_materials.append(surface)
	G.dunes(parent, surface, mode)


func _halo(parent: Node3D, at: Vector3, tint: Color, size: float) -> MeshInstance3D:
	var surface := ShaderMaterial.new()
	surface.shader = preload("res://assets/films/threshold/glow.gdshader")
	surface.set_shader_parameter("tint", tint)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	var halo := G.node(parent, quad, surface, at)
	if halo.global_position.length_squared() > 0.001:
		halo.look_at(Vector3.ZERO, Vector3.UP, true)
	return halo


func _dust(parent: Node3D, tint: Color, count: int, radius: float, size: float) -> void:
	var cloud := Node3D.new()
	parent.add_child(cloud)
	dust_clouds.append(cloud)
	var shape := SphereMesh.new()
	shape.radius = 1.0
	shape.height = 2.0
	shape.radial_segments = 6
	shape.rings = 3
	var poses: Array[Transform3D] = []
	var colors: Array[Color] = []
	for i in range(count):
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 1), rng.randf_range(-1, 1)).normalized()
		var at := direction * rng.randf_range(7, radius)
		var scale_value := size * rng.randf_range(0.5, 1.6)
		poses.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_value), at))
		colors.append(tint * rng.randf_range(0.55, 1.0))
	G.batch(cloud, shape, G.material("ffffff", true), poses, colors)


func _build_titles() -> void:
	intro = Node3D.new()
	add_child(intro)
	G.text(intro, "T H R E S H O L D", Vector3(0, 2.6, -13), 144, 0.0065, Color("eee5c9"))
	G.text(intro, "FOUR IMPOSSIBLE WORLDS  /  ONE SHARED SKY", Vector3(0, 1.35, -13), 48, 0.006, Color("88c3c5"))
	G.text(intro, "LOOK AROUND. THE WORLD CONTINUES BEHIND YOU.", Vector3(0, -0.1, -13), 38, 0.006, Color("88c3c5"))
	for i in range(4):
		chapter_labels.append(G.text(self, CHAPTERS[i], Vector3(0, -0.2, -12), 72, 0.007, Color("f5e5c3")))
		chapter_numbers.append(G.text(self, "%02d   /   THRESHOLD" % (i + 1), Vector3(0, 0.45, -12), 36, 0.006, Color("bdcec9")))
	ending = Node3D.new()
	add_child(ending)
	G.text(ending, "EVERY END IS A DOOR", Vector3(0, 2.3, -12), 94, 0.005, Color("efdab5"))
	G.text(ending, "T H R E S H O L D", Vector3(0, 1.3, -12), 46, 0.004, Color("acafcb"))


func _fade_labels(parent: Node3D, opacity: float) -> void:
	for child in parent.get_children():
		if child is Label3D:
			child.modulate.a = opacity
