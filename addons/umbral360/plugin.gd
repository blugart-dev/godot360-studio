@tool
extends EditorPlugin

var panel: Control


func _enter_tree() -> void:
	panel = preload("studio_panel.gd").new()
	panel.name = "Godot360"
	add_control_to_bottom_panel(panel, "Godot360")


func _exit_tree() -> void:
	remove_control_from_bottom_panel(panel)
	panel.queue_free()
