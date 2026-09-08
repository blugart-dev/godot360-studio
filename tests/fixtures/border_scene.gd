extends Node3D
## A moving emitter beside an equatorial edge, a three-face corner and a top edge.
var job: Dictionary
var emitter: MeshInstance3D


func prepare_360_capture(settings: Dictionary) -> void:
	job = settings


func _ready() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.025, 0.025, 0.025)
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = bool(job.get("glow", true))
	environment.glow_intensity = 1.4
	$Camera3D.environment = environment
	emitter = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	emitter.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 20.0
	emitter.material_override = material
	add_child(emitter)


func sample_360_frame(index: int, _seconds: float, _settings: Dictionary) -> String:
	var angle := deg_to_rad(42.0 + 6.0 * float(index % 30) / 29.0)
	var longitude := angle
	var latitude := 0.0
	if index >= 30 and index < 60:
		latitude = atan(1.0 / sqrt(2.0))
	elif index >= 60:
		longitude = 0.0
		latitude = angle
	emitter.position = Vector3(sin(longitude) * cos(latitude), sin(latitude), -cos(longitude) * cos(latitude)) * 4.0
	return ""
