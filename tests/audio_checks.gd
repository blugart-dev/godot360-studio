extends SceneTree
const Audio = preload("res://addons/godot360/audio_plan.gd")
const Planner = preload("res://addons/godot360/job_planner.gd")
const IO = preload("res://addons/godot360/job_io.gd")
const Profile = preload("res://addons/godot360/export_profile.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var folder := ProjectSettings.globalize_path("res://.godot360/audio-checks-" + str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("sound ' & [cue].wav")
	FileAccess.open(path, FileAccess.WRITE).store_buffer(PackedByteArray([1, 2, 3]))
	var old := {"fps": 30, "frames": 180, "warmup_frames": 2}
	check(Audio.validate(old).is_empty() and Audio.legacy(old), "Old recipes keep unchanged scene audio defaults")
	check(Audio.encoding(old, folder).options[-1] == "atrim=start=0.066666667,asetpts=PTS-STARTPTS,apad", "Legacy warmup filter remains byte-for-byte unchanged")
	var profile := Profile.new()
	profile.audio_mode = "mix"
	profile.soundtrack_path = path
	profile.soundtrack_trim_seconds = 0.5
	profile.soundtrack_offset_seconds = -0.125
	profile.scene_audio_offset_seconds = 0.25
	profile.soundtrack_gain_db = -6.0
	check(ResourceSaver.save(profile, folder.path_join("recipe.tres")) == OK, "Audio recipe saves as a portable resource")
	var loaded = load(folder.path_join("recipe.tres"))
	check(Audio.settings(loaded.to_dictionary()) == Audio.settings(profile.to_dictionary()), "All audio fields survive resource round-trip")
	var job := profile.to_dictionary()
	var plan := Audio.encoding(job, folder)
	check(plan.inputs.has(path) and not plan.options[1].contains(path), "Soundtrack paths are separate arguments even with punctuation")
	check(plan.options[1].contains("adelay=delays=12000S:all=1"), "Positive scene offset delays both channels on the sample clock")
	check(plan.options[1].contains("atrim=start_sample=30000"), "Soundtrack trim and negative offset combine without scene warmup")
	check(plan.options[1].contains("normalize=0") and plan.options[1].contains("level=0:latency=1"), "Mixing preserves gains and compensates limiter latency")
	for change in [{"audio_mode": "wrong"}, {"soundtrack_trim_seconds": -1}, {"soundtrack_offset_seconds": INF},
		{"scene_audio_gain_db": NAN}, {"soundtrack_gain_db": 1}, {"scene_audio_offset_seconds": 3601},
		{"soundtrack_trim_seconds": "1"}, {"soundtrack_path": "relative.wav"}, {"soundtrack_path": "res://missing.wav"}]:
		var invalid := job.duplicate()
		invalid.merge(change, true)
		check(not Audio.validate(invalid).is_empty(), "Invalid audio settings are rejected: " + str(change))
	check(not Audio.validate_probe({}, job).is_empty(), "Non-audio files fail soundtrack preflight")
	var probe := {"streams": [{"codec_type": "audio", "channels": 2, "sample_rate": "48000", "duration": "6"}]}
	check(Audio.validate_probe(probe, job).is_empty(), "Stereo soundtrack passes preflight")
	probe.streams[0].channels = 1
	check(Audio.validate_probe(probe, job).is_empty(), "Mono soundtrack can be converted to stereo")
	probe.streams[0].channels = 6
	check(not Audio.validate_probe(probe, job).is_empty(), "Multichannel soundtrack requires an explicit external downmix")
	probe.streams[0].channels = 2
	probe.streams[0].duration = "0.4"
	check(not Audio.validate_probe(probe, job).is_empty(), "Trimming past the soundtrack duration fails before capture")
	var legacy_profile := Profile.new().to_dictionary()
	var legacy_sample := legacy_profile.duplicate()
	for key in Audio.DEFAULTS:
		legacy_sample.erase(key)
	check(not Planner.matches(legacy_sample, legacy_profile), "Pre-renderer planning samples require a new test even with default audio")
	var sample := job.duplicate(true)
	preload("res://addons/godot360/renderer_policy.gd").stamp(sample)
	sample.audio_signature = Audio.signature(job)
	check(Planner.matches(sample, job), "Matching audio settings reuse a planning sample")
	check(Planner.matches(JSON.parse_string(JSON.stringify(sample)), job), "Audio planning signature survives JSON number conversion")
	var rounded := job.duplicate()
	rounded.soundtrack_offset_seconds += 0.0000000000001
	check(Planner.matches(sample, rounded), "Sub-sample floating point differences do not invalidate an estimate")
	job.soundtrack_gain_db = -7.0
	check(not Planner.matches(sample, job), "Audio level changes invalidate the estimate")
	job.soundtrack_gain_db = -6.0
	FileAccess.open(path, FileAccess.WRITE).store_buffer(PackedByteArray([1, 2, 3, 4]))
	check(not Planner.matches(sample, job), "Changing the attached file invalidates the saved estimate")
	var capture := folder.path_join("capture")
	DirAccess.make_dir_recursive_absolute(capture.path_join("frames"))
	job.soundtrack_resolved_path = path
	job.scene_path = "res://scene-not-installed.tscn"
	IO.write_json(capture.path_join("job.json"), job)
	IO.write_json(capture.path_join("capture-result.json"), {"ok": true})
	var request := {"source_dir": capture, "output_dir": folder.path_join("new"), "crf": 25}
	var resolved := Planner.resolve_reencode(request)
	check(resolved.error.is_empty() and resolved.job.soundtrack_resolved_path == path and resolved.job.soundtrack_offset_seconds == -0.125, "CLI re-encode inherits saved audio and its resolved path")
	request.merge({"audio_mode": "scene", "scene_audio_offset_seconds": -0.1, "soundtrack_path": "", "width": 7680}, true)
	resolved = Planner.resolve_reencode(request)
	check(resolved.error.is_empty() and resolved.job.audio_mode == "scene" and resolved.job.scene_audio_offset_seconds == -0.1 and resolved.job.width == job.width, "Re-encode changes audio while keeping captured video dimensions")
	check(not resolved.job.has("soundtrack_resolved_path") and not resolved.job.has("audio_signature"), "New audio selection clears stale path and fingerprint")
	print("AUDIO CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
