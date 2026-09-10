extends Node3D
## AFTERGLOW: a sixty-second original disco ritual. All motion uses absolute time.
const G = preload("threshold_geometry.gd")
const DURATION := 60.0
const BPM := 116.0
const BEAT := 60.0 / BPM
const HEART := Vector3(0, 7.3, -7.5)
const PLINTH_RADIUS := 3.5
var capture_mode := false
var time_offset := 0.0
var elapsed := 0.0
var look := Vector2.ZERO
var camera: Camera3D
var audio: AudioStreamPlayer
var cues: Dictionary
var surfaces: Dictionary = {}
var crystal: Node3D
var mirrors: Node3D
var petals: Array[Node3D] = []
var hoops: Array[Node3D] = []
var lanterns: Array[Node3D] = []
var lantern_materials: Array[StandardMaterial3D] = []
var pillars: Array[Node3D] = []
var ribs: Array[Node3D] = []
var outer_arches: Array[Node3D] = []
var satellites: Array[Node3D] = []
var beams: Array[MeshInstance3D] = []
var ribbons: Array[MeshInstance3D] = []
var motes: Node3D
var titles: Node3D
var ending_titles: Node3D
var glow_light: OmniLight3D


func prepare_360_capture(settings: Dictionary) -> void:
	capture_mode = true
	time_offset = float(settings.get("afterglow_offset", 0.0))


func _ready() -> void:
	camera = $Camera3D
	cues = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/afterglow-score.cues.json"))
	for id in ["tiles", "facets", "beam", "dust", "sky", "ribbon"]:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://assets/films/afterglow/%s.gdshader" % id)
		surfaces[id] = mat
	_environment()
	_floor()
	_architecture()
	_heart()
	_atmosphere()
	titles = _title("A F T E R G L O W", "A MIDNIGHT DISCO RITUAL", Vector3(0, 3.8, -8), .0043)
	ending_titles = _title("A F T E R G L O W", "MADE WITH GODOT360 STUDIO", Vector3(0, 3.8, -8), .0040)
	_apply_time(0.0)
	if not capture_mode:
		audio = AudioStreamPlayer.new()
		audio.stream = load("res://assets/audio/afterglow-score.wav")
		add_child(audio)
		audio.play()


func _environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("080312")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("9874b2")
	environment.ambient_light_energy = 0.68
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.12
	environment.glow_enabled = true
	environment.glow_intensity = 0.85
	environment.glow_bloom = 0.06
	environment.fog_enabled = true
	environment.fog_light_color = Color("160b25")
	environment.fog_light_energy = 0.30
	environment.fog_density = 0.004
	world.environment = environment
	add_child(world)
	var attributes := CameraAttributesPractical.new()
	attributes.exposure_multiplier = 1.42
	camera.attributes = attributes
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -35, 0)
	key.light_color = Color("b790cb")
	key.light_energy = 1.05
	add_child(key)
	glow_light = OmniLight3D.new()
	glow_light.position = HEART
	glow_light.light_color = Color("ffb662")
	glow_light.light_energy = 4
	glow_light.omni_range = 26
	add_child(glow_light)
	for i in range(4):
		var light := OmniLight3D.new()
		var a := i * TAU / 4 + PI / 4
		light.position = Vector3(sin(a) * 12, 4, cos(a) * 12)
		light.light_color = Color("d14497") if i % 2 else Color("7154de")
		light.light_energy = 4.5
		light.omni_range = 16
		add_child(light)
	G.sphere(self, 180, surfaces.sky, Vector3.ZERO, Vector3.ONE, 48)


func _floor() -> void:
	surfaces.tiles.set_shader_parameter("plinth_center", Vector2(HEART.x, HEART.z))
	surfaces.tiles.set_shader_parameter("plinth_radius", PLINTH_RADIUS)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(.92, .27, .92)
	var positions: Array[Vector3] = []
	for z in range(-21, 22):
		for x in range(-21, 22):
			var p := Vector3(x * 1.01, 0, z * 1.01)
			if Vector2(p.x, p.z).length() < 21:
				positions.append(p)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = positions.size()
	for i in range(positions.size()):
		var p := positions[i]
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
		mm.set_instance_custom_data(i, Color(p.x, p.z, fposmod(sin(i * 74.39) * 457.3, 1), 1))
	var tiles := MultiMeshInstance3D.new()
	tiles.name = "DancingGlass"
	tiles.multimesh = mm
	tiles.material_override = surfaces.tiles
	tiles.custom_aabb = AABB(Vector3(-24, -2, -24), Vector3(48, 7, 48))
	tiles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(tiles)
	var obsidian := _metal("171020", .78)
	var gold := _metal("b48a53", .72)
	G.cylinder(self, 22.1, 21.6, .8, obsidian, Vector3(0, -.9, 0), 128)
	for r in [21.6, 21.9, 22.2]:
		G.ring(self, r, .035, gold, Vector3(0, -.42, 0), 180)
	G.ring(self, 22.05, .025, _emissive("d881cf", 1.0), Vector3(0, -.35, 0), 180)
	# Engraved perimeter, surrounding the viewer in every direction.
	for i in range(96):
		var a := i * TAU / 96
		var tick := G.box(self, Vector3(.045, .028, .52 if i % 4 == 0 else .22), gold, Vector3(sin(a) * 21.4, -.2, cos(a) * 21.4))
		tick.rotation.y = a


func _architecture() -> void:
	var stone := _metal("241629", .48)
	var bronze := _metal("a17449", .75)
	var black := _metal("100d19", .72)
	var gold := _emissive("d99b59", .35)
	for i in range(24):
		var a := (i + .5) * TAU / 24
		var at := Vector3(sin(a) * 24, 0, cos(a) * 24)
		var pillar := Node3D.new()
		pillar.position = at
		pillar.rotation.y = a
		add_child(pillar)
		pillars.append(pillar)
		G.box(pillar, Vector3(1.35, .55, 1.2), bronze, Vector3(0, .1, 0))
		G.box(pillar, Vector3(.83, 10, .82), stone, Vector3(0, 5.35, 0))
		for side in [-1.0, 1.0]:
			G.box(pillar, Vector3(.06, 9.2, .05), bronze, Vector3(side * .43, 5.3, -.44))
		G.box(pillar, Vector3(1.28, .36, 1.0), bronze, Vector3(0, 10.35, 0))
		var glow := _emissive(_lantern_color(i), .4)
		lantern_materials.append(glow)
		var lantern := Node3D.new()
		lantern.position = at * .94 + Vector3(0, 5, 0)
		add_child(lantern)
		var crystal_mesh := G.cylinder(lantern, .09, .26, 3.6, glow, Vector3.ZERO, 4)
		crystal_mesh.rotation.z = PI
		G.ring(lantern, .42, .035, bronze, Vector3(0, -1.7, 0), 32)
		G.ring(lantern, .42, .035, bronze, Vector3(0, 1.7, 0), 32)
		lanterns.append(lantern)
		var path := PackedVector3Array()
		var inset := PackedVector3Array()
		for step in range(33):
			var u := step / 32.0
			var radius := lerpf(24, 6.8, u)
			var height := 10.5 + sin(u * PI * .5) * 8.0
			path.append(Vector3(sin(a) * radius, height, cos(a) * radius))
			inset.append(Vector3(sin(a) * (radius - .15), height - .16, cos(a) * (radius - .15)))
		var rib := Node3D.new()
		add_child(rib)
		G.tube(rib, path, .14, black)
		G.tube(rib, inset, .025, gold)
		ribs.append(rib)
	for r in [6.8, 7.2]:
		G.ring(self, r, .075, bronze, Vector3(0, 18.5, 0), 160)
	# Arched windows form a second silhouette beyond the colonnade.
	for i in range(12):
		var a := i * TAU / 12
		var root_node := Node3D.new()
		root_node.position = Vector3(sin(a) * 35, 0, cos(a) * 35)
		root_node.rotation.y = a
		add_child(root_node)
		outer_arches.append(root_node)
		var arch := PackedVector3Array()
		for j in range(49):
			var angle := j / 48.0 * PI
			arch.append(Vector3(cos(angle) * 4.5, 8 + sin(angle) * 9.0, 0))
		G.tube(root_node, arch, .11, bronze)
		for x in [-4.5, 4.5]:
			G.box(root_node, Vector3(.2, 8, .3), black, Vector3(x, 4, 0))


func _heart() -> void:
	crystal = Node3D.new()
	crystal.position = HEART
	add_child(crystal)
	mirrors = Node3D.new()
	crystal.add_child(mirrors)
	var dark := _metal("55305d", .7)
	var bronze := _metal("c69a59", .8)
	G.sphere(mirrors, 1.76, dark, Vector3.ZERO, Vector3.ONE, 48)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(.245, .245, .035)
	var transforms: Array[Transform3D] = []
	for row in range(1, 21):
		var latitude := row / 21.0 * PI
		var count := maxi(8, roundi(sin(latitude) * 44))
		for col in range(count):
			var a := (col + row % 2 * .5) * TAU / count
			var direction := Vector3(sin(latitude) * sin(a), cos(latitude), sin(latitude) * cos(a))
			var orientation := Basis.looking_at(direction, Vector3.UP)
			transforms.append(Transform3D(orientation, direction * 1.80))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_custom_data(i, Color(fposmod(i * .6180339, 1), 0, 0, 1))
	var mosaic := MultiMeshInstance3D.new()
	mosaic.multimesh = mm
	mosaic.material_override = surfaces.facets
	mirrors.add_child(mosaic)
	for i in range(12):
		var petal := Node3D.new()
		crystal.add_child(petal)
		var shard := G.node(petal, _shard_mesh(), dark)
		shard.rotation_degrees.y = 45
		G.cylinder(petal, .018, .03, 2.9, _emissive("ffbf71", .9), Vector3(0, 0, -.34), 6)
		G.ring(petal, .42, .02, bronze, Vector3(0, 1.2, 0), 16)
		petals.append(petal)
	for i in range(3):
		var hoop := Node3D.new()
		crystal.add_child(hoop)
		G.ring(hoop, 3.25 + i * .32, .046, bronze, Vector3.ZERO, 144)
		G.ring(hoop, 3.18 + i * .32, .012, _emissive("ebba6c", .8), Vector3.ZERO, 144)
		hoops.append(hoop)
	var plinth := G.cylinder(self, 3.1, PLINTH_RADIUS, .7, dark, HEART * Vector3(1, 0, 1) + Vector3(0, .5, 0), 64)
	plinth.name = "CrownPlinth"
	G.ring(self, 3.45, .045, bronze, Vector3(0, .87, -7.5), 128)
	for i in range(16):
		var beam_mesh := CylinderMesh.new()
		beam_mesh.bottom_radius = .9
		beam_mesh.top_radius = .025
		beam_mesh.height = 1
		beam_mesh.radial_segments = 16
		var material: ShaderMaterial = surfaces.beam.duplicate()
		material.set_shader_parameter("tint", Color(1, .44, .11, .095) if i % 3 else Color(.75, .13, 1, .085))
		var beam := G.node(self, beam_mesh, material)
		beams.append(beam)
	# A nearer constellation makes movement readable when looking away from the crown.
	for i in range(8):
		var satellite := Node3D.new()
		add_child(satellite)
		var tint := _emissive(_lantern_color(i), 1.5)
		G.node(satellite, _shard_mesh(), tint, Vector3.ZERO, Vector3(.42, .62, .42))
		G.ring(satellite, .77, .035, bronze, Vector3.ZERO, 48)
		var halo := G.ring(satellite, .89, .018, tint, Vector3.ZERO, 48)
		halo.rotation.x = PI * .5
		satellites.append(satellite)


func _atmosphere() -> void:
	motes = Node3D.new()
	add_child(motes)
	var rng := RandomNumberGenerator.new()
	rng.seed = 116360
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 5
	mesh.rings = 3
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = 1800
	for i in range(mm.instance_count):
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(5, 65)
		var at := Vector3(sin(a) * r, rng.randf_range(.6, 32), cos(a) * r)
		var size_value := rng.randf_range(.012, .035)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size_value), at))
		mm.set_instance_custom_data(i, Color(rng.randf(), rng.randf(), rng.randf(), rng.randf()))
	var points := MultiMeshInstance3D.new()
	points.multimesh = mm
	points.material_override = surfaces.dust
	points.custom_aabb = AABB(Vector3(-70, -2, -70), Vector3(140, 40, 140))
	motes.add_child(points)
	for i in range(7):
		var material: ShaderMaterial = surfaces.ribbon.duplicate()
		material.set_shader_parameter("phase", i * .89)
		material.set_shader_parameter("tint", Color("ffba63") if i % 2 else Color("e674c0"))
		var ribbon := G.ring(self, 9.0 + i * 1.7, .035, material, Vector3(0, 3.5 + i * .75, 0), 180)
		ribbon.rotation.z = .13 * sin(i * 1.7)
		ribbon.custom_aabb = AABB(Vector3(-24, -3, -24), Vector3(48, 6, 48))
		ribbons.append(ribbon)


func _process(delta: float) -> void:
	if capture_mode:
		return
	elapsed = minf(DURATION, elapsed + delta)
	if audio and audio.playing:
		elapsed = clampf(audio.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency(), 0, DURATION)
	_apply_time(elapsed)


func sample_360_frame(_frame: int, time: float, _settings: Dictionary) -> String:
	_apply_time(clampf(time + time_offset, 0, DURATION))
	return ""


func note_at(part: String, time: float, decay: float = .16) -> Vector2:
	var value := Vector2.ZERO
	for note in cues.tracks[part]:
		var age: float = time - float(note.time)
		if age < 0:
			break
		if age < 1.4:
			var strength: float = exp(-age / decay) * float(note.velocity) / 110.0
			if strength > value.x:
				value = Vector2(strength, float(note.note))
	return value


func _apply_time(time: float) -> void:
	# Pure sampling allows seeking backward and matches every exported cube face.
	var bass := note_at("bass", time, .19)
	var guitar := note_at("guitar", time, .10)
	var brass := note_at("brass", time, .26)
	var build := smoothstep(1, 42, time)
	var suspended := smoothstep(40.8, 42.4, time) * (1 - smoothstep(45.3, 45.8, time))
	var release := smoothstep(45.45, 46.2, time)
	var end := 1 - smoothstep(58.0, 60.0, time)
	var dance := smoothstep(3.8, 18, time) * (1 - suspended * .6) * end
	var beat_angle := time / BEAT * TAU
	camera.position = Vector3(0, 2.8 + smoothstep(16, 40, time) * .65, 4.0 - smoothstep(8, 40, time) * .6)
	camera.rotation = Vector3.ZERO if capture_mode else Vector3(look.y, look.x, 0)
	for id in ["tiles", "facets", "dust", "sky"]:
		surfaces[id].set_shader_parameter("clock", time)
		surfaces[id].set_shader_parameter("build", build)
	surfaces.tiles.set_shader_parameter("bass", bass.x)
	surfaces.tiles.set_shader_parameter("bass_note", bass.y if bass.y > 0 else 38.0)
	surfaces.tiles.set_shader_parameter("guitar", guitar.x)
	surfaces.tiles.set_shader_parameter("suspended", suspended)
	surfaces.tiles.set_shader_parameter("ending", end)
	surfaces.facets.set_shader_parameter("pulse", brass.x + bass.x * .3)
	surfaces.dust.set_shader_parameter("pulse", brass.x * .5)
	mirrors.rotation = Vector3(.18 * sin(beat_angle * .125), time * .40, .15 * cos(beat_angle * .125))
	crystal.position = HEART + Vector3(sin(beat_angle * .0625) * .60 * dance, sin(beat_angle * .25) * .30 * dance + bass.x * .30 * dance + suspended * 1.1, cos(beat_angle * .0625) * .35 * dance)
	crystal.scale = Vector3.ONE * (1 + bass.x * .045 * dance)
	surfaces.tiles.set_shader_parameter("core_position", crystal.position)
	var lantern_orbit := time * .045 * smoothstep(8, 24, time)
	surfaces.tiles.set_shader_parameter("lantern_orbit", lantern_orbit)
	surfaces.tiles.set_shader_parameter("dance", dance)
	for i in range(petals.size()):
		var phase := i * TAU / petals.size()
		var a := phase + time * .18
		var opening := smoothstep(12, 34, time) * .70 + release * .30
		var accent := bass.x * .32 + brass.x * .38 * (1.0 if i % 2 else .4)
		var radius := 1.95 + opening * 2.3 + suspended * .65 + accent * dance
		petals[i].position = Vector3(sin(a) * radius, sin(phase * 2 + beat_angle * .25) * (.12 + dance * .68), cos(a) * radius)
		petals[i].rotation = Vector3(.10 + opening * 1.15 + sin(beat_angle * .25 + phase) * .22 * dance, a, sin(phase + beat_angle * .125) * .2 * dance)
	for i in range(hoops.size()):
		hoops[i].rotation = Vector3(.25 + i * .7 + time * .22 + sin(beat_angle * .25 + i) * .12 * dance, time * .19 * (1 if i % 2 else -1), i * .45 + time * .11)
		hoops[i].scale = Vector3.ONE * (1 + bass.x * .08 * dance)
	for i in range(pillars.size()):
		var phase := (i + .5) * TAU / pillars.size()
		var swing := sin(beat_angle * .25 - phase * 2)
		var radius := 24.0 + (swing * .85 + bass.x * .48) * dance
		pillars[i].position = Vector3(sin(phase) * radius, (1 + swing) * .35 * dance + suspended * .8, cos(phase) * radius)
		pillars[i].rotation = Vector3(.07 * swing * dance, phase + .08 * cos(beat_angle * .125 + phase) * dance, .075 * sin(beat_angle * .25 + phase) * dance)
		pillars[i].scale.y = 1 + (.07 * swing + bass.x * .045) * dance
		ribs[i].rotation.y = .045 * sin(beat_angle * .125 + phase * 2) * dance
		ribs[i].position.y = sin(beat_angle * .125 + phase * 2) * .55 * dance + suspended * .9
		ribs[i].scale.y = 1 + sin(beat_angle * .125 + phase) * .025 * dance
	for i in range(outer_arches.size()):
		var phase := i * TAU / outer_arches.size()
		var a := phase + sin(beat_angle * .0625 + phase) * .04 * dance
		outer_arches[i].position = Vector3(sin(a) * 35, (1 + sin(beat_angle * .125 + phase)) * 1.1 * dance, cos(a) * 35)
		outer_arches[i].rotation = Vector3(.06 * sin(beat_angle * .125 + phase) * dance, a, .04 * cos(beat_angle * .125 + phase) * dance)
	for i in range(lanterns.size()):
		var phase := (i + .5) * TAU / lanterns.size()
		var a := phase + lantern_orbit
		var radius := 22.56 + sin(beat_angle * .125 + phase) * 1.05 * dance
		lanterns[i].position = Vector3(sin(a) * radius, 5 + sin(beat_angle * .25 + phase * 2) * (.13 + dance * 1.15) + bass.x * .38 * dance + suspended * .9, cos(a) * radius)
		lanterns[i].rotation = Vector3(sin(beat_angle * .25 + phase) * .35 * dance, time * .42 + phase, cos(beat_angle * .25 + phase) * .22 * dance)
		var chase := pow(maxf(0, cos(phase * 2 - time * 2.8)), 8)
		var tint := Color(_lantern_color(i))
		lantern_materials[i].albedo_color = tint * (.12 + build * .55)
		lantern_materials[i].emission_energy_multiplier = .25 + build * .95 + chase * (guitar.x * 1.2 + .7) + brass.x * .8
	for i in range(ribbons.size()):
		var ribbon := ribbons[i]
		ribbon.position.y = 3.5 + i * .75 + sin(beat_angle * .125 + i) * .65 * dance
		ribbon.rotation = Vector3(sin(beat_angle * .0625 + i) * .25 * dance, time * .075 * (1 if i % 2 else -1), .13 * sin(i * 1.7) + cos(beat_angle * .125 + i) * .16 * dance)
		var material: ShaderMaterial = ribbon.material_override
		material.set_shader_parameter("clock", time)
		material.set_shader_parameter("strength", smoothstep(8.2, 20, time) * (.65 + guitar.x * .7 + brass.x * .4) * end)
	for i in range(satellites.size()):
		var phase := i * TAU / satellites.size()
		var a := phase + time * .22
		var radius := 12.8 + sin(beat_angle * .125 + phase) * 2.0 * dance
		satellites[i].position = Vector3(sin(a) * radius, 5.3 + sin(beat_angle * .25 + phase * 2) * 1.6 * dance + brass.x * .35, cos(a) * radius)
		satellites[i].rotation = Vector3(time * .65 + phase, -time * .7, sin(beat_angle * .125 + phase) * .55)
		satellites[i].scale = Vector3.ONE * maxf(.001, smoothstep(8, 16, time) * (.75 + brass.x * .18) * end)
	for i in range(beams.size()):
		var a := i * TAU / beams.size() + time * .24 + sin(beat_angle * .125 + i) * .11 * dance
		var radius := 14 + sin(beat_angle * .125 + i) * 4
		var target := Vector3(sin(a) * radius, .25 + (1 + sin(beat_angle * .125 + i)) * 1.8 * release, cos(a) * radius)
		var source := crystal.position
		var delta := source - target
		beams[i].transform = Transform3D(Basis(Quaternion(Vector3.UP, delta.normalized())).scaled(Vector3(1, delta.length(), 1)), (source + target) * .5)
		var material: ShaderMaterial = beams[i].material_override
		material.set_shader_parameter("strength", smoothstep(16, 30, time) * (.40 + release * .45 + brass.x * .65) * (1 - suspended * .8) * end)
		material.set_shader_parameter("clock", time)
	glow_light.position = crystal.position
	glow_light.light_energy = 3 + build * 2.4 + brass.x * 2.2
	_fade(titles, smoothstep(.2, 1.6, time) * (1 - smoothstep(5.5, 7.3, time)))
	_fade(ending_titles, smoothstep(57.7, 58.6, time) * (1 - smoothstep(59.4, 60, time)))


func _unhandled_input(event: InputEvent) -> void:
	if capture_mode:
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		look.x -= event.relative.x * .003
		look.y = clampf(look.y - event.relative.y * .003, -1.45, 1.45)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.keycode == KEY_R:
			elapsed = 0
			audio.play(0)


func _metal(hex: String, metallic: float) -> StandardMaterial3D:
	var mat := G.material(hex, false, metallic)
	mat.roughness = .27
	return mat


func _lantern_color(index: int) -> String:
	return ["ffb343", "ff419c", "ae5eff", "ffbf5a", "48d8df", "f34cca"][index % 6]


func _shard_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in range(4):
		var a := side * TAU / 4
		var b := (side + 1) * TAU / 4
		var first := Vector3(sin(a) * .48, .50, cos(a) * .48)
		var second := Vector3(sin(b) * .48, .50, cos(b) * .48)
		for point in [Vector3(0, 1.6, 0), second, first, Vector3(0, -1.6, 0), first, second]:
			surface.set_smooth_group(-1)
			surface.add_vertex(point)
	surface.generate_normals()
	return surface.commit()


func _emissive(hex: String, energy: float) -> StandardMaterial3D:
	var mat := G.material(hex, true)
	mat.albedo_color = Color(hex) * .38
	mat.emission_enabled = true
	mat.emission = Color(hex)
	mat.emission_energy_multiplier = energy
	return mat


func _title(words: String, subtitle: String, at: Vector3, size_value: float) -> Node3D:
	var group := Node3D.new()
	group.position = at
	add_child(group)
	for i in range(2):
		var label := G.text(group, words if i == 0 else subtitle, Vector3(0, -i * .48, 0), 100 if i == 0 else 27, size_value, Color("f3d7ad") if i == 0 else Color("b89abf"))
		label.alpha_cut = Label3D.ALPHA_CUT_DISABLED
	return group


func _fade(group: Node3D, alpha: float) -> void:
	group.visible = alpha > .001
	for child in group.get_children():
		child.modulate.a = alpha
