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
		if type in ["Sprite3D", "AnimatedSprite3D", "Label3D"] and int(node.get("billboard", 0)) != 0:
			result.warnings.append("%s faces the camera and may create seams. Disable billboarding or review a test." % node_path)
		var environment = node.get("environment")
		if environment is Environment and (environment.ssao_enabled or environment.ssil_enabled or environment.ssr_enabled):
			result.warnings.append("Screen-space effects on %s may create seams. Review all directions in a test." % node_path)
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
			if name in ["current", "billboard", "environment"]:
				node[name] = state.get_node_property_value(index, property)
		nodes[path] = node


static func preferred_camera(cameras: Array) -> String:
	if cameras.size() == 1:
		return str(cameras[0].path)
	var current: Array = cameras.filter(func(camera: Dictionary): return camera.current)
	return str(current[0].path) if current.size() == 1 else ""
