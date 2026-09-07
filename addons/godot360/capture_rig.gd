extends Node
## Six simultaneous views of one World3D; the scene advances only once per frame.

const DIRECTIONS: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP,
	Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]
const UP_VECTORS: Array[Vector3] = [Vector3.UP, Vector3.UP, Vector3.BACK,
	Vector3.FORWARD, Vector3.UP, Vector3.UP]
const FACE_NAMES: Array[String] = ["right", "left", "up", "down", "front", "back"]
var source: Camera3D
var cameras: Array[Camera3D] = []
var material: ShaderMaterial
var before_sync: Callable


func build(camera: Camera3D, face_size: int, output_size: Vector2i) -> void:
	source = camera
	material = ShaderMaterial.new()
	material.shader = preload("equirectangular.gdshader")
	for i in range(6):
		var viewport := SubViewport.new()
		viewport.name = "Face_" + FACE_NAMES[i]
		viewport.size = Vector2i(face_size, face_size)
		viewport.world_3d = source.get_world_3d()
		viewport.audio_listener_enable_3d = false
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		viewport.msaa_3d = source.get_viewport().msaa_3d
		add_child(viewport)
		var view := Camera3D.new()
		view.fov = 90.0
		view.near = source.near
		view.far = source.far
		view.cull_mask = source.cull_mask
		view.environment = source.environment
		view.attributes = source.attributes
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
	_process(0.0)


func _process(_delta: float) -> void:
	if before_sync.is_valid():
		before_sync.call()
	sync_camera()


func sync_camera() -> void:
	if not is_instance_valid(source):
		return
	for i in range(cameras.size()):
		var local_basis := Basis.looking_at(DIRECTIONS[i], UP_VECTORS[i])
		cameras[i].global_transform = Transform3D(source.global_basis.orthonormalized() * local_basis,
			source.global_position)
