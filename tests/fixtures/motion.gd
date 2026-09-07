extends "res://addons/godot360/examples/timeline.gd"
## A deliberately simple camera trajectory gives the image test an independent oracle.


func prepare_360_capture(job: Dictionary) -> void:
	super.prepare_360_capture(job)
	var path: Path3D = $CameraPath
	path.curve = Curve3D.new()
	path.curve.add_point(Vector3.ZERO)
	path.curve.add_point(Vector3(0.4, 0, 0))
	var animation: Animation = $AnimationPlayer.get_animation("film").duplicate(true)
	$AnimationPlayer.get_animation_library("").remove_animation("film")
	$AnimationPlayer.get_animation_library("").add_animation("film", animation)
	animation.track_remove_key(0, 1)
	animation.track_remove_key(0, 0)
	for key in range(9):
		animation.track_insert_key(0, float(key) * 0.75, float(key % 2))
