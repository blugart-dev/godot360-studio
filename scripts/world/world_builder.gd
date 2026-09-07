extends Node3D

const MOTH: Texture2D = preload("res://assets/sprites/moth.svg")
const EYE: Texture2D = preload("res://assets/sprites/eye.svg")

var mobile: Node3D
var sprites: Array[Sprite3D] = []
var sprite_origins: Array[Vector3] = []
var rear_trail: Array[MeshInstance3D] = []
var clock: float = 0.0


func _ready() -> void:
	_build_floor()
	_build_architecture()
	_build_cutouts()
	_build_ceiling()
	_build_stars()


func _build_floor() -> void:
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 16.0
	floor_mesh.bottom_radius = 16.0
	floor_mesh.height = 0.3
	floor_mesh.radial_segments = 96
	MeshFactory.mesh_node(self, floor_mesh, MeshFactory.material(Color("172d36")), Vector3(0, -0.2, 0))
	var ink := MeshFactory.material(Color("37525b"), true)
	var brass := MeshFactory.material(Color("876f51"), true)
	for radius in [2.4, 5.3, 9.8, 10.0, 14.0]:
		MeshFactory.ring(self, radius, 0.013, ink, Vector3(0, -0.035, 0))
	for index in range(72):
		var angle: float = TAU * index / 72.0
		var tick := MeshFactory.box(self, Vector3(0.018, 0.018, 0.32 if index % 6 == 0 else 0.13),
			brass, Vector3(sin(angle) * 9.6, -0.025, cos(angle) * 9.6))
		tick.rotation.y = angle
	for index in range(4):
		var angle: float = TAU * index / 4.0
		var plinth_mesh := CylinderMesh.new()
		plinth_mesh.top_radius = 1.55
		plinth_mesh.bottom_radius = 1.7
		plinth_mesh.height = 0.22
		plinth_mesh.radial_segments = 48
		var at := Vector3(sin(angle) * 7.4, 0.04, -cos(angle) * 7.4)
		MeshFactory.mesh_node(self, plinth_mesh, MeshFactory.material(Color("243d45")), at)
		MeshFactory.ring(self, 1.55, 0.014, brass, at + Vector3.UP * 0.12)
	for index in range(14):
		var angle: float = PI * 0.08 + PI * 0.84 * index / 13.0
		var dot := MeshFactory.sphere(self, 0.055, MeshFactory.material(Color("92dec7"), true),
			Vector3(sin(angle) * 5.3, 0.08, -cos(angle) * 5.3))
		dot.visible = false
		rear_trail.append(dot)


func _build_architecture() -> void:
	var stone := MeshFactory.material(Color("26434c"))
	var line := MeshFactory.material(Color("526f72"), true)
	for index in range(24):
		var angle: float = TAU * index / 24.0
		var at := Vector3(sin(angle) * 13.0, 0.0, -cos(angle) * 13.0)
		var height: float = 3.6 + float(index % 3) * 0.55
		var column := MeshFactory.box(self, Vector3(0.22, height, 0.45), stone,
			at + Vector3.UP * height / 2.0)
		column.rotation.y = angle
		MeshFactory.sphere(self, 0.035, line, at + Vector3.UP * (height + 0.15))
	for index in range(4):
		var angle: float = TAU * index / 4.0
		var arch := Node3D.new()
		add_child(arch)
		arch.rotation.y = angle
		MeshFactory.box(arch, Vector3(0.16, 5.4, 0.26), stone, Vector3(-2.8, 2.65, -10.0))
		MeshFactory.box(arch, Vector3(0.16, 5.4, 0.26), stone, Vector3(2.8, 2.65, -10.0))
		MeshFactory.box(arch, Vector3(5.75, 0.16, 0.26), stone, Vector3(0, 5.3, -10.0))
	var names: Array[String] = ["01    /    THE CORE", "02    /    THE ECHO", "03    /    THE REVERSE", "04    /    THE WITNESS"]
	for index in range(4):
		var angle: float = TAU * index / 4.0
		var label_height: float = 5.8 if index == 2 else 4.95
		MeshFactory.label(self, names[index], Vector3(sin(angle) * 9.8, label_height, -cos(angle) * 9.8), 36)


func _build_cutouts() -> void:
	var positions: Array[Vector3] = [Vector3(-3.6, 3.2, -7), Vector3(4.1, 3.5, -7.8),
		Vector3(8, 3.8, 3), Vector3(-4.3, 3.9, 7.8), Vector3(-8.7, 4.0, -4)]
	for index in range(positions.size()):
		var sprite := Sprite3D.new()
		sprite.texture = EYE if index == 2 else MOTH
		sprite.pixel_size = 0.006
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.no_depth_test = false
		sprite.position = positions[index]
		add_child(sprite)
		sprites.append(sprite)
		sprite_origins.append(sprite.position)


func _build_ceiling() -> void:
	mobile = Node3D.new()
	mobile.name = "CeilingMobile"
	add_child(mobile)
	mobile.position = Vector3(0, 6.4, 0)
	var material := MeshFactory.material(Color("719fa4"), true)
	MeshFactory.ring(mobile, 2.8, 0.016, material)
	MeshFactory.ring(mobile, 1.1, 0.014, material)
	for index in range(9):
		var angle: float = TAU * index / 9.0
		var at := Vector3(sin(angle) * 2.8, 0, cos(angle) * 2.8)
		var length: float = 0.4 + float(index % 3) * 0.25
		MeshFactory.box(mobile, Vector3(0.007, length, 0.007), material, at - Vector3.UP * length / 2.0)
		MeshFactory.sphere(mobile, 0.1, material, at - Vector3.UP * length)
	MeshFactory.label(self, "THE SKY MOVES TOO", Vector3(0, 5.4, -3.8), 23)


func _build_stars() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 360
	var material := MeshFactory.material(Color("749399"), true)
	for index in range(100):
		var angle: float = random.randf_range(0.0, TAU)
		var elevation: float = random.randf_range(0.1, 1.4)
		var at := Vector3(sin(angle) * cos(elevation), sin(elevation), cos(angle) * cos(elevation)) * 38.0
		MeshFactory.sphere(self, random.randf_range(0.016, 0.048), material, at)


func _process(delta: float) -> void:
	clock += delta
	mobile.rotation.y += delta * 0.055
	for index in range(sprites.size()):
		sprites[index].position.y = sprite_origins[index].y + sin(clock * 0.8 + index) * 0.13
		sprites[index].rotation.z = sin(clock * 0.65 + index) * 0.05


func cue_rear() -> void:
	var animation := create_tween()
	for dot in rear_trail:
		animation.tween_callback(dot.show)
		animation.tween_interval(0.07)
