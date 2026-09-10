@tool
extends RefCounted
## Read saved scene metadata, including inherited and instanced nodes. Never
## instantiate the scene: user scripts must not run just to populate a picker.


static func inspect(path: String) -> Dictionary:
	var result := {"error": "", "cameras": [], "warnings": [], "nodes": {}}
	if path.is_empty() or not ResourceLoader.exists(path, "PackedScene"):
		result.error = "Choose a saved .tscn scene."
		return result
	var packed := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as PackedScene
	if packed == null:
		result.error = "The saved scene could not be read. Check Godot's error output."
		return result
	_collect(packed.get_state(), "", result.nodes, 0)
	for node_path in result.nodes:
		var node: Dictionary = result.nodes[node_path]
		var type := str(node.get("type", ""))
		if type == "Camera3D":
			result.cameras.append({"path": node_path, "current": bool(node.get("current", false))})
		if type == "CanvasLayer":
			result.warnings.append("2D UI under %s is hidden during capture. Use 3D titles to include it." % node_path)
		if type in ["CPUParticles3D", "GPUParticles3D"]:
			var meshes: Array = [node.get("mesh")] if type == "CPUParticles3D" else []
			if type == "GPUParticles3D":
				for pass_index in range(int(node.get("draw_passes", 1))):
					meshes.append(node.get("draw_pass_%d" % (pass_index + 1)))
			if preload("particle_notes.gd").has_face_billboard(meshes, node.get("material_override"), node.get("material_overlay")):
				result.warnings.append(preload("particle_notes.gd").billboard_note(node_path))
			if type == "GPUParticles3D" and node.get("trail_enabled", false):
				result.warnings.append(preload("particle_notes.gd").trail_note(node_path))
		if type in ["Sprite3D", "AnimatedSprite3D", "Label3D"] and int(node.get("billboard", 0)) != 0:
			result.warnings.append("%s faces the camera and may create seams. Disable billboarding or review a test." % node_path)
		var environment = node.get("environment")
		if environment is Environment and (environment.ssao_enabled or environment.ssil_enabled or environment.ssr_enabled):
			result.warnings.append("Screen-space effects on %s may create seams. Review all directions in a test." % node_path)
		if environment is Environment:
			if environment.glow_enabled:
				result.warnings.append("Glow on %s can stop at cube edges. Check bright objects crossing the boundaries during playback." % node_path)
			if environment.fog_enabled or environment.volumetric_fog_enabled:
				result.warnings.append("Fog on %s is evaluated per face. Inspect the horizon and moving lights for boundaries." % node_path)
			if environment.sdfgi_enabled:
				result.warnings.append("SDFGI on %s needs time to converge. Inspect the opening and camera motion; warmup is currently limited to ten frames." % node_path)
		for key in ["attributes", "camera_attributes"]:
			var attributes = node.get(key)
			if attributes is CameraAttributes and attributes.auto_exposure_enabled:
				result.warnings.append("Auto exposure on %s meters each face separately and can create brightness seams. Use fixed exposure for consistent 360 delivery." % node_path)
			if attributes is CameraAttributesPhysical or (attributes is CameraAttributesPractical and (attributes.dof_blur_far_enabled or attributes.dof_blur_near_enabled)):
				result.warnings.append("Depth of field on %s uses face-camera depth. Inspect blur across cube edges." % node_path)
		if node.get("compositor") is Compositor:
			result.warnings.append("The compositor on %s runs for multiple face views. Check that custom effects keep history per view." % node_path)
		if node.get("placeholder", false):
			result.warnings.append("%s is a runtime placeholder; its cameras cannot be listed until it is loaded." % node_path)
	return result


static func _collect(state: SceneState, prefix: String, nodes: Dictionary, depth: int) -> void:
	if state == null or depth > 64:
		return
	_collect(state.get_base_scene_state(), prefix, nodes, depth + 1)
	for index in range(state.get_node_count()):
		var local_path := str(state.get_node_path(index)).trim_prefix("./")
		var path := prefix if local_path == "." else prefix.path_join(local_path) if not prefix.is_empty() else local_path
		if path.is_empty():
			path = "."
		var instance := state.get_node_instance(index)
		if instance != null:
			_collect(instance.get_state(), "" if path == "." else path, nodes, depth + 1)
		var node: Dictionary = nodes.get(path, {})
		var type := str(state.get_node_type(index))
		if not type.is_empty():
			node.type = type
		if not state.get_node_instance_placeholder(index).is_empty():
			node.placeholder = true
		for property in range(state.get_node_property_count(index)):
			var name := str(state.get_node_property_name(index, property))
			if name in ["current", "billboard", "environment", "attributes", "camera_attributes", "compositor", "mesh", "draw_passes", "draw_pass_1", "draw_pass_2", "draw_pass_3", "draw_pass_4", "material_override", "material_overlay", "trail_enabled"]:
				node[name] = state.get_node_property_value(index, property)
		nodes[path] = node


static func preferred_camera(cameras: Array) -> String:
	if cameras.size() == 1:
		return str(cameras[0].path)
	var current: Array = cameras.filter(func(camera: Dictionary): return camera.current)
	return str(current[0].path) if current.size() == 1 else ""
