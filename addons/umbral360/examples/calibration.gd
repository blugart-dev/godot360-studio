extends Node3D
## Six colored walls, asymmetric labels, a rotating marker, and a generated tone.
## This example has no dependencies outside the addon.

var marker: MeshInstance3D
var elapsed: float = 0.0


func _ready() -> void:
	var directions: Array[Vector3] = [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT, Vector3.UP, Vector3.DOWN]
	var colors: Array[Color] = [Color("244766"), Color("873f32"), Color("633f73"), Color("2a6b57"), Color("517b98"), Color("463c30")]
	var titles: Array[String] = ["FRONT / -Z", "RIGHT / +X", "BACK / +Z", "LEFT / -X", "UP / +Y", "DOWN / -Y"]
	for i in range(6):
		var face := Node3D.new()
		add_child(face)
		face.position = directions[i] * 8.0
		var up := Vector3.BACK if i == 4 else Vector3.FORWARD if i == 5 else Vector3.UP
		face.look_at(Vector3.ZERO, up, true)
		var plane := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(16.0, 16.0)
		plane.mesh = quad
		plane.material_override = _material(colors[i])
		face.add_child(plane)
		_label(face, titles[i], Vector3(0, 0.4, 0.05), 96)
		_label(face, "TOP  ^", Vector3(0, 4, 0.05), 54)
		_label(face, "L  <               >  R", Vector3(0, -1.5, 0.05), 54)
		# The grid crosses cube boundaries; adjacent views must meet without gaps.
		for step in range(-3, 4):
			_line(face, Vector3(step * 2.0, 0, 0.03), Vector3(0.025, 16, 0.015))
			_line(face, Vector3(0, step * 2.0, 0.03), Vector3(16, 0.025, 0.015))
	marker = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	marker.mesh = sphere
	marker.material_override = _material(Color("ffe7a0"))
	add_child(marker)
	marker.position = Vector3(0, -1.5, -4)
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 48000
	sound.stereo = false
	sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
	sound.loop_end = 48000
	var samples := PackedByteArray()
	samples.resize(96000)
	for sample in range(48000):
		var value: int = roundi(sin(TAU * 440.0 * sample / 48000.0) * 1500.0)
		samples.encode_s16(sample * 2, value)
	sound.data = samples
	var audio := AudioStreamPlayer.new()
	audio.stream = sound
	add_child(audio)
	audio.play()


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material


func _line(parent: Node3D, at: Vector3, size: Vector3) -> void:
	var line := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	line.mesh = box
	line.material_override = _material(Color(0.75, 0.8, 0.8) * 0.5)
	line.position = at
	parent.add_child(line)


func _label(parent: Node3D, text: String, at: Vector3, font_size: int) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.pixel_size = 0.012
	label.position = at
	label.outline_size = 5
	parent.add_child(label)


func _process(delta: float) -> void:
	elapsed += delta
	marker.position = Vector3(sin(elapsed) * 4.0, -1.5, -cos(elapsed) * 4.0)
