extends Node3D
## Thirteen visible bits identify every delivered frame, including across cube edges.
const CUES = [0.5, 15.0, 30.0, 45.0, 60.0, 75.0, 88.0]
var cues: Array[float] = []
var job: Dictionary
var bits: Array[StandardMaterial3D] = []
var flash: MeshInstance3D


func prepare_360_capture(settings: Dictionary) -> void:
	job = settings


func _ready() -> void:
	for bit in range(13):
		var angle: float = deg_to_rad(-60.0 + bit * 10.0)
		var quad := _quad(Vector3(4 * sin(angle), 0, -4 * cos(angle)))
		bits.append(quad.material_override)
	flash = _quad(Vector3(0, 1, -4))
	flash.visible = false
	var rate := 48000
	var duration: float = float(job.get("frames", 5400)) / float(job.get("fps", 60))
	for second in CUES:
		if second + 0.1 < duration:
			cues.append(second)
	if duration > 2.5 and not (duration - 2.0) in cues:
		cues.append(duration - 2.0)
	cues.sort()
	# Same explicitly measured warmup compensation as Motion Lab. The reviewer
	# independently measures actual cue alignment and drift instead of assuming it.
	var preroll: float = _audio_preroll()
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.stereo = true
	var samples := PackedByteArray()
	samples.resize(ceili((duration + preroll) * rate) * 4)
	for second in cues:
		var start: int = roundi((second + preroll) * rate)
		if start + 4800 > samples.size() / 4:
			continue
		for offset in range(4800):
			var t: float = float(offset) / rate
			var value: int = roundi(6000 * sin(TAU * (400 * t + 3500 * t * t)) * pow(sin(PI * offset / 4800.0), 2))
			samples.encode_s16((start + offset) * 4, value)
			samples.encode_s16((start + offset) * 4 + 2, value)
	sound.data = samples
	$Audio.stream = sound
	$Audio.play()


func _audio_preroll() -> float:
	return float(maxi(0, int(job.get("warmup_frames", 2)) - 1)) / float(job.get("fps", 60))


func _quad(position_at: Vector3) -> MeshInstance3D:
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.28, 0.28)
	quad.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	quad.material_override = material
	add_child(quad)
	quad.position = position_at
	quad.look_at(Vector3.ZERO, Vector3.UP, true)
	return quad


func sample_360_frame(index: int, seconds: float, _settings: Dictionary) -> String:
	for bit in range(13):
		bits[bit].albedo_color = Color.WHITE if index & (1 << bit) else Color(0.08, 0.08, 0.08)
	flash.visible = false
	for second in cues:
		if seconds >= second and seconds < second + 0.1 - 0.000001:
			flash.visible = true
	return ""
