class_name PlayerLook
extends Node3D

signal capture_changed(captured: bool)

## Degrees per pixel. Smoothing is independent of the frame rate.
@export_range(0.01, 0.8, 0.01) var mouse_sensitivity: float = 0.12
@export_range(1.0, 30.0, 0.5) var smoothing_speed: float = 14.0
@export_range(10.0, 89.0, 1.0) var pitch_limit_degrees: float = 85.0
@export var auto_capture: bool = true

@onready var camera: Camera3D = $Camera3D
var target_yaw: float = 0.0
var target_pitch: float = 0.0
var captured: bool = false


func _ready() -> void:
	set_capture(auto_capture)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				set_capture(not captured)
				get_viewport().set_input_as_handled()
			KEY_R:
				recenter()
	if event is InputEventMouseMotion and captured:
		apply_mouse_motion(event.screen_relative)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and not captured:
			set_capture(true)


func apply_mouse_motion(motion: Vector2) -> void:
	target_yaw -= deg_to_rad(motion.x * mouse_sensitivity)
	target_pitch = clampf(target_pitch - deg_to_rad(motion.y * mouse_sensitivity),
		-deg_to_rad(pitch_limit_degrees), deg_to_rad(pitch_limit_degrees))


func _process(delta: float) -> void:
	var weight: float = 1.0 - exp(-smoothing_speed * delta)
	rotation.y = lerpf(rotation.y, target_yaw, weight)
	camera.rotation.x = lerpf(camera.rotation.x, target_pitch, weight)
	# Keep angles small without limiting full turns or changing the interpolation.
	if absf(rotation.y) > TAU:
		var turns: float = floorf(rotation.y / TAU) * TAU
		rotation.y -= turns
		target_yaw -= turns


func recenter() -> void:
	target_yaw = rotation.y + wrapf(-rotation.y, -PI, PI)
	target_pitch = 0.0


func set_capture(value: bool) -> void:
	captured = value
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE
	capture_changed.emit(value)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and captured:
		set_capture(false)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
