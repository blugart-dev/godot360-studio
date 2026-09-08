extends Node
## Six simultaneous views of one World3D; the scene advances only once per frame.

const DIRECTIONS: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP,
	Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]
const UP_VECTORS: Array[Vector3] = [Vector3.UP, Vector3.UP, Vector3.BACK,
	Vector3.FORWARD, Vector3.UP, Vector3.UP]
const FACE_NAMES: Array[String] = ["right", "left", "up", "down", "front", "back"]
const VIEWPORT_SETTINGS = ["msaa_3d", "screen_space_aa", "use_taa", "use_debanding",
	"scaling_3d_mode", "scaling_3d_scale", "fsr_sharpness", "texture_mipmap_bias",
	"mesh_lod_threshold", "use_occlusion_culling", "positional_shadow_atlas_size",
	"positional_shadow_atlas_16_bits", "positional_shadow_atlas_quad_0",
	"positional_shadow_atlas_quad_1", "positional_shadow_atlas_quad_2", "positional_shadow_atlas_quad_3"]
var source: Camera3D
var cameras: Array[Camera3D] = []
var material: ShaderMaterial
var before_sync: Callable
var projection: Dictionary
var exposure := preload("capture_exposure.gd").new()
var exposure_sync_usec := 0


func build(camera: Camera3D, face_size: int, output_size: Vector2i, border_percent: float = 0.0, exposure_mode: String = "scene") -> void:
	source = camera
	exposure.mode = exposure_mode
	projection = preload("capture_projection.gd").geometry(face_size, border_percent)
	material = ShaderMaterial.new()
	material.shader = preload("equirectangular.gdshader")
	material.set_shader_parameter("face_uv_scale", projection.uv_scale)
	for i in range(6):
		var viewport := SubViewport.new()
		viewport.name = "Face_" + FACE_NAMES[i]
		viewport.size = Vector2i(projection.texture_size, projection.texture_size)
		viewport.world_3d = source.get_world_3d()
		viewport.audio_listener_enable_3d = false
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		# Faces end in Godot's tone-mapped SDR/sRGB target. The assembler is
		# also SDR 2D: sampling must not decode sRGB or apply tone mapping again.
		viewport.use_hdr_2d = false
		for property in VIEWPORT_SETTINGS:
			viewport.set(property, source.get_viewport().get(property))
		add_child(viewport)
		var view := Camera3D.new()
		viewport.add_child(view)
		view.current = true
		cameras.append(view)
		material.set_shader_parameter("face_" + FACE_NAMES[i], viewport.get_texture())
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var output := ColorRect.new()
	output.size = output_size
	output.material = material
	output.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(output)
	process_priority = 1000
	if before_sync.is_valid():
		before_sync.call()
	sync_camera()


func _process(_delta: float) -> void:
	if before_sync.is_valid():
		before_sync.call()
	# Skeleton3D applies its final pose and BoneAttachment3D transforms in the
	# deferred queue. Read the camera after those updates, still before Godot
	# flushes Node3D transforms for this draw. Sampling itself stays in _process.
	sync_camera.call_deferred()


func sync_camera() -> void:
	if not is_instance_valid(source):
		return
	var started := Time.get_ticks_usec()
	var attributes: CameraAttributes = exposure.resolve(source)
	exposure_sync_usec += Time.get_ticks_usec() - started
	for i in range(cameras.size()):
		var view := cameras[i]
		view.environment = source.environment
		view.attributes = attributes
		view.compositor = source.compositor
		view.cull_mask = source.cull_mask
		view.set_perspective(float(projection.fov), source.near, source.far)
		var local_basis := Basis.looking_at(DIRECTIONS[i], UP_VECTORS[i])
		var transform := source.get_camera_transform()
		view.global_transform = Transform3D(transform.basis.orthonormalized() * local_basis, transform.origin)


func settings() -> Dictionary:
	var result := {}
	for property in VIEWPORT_SETTINGS:
		result[property] = cameras[0].get_viewport().get(property)
	return result
