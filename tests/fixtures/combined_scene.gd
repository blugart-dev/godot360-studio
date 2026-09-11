extends "res://tests/fixtures/lightmap_scene.gd"
## Saved GI, dynamic probes, lit intersecting alpha and long per-view history.
var panels: Array[Node3D] = []
var combined_samples: Array[Dictionary] = []
var oracle_effects: Array[CompositorEffect] = []

func _ready() -> void:
	# The parent creates separate worlds and applies the lightmap/probe controls.
	var selected := mode
	mode = str(job.get("lighting", "lightmap"))
	super._ready()
	mode = selected
	for parent in [room, oracle_room]:
		panels.append(_transparency(parent))
		var env := parent.get_node("Environment").environment as Environment
		env.tonemap_exposure = 1.0
	get_viewport().msaa_3d = Viewport.MSAA_4X if str(job.rendering_method) == "mobile" else Viewport.MSAA_DISABLED
	if mode.begins_with("history"):
		effect = _history(bool(job.get("wrong_shared_history", false)))
		$Camera3D.compositor = Compositor.new()
		$Camera3D.compositor.compositor_effects = [effect]
	initial = _viewport_settings(get_viewport())

func _history(wrong: bool = false) -> CompositorEffect:
	var result := preload("temporal_history.gd").new()
	result.history_weight = 0.95
	result.shared_history = wrong
	return result

func _transparency(parent: Node3D) -> Node3D:
	var group := Node3D.new()
	group.name = "IntersectingAlpha"
	parent.add_child(group)
	group.visible = not bool(job.get("transparency_off", false))
	# Four crossed pairs span side-face joins, with overlapping lit surfaces.
	for quadrant in range(4):
		var angle := PI / 4 + quadrant * PI / 2
		for crossed in range(2):
			var panel := MeshInstance3D.new()
			var mesh := QuadMesh.new()
			mesh.size = Vector2(2.4, 2.4)
			panel.mesh = mesh
			panel.position = Vector3(sin(angle) * 4.2, 1.2, -cos(angle) * 4.2)
			panel.rotation.y = -angle + crossed * PI / 2
			panel.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
			var mat := StandardMaterial3D.new()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat.albedo_color = Color(0.1, 0.8, 0.6, 0.45) if crossed else Color(0.9, 0.25, 0.08, 0.55)
			mat.roughness = 0.6
			if bool(job.get("transparency_unlit", false)):
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			panel.material_override = mat
			group.add_child(panel)
	return group

func begin_360_capture(settings: Dictionary) -> void:
	super.begin_360_capture(settings)
	if mode.begins_with("history"):
		for cam in cameras:
			var native_effect := _history()
			cam.compositor.compositor_effects = [native_effect]
			oracle_effects.append(native_effect)

func sample_360_frame(frame_index: int, seconds: float, settings: Dictionary) -> String:
	super.sample_360_frame(frame_index, seconds, settings)
	var phase := seconds * TAU / (float(job.frames) / float(job.fps))
	# Smooth six-axis pose changes on both sides of the explicit mid-clip cut.
	var pose := Transform3D(Basis.from_euler(Vector3(0.07 * sin(phase), 0.12 * sin(phase * 0.5), 0.04 * cos(phase))),
		Vector3(0.16 * sin(phase), 0.05 * sin(phase * 2), 0.1 * cos(phase)))
	if frame_index >= int(job.frames) / 2:
		pose = Transform3D(Basis.from_euler(Vector3(0.08, 0.35, 0.1)), Vector3(0.3, 0.1, -0.2)) * pose
	$Camera3D.transform = pose
	for i in range(cameras.size()):
		cameras[i].global_transform = pose * Transform3D(Basis.looking_at(DIRECTIONS[i] if i < 6 else Vector3(1, 0, -1), UPS[i] if i < 6 else Vector3.UP), Vector3.ZERO)
	for group in panels:
		group.rotation.y = 0.08 * sin(phase * 2)
	return ""

func _save_references() -> void:
	super._save_references()
	var worlds_independent := room.get_world_3d() != oracle_room.get_world_3d()
	var exposures: Array[float] = []
	for parent in [room, oracle_room]:
		exposures.append(parent.get_node("Environment").environment.tonemap_exposure)
	combined_samples.append({"frame": index, "independent_worlds": worlds_independent,
		"panels": panels[0].get_child_count(), "visible": panels[0].visible,
		"panel_pose_error": absf(panels[0].rotation.y - panels[1].rotation.y),
		"exposures": exposures, "camera_position": [$Camera3D.position.x, $Camera3D.position.y, $Camera3D.position.z],
		"history_weight": effect.history_weight if effect else 0.0})
	if index == int(job.frames) - 1:
		var histories: Array[Dictionary] = []
		for native_effect in oracle_effects:
			histories.append(native_effect.snapshot())
		assert(preload("res://addons/godot360/job_io.gd").write_json(str(job.output_dir).path_join("combined-samples.json"),
			{"samples": combined_samples, "oracle_histories": histories}))
