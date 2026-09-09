extends SkeletonModifier3D
## Stateless head aim for this unit-scale rig; target supplies calibrated facing.
var bone_name: String
var target: Node3D
var calibration := Basis.IDENTITY
var evaluations := 0


func _process_modification() -> void:
	var skeleton := get_skeleton()
	var bone := skeleton.find_bone(bone_name)
	if bone < 0 or not is_instance_valid(target):
		return
	var pose := skeleton.global_transform * skeleton.get_bone_global_pose(bone)
	pose.basis = Basis.looking_at(target.global_position - pose.origin, Vector3.UP) * calibration
	skeleton.set_bone_global_pose(bone, skeleton.global_transform.affine_inverse() * pose)
	evaluations += 1
