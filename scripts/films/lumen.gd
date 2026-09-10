extends Node3D
## LUMEN: an original 24-second orbital observatory for immersive installations.
## The camera moves gently; viewers choose the direction they watch.
const G = preload("threshold_geometry.gd")
const DURATION := 24.0
const CENTER := Vector3(0, 4.8, -13)
var capture_mode := false
var elapsed := 0.0
var look := Vector2.ZERO
var camera: Camera3D
var core_material: ShaderMaterial
var sky_material: ShaderMaterial
var sky: MeshInstance3D
var core: Node3D
var gyroscopes: Array[Node3D] = []
var orbits: Array[Node3D] = []
var emitters: Array[GPUParticles3D] = []
var titles: Node3D
var ending: Node3D
var audio: AudioStreamPlayer


func prepare_360_capture(_settings: Dictionary) -> void:
	capture_mode = true


func _ready() -> void:
	camera = $Camera3D
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("07121f")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("789eb2")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.65
	world.environment = environment
	add_child(world)
	var attributes := CameraAttributesPractical.new()
	attributes.exposure_multiplier = 1.15
	camera.attributes = attributes
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, -25, 0)
	light.light_color = Color("7cbbd8")
	light.light_energy = 1.3
	add_child(light)
	var warm := OmniLight3D.new()
	warm.position = CENTER
	warm.light_color = Color("ffac57")
	warm.light_energy = 4.0
	warm.omni_range = 24
	add_child(warm)
	sky_material = ShaderMaterial.new()
	sky_material.shader = preload("res://assets/films/lumen/sky.gdshader")
	sky = G.sphere(self, 180, sky_material, Vector3.ZERO, Vector3.ONE, 64)
	_build_observatory()
	_build_engine()
	_build_particles()
	titles = _title("L U M E N", "AN ORBITAL OBSERVATORY", Vector3(0, 3.1, -8), 0.006)
	ending = _title("WORLDS YOU CAN LOOK AROUND", "MADE WITH GODOT360 STUDIO", Vector3(0, 3.0, -8), 0.0028)
	_apply_time(0)
	if not capture_mode:
		audio = AudioStreamPlayer.new()
		audio.stream = load("res://assets/audio/lumen-score.wav")
		add_child(audio)
		audio.play()


func _build_observatory() -> void:
	var stone := G.material("233848", false, 0.45)
	var dark := G.material("122431", false, 0.55)
	var brass := G.material("ad8053", false, 0.65)
	var cyan := _light_material("70d4db", 0.9)
	var amber := _light_material("ffc580", 0.8)
	var floor_material := ShaderMaterial.new()
	floor_material.shader = preload("res://assets/films/lumen/floor.gdshader")
	G.cylinder(self, 45, 45, 0.6, floor_material, Vector3(0, -0.45, 0), 128)
	for radius in [8.0, 16.0, 26.0]:
		G.ring(self, radius, 0.022, cyan, Vector3(0, -0.12, 0), 192)
	G.cylinder(self, 5.0, 4.8, 0.6, dark, Vector3(0, 0.05, -13), 96)
	G.ring(self, 4.9, 0.035, amber, Vector3(0, 0.37, -13))
	G.cylinder(self, 2.5, 2.1, 0.9, brass, Vector3(0, 0.72, -13), 64)
	for i in range(32):
		var a := i * TAU / 32.0
		var at := Vector3(sin(a) * 27, 0, cos(a) * 27)
		G.cylinder(self, 0.8, 0.48, 10, stone, at + Vector3(0, 4.8, 0))
		G.cylinder(self, 1.2, 1.2, 0.5, brass, at + Vector3(0, 0.2, 0))
		G.cylinder(self, 0.9, 1.1, 0.45, brass, at + Vector3(0, 9.7, 0))
		G.cylinder(self, 0.08, 0.08, 7.5, cyan, at * 0.978 + Vector3(0, 4.8, 0), 8)
		var arch := PackedVector3Array()
		for step in range(25):
			var u := step / 24.0
			var r := lerpf(27, 10, u)
			arch.append(Vector3(sin(a) * r, 10 + sin(u * PI * 0.5) * 8, cos(a) * r))
		G.tube(self, arch, 0.11, stone)
	for r in [10.0, 10.4, 26.6, 27.4]:
		G.ring(self, r, 0.06, brass, Vector3(0, 18 if r < 11 else 10, 0), 160)
	G.ring(self, 10.05, 0.025, cyan, Vector3(0, 17.9, 0), 160)
	# Real geometry supplies fine constellations in every viewing direction.
	var stars: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 2409360
	for i in range(650):
		var a := rng.randf_range(0, TAU)
		var elevation := rng.randf_range(-0.12, 1.45)
		var at := Vector3(sin(a) * cos(elevation), sin(elevation), cos(a) * cos(elevation)) * 125
		stars.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.04, 0.12)), at))
	var bead := SphereMesh.new()
	bead.radius = 1
	bead.height = 2
	bead.radial_segments = 6
	bead.rings = 3
	G.batch(self, bead, _light_material("bdd6e8", 0.5), stars)
	# Suspended long filaments are authored geometry, distinct from native trails.
	for i in range(5):
		var orbit := Node3D.new()
		orbit.position = Vector3(0, 9, -4)
		add_child(orbit)
		var path := PackedVector3Array()
		var radius := 14.0 + i * 1.4
		for j in range(161):
			var a := j * TAU / 160.0
			path.append(Vector3(cos(a) * radius, sin(a * 3 + i) * 0.32, sin(a) * radius))
		G.tube(orbit, path, 0.025 if i % 2 else 0.04, cyan if i % 2 else amber)
		orbits.append(orbit)


func _build_engine() -> void:
	core = Node3D.new()
	core.position = CENTER
	add_child(core)
	core_material = ShaderMaterial.new()
	core_material.shader = preload("res://assets/films/lumen/core.gdshader")
	G.sphere(core, 2.15, core_material, Vector3.ZERO, Vector3.ONE, 64)
	var metal := G.material("b39775", false, 0.8)
	var light := _light_material("ffe0a2", 0.7)
	for i in range(4):
		var mount := Node3D.new()
		core.add_child(mount)
		var r := 2.8 + i * 0.65
		G.ring(mount, r, 0.065, metal)
		G.ring(mount, r - 0.09, 0.017, light)
		for j in range(36):
			var a := j * TAU / 36.0
			var tick := G.box(mount, Vector3(0.04, 0.1, 0.22 if j % 3 else 0.38), metal, Vector3(sin(a) * r, 0, cos(a) * r))
			tick.rotation.y = a
		gyroscopes.append(mount)


func _build_particles() -> void:
	for i in range(8):
		var emitter := GPUParticles3D.new()
		emitter.name = "LightTrail%d" % i
		emitter.amount = 28
		emitter.lifetime = 3.137
		emitter.fixed_fps = 30
		emitter.fract_delta = false
		emitter.interpolate = false
		emitter.use_fixed_seed = true
		emitter.seed = 9360 + i
		emitter.local_coords = false
		emitter.visibility_aabb = AABB(Vector3(-45, -30, -45), Vector3(90, 60, 90))
		emitter.trail_enabled = true
		emitter.trail_lifetime = 0.65
		var mesh := TubeTrailMesh.new()
		mesh.radius = 0.028
		mesh.radial_steps = 5
		mesh.sections = 8
		mesh.section_rings = 3
		mesh.section_length = 0.12
		var material := _light_material("72e2e0" if i % 2 else "ffd99c", 0.85)
		material.use_particle_trails = true
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material = material
		emitter.draw_pass_1 = mesh
		var process := ParticleProcessMaterial.new()
		process.direction = Vector3(0, 1, 0)
		process.spread = 0
		process.initial_velocity_min = 1.1
		process.initial_velocity_max = 1.1
		process.gravity = Vector3.ZERO
		emitter.process_material = process
		emitter.position = _emitter_position(i, 0)
		add_child(emitter)
		emitters.append(emitter)
	for i in range(4):
		var smoke := GPUParticles3D.new()
		smoke.name = "Vapor%d" % i
		smoke.amount = 18
		smoke.lifetime = 3.137
		smoke.fixed_fps = 0
		smoke.fract_delta = false
		smoke.interpolate = false
		smoke.local_coords = false
		smoke.use_fixed_seed = true
		smoke.seed = 10360 + i
		smoke.visibility_aabb = AABB(Vector3(-15, -5, -15), Vector3(30, 30, 30))
		var quad := QuadMesh.new()
		quad.size = Vector2(3.2, 3.6)
		var material := ShaderMaterial.new()
		material.shader = preload("res://addons/godot360/examples/spherical_smoke.gdshader")
		material.set_shader_parameter("smoke_color", Color(0.32, 0.66, 0.72, 0.22))
		quad.material = material
		smoke.draw_pass_1 = quad
		var process := ParticleProcessMaterial.new()
		process.direction = Vector3.UP
		process.spread = 0
		process.initial_velocity_min = 0.8
		process.initial_velocity_max = 0.8
		process.gravity = Vector3.ZERO
		smoke.process_material = process
		var a := i * TAU / 4 + PI / 4
		smoke.position = CENTER + Vector3(sin(a) * 4.7, -3.5, cos(a) * 4.7)
		add_child(smoke)


func _emitter_position(index: int, time: float) -> Vector3:
	var a := index * TAU / 8.0 + time * 0.22
	return Vector3(sin(a) * (9 + index % 2 * 4), 3.0 + sin(a * 2 + time * 0.15) * 2.2, cos(a) * (9 + index % 2 * 4) - 5)


func _process(delta: float) -> void:
	# Move emitters before child simulation. Capture warmup holds this clock.
	for i in range(emitters.size()):
		emitters[i].position = _emitter_position(i, elapsed)
	elapsed = minf(DURATION, elapsed + delta)
	if not capture_mode:
		_apply_time(elapsed)


func sample_360_frame(_frame: int, time: float, _settings: Dictionary) -> String:
	_apply_time(clampf(time, 0, DURATION))
	return ""


func _apply_time(time: float) -> void:
	var travel := smoothstep(0, DURATION, time)
	camera.position = Vector3(sin(time * 0.13) * 0.5, 2.0 + travel * 1.4, 2.5 - travel * 2)
	camera.rotation = Vector3.ZERO if capture_mode else Vector3(look.y, look.x, 0)
	sky.position = camera.position
	sky_material.set_shader_parameter("clock", time)
	core_material.set_shader_parameter("clock", time)
	core.rotation.y = time * 0.075
	for i in range(gyroscopes.size()):
		gyroscopes[i].rotation = Vector3(PI / 2 + i * 0.55 + time * 0.035, i * 0.65 + time * 0.055 * (1 if i % 2 else -1), i * 0.4)
	for i in range(orbits.size()):
		orbits[i].rotation = Vector3(0.12 + i * 0.14, time * 0.015 * (1 if i % 2 else -1), sin(time * 0.11 + i) * 0.13)
	_fade(titles, smoothstep(0.2, 1.5, time) * (1 - smoothstep(4, 5.5, time)))
	_fade(ending, smoothstep(20, 21.5, time) * (1 - smoothstep(23, 24, time)))


func _unhandled_input(event: InputEvent) -> void:
	if capture_mode:
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		look.x -= event.relative.x * 0.003
		look.y = clampf(look.y - event.relative.y * 0.003, -1.45, 1.45)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()


func _title(text: String, subtitle: String, at: Vector3, size: float) -> Node3D:
	var group := Node3D.new()
	group.position = at
	add_child(group)
	for i in range(2):
		var label := Label3D.new()
		label.text = text if i == 0 else subtitle
		label.font_size = 100 if i == 0 else 30
		label.pixel_size = size
		label.position.y = 0 if i == 0 else -0.48
		label.modulate = Color("f5e1bd") if i == 0 else Color("94b8c5")
		label.outline_size = 0
		label.no_depth_test = false
		group.add_child(label)
	return group


func _fade(group: Node3D, alpha: float) -> void:
	group.visible = alpha > 0.001
	for label in group.get_children():
		label.modulate.a = alpha


func _light_material(hex: String, energy: float) -> StandardMaterial3D:
	var material := G.material(hex, true)
	material.emission_enabled = true
	material.emission = Color(hex)
	material.emission_energy_multiplier = energy
	return material
