extends "res://tests/fixtures/temporal_scene.gd"
## Two independently instantiated worlds load the same immutable, pre-baked room.
var room: Node3D
var oracle_room: Node3D
var oracle_ball: MeshInstance3D
var oracle_world: SubViewport
var lightmap_samples: Array[Dictionary] = []

func _ready() -> void:
	room = load("res://generated/lightmap_scene.tscn").instantiate()
	add_child(room)
	moving = _ball(room)
	oracle_world = SubViewport.new()
	oracle_world.own_world_3d = true
	oracle_world.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(oracle_world)
	oracle_room = load("res://generated/lightmap_scene.tscn").instantiate()
	oracle_world.add_child(oracle_room)
	oracle_ball = _ball(oracle_room)
	if mode == "lightmap_off":
		room.get_node("LightmapGI").light_data = null
		oracle_room.get_node("LightmapGI").light_data = null
	if mode == "probes_off":
		moving.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		oracle_ball.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	if bool(job.get("missing_lightmap_control", false)):
		room.get_node("LightmapGI").light_data = null
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	initial = _viewport_settings(get_viewport())

func _ball(parent: Node3D) -> MeshInstance3D:
	var ball := MeshInstance3D.new()
	ball.name = "DynamicProbeReceiver"
	var mesh := SphereMesh.new()
	mesh.radius = 0.55
	mesh.height = 1.1
	ball.mesh = mesh
	ball.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.75, 0.75, 0.75)
	material.roughness = 0.85
	ball.material_override = material
	parent.add_child(ball)
	return ball

func begin_360_capture(settings: Dictionary) -> void:
	super.begin_360_capture(settings)
	for view in references:
		# own_world_3d uses a viewport-owned world; its world_3d property is null.
		view.world_3d = oracle_room.get_world_3d()

func sample_360_frame(frame_index: int, seconds: float, settings: Dictionary) -> String:
	super.sample_360_frame(frame_index, seconds, settings)
	oracle_ball.transform = moving.transform
	return ""

func _save_references() -> void:
	super._save_references()
	var captured := room.get_node("LightmapGI") as LightmapGI
	var native := oracle_room.get_node("LightmapGI") as LightmapGI
	var independent_views := true
	for camera in cameras:
		independent_views = independent_views and camera.get_world_3d() == oracle_room.get_world_3d()
	lightmap_samples.append({"frame": index, "captured_users": captured.light_data.get_user_count() if captured.light_data else 0,
		"native_users": native.light_data.get_user_count() if native.light_data else 0,
		"dynamic_gi_mode": moving.gi_mode, "native_dynamic_gi_mode": oracle_ball.gi_mode,
		"independent_worlds": room.get_world_3d() != oracle_room.get_world_3d() and independent_views,
		"ball_position_error": moving.position.distance_to(oracle_ball.position)})
	if index == int(job.frames) - 1:
		assert(preload("res://addons/godot360/job_io.gd").write_json(str(job.output_dir).path_join("lightmap-samples.json"), {"samples": lightmap_samples}))
