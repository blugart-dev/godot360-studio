class_name GazeDetector
extends Node

signal target_changed(target: GazeTarget)
signal progress_changed(fraction: float)

@export var camera: Camera3D
@export_range(1.0, 100.0) var max_distance: float = 40.0
## Layer 1 blocks vision; layer 2 contains Area3D gaze targets.
@export_flags_3d_physics var collision_mask: int = 3
@export var input_enabled: bool = true

var current_target: GazeTarget
var gaze_seconds: float = 0.0
var _had_target: bool = false


func _physics_process(delta: float) -> void:
	if not input_enabled or not is_instance_valid(camera):
		clear_gaze()
		return
	var origin: Vector3 = camera.global_position
	var end: Vector3 = origin - camera.global_basis.z * max_distance
	var query := PhysicsRayQueryParameters3D.create(origin, end, collision_mask)
	query.collide_with_areas = true
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	var target: GazeTarget = null
	if not hit.is_empty():
		var node: Node = hit["collider"] as Node
		while node != null:
			if node is GazeTarget:
				target = node as GazeTarget
				break
			node = node.get_parent()
		if target != null and (not target.enabled or not target.is_visible_in_tree()):
			target = null
	if not is_instance_valid(current_target):
		# Also reset the UI if a currently observed target was removed from the tree.
		if _had_target:
			clear_gaze()
		current_target = null
	if target != current_target:
		_change_target(target)
	if not is_instance_valid(current_target):
		return
	if current_target.completed_this_visit:
		progress_changed.emit(1.0)
		return
	gaze_seconds = minf(gaze_seconds + delta, current_target.dwell_time)
	progress_changed.emit(gaze_seconds / current_target.dwell_time)
	if gaze_seconds >= current_target.dwell_time:
		current_target.activate()


func _change_target(target: GazeTarget) -> void:
	if is_instance_valid(current_target):
		current_target.exit_gaze()
	current_target = target
	_had_target = is_instance_valid(target)
	gaze_seconds = 0.0
	if is_instance_valid(current_target):
		current_target.enter_gaze()
	target_changed.emit(current_target)
	progress_changed.emit(0.0)


func clear_gaze() -> void:
	if _had_target:
		_change_target(null)


func set_input_enabled(value: bool) -> void:
	input_enabled = value
	if not value:
		clear_gaze()
