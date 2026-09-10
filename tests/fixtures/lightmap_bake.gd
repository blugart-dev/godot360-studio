@tool
extends EditorPlugin
## Disposable-project editor helper: use Godot's real Bake Lightmaps action.
const SCENE = "res://generated/lightmap_scene.tscn"

func _enter_tree() -> void:
	_build_and_bake.call_deferred()

func _build_and_bake() -> void:
	while EditorInterface.get_resource_filesystem().is_scanning():
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute("res://generated")
	var scene := Node3D.new()
	scene.name = "BakedRoom"
	var env := WorldEnvironment.new()
	env.name = "Environment"
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.015, 0.02, 0.025)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.025
	_owned(scene, env)
	_box(scene, "Floor", Vector3(12, 0.2, 12), Vector3(0, -1.6, 0), Color(0.65, 0.65, 0.65))
	_box(scene, "Ceiling", Vector3(12, 0.2, 12), Vector3(0, 3.6, 0), Color(0.6, 0.6, 0.6))
	_box(scene, "Left", Vector3(0.2, 5, 12), Vector3(-6, 1, 0), Color(0.85, 0.16, 0.04))
	_box(scene, "Right", Vector3(0.2, 5, 12), Vector3(6, 1, 0), Color(0.04, 0.32, 0.85))
	_box(scene, "Front", Vector3(12, 5, 0.2), Vector3(0, 1, -6), Color(0.65, 0.65, 0.65))
	_box(scene, "Back", Vector3(12, 5, 0.2), Vector3(0, 1, 6), Color(0.65, 0.65, 0.65))
	for i in range(4):
		_box(scene, "Column%d" % i, Vector3(0.55, 3, 0.55), Vector3(-3 if i % 2 else 3, 0, -3 if i < 2 else 3), Color(0.6, 0.6, 0.6))
	for side in [-1, 1]:
		var light := OmniLight3D.new()
		light.name = "BakedLight%d" % (side + 1)
		light.position = Vector3(side * 3, 2.5, -1.5)
		light.light_color = Color(1, 0.55, 0.2) if side < 0 else Color(0.25, 0.6, 1)
		light.light_energy = 5
		light.omni_range = 12
		light.shadow_enabled = true
		light.light_bake_mode = Light3D.BAKE_STATIC
		_owned(scene, light)
	var lightmap := LightmapGI.new()
	lightmap.name = "LightmapGI"
	lightmap.quality = LightmapGI.BAKE_QUALITY_LOW
	lightmap.bounces = 3
	lightmap.directional = true
	lightmap.interior = true
	lightmap.generate_probes_subdiv = LightmapGI.GENERATE_PROBES_SUBDIV_8
	lightmap.max_texture_size = 2048
	_owned(scene, lightmap)
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, SCENE) == OK)
	scene.free()
	EditorInterface.get_resource_filesystem().scan()
	while EditorInterface.get_resource_filesystem().is_scanning():
		await get_tree().process_frame
	EditorInterface.open_scene_from_path(SCENE)
	await get_tree().process_frame
	var edited := EditorInterface.get_edited_scene_root()
	assert(edited != null and edited.scene_file_path == SCENE)
	var baked := edited.get_node("LightmapGI") as LightmapGI
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(baked)
	EditorInterface.edit_node(baked)
	await get_tree().process_frame
	var button := _bake_button(EditorInterface.get_base_control())
	assert(button != null and not button.disabled, "Bake Lightmaps action unavailable")
	button.pressed.emit()
	var dialogs := button.find_children("*", "EditorFileDialog", true, false)
	assert(dialogs.size() == 1 and dialogs[0].visible, "Lightmap save dialog unavailable")
	dialogs[0].file_selected.emit("res://generated/room.lmbake")
	dialogs[0].hide()
	assert(baked.light_data != null and baked.light_data.get_user_count() == 10, "Lightmap bake failed")
	assert(EditorInterface.save_scene() == OK)
	var data := baked.light_data
	var capture: Dictionary = data.get("probe_data")
	var report := {"ok": true, "engine": Engine.get_version_info(), "users": data.get_user_count(),
		"directional": data.is_using_spherical_harmonics(), "textures": data.lightmap_textures.size(),
		"probe_points": capture.get("points", PackedVector3Array()).size(),
		"adapter": RenderingServer.get_video_adapter_name()}
	FileAccess.open("res://generated/bake.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("LIGHTMAP_BAKE_OK ", JSON.stringify(report))
	EditorInterface.get_selection().clear()
	EditorInterface.edit_node(null)
	if EditorInterface.has_method("close_scene"):
		EditorInterface.call("close_scene")
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()

func _owned(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = parent

func _box(parent: Node3D, label: String, size: Vector3, location: Vector3, color: Color) -> void:
	var primitive := BoxMesh.new()
	primitive.size = size
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, primitive.get_mesh_arrays())
	assert(mesh.lightmap_unwrap(Transform3D.IDENTITY, 0.25) == OK)
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = location
	node.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	node.material_override = material
	_owned(parent, node)

func _bake_button(node: Node) -> Button:
	if node is Button and node.text == "Bake Lightmaps":
		return node
	for child in node.get_children():
		var found := _bake_button(child)
		if found != null:
			return found
	return null
