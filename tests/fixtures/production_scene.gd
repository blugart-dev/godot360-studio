extends "res://tests/fixtures/endurance.gd"
## Sustained load: textured geometry, dynamic shadows, alpha, particles, history.
var batches: Array[MultiMeshInstance3D] = []
var lamps: Array[OmniLight3D] = []
var emitters: Array[GPUParticles3D] = []
var history: CompositorEffect
var rendered_samples: Array[Dictionary] = []
var frame_index := 0
var draw_count := 0

func _audio_preroll() -> float:
	return float(job.warmup_frames) / float(job.fps)

func _ready() -> void:
	assert(preload("res://addons/godot360/job_io.gd").write_json(str(job.output_dir).path_join("production-worker.json"), {"pid": OS.get_process_id()}))
	get_viewport().msaa_3d = int(job.get("benchmark_msaa", Viewport.MSAA_4X))
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.045, 0.075)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.7, 0.9)
	env.ambient_light_energy = 0.3
	env.tonemap_exposure = 1.0
	env.glow_enabled = str(job.rendering_method) == "forward_plus"
	env.glow_intensity = 0.4
	env.glow_hdr_threshold = 2.0
	world.environment = env
	add_child(world)
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 1.1
	mesh.radial_segments = 64
	mesh.rings = 32
	var rng := RandomNumberGenerator.new()
	rng.seed = 3602026
	for material_index in range(12):
		var material := StandardMaterial3D.new()
		material.albedo_texture = load("res://generated/textures/albedo-%02d.png" % material_index)
		material.normal_enabled = true
		material.normal_texture = load("res://generated/textures/normal-%02d.png" % material_index)
		material.metallic = 0.4 if material_index % 2 else 0.1
		material.roughness = 0.3 + 0.04 * material_index
		var batch := MultiMeshInstance3D.new()
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = 64
		for i in range(64):
			var angle := TAU * (float(i) / 64 + float(material_index) / 768)
			var radius := 10.0 + (material_index % 4) * 4.0
			var at := Vector3(sin(angle) * radius, -0.3 + floori(material_index / 4.0) * 3.5 + sin(angle * 3) * 0.5, cos(angle) * radius)
			var basis := Basis.from_euler(Vector3(rng.randf(), rng.randf(), rng.randf()))
			multi.set_instance_transform(i, Transform3D(basis.scaled(Vector3.ONE * rng.randf_range(0.7, 1.4)), at))
		batch.multimesh = multi
		batch.material_override = material
		add_child(batch)
		batches.append(batch)
	var ground := MeshInstance3D.new()
	var ground_mesh := CylinderMesh.new()
	ground_mesh.top_radius = 30
	ground_mesh.bottom_radius = 30
	ground_mesh.height = 0.4
	ground_mesh.radial_segments = 128
	ground.mesh = ground_mesh
	ground.position.y = -1.3
	ground.material_override = batches[0].material_override
	add_child(ground)
	for i in range(6):
		var lamp := OmniLight3D.new()
		var angle := TAU * i / 6
		lamp.position = Vector3(sin(angle) * 13, 5, cos(angle) * 13)
		lamp.light_color = Color.from_hsv(float(i) / 6, 0.45, 1.0)
		lamp.light_energy = 5
		lamp.omni_range = 20
		lamp.shadow_enabled = true
		add_child(lamp)
		lamps.append(lamp)
		_particles(lamp.position - Vector3(0, 3, 0), lamp.light_color)
	for i in range(24):
		var panel := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(4, 5)
		panel.mesh = quad
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color.from_hsv(float(i) / 24, 0.55, 0.7, 0.22)
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.roughness = 0.35
		panel.material_override = material
		var angle := i * TAU / 24
		panel.position = Vector3(sin(angle) * 8, 3.5, cos(angle) * 8)
		panel.rotation.y = angle + PI / 4
		add_child(panel)
	history = preload("temporal_history.gd").new()
	# Short history leaves the independent black/white frame identifier readable.
	history.history_weight = 0.15
	$Camera3D.compositor = Compositor.new()
	$Camera3D.compositor.compositor_effects = [history]
	if int(job.get("storage_fault_after", 0)) > 0:
		get_tree().storage.sample_interval_msec = 0
		get_tree().storage.space_reader = func() -> int: return 0 if get_tree().rendered >= int(job.storage_fault_after) else 1000000000000
	RenderingServer.frame_post_draw.connect(_record)
	# Start the clock only after expensive resource construction has finished.
	var existing := get_children()
	# The WAV already includes warmup padding; its player must keep advancing
	# while capture holds ordinary scene processing during warmup.
	$Audio.process_mode = Node.PROCESS_MODE_ALWAYS
	super._ready()
	for child in get_children():
		if child is MeshInstance3D and child not in existing:
			child.reparent($Camera3D, false)

func _particles(at: Vector3, tint: Color) -> void:
	var particle := GPUParticles3D.new()
	particle.amount = 256
	particle.lifetime = 4.0
	particle.fixed_fps = 30
	particle.interpolate = false
	particle.use_fixed_seed = true
	particle.seed = 360 + emitters.size()
	particle.visibility_aabb = AABB(Vector3(-5, -2, -5), Vector3(10, 14, 10))
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 25
	process.initial_velocity_min = 1.2
	process.initial_velocity_max = 2.0
	process.gravity = Vector3(0, 0.15, 0)
	process.scale_min = 0.08
	process.scale_max = 0.22
	particle.process_material = process
	var sphere := SphereMesh.new()
	sphere.radius = 1
	sphere.height = 2
	sphere.radial_segments = 8
	sphere.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 3.0
	sphere.material = material
	particle.draw_pass_1 = sphere
	particle.position = at
	add_child(particle)
	emitters.append(particle)

func sample_360_frame(index: int, seconds: float, settings: Dictionary) -> String:
	super.sample_360_frame(index, seconds, settings)
	# An opaque dark panel prevents the lit background from imitating a flash.
	flash.material_override.albedo_color = Color.WHITE if flash.visible else Color(0.02, 0.02, 0.02)
	flash.visible = true
	frame_index = index
	var phase := seconds * TAU / 30.0
	$Camera3D.position = Vector3(0.6 * sin(phase), 2.0 + 0.3 * sin(phase * 0.7), 0.6 * cos(phase))
	$Camera3D.rotation = Vector3(0.03 * sin(phase), 0.12 * sin(phase * 0.5), 0)
	# The fixed timeline makes short-probe estimates refer to the same scene.
	if seconds >= 30:
		$Camera3D.rotation.y += 0.5
	for i in range(batches.size()):
		batches[i].rotation.y = seconds * (0.018 if i % 2 else -0.015)
	for i in range(lamps.size()):
		lamps[i].light_energy = 4.0 + sin(phase + i) * 1.5
	return ""

func _record() -> void:
	draw_count += 1
	if frame_index % 30 == 0 or frame_index == int(job.frames) - 1:
		rendered_samples.append({"frame": frame_index, "draw": draw_count,
			"engine_video_bytes": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),
			"engine_texture_bytes": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED),
			"engine_buffer_bytes": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED),
			"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)})
	if frame_index == int(job.frames) - 1:
		assert(preload("res://addons/godot360/job_io.gd").write_json(str(job.output_dir).path_join("production-scene.json"),
			{"samples": rendered_samples, "history_counts": history.snapshot(), "instances": 768,
			"texture_maps": 24, "shadowed_lights": 6, "alpha_panels": 24, "gpu_particles": 1536,
			"glow": str(job.rendering_method) == "forward_plus", "msaa_3d": get_viewport().msaa_3d}))
