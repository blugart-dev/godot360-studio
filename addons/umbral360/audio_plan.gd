extends RefCounted
## Audio timing is relative to delivered video frame zero, after scene warmup.
const RATE = 48000
const DEFAULTS = {"audio_mode": "scene", "soundtrack_path": "", "soundtrack_trim_seconds": 0.0,
	"soundtrack_offset_seconds": 0.0, "soundtrack_gain_db": 0.0,
	"scene_audio_offset_seconds": 0.0, "scene_audio_gain_db": 0.0}


static func settings(job: Dictionary) -> Dictionary:
	var result := DEFAULTS.duplicate()
	for key in result:
		result[key] = str(job.get(key, result[key])) if result[key] is String else float(job.get(key, result[key]))
	return result


static func uses_soundtrack(job: Dictionary) -> bool:
	return str(job.get("audio_mode", "scene")) in ["soundtrack", "mix"]


static func resolved_path(job: Dictionary) -> String:
	var saved: String = str(job.get("soundtrack_resolved_path", ""))
	var selected: String = str(job.get("soundtrack_path", ""))
	return saved if not saved.is_empty() else ProjectSettings.globalize_path(selected) if not selected.is_empty() else ""


static func validate(job: Dictionary) -> String:
	if str(job.get("audio_mode", "scene")) not in ["scene", "soundtrack", "mix"]:
		return "Choose scene, soundtrack, or mix for audio mode."
	for key in DEFAULTS:
		if DEFAULTS[key] is String:
			continue
		var value = job.get(key, DEFAULTS[key])
		if not (value is float or value is int) or not is_finite(float(value)):
			return "Audio setting must be a finite number: " + key
		var minimum := -60.0 if key.ends_with("_db") else 0.0 if key == "soundtrack_trim_seconds" else -3600.0
		var maximum := 0.0 if key.ends_with("_db") else 3600.0
		if float(value) < minimum or float(value) > maximum:
			return "Audio setting %s must be between %s and %s." % [key, str(minimum), str(maximum)]
	if uses_soundtrack(job):
		var path: String = str(job.get("soundtrack_path", ""))
		if path.is_empty() or not (path.begins_with("res://") or path.is_absolute_path()) or path.begins_with("user://"):
			return "Choose a local soundtrack using res:// or an absolute file path."
		if not FileAccess.file_exists(resolved_path(job)):
			return "Soundtrack file does not exist: " + resolved_path(job)
	return ""


# Cheap enough for panel polling. The saved job freezes this signature; execution
# separately records/checks SHA-256 before and after encoding.
static func signature(job: Dictionary) -> Dictionary:
	var result := settings(job)
	if not uses_soundtrack(job):
		for key in ["soundtrack_path", "soundtrack_trim_seconds", "soundtrack_offset_seconds", "soundtrack_gain_db"]:
			result.erase(key)
	else:
		var path := resolved_path(job)
		var file := FileAccess.open(path, FileAccess.READ) if FileAccess.file_exists(path) else null
		result.soundtrack_file = {"path": path.replace("\\", "/").simplify_path(),
			"bytes": file.get_length() if file != null else -1, "modified": FileAccess.get_modified_time(path) if file != null else 0}
	if str(job.get("audio_mode", "scene")) == "soundtrack":
		result.erase("scene_audio_offset_seconds")
		result.erase("scene_audio_gain_db")
	# Canonical strings avoid tiny SpinBox/JSON float differences invalidating an
	# unchanged recipe. Use the same sample rounding and gain precision as encoding.
	for key in result.keys():
		if key.ends_with("_seconds"):
			result[key] = str(roundi(float(result[key]) * RATE))
		elif key.ends_with("_db"):
			result[key] = str(roundi(float(result[key]) * 1000000))
	if result.has("soundtrack_file"):
		result.soundtrack_file.bytes = str(result.soundtrack_file.bytes)
		result.soundtrack_file.modified = str(result.soundtrack_file.modified)
	return result


static func validate_probe(probe: Dictionary, job: Dictionary) -> String:
	for stream in probe.get("streams", []):
		if stream.get("codec_type") != "audio":
			continue
		if int(stream.get("channels", 0)) not in [1, 2] or int(stream.get("sample_rate", 0)) <= 0:
			return "Soundtrack must contain mono or stereo audio."
		var duration := float(stream.get("duration", probe.get("format", {}).get("duration", 0)))
		if duration > 0 and float(job.get("soundtrack_trim_seconds", 0)) >= duration:
			return "Soundtrack trim starts at or beyond the end of the file."
		return ""
	return "The selected soundtrack has no readable audio stream."


static func legacy(job: Dictionary) -> bool:
	return str(job.get("audio_mode", "scene")) == "scene" and float(job.get("scene_audio_offset_seconds", 0)) == 0.0 and float(job.get("scene_audio_gain_db", 0)) == 0.0


static func required_filters(job: Dictionary) -> Array:
	var result := ["atrim", "asetpts", "apad"]
	if not legacy(job):
		result.append_array(["aresample", "aformat", "volume", "adelay"])
	if str(job.get("audio_mode", "scene")) == "mix":
		result.append_array(["amix", "alimiter"])
	return result


static func _chain(trim: float, offset: float, gain: float, samples: int) -> String:
	var skip := roundi(trim * RATE) + maxi(0, -roundi(offset * RATE))
	var delay := maxi(0, roundi(offset * RATE))
	# Convert to the common sample clock before applying sample-count timing.
	var chain := "aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,atrim=start_sample=%d,asetpts=PTS-STARTPTS,volume=%.6fdB" % [skip, gain]
	if delay > 0:
		chain += ",adelay=delays=%dS:all=1" % delay
	# Delay/trim can preserve discontinuous input timestamps. Rebuild the final
	# clock from emitted samples so AAC always receives monotonically spaced PTS.
	return chain + ",apad=whole_len=%d,atrim=end_sample=%d,asetpts=N/SR/TB" % [samples, samples]


# Inputs are appended after input zero (the retained video frames). Paths are
# separate process arguments, never embedded in the filter expression.
static func encoding(job: Dictionary, source_folder: String) -> Dictionary:
	var warmup := float(job.get("warmup_frames", 2)) / float(job.fps)
	if legacy(job):
		return {"inputs": PackedStringArray(["-i", source_folder.path_join("frames/frame.wav")]),
			"options": PackedStringArray(["-map", "1:a:0", "-af", "atrim=start=%.9f,asetpts=PTS-STARTPTS,apad" % warmup]), "legacy": true}
	var config := settings(job)
	var samples := roundi(float(job.frames) * RATE / float(job.fps))
	var inputs := PackedStringArray()
	var chains := PackedStringArray()
	var index := 1
	if config.audio_mode in ["scene", "mix"]:
		inputs.append_array(["-i", source_folder.path_join("frames/frame.wav")])
		chains.append("[%d:a:0]%s[scene_audio]" % [index, _chain(warmup, config.scene_audio_offset_seconds, config.scene_audio_gain_db, samples)])
		index += 1
	if config.audio_mode in ["soundtrack", "mix"]:
		inputs.append_array(["-i", resolved_path(job)])
		chains.append("[%d:a:0]%s[soundtrack_audio]" % [index, _chain(config.soundtrack_trim_seconds, config.soundtrack_offset_seconds, config.soundtrack_gain_db, samples)])
	var output := "scene_audio" if config.audio_mode == "scene" else "soundtrack_audio"
	if config.audio_mode == "mix":
		chains.append("[scene_audio][soundtrack_audio]amix=inputs=2:duration=longest:dropout_transition=0:normalize=0,alimiter=limit=0.95:level=0:latency=1,apad=whole_len=%d,atrim=end_sample=%d,asetpts=N/SR/TB[audio_out]" % [samples, samples])
		output = "audio_out"
	return {"inputs": inputs, "options": PackedStringArray(["-filter_complex", ";".join(chains), "-map", "[" + output + "]"]), "legacy": false}
