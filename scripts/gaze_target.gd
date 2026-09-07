class_name GazeTarget
extends Area3D

signal gaze_entered
signal gaze_exited
signal gaze_activated

@export var display_name: String = "Object"
@export_range(0.1, 10.0, 0.1) var dwell_time: float = 1.0
@export var activate_once: bool = true
@export var enabled: bool = true
@export var accent_color: Color = Color("f2bd7e")

var has_activated: bool = false
var completed_this_visit: bool = false
var is_gazing: bool = false


func _ready() -> void:
	add_to_group("gaze_targets")


func enter_gaze() -> void:
	is_gazing = true
	completed_this_visit = activate_once and has_activated
	gaze_entered.emit()


func exit_gaze() -> void:
	is_gazing = false
	completed_this_visit = false
	gaze_exited.emit()


func activate() -> bool:
	if not enabled or not is_gazing or completed_this_visit:
		return false
	if activate_once and has_activated:
		return false
	has_activated = true
	completed_this_visit = true
	gaze_activated.emit()
	return true


func reset_activation() -> void:
	has_activated = false
	completed_this_visit = false
