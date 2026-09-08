extends Node3D
## Uneven illumination, moving emitter/camera, a light cut and authored exposure.
var job: Dictionary
var environment: Environment
var attributes: CameraAttributes
var emitter: MeshInstance3D
var index := 0


func prepare_360_capture(settings: Dictionary) -> void:
	job = settings


func _ready() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = bool(job.get("glow", false))
	$WorldEnvironment.environment = environment
	attributes = CameraAttributesPhysical.new() if job.get("physical", false) else CameraAttributesPractical.new()
	attributes.auto_exposure_enabled = not job.get("oracle", false)
	attributes.auto_exposure_speed = 3.0
	if job.get("world_attributes", false):
		$WorldEnvironment.camera_attributes = attributes
	else:
		$Camera3D.attributes = attributes
	emitter = _sphere(Vector3(0, 0, -4), Color.WHITE, 0.9)
	for n in range(12):
		var angle := n * TAU / 12.0
		_sphere(Vector3(sin(angle) * 4, -1.0, -cos(angle) * 4), Color.from_hsv(n / 12.0, 0.7, 0.65), 0.22)


func _sphere(location: Vector3, color: Color, radius: float) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	item.mesh = mesh
	item.position = location
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	item.material_override = material
	add_child(item)
	return item


func sample_360_frame(frame: int, seconds: float, _settings: Dictionary) -> String:
	index = frame
	# The whole sphere changes light at frame 45. Exposure remains an authored
	# smooth curve, including after swapping the resource at frame 60.
	if frame == 60:
		attributes = attributes.duplicate()
		if job.get("world_attributes", false):
			$WorldEnvironment.camera_attributes = attributes
		else:
			$Camera3D.attributes = attributes
	attributes.exposure_multiplier = 0.7 + 0.5 * seconds / 3.0
	environment.background_color = Color(0.18, 0.20, 0.24) * (0.35 if frame >= 45 else 1.0)
	var angle := deg_to_rad(20.0 + seconds * 28.0)
	emitter.position = Vector3(sin(angle), 0.4 * sin(seconds * 2.0), -cos(angle)) * 4.0
	emitter.material_override.albedo_color = Color(12, 10, 8) * (0.35 if frame >= 45 else 1.0)
	$Camera3D.rotation_degrees = Vector3(4.0 * sin(seconds), 12.0 * sin(seconds * 1.5), 0)
	return ""
