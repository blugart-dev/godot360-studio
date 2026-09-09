extends "res://addons/godot360/timeline_scene.gd"
## Normal GLB import/AnimationPlayer/skin, checked against raw-glTF CPU samples.
var job: Dictionary
var reference: Dictionary
var skeleton: Skeleton3D
var camera: Camera3D
var boom: Node3D
var imported_mesh: MeshInstance3D
var cpu_mesh: MeshInstance3D
var sampled_frame := 0
var observations: Array[Dictionary] = []
var look: SkeletonModifier3D
var look_target: Node3D
var nested: Skeleton3D
var final_bones := {}
var nested_final := Transform3D.IDENTITY
var face_cameras: Array[Camera3D] = []


func prepare_360_capture(settings: Dictionary) -> void:
	super.prepare_360_capture(settings)
	job = settings
	reference = preload("res://addons/godot360/job_io.gd").read_json("res://reference/reference.json")


func _ready() -> void:
	var character := preload("res://tests/fixtures/cesium_man/CesiumMan.glb").instantiate()
	character.name = "Character"
	add_child(character)
	skeleton = character.find_children("*", "Skeleton3D", true, false)[0]
	imported_mesh = character.find_children("*", "MeshInstance3D", true, false)[0]
	var player: AnimationPlayer = character.find_children("*", "AnimationPlayer", true, false)[0]
	animation_player_path = get_path_to(player)
	for candidate in player.get_animation_list():
		if candidate != &"RESET":
			animation_name = candidate
			break
	player.get_animation(animation_name).loop_mode = Animation.LOOP_NONE
	if not job.get("textured", false):
		imported_mesh.material_override = _material(Color(1, 0.32, 0.02))
	var attachment := BoneAttachment3D.new()
	attachment.name = "HeadAttachment"
	attachment.use_external_skeleton = true
	attachment.bone_name = reference.head
	# External path is relative to the attachment, whose parent is this node.
	attachment.external_skeleton = NodePath("../" + str(get_path_to(skeleton)))
	add_child(attachment)
	if job.get("head_look", false):
		look_target = Node3D.new()
		add_child(look_target)
		look = preload("res://tests/fixtures/head_look.gd").new()
		look.bone_name = reference.head
		look.target = look_target
		var c: Array = reference.calibration
		look.calibration = Basis(Vector3(c[0], c[1], c[2]), Vector3(c[3], c[4], c[5]), Vector3(c[6], c[7], c[8]))
		skeleton.add_child(look)
		skeleton.modifier_callback_mode_process = Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_MANUAL
	skeleton.skeleton_updated.connect(_final_pose)
	var mount: Node3D = attachment
	if job.get("nested", false):
		nested = Skeleton3D.new()
		nested.name = "NestedSkeleton"
		attachment.add_child(nested)
		nested.position = Vector3(0.18, 0.12, 0)
		nested.add_bone("mount")
		var inner := BoneAttachment3D.new()
		inner.name = "MountAttachment"
		inner.bone_name = "mount"
		nested.add_child(inner)
		mount = inner
		nested.skeleton_updated.connect(func(): nested_final = nested.global_transform * nested.get_bone_global_pose(0))
	boom = Node3D.new()
	boom.name = "Boom"
	mount.add_child(boom)
	boom.transform = _transform(reference.boom)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	if job.get("oracle_camera", false):
		add_child(camera)
	else:
		boom.add_child(camera)
	if job.get("oracle_skin", false):
		imported_mesh.visible = false
		cpu_mesh = MeshInstance3D.new()
		cpu_mesh.mesh = ArrayMesh.new()
		cpu_mesh.material_override = _material(Color(1, 0.32, 0.02))
		add_child(cpu_mesh)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.035, 0.04, 0.055)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color.WHITE
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -30, 0)
	add_child(light)
	for n in range(16):
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.10
		sphere.height = 0.20
		marker.mesh = sphere
		marker.material_override = _material(Color.from_hsv(n / 16.0, 0.8, 0.9))
		marker.position = Vector3(sin(n * TAU / 16) * 4, 0.5, -cos(n * TAU / 16) * 4)
		add_child(marker)
	RenderingServer.frame_post_draw.connect(_observe)
	super._ready()


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	return material


func _transform(values: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(values[0], values[1], values[2]), Vector3(values[4], values[5], values[6]),
		Vector3(values[8], values[9], values[10])), Vector3(values[12], values[13], values[14]))


func _values(value: Transform3D) -> Array:
	return [value.basis.x.x, value.basis.x.y, value.basis.x.z, 0, value.basis.y.x, value.basis.y.y, value.basis.y.z, 0,
		value.basis.z.x, value.basis.z.y, value.basis.z.z, 0, value.origin.x, value.origin.y, value.origin.z, 1]


func sample_360_frame(frame: int, seconds: float, settings: Dictionary) -> String:
	var error := super.sample_360_frame(frame, seconds, settings)
	if not error.is_empty():
		return error
	sampled_frame = frame
	if look != null:
		var base: Array = reference.target_base
		var aim_frame := maxi(0, frame - int(job.get("look_delay", 0)))
		look_target.position = Vector3(base[0] + 0.85 * sin(aim_frame * 0.17), base[1] + 0.35 * sin(aim_frame * 0.23), base[2])
		# A manual, stateless modifier runs at the absolute sample, including warmup.
		skeleton.advance(0.0)
	if job.get("oracle_camera", false):
		camera.transform = _transform(reference.frames[maxi(0, frame - int(job.get("camera_delay", 0)))].camera)
	else:
		camera.rotation.y = 0.55 if frame >= int(job.frames) / 2 else 0.0
	if cpu_mesh != null:
		var index := maxi(0, frame - int(job.get("skin_delay", 0)))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = FileAccess.get_file_as_bytes("res://reference/vertices-%03d.bin" % index).to_vector3_array()
		arrays[Mesh.ARRAY_INDEX] = FileAccess.get_file_as_bytes("res://reference/indices.bin").to_int32_array()
		cpu_mesh.mesh.clear_surfaces()
		cpu_mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return ""


func _final_pose() -> void:
	final_bones.clear()
	for bone in range(skeleton.get_bone_count()):
		final_bones[skeleton.get_bone_name(bone)] = _values(skeleton.global_transform * skeleton.get_bone_global_pose(bone))
	if nested != null:
		# Downstream posing is queued during the upstream skeleton_updated callback.
		nested.set_bone_pose_rotation(0, Quaternion(Vector3.UP, 0.2 * sin(sampled_frame * 0.31)))


func _observe() -> void:
	if face_cameras.is_empty():
		for face in get_tree().root.find_children("Face_*", "SubViewport", true, false):
			face_cameras.append(face.get_camera_3d())
	var faces: Array = []
	for face in face_cameras:
		faces.append(_values(face.global_transform))
	var bones := {}
	for bone in range(skeleton.get_bone_count()):
		bones[skeleton.get_bone_name(bone)] = _values(skeleton.global_transform * skeleton.get_bone_global_pose(bone))
	observations.append({"frame": sampled_frame, "camera": _values(camera.global_transform), "bones": final_bones.duplicate(true),
		"base_bones": bones, "nested": _values(nested_final), "faces": faces,
		"evaluations": look.evaluations if look != null else 0})
	if sampled_frame == int(job.frames) - 1:
		preload("res://addons/godot360/job_io.gd").write_json(str(job.output_dir).path_join("character-samples.json"),
			{"samples": observations, "animation": str(animation_name), "bones": skeleton.get_bone_count(),
			"animation_tracks": timeline_animation.get_track_count()})
