extends "res://tests/fixtures/renderer_lab.gd"
## Every-frame references: native views have separate camera/compositor resources.
const NAMES = ["right", "left", "up", "down", "front", "back"]
const DIRECTIONS = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]
const UPS = [Vector3.UP, Vector3.UP, Vector3.BACK, Vector3.FORWARD, Vector3.UP, Vector3.UP]
const PROPERTIES = ["msaa_3d", "use_taa", "scaling_3d_mode", "scaling_3d_scale", "fsr_sharpness",
	"positional_shadow_atlas_size", "positional_shadow_atlas_16_bits",
	"positional_shadow_atlas_quad_0", "positional_shadow_atlas_quad_1",
	"positional_shadow_atlas_quad_2", "positional_shadow_atlas_quad_3"]
var references: Array[SubViewport] = []
var cameras: Array[Camera3D] = []
var drawn := 0
var samples: Array[Dictionary] = []
var initial := {}
var effect: CompositorEffect
var probe: CompositorEffect
var voxel: VoxelGI

func _ready() -> void:
	# Build one shared scene, then choose only the effect under review.
	var selected := mode
	mode = "gi_off" if selected.begins_with("voxel") else "lit"
	super._ready()
	mode = selected
	get_viewport().msaa_3d = int(job.get("temporal_msaa", Viewport.MSAA_DISABLED))
	get_viewport().use_taa = mode == "taa"
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2 if mode == "fsr2" else Viewport.SCALING_3D_MODE_FSR if mode == "fsr1" else Viewport.SCALING_3D_MODE_BILINEAR
	get_viewport().scaling_3d_scale = 0.67 if mode in ["fsr1", "fsr2"] else 1.0
	if mode.begins_with("history"):
		effect = preload("temporal_history.gd").new()
		effect.shared_history = bool(job.get("wrong_shared_history", false))
		effect.direct_only = bool(job.get("expect_render_failure", false))
		var compositor := Compositor.new()
		compositor.compositor_effects = [effect]
		if mode == "history_world":
			for child in get_children():
				if child is WorldEnvironment:
					child.compositor = compositor
		else:
			$Camera3D.compositor = compositor
	else:
		probe = preload("temporal_probe.gd").new()
		$Camera3D.compositor = Compositor.new()
		$Camera3D.compositor.compositor_effects = [probe]
	if mode.begins_with("voxel"):
		for child in get_children():
			if child is MeshInstance3D and child != moving:
				child.gi_mode = GeometryInstance3D.GI_MODE_STATIC
		voxel = VoxelGI.new()
		voxel.size = Vector3(14, 8, 14)
		voxel.subdiv = VoxelGI.SUBDIV_64
		add_child(voxel)
		voxel.bake.call_deferred(self)
		voxel.visible = mode == "voxel"
	initial = _viewport_settings(get_viewport())

func begin_360_capture(_settings: Dictionary) -> void:
	var border := ceili(int(job.face_size) * float(job.get("capture_border_percent", 0)) / 100.0)
	var size := int(job.face_size) + 2 * border
	var fov := rad_to_deg(2 * atan(float(size) / int(job.face_size)))
	for i in range(7):
		var view := SubViewport.new()
		view.name = "Independent_" + (NAMES[i] if i < 6 else "diagonal")
		view.size = Vector2i(size, size) if i < 6 else Vector2i(256, 256)
		view.world_3d = get_world_3d()
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		for property in PROPERTIES:
			view.set(property, initial[property])
		add_child(view)
		var cam := Camera3D.new()
		cam.current = true
		cam.set_perspective(fov if i < 6 else 60.0, $Camera3D.near, $Camera3D.far)
		if mode.begins_with("history"):
			# Override any world effect with a fresh camera-owned history oracle.
			cam.compositor = Compositor.new()
			cam.compositor.compositor_effects = [preload("temporal_history.gd").new()]
		view.add_child(cam)
		references.append(view)
		cameras.append(cam)
	for folder in ["native", "faces"]:
		DirAccess.make_dir_recursive_absolute(str(job.output_dir).path_join(folder))
	RenderingServer.frame_post_draw.connect(_save_references)

func sample_360_frame(frame_index: int, seconds: float, _settings: Dictionary) -> String:
	index = frame_index
	# One orbit crosses all side faces and rear seam. Cut changes pose halfway.
	var phase := seconds * TAU / (float(job.frames) / float(job.fps))
	moving.position = Vector3(sin(phase) * 3, sin(phase * 2) * 0.6, -cos(phase) * 3)
	$Camera3D.transform = Transform3D(Basis.from_euler(Vector3(0.08, 0.35, 0.1)), Vector3(0.3, 0.1, -0.2)) if index >= int(job.frames) / 2 else Transform3D.IDENTITY
	for i in range(cameras.size()):
		var direction: Vector3 = DIRECTIONS[i] if i < 6 else Vector3(1, 0, -1)
		var up: Vector3 = UPS[i] if i < 6 else Vector3.UP
		cameras[i].global_transform = $Camera3D.transform * Transform3D(Basis.looking_at(direction, up), Vector3.ZERO)
	return ""

func _save_references() -> void:
	var record := {"frame": index, "faces": [], "settings_unchanged": initial == _viewport_settings(get_viewport())}
	for i in range(6):
		var face := get_tree().root.find_child("Face_" + NAMES[i], true, false) as SubViewport
		if face == null:
			continue
		var transform_error := face.get_camera_3d().global_transform.origin.distance_to(cameras[i].global_transform.origin)
		for axis in range(3):
			transform_error = maxf(transform_error, face.get_camera_3d().global_transform.basis[axis].distance_to(cameras[i].global_transform.basis[axis]))
		record.faces.append({"name": NAMES[i], "pose_error": transform_error, "settings": _viewport_settings(face)})
		if drawn >= int(job.warmup_frames):
			_save(face, "faces", NAMES[i])
			_save(references[i], "native", NAMES[i])
	if drawn >= int(job.warmup_frames):
		_save(references[6], "native", "diagonal")
	samples.append(record)
	drawn += 1
	if index == int(job.frames) - 1:
		var evidence := {"samples": samples, "initial": initial, "final": _viewport_settings(get_viewport()),
			"history_counts": effect.snapshot() if effect != null else {},
			"render_buffers": probe.snapshot() if probe != null else {},
			"voxel_baked": voxel != null and voxel.data != null}
		assert(preload("res://addons/godot360/job_io.gd").write_json(str(job.output_dir).path_join("temporal-samples.json"), evidence))

func _save(view: SubViewport, folder: String, label: String) -> void:
	assert(view.get_texture().get_image().save_png(str(job.output_dir).path_join("%s/%s-%03d.png" % [folder, label, index])) == OK)

func _viewport_settings(view: Viewport) -> Dictionary:
	var result := {}
	for property in PROPERTIES:
		result[property] = view.get(property)
	return result
