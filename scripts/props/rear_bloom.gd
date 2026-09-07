extends Node3D

var opened: bool = false
var petals: Array[MeshInstance3D] = []
var petal_material: StandardMaterial3D
var halo: MeshInstance3D
var clock: float = 0.0
var animation: Tween


func _ready() -> void:
	petal_material = MeshFactory.material(Color("4e968f"), true)
	for index in range(8):
		var angle: float = TAU * index / 8.0
		var petal := MeshFactory.sphere(self, 0.35, petal_material,
			Vector3(sin(angle), cos(angle), 0) * 0.6)
		petal.scale = Vector3(0.5, 1.3, 0.22)
		petal.rotation.z = -angle
		petals.append(petal)
	MeshFactory.sphere(self, 0.25, MeshFactory.material(Color("d0eee1"), true))
	halo = MeshFactory.ring(self, 1.4, 0.013, petal_material)
	halo.rotation.x = PI / 2.0


func _process(delta: float) -> void:
	clock += delta
	rotation.z += delta * (0.2 if opened else 0.04)
	halo.scale = Vector3.ONE * (1.0 + sin(clock * 1.4) * 0.035)


func signal_presence() -> void:
	if opened:
		return
	var pulse := create_tween()
	pulse.tween_property(petal_material, "albedo_color", Color("b3f9d8"), 0.5)
	pulse.tween_property(petal_material, "albedo_color", Color("4e968f"), 1.5)


func open_bloom() -> void:
	opened = true
	animation = create_tween().set_parallel(true)
	animation.tween_property(petal_material, "albedo_color", Color("b4f6d2"), 0.65)
	for index in range(petals.size()):
		var angle: float = TAU * index / petals.size()
		animation.tween_property(petals[index], "position",
			Vector3(sin(angle), cos(angle), 0) * 1.08, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animation.tween_property(get_parent(), "position:y", 3.0, 1.3).set_trans(Tween.TRANS_SINE)
	animation.tween_property(halo, "rotation:y", PI, 1.7)
