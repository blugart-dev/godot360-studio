extends "../timeline_scene.gd"
## Editable camera/property timeline with a generated stereo synchronization cue.
## Audio is an ordinary scene player; it is not sampled by AnimationPlayer.seek.
var capture_job: Dictionary = {}
@export var play_sync_audio: bool = true


func prepare_360_capture(job: Dictionary) -> void:
	super.prepare_360_capture(job)
	capture_job = job


func _ready() -> void:
	super._ready()
	if not play_sync_audio:
		return
	var rate: int = 48000
	# The tested Movie Maker path adds one startup mix interval when warmup
	# disables scene processing. Zero warmup needs no such compensation.
	var preroll: float = float(maxi(0, int(capture_job.get("warmup_frames", 0)) - 1)) / float(capture_job.get("fps", 30)) if capture_mode else 0.0
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.stereo = true
	var samples := PackedByteArray()
	samples.resize(ceili((6.0 + preroll) * rate) * 4)
	for second in [1.0, 3.0, 5.0]:
		var start: int = roundi((second + preroll) * rate)
		for offset in range(4800):
			# A short fade avoids clicks without obscuring the cue's onset.
			var envelope: float = minf(1.0, float(offset) / 96.0) * minf(1.0, float(4799 - offset) / 96.0)
			var value: int = roundi(sin(TAU * 880.0 * offset / rate) * 3000.0 * envelope)
			samples.encode_s16((start + offset) * 4, value)
			samples.encode_s16((start + offset) * 4 + 2, value)
	sound.data = samples
	$Audio.stream = sound
	$Audio.play()
