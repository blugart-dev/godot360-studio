extends Node3D
## Continuous transparent smoke from moving CPU/GPU emitters, with analytic quads.

const COUNT := 12
# Avoid births exactly on frame boundaries: CPU double and GPU float phase
# accumulation can place those births on opposite sides of the same sample.
const LIFE := 2.137
const VELOCITY := Vector3(0, 0.7, 0)
var job: Dictionary
var emitters: Array[Node3D] = []
var markers: Array[Array] = []
var camera: Camera3D
var ticks := 0
var deltas: Array[float] = []
var samples: Array[Dictionary] = []
var initial_settings: Array[Dictionary] = []
var draw_samples: Array[Dictionary] = []
var sampled_frame := 0


func prepare_360_capture(settings: Dictionary) -> void:
	job = settings


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "Camera3D"
	add_child(camera)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.025, 0.03, 0.04)
	add_child(world)
	# Dark opaque posts intersect the smoke to exercise depth testing and alpha
	# transmission. They stay below the reviewer's bright-smoke foreground mask.
	for index in range(4):
		var post := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.16, 2.5, 0.2)
		var dark := StandardMaterial3D.new()
		dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dark.albedo_color = Color(0.04, 0.055, 0.07)
		box.material = dark
		post.mesh = box
		post.position = _origin(index, 1.0) * 0.86
		add_child(post)
	for stream in range(4):
		var mesh := QuadMesh.new()
		mesh.size = Vector2(1.2, 1.5)
		var material := ShaderMaterial.new()
		material.shader = preload("res://addons/godot360/examples/spherical_smoke.gdshader")
		material.set_shader_parameter("point_billboard", not job.get("smoke_oracle", false))
		if job.get("smoke_wrong_alpha", false):
			material.set_shader_parameter("smoke_color", Color(0.72, 0.78, 0.86, 0.72))
		if job.get("smoke_face_billboard", false):
			# Same fragment shader; only the billboard basis changes in this control.
			var face_shader := Shader.new()
			face_shader.code = material.shader.code.replace("vec3 facing = CAMERA_POSITION_WORLD - MODEL_MATRIX[3].xyz;", "vec3 facing = INV_VIEW_MATRIX[2].xyz;").replace("vec3 up = abs(facing.y) > 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(0.0, 1.0, 0.0);", "vec3 up = INV_VIEW_MATRIX[1].xyz;")
			material.shader = face_shader
		mesh.material = material
		if job.get("smoke_oracle", false):
			var group: Array = []
			for index in range(COUNT):
				var marker := MeshInstance3D.new()
				marker.mesh = mesh
				add_child(marker)
				group.append(marker)
			markers.append(group)
		else:
			var emitter: Node3D
			if job.get("smoke_kind", "gpu") == "cpu":
				emitter = CPUParticles3D.new()
				emitter.mesh = mesh
				emitter.direction = VELOCITY
				emitter.gravity = Vector3.ZERO
				emitter.spread = 0
				emitter.initial_velocity_min = VELOCITY.length()
				emitter.initial_velocity_max = VELOCITY.length()
			else:
				emitter = GPUParticles3D.new()
				emitter.draw_pass_1 = mesh
				emitter.interpolate = false
				emitter.use_fixed_seed = true
				emitter.seed = 360 + stream
				var process := ParticleProcessMaterial.new()
				process.direction = VELOCITY
				process.gravity = Vector3.ZERO
				process.spread = 0
				process.initial_velocity_min = VELOCITY.length()
				process.initial_velocity_max = VELOCITY.length()
				emitter.process_material = process
			emitter.name = "Smoke%d" % stream
			emitter.amount = COUNT
			emitter.lifetime = LIFE
			emitter.fixed_fps = int(job.get("smoke_fixed_fps", 0))
			emitter.fract_delta = false
			emitter.local_coords = bool(job.get("smoke_local", false))
			emitter.preprocess = float(job.get("smoke_preprocess", 0.0))
			emitter.visibility_aabb = AABB(Vector3(-12, -12, -12), Vector3(24, 24, 24))
			emitter.position = _origin(stream, 0)
			add_child(emitter)
			emitters.append(emitter)
	initial_settings = _settings()
	RenderingServer.frame_post_draw.connect(_after_draw)


func _origin(stream: int, time: float) -> Vector3:
	var angle := PI / 4.0 - 0.3 + time * 0.38 + stream * PI / 2.0
	var p := Vector3(sin(angle), 0, -cos(angle)) * 4.0
	p.y = -0.6 if stream < 2 else 3.2
	return p


func _process(delta: float) -> void:
	# Pause before child CPU simulation and the later GPU draw simulation. A
	# late sampling-hook pause would stop the GPU one sample before the CPU.
	if ticks == int(job.get("smoke_pause", -1)):
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	for stream in range(emitters.size()):
		emitters[stream].position = _origin(stream, ticks / float(job.fps))
	ticks += 1
	deltas.append(delta)


func sample_360_frame(frame: int, _time: float, settings: Dictionary) -> String:
	sampled_frame = frame
	var pause := int(settings.get("smoke_pause", -1))
	var sim_frame := mini(frame, pause - 1) if pause >= 0 else frame
	var fps := float(settings.fps)
	var time := (sim_frame + 1) / fps
	var cut := frame >= int(settings.get("smoke_cut", 36))
	camera.position = Vector3(0.3, 0.15, -0.2) if cut else Vector3.ZERO
	camera.rotation = Vector3(0.08, 0.31, 0.12) if cut else Vector3.ZERO
	for stream in range(markers.size()):
		for index in range(COUNT):
			var marker: MeshInstance3D = markers[stream][index]
			var birth := index * LIFE / COUNT
			while birth + LIFE < time - 0.00001:
				birth += LIFE
			marker.visible = birth < time - 0.00001
			var birth_frame := floori(birth * fps)
			var age := (sim_frame - birth_frame + 1) / fps
			var spawn := _origin(stream, birth_frame / fps)
			if settings.get("smoke_local", false):
				spawn = _origin(stream, sim_frame / fps)
			marker.position = spawn + VELOCITY * age
			if settings.get("smoke_late", false):
				marker.position -= Vector3(0.12, 0, 0)
			var facing := (camera.position - marker.position).normalized()
			var up := Vector3.BACK if absf(facing.y) > 0.999 else Vector3.UP
			var right := up.cross(facing).normalized()
			marker.basis = Basis(right, facing.cross(right), facing)
	samples.append({"frame": frame, "ticks": ticks, "mode": process_mode,
		"camera": str(camera.transform), "emitter": str(emitters[0].position) if not emitters.is_empty() else "oracle"})
	return ""


func _after_draw() -> void:
	# Observe actual face transforms after drawing, including the cut during pause.
	var max_error := 0.0
	var count := 0
	var cut := sampled_frame >= int(job.get("smoke_cut", 36))
	var expected := Transform3D(Basis.from_euler(Vector3(0.08, 0.31, 0.12)), Vector3(0.3, 0.15, -0.2)) if cut else Transform3D.IDENTITY
	for sibling in get_parent().get_children():
		for child in sibling.get_children():
			if child is SubViewport and str(child.name).begins_with("Face_"):
				var face_index: int = preload("res://addons/godot360/capture_rig.gd").FACE_NAMES.find(str(child.name).trim_prefix("Face_"))
				var directions := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]
				var ups := [Vector3.UP, Vector3.UP, Vector3.BACK, Vector3.FORWARD, Vector3.UP, Vector3.UP]
				var target := expected * Transform3D(Basis.looking_at(directions[face_index], ups[face_index]), Vector3.ZERO)
				var actual: Transform3D = child.get_camera_3d().global_transform
				max_error = maxf(max_error, actual.origin.distance_to(target.origin))
				for axis in range(3):
					max_error = maxf(max_error, actual.basis[axis].distance_to(target.basis[axis]))
				count += 1
	draw_samples.append({"frame": sampled_frame, "faces": count, "camera_error": max_error})
	if sampled_frame == int(job.frames) - 1:
		if not preload("res://addons/godot360/job_io.gd").write_json(str(job.output_dir).path_join("smoke-samples.json"), {
			"samples": samples, "draw_samples": draw_samples, "deltas": deltas, "initial": initial_settings, "final": _settings()}):
			push_error("Cannot save smoke evidence.")


func _settings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for emitter in emitters:
		result.append({"fixed_fps": emitter.fixed_fps, "local_coords": emitter.local_coords,
			"preprocess": emitter.preprocess, "amount": emitter.amount, "lifetime": emitter.lifetime,
			"speed_scale": emitter.speed_scale, "emitting": emitter.emitting, "bounds": str(emitter.visibility_aabb)})
	return result
