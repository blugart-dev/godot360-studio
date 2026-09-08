extends "res://addons/godot360/timeline_scene.gd"
## Bone camera and a two-bone weighted mesh, each with an independent oracle.
var job: Dictionary
var skeleton: Skeleton3D
var camera: Camera3D
var mesh_instance: MeshInstance3D
var vertices := PackedVector3Array()
var weights := PackedFloat32Array()
var arrays: Array


func prepare_360_capture(settings: Dictionary) -> void:
	super.prepare_360_capture(settings)
	job = settings


func _ready() -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	add_child(skeleton)
	for bone in ["camera", "base", "tip"]:
		skeleton.add_bone(bone)
	skeleton.set_bone_parent(2, 1)
	skeleton.set_bone_rest(1, Transform3D(Basis.IDENTITY, Vector3(3, 0, -4)))
	skeleton.set_bone_rest(2, Transform3D(Basis.IDENTITY, Vector3(0, 1, 0)))
	skeleton.reset_bone_poses()
	var attachment := BoneAttachment3D.new()
	attachment.name = "Attachment"
	attachment.bone_name = "camera"
	if job.get("external_skeleton", false):
		attachment.use_external_skeleton = true
		attachment.external_skeleton = NodePath("../Skeleton3D")
		add_child(attachment)
	else:
		skeleton.add_child(attachment)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	if job.get("oracle_camera", false):
		add_child(camera)
	else:
		attachment.add_child(camera)
	# Keep a nontrivial local camera transform in both paths.
	camera.position = Vector3(0.1, 0.1, 0.05)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.035, 0.04, 0.055)
	add_child(world)
	for n in range(16):
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.16
		sphere.height = 0.32
		marker.mesh = sphere
		marker.material_override = _material(Color.from_hsv(n / 16.0, 0.8, 0.9))
		marker.position = Vector3(sin(n * TAU / 16), -0.5, -cos(n * TAU / 16)) * 5
		add_child(marker)
	_create_mesh()
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	add_child(player)
	var library := AnimationLibrary.new()
	var animation := Animation.new()
	animation.length = 2
	var track := animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(track, NodePath("Skeleton3D:camera"))
	for key in [[0.0, 0.0], [0.5, 0.7], [1.0, 0.0], [1.5, -0.7], [2.0, 0.0]]:
		animation.position_track_insert_key(track, key[0], Vector3(key[1], 0, 0))
	track = animation.add_track(Animation.TYPE_ROTATION_3D)
	animation.track_set_path(track, NodePath("Skeleton3D:tip"))
	for key in [[0.0, -0.7], [1.0, 0.7], [2.0, -0.7]]:
		animation.rotation_track_insert_key(track, key[0], Quaternion(Vector3.FORWARD, key[1]))
	# A hard viewpoint cut at delivered frame 30, while the mesh keeps moving.
	track = animation.add_track(Animation.TYPE_ROTATION_3D)
	animation.track_set_path(track, NodePath("Skeleton3D:camera"))
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_NEAREST)
	animation.rotation_track_insert_key(track, 0, Quaternion.IDENTITY)
	animation.rotation_track_insert_key(track, 1, Quaternion(Vector3.UP, 0.55))
	library.add_animation("film", animation)
	player.add_animation_library("", library)
	super._ready()


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	return material


func _create_mesh() -> void:
	arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	var bones := PackedInt32Array()
	var indices := PackedInt32Array()
	for row in range(17):
		var height := row / 8.0
		for side in [-1, 1]:
			vertices.append(Vector3(3 + side * 0.28, height, -4))
			var weight := clampf(height - 0.5, 0, 1)
			weights.append_array([1 - weight, weight, 0, 0])
			bones.append_array([1, 2, 0, 0])
		if row < 16:
			var i := row * 2
			indices.append_array([i, i+1, i+2, i+1, i+3, i+2])
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	if not job.get("oracle_skin", false):
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = ArrayMesh.new()
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.material_override = _material(Color(1, 0.32, 0.02))
	skeleton.add_child(mesh_instance)
	if not job.get("oracle_skin", false):
		mesh_instance.skeleton = NodePath("..")
		mesh_instance.skin = skeleton.create_skin_from_rest_transforms()


func sample_360_frame(frame: int, seconds: float, settings: Dictionary) -> String:
	var error := super.sample_360_frame(frame, seconds, settings)
	if not error.is_empty():
		return error
	if job.get("oracle_camera", false):
		# Triangle wave: 0, +0.7, 0, -0.7, 0 at half-second intervals.
		var x := 1.4 * seconds if seconds < 0.5 else (1.4 - 1.4 * seconds if seconds < 1.5 else 1.4 * seconds - 2.8)
		var basis := Basis(Vector3.UP, 0.55 if seconds >= 1 else 0.0)
		camera.transform = Transform3D(basis, Vector3(x, 0, 0)) * Transform3D(Basis.IDENTITY, Vector3(0.1, 0.1, 0.05))
	if job.get("oracle_skin", false):
		var angle := -0.7 + 1.4 * seconds if seconds <= 1 else 2.1 - 1.4 * seconds
		var pivot := Vector3(3, 1, -4)
		var deformed := PackedVector3Array()
		for i in range(vertices.size()):
			var point := vertices[i]
			deformed.append(point.lerp(pivot + Basis(Vector3.FORWARD, angle) * (point - pivot), weights[i*4+1]))
		arrays[Mesh.ARRAY_VERTEX] = deformed
		mesh_instance.mesh.clear_surfaces()
		mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return ""
