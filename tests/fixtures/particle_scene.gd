extends Node3D
## Constant-velocity particles cross cube edges; a mesh supplies an analytic oracle.

var job: Dictionary
var markers: Array[MeshInstance3D] = []
var origins: Array[Vector3] = []
var velocities: Array[Vector3] = []
var process_ticks := 0
var process_deltas: Array[float] = []
var samples: Array[Dictionary] = []
var authored_emitters: Array[Dictionary] = []


func prepare_360_capture(settings: Dictionary) -> void:
	job = settings


func _ready() -> void:
	process_mode = int(job.get("particle_root_mode", Node.PROCESS_MODE_INHERIT))
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	add_child(camera)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.025, 0.03, 0.04)
	add_child(world)
	for index in range(8):
		var angle := index * TAU / 8 + PI / 4 - 0.15
		var origin := Vector3(sin(angle), 0, -cos(angle)) * 4
		var velocity := Vector3(cos(angle) * 0.8, 0.6, sin(angle) * 0.8)
		origin.y = -1.0
		origins.append(origin)
		velocities.append(velocity)
		var mesh := SphereMesh.new()
		mesh.radius = 0.14
		mesh.height = 0.28
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color.from_hsv(index / 8.0, 0.7, 1.0)
		mesh.material = material
		if job.get("particle_oracle", false):
			var marker := MeshInstance3D.new()
			marker.mesh = mesh
			marker.position = origin
			add_child(marker)
			markers.append(marker)
		elif job.get("particle_kind", "gpu") == "cpu":
			var emitter := CPUParticles3D.new()
			emitter.name = "Particle%d" % index
			emitter.amount = 1
			emitter.lifetime = 10
			emitter.explosiveness = 1
			emitter.fixed_fps = int(job.get("particle_fps", 0))
			emitter.fract_delta = false
			emitter.direction = velocity
			emitter.spread = 0
			emitter.gravity = Vector3.ZERO
			emitter.initial_velocity_min = 1
			emitter.initial_velocity_max = 1
			if not job.get("particle_auto_bounds", false):
				emitter.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 8, 4))
			emitter.mesh = mesh
			emitter.position = origin
			add_child(emitter)
		else:
			var emitter := GPUParticles3D.new()
			emitter.name = "Particle%d" % index
			emitter.amount = 1
			emitter.lifetime = 10
			emitter.explosiveness = 1
			emitter.fixed_fps = int(job.get("particle_fps", 0))
			emitter.fract_delta = false
			emitter.interpolate = false
			emitter.use_fixed_seed = true
			emitter.seed = 360 + index
			emitter.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 8, 4))
			var process := ParticleProcessMaterial.new()
			process.direction = velocity
			process.spread = 0
			process.gravity = Vector3.ZERO
			process.initial_velocity_min = 1
			process.initial_velocity_max = 1
			emitter.process_material = process
			emitter.draw_pass_1 = mesh
			emitter.position = origin
			add_child(emitter)
	authored_emitters = _emitter_settings()


func sample_360_frame(frame_index: int, _time_seconds: float, settings: Dictionary) -> String:
	if frame_index == int(settings.get("particle_pause_frame", -1)):
		process_mode = Node.PROCESS_MODE_DISABLED
	for index in range(markers.size()):
		markers[index].position = origins[index] + velocities[index] * (float(frame_index) + float(settings.get("particle_offset", 1))) / float(settings.fps)
	samples.append({"frame": frame_index, "process_ticks": process_ticks, "mode": process_mode})
	if frame_index == int(settings.frames) - 1:
		if not preload("res://addons/godot360/job_io.gd").write_json(str(settings.output_dir).path_join("particle-samples.json"), {
			"samples": samples, "process_deltas": process_deltas,
			"authored_emitters": authored_emitters, "final_emitters": _emitter_settings()}):
			return "Cannot save particle fixture timing evidence."
	return ""


func _process(_delta: float) -> void:
	process_ticks += 1
	process_deltas.append(_delta)


func _emitter_settings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for child in get_children():
		if child is CPUParticles3D or child is GPUParticles3D:
			var settings := {"name": str(child.name), "fixed_fps": child.fixed_fps,
				"visibility_aabb": str(child.visibility_aabb), "custom_aabb": str(child.custom_aabb),
				"speed_scale": child.speed_scale, "emitting": child.emitting,
				"preprocess": child.preprocess, "fract_delta": child.fract_delta}
			if child is GPUParticles3D:
				settings.merge({"interpolate": child.interpolate, "use_fixed_seed": child.use_fixed_seed, "seed": child.seed})
			result.append(settings)
	return result
