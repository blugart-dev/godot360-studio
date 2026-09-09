extends "res://tests/fixtures/renderer_lab.gd"
## Combined materials/light lab. Each crossing is sampled at an absolute time.
var authored: CameraAttributesPractical
var world: WorldEnvironment
var point: OmniLight3D


func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is WorldEnvironment:
			world = child
		elif child is OmniLight3D:
			point = child
	environment.glow_enabled = bool(job.get("glow", true))
	environment.glow_intensity = 1.4
	authored = CameraAttributesPractical.new()
	authored.auto_exposure_enabled = not bool(job.get("oracle", false))
	authored.auto_exposure_speed = 3.0
	$Camera3D.attributes = authored
	moving.material_override.emission = Color(1.0, 0.7, 0.3)
	moving.material_override.emission_energy_multiplier = 18.0
	# A pure geometry/color control has no view-dependent lighting or glow.
	if bool(job.get("geometry_control", false)):
		environment.glow_enabled = false
		for child in get_children():
			if child is MeshInstance3D:
				child.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				child.material_override.emission_enabled = false
				child.material_override.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED


func begin_360_capture(_settings: Dictionary) -> void:
	# This lab uses separate authored-oracle exports rather than extra viewports.
	pass


func sample_360_frame(frame: int, seconds: float, _settings: Dictionary) -> String:
	index = frame
	# Exercise both attribute sources, then replace the resource. Do this by state,
	# not by accumulating deltas: warmup repeatedly samples frame zero.
	if frame == 60 and $Camera3D.attributes == null:
		authored = authored.duplicate()
		$Camera3D.attributes = authored
	elif frame >= 30 and frame < 60:
		world.camera_attributes = authored
		$Camera3D.attributes = null
	authored.exposure_multiplier = 0.7 + 0.5 * seconds / 3.0
	var light_scale := 0.35 if frame >= 45 else 1.0
	environment.ambient_light_energy = 0.45 * light_scale
	environment.background_color = Color(0.18, 0.24, 0.32) * light_scale
	$Camera3D.position = Vector3(0.3 * sin(seconds), 0.08 * sin(seconds * 2.0), 0)
	$Camera3D.rotation_degrees = Vector3(4.0 * sin(seconds), 12.0 * sin(seconds * 1.5), 0)
	var angle := deg_to_rad(40.0 + 10.0 * float(frame % 30) / 29.0)
	var longitude := angle if frame < 60 else PI + angle
	var latitude := atan(1.0 / sqrt(2.0)) if frame >= 30 and frame < 60 else 0.0
	var direction := Vector3(sin(longitude) * cos(latitude), sin(latitude), -cos(longitude) * cos(latitude))
	# Place the emitter relative to the sampled camera so each segment crosses a
	# known boundary despite camera translation and rotation in the authored world.
	moving.position = $Camera3D.transform * (direction * 3.0)
	point.position = moving.position + Vector3(0, 0.25, 0)
	point.light_energy = 5.0 * light_scale
	moving.material_override.emission_energy_multiplier = 18.0 * light_scale
	return ""
