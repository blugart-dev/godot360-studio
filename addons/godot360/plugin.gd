@tool
extends EditorPlugin

var panel: Control


func _enter_tree() -> void:
	panel = preload("studio_panel.gd").new()
	panel.current_scene_provider = EditorInterface.get_edited_scene_root
	panel.save_current_scene = EditorInterface.save_scene
	panel.name = "Godot360"
	add_control_to_bottom_panel(panel, "Godot360")


func _exit_tree() -> void:
	remove_control_from_bottom_panel(panel)
	panel.queue_free()
