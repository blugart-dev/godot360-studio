extends GazeTarget

@export var watched_target: GazeTarget
@export var detector: GazeDetector
@export_range(0.01, 1.0, 0.01) var angular_speed: float = 0.1

var motion_seen: bool = false
var arc_angle: float = -PI / 2.0
var walking: bool = false
var walk_time: float = 0.0


func _physics_process(delta: float) -> void:
	walking = is_instance_valid(detector) and detector.input_enabled \
		and detector.current_target == watched_target and not is_gazing
	if not walking:
		return
	if arc_angle >= -0.55:
		walking = false
		return
	motion_seen = true
	arc_angle = minf(arc_angle + angular_speed * delta, -0.55)
	walk_time += delta
	position = Vector3(sin(arc_angle) * 7.1, 1.6, -cos(arc_angle) * 7.1)
	$Figure.position.y = sin(walk_time * 5.0) * 0.035


func acknowledge() -> void:
	var animation := create_tween()
	animation.tween_property($Figure, "modulate", Color("f2ce8e"), 0.4)
	animation.tween_property($Figure, "modulate", Color.WHITE, 1.0)
