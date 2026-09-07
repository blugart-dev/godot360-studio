extends WorldEnvironment

## Assign any imported 2:1 equirectangular image here. Empty = procedural sky.
@export var panorama_texture: Texture2D
@export_range(-180.0, 180.0, 1.0) var panorama_rotation_degrees: float = 0.0


func _ready() -> void:
	apply_background()


func apply_background() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	if panorama_texture != null:
		var panorama := PanoramaSkyMaterial.new()
		panorama.panorama = panorama_texture
		sky.sky_material = panorama
	else:
		var procedural := ProceduralSkyMaterial.new()
		procedural.sky_top_color = Color("081521")
		procedural.sky_horizon_color = Color("294c57")
		procedural.ground_bottom_color = Color("081521")
		procedural.ground_horizon_color = Color("294c57")
		procedural.sky_curve = 0.22
		procedural.sun_angle_max = 0.0
		sky.sky_material = procedural
	environment.sky = sky
	environment.sky_rotation.y = deg_to_rad(panorama_rotation_degrees)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8ab8c2")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
