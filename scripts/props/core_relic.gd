extends Node3D

var awakened: bool = false
var orb_material: StandardMaterial3D
var orbit_a: MeshInstance3D
var orbit_b: MeshInstance3D
var orb: MeshInstance3D
var clock: float = 0.0
var animation: Tween


func _ready() -> void:
	orb_material = MeshFactory.material(Color("d4884f"))
	orb = MeshFactory.sphere(self, 0.7, orb_material)
	var brass := MeshFactory.material(Color("ecba7c"), true)
	orbit_a = MeshFactory.ring(self, 1.15, 0.016, brass)
	orbit_b = MeshFactory.ring(self, 1.38, 0.012, brass)
	orbit_a.rotation_degrees = Vector3(75, 12, 25)
	orbit_b.rotation_degrees = Vector3(20, -20, -30)
	MeshFactory.sphere(orbit_a, 0.075, brass, Vector3(1.15, 0, 0))
	MeshFactory.sphere(orbit_b, 0.045, brass, Vector3(-1.38, 0, 0))
	scale = Vector3.ONE * 0.001


func _process(delta: float) -> void:
	clock += delta
	orbit_a.rotate_y(delta * (0.5 if awakened else 0.14))
	orbit_b.rotate_z(delta * 0.12)
	orb.position.y = sin(clock * 1.3) * 0.08


func reveal() -> void:
	animation = create_tween()
	animation.tween_property(self, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func awaken() -> void:
	awakened = true
	if animation != null:
		animation.kill()
	animation = create_tween().set_parallel(true)
	animation.tween_property(orb_material, "albedo_color", Color("b0efd3"), 0.6)
	animation.tween_property(self, "scale", Vector3.ONE * 1.16, 0.35).set_trans(Tween.TRANS_SINE)
	animation.chain().tween_property(self, "scale", Vector3.ONE, 0.65)
