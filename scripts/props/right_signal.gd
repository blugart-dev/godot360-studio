extends Node3D

var frames: Array[MeshInstance3D] = []
var signal_material: StandardMaterial3D
var pulses: int = 0
var clock: float = 0.0
var animation: Tween


func _ready() -> void:
	signal_material = MeshFactory.material(Color("638aab"), true)
	for index in range(3):
		var frame := MeshFactory.ring(self, 0.9 + index * 0.24, 0.025, signal_material)
		frame.rotation_degrees = Vector3(90, index * 22, 0)
		frames.append(frame)
	MeshFactory.sphere(self, 0.18, MeshFactory.material(Color("c1d8ef"), true))


func _process(delta: float) -> void:
	clock += delta
	for index in range(frames.size()):
		frames[index].rotation.z = clock * 0.16 * (index + 1)


func pulse() -> void:
	pulses += 1
	if animation != null:
		animation.kill()
	animation = create_tween().set_parallel(true)
	animation.tween_property(self, "scale", Vector3.ONE * 1.3, 0.35)
	animation.tween_property(signal_material, "albedo_color", Color("d1d6ff"), 0.3)
	animation.chain().tween_property(self, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_SINE)
	animation.parallel().tween_property(signal_material, "albedo_color", Color("638aab"), 1.0)
