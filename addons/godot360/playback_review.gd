@tool
extends VBoxContainer
## Optional local review copy. The delivery MP4 and capture are read-only.
signal texture_changed(texture: Texture2D)
signal setup_requested

const IO = preload("job_io.gd")
const Runner = preload("process_runner.gd")
const Tools = preload("tool_paths.gd")
const Storage = preload("storage_guard.gd")
const CACHE_ROOT = "res://.godot360/playback"
const FORMAT = "theora-srgb-2k-30-v3-decoded"
var player: VideoStreamPlayer
var play_button: Button
var cancel_button: Button
var sound_button: Button
var seek: HSlider
var clock_label: Label
var note: Label
var tools_provider: Callable
var source := ""
var fingerprint := ""
var duration := 0.0
var cache_dir := ""
var media_path := ""
var proxy_path := ""
var attempt := ""
var phase := ""
var runner: RefCounted
var guard: RefCounted
var expected := {}
var started := 0
var last_error := ""
var cache_hit := false
var dragging := false
var was_playing := false
var ended := false
var progress_poll := 0.0
var error_actions: HFlowContainer
var log_button: Button
var log_path := ""


func _ready() -> void:
	var row := HBoxContainer.new()
	add_child(row)
	play_button = Button.new()
	play_button.text = "Play video"
	play_button.disabled = true
	play_button.pressed.connect(toggle)
	play_button.tooltip_text = "Prepare and fully check a local playback copy, then play it. The delivery MP4 keeps its original quality."
	row.add_child(play_button)
	seek = HSlider.new()
	seek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seek.step = 0.001
	seek.editable = false
	seek.tooltip_text = "Review position (approximate, not frame-accurate)"
	seek.drag_started.connect(func():
		dragging = true
		was_playing = player.is_playing() and not player.paused
		player.paused = true)
	seek.drag_ended.connect(func(_changed: bool):
		dragging = false
		seek_to(seek.value)
		player.paused = not was_playing)
	seek.value_changed.connect(func(value: float):
		if not dragging:
			seek_to(value))
	row.add_child(seek)
	clock_label = Label.new()
	clock_label.text = "0:00 / 0:00"
	row.add_child(clock_label)
	sound_button = Button.new()
	sound_button.text = "Mute"
	sound_button.toggle_mode = true
	sound_button.disabled = true
	sound_button.tooltip_text = "Mute the review audio"
	sound_button.toggled.connect(func(muted: bool):
		player.volume = 0.0 if muted else 1.0
		sound_button.text = "Unmute" if muted else "Mute"
		sound_button.tooltip_text = "Restore review audio" if muted else "Mute review audio")
	row.add_child(sound_button)
	cancel_button = Button.new()
	cancel_button.text = "Cancel preview"
	cancel_button.hide()
	cancel_button.pressed.connect(cancel)
	add_child(cancel_button)
	note = Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Drag the sphere to look around · Arrow keys when focused."
	note.max_lines_visible = 4
	note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(note)
	error_actions = HFlowContainer.new()
	error_actions.hide()
	add_child(error_actions)
	var setup := Button.new()
	setup.text = "Tool setup"
	setup.pressed.connect(func(): setup_requested.emit())
	error_actions.add_child(setup)
	log_button = Button.new()
	log_button.text = "Playback logs"
	log_button.pressed.connect(func():
		if not log_path.is_empty():
			OS.shell_open(log_path.get_base_dir()))
	error_actions.add_child(log_button)
	player = VideoStreamPlayer.new()
	player.expand = true
	player.hide()
	player.finished.connect(func():
		ended = true
		play_button.text = "Replay"
		seek.set_value_no_signal(duration)
		clock_label.text = _time(duration) + " / " + _time(duration))
	add_child(player)
	visibility_changed.connect(func():
		if not is_visible_in_tree() and player.is_playing():
			player.paused = true
			play_button.text = "Play video")


func select_job(folder: String) -> void:
	clear()
	var report := IO.read_json(folder.path_join("report.json"))
	var job := IO.read_json(folder.path_join("job.json"))
	var path := folder.path_join("video-360.mp4")
	if not report.get("ok", false) or not FileAccess.file_exists(path):
		return
	duration = float(job.get("frames", 0)) / maxf(1.0, float(job.get("fps", 0)))
	if duration <= 0.0 or duration > 3600.0:
		return
	source = path
	seek.max_value = duration
	clock_label.text = "0:00 / " + _time(duration)
	play_button.disabled = false
	note.text = "Play video prepares a checked 2K copy. Open delivery MP4 for full detail."


func clear() -> void:
	_stop_worker()
	if player == null:
		return
	player.stop()
	player.stream = null
	source = ""
	proxy_path = ""
	last_error = ""
	log_path = ""
	note.tooltip_text = ""
	error_actions.hide()
	sound_button.disabled = true
	cache_hit = false
	ended = false
	dragging = false
	was_playing = false
	seek.editable = false
	seek.set_value_no_signal(0)
	clock_label.text = "0:00 / 0:00"
	play_button.text = "Play video"
	play_button.disabled = true
	cancel_button.hide()
	note.text = "Drag the sphere to look around · Arrow keys when focused."


func toggle() -> void:
	if source.is_empty() or not phase.is_empty():
		return
	if player.stream == null:
		prepare()
		return
	texture_changed.emit(player.get_video_texture())
	if ended or not player.is_playing():
		ended = false
		player.play()
		player.paused = false
	else:
		player.paused = not player.paused
	play_button.text = "Play video" if player.paused else "Pause"
	note.text = "Playback copy · Up to 2K / 30 FPS. Open the delivery MP4 for full detail."


func pause_for_still() -> void:
	if player.stream != null:
		player.paused = true
		play_button.text = "Play video"


func seek_to(seconds: float) -> void:
	if player.stream == null:
		return
	var paused := player.paused or ended
	if not player.is_playing():
		player.play()
	ended = false
	player.paused = paused
	player.stream_position = clampf(seconds, 0.0, maxf(0.0, duration - 0.001))
	play_button.text = "Play video" if paused else "Pause"
	texture_changed.emit(player.get_video_texture())


func prepare() -> void:
	if source.is_empty() or not phase.is_empty():
		return
	last_error = ""
	note.tooltip_text = ""
	error_actions.hide()
	cache_hit = false
	fingerprint = source_signature(source)
	if fingerprint.is_empty():
		_fail("The delivery video is missing or empty. Reopen the completed export.")
		return
	cache_dir = ProjectSettings.globalize_path(CACHE_ROOT.path_join(fingerprint.sha256_text()))
	var ready := IO.read_json(cache_dir.path_join("ready.json"))
	var cached := str(ready.get("file", ""))
	if cached.length() == 36 and cached.ends_with(".ogv") and cached.left(32).is_valid_hex_number():
		var path := cache_dir.path_join(cached)
		if ready.get("source") == fingerprint and _size(path) > 0 and _size(path) == int(ready.get("bytes", 0)):
			cache_hit = true
			_load_proxy(path)
			return
	if DirAccess.make_dir_recursive_absolute(cache_dir) != OK:
		_fail("Cannot create the local playback cache. Check project folder access.")
		return
	guard = Storage.new(cache_dir)
	var space: Dictionary = guard.check(16 * 1024 * 1024, "Preparing playback", true)
	if not str(space.error).is_empty():
		_fail(str(space.error))
		return
	var paths: Dictionary = tools_provider.call() if tools_provider.is_valid() else {}
	var ffmpeg := Tools.find_executable(str(paths.get("ffmpeg", "ffmpeg")))
	var ffprobe := Tools.find_executable(str(paths.get("ffprobe", "ffprobe")))
	if ffmpeg.is_empty() or ffprobe.is_empty():
		_fail("Select FFmpeg and FFprobe in Tool setup to prepare playback.")
		return
	expected = {"ffmpeg": ffmpeg, "ffprobe": ffprobe}
	attempt = Crypto.new().generate_random_bytes(16).hex_encode()
	media_path = cache_dir.path_join(attempt + ".ogv")
	started = Time.get_ticks_msec()
	# The delivery is BT.709. Godot's native Theora texture uses fixed BT.601
	# YUV-to-RGB conversion and is displayed as sRGB, so convert pixels explicitly.
	_start(ffmpeg, ["-hide_banner", "-nostdin", "-nostats", "-n", "-progress", cache_dir.path_join(attempt + "-progress.txt"),
		"-i", source, "-map", "0:v:0", "-map", "0:a:0", "-map_metadata", "-1",
		"-vf", "scale=min(2048\\,iw):-2,colorspace=iall=bt709:all=bt709:space=smpte170m:trc=srgb:range=tv:format=yuv420p,setsar=1,fps=30",
		"-c:v", "libtheora", "-q:v", "8", "-g", "15",
		"-pix_fmt", "yuv420p", "-c:a", "libvorbis", "-q:a", "5", "-ar", "48000", "-ac", "2", media_path], "encode")


func _start(executable: String, arguments: PackedStringArray, stage: String) -> void:
	runner = Runner.new()
	var error: String = runner.start(executable, arguments, cache_dir.path_join(attempt + "-" + stage + ".log"))
	if not error.is_empty():
		_fail(error)
		return
	phase = stage
	log_path = cache_dir.path_join(attempt + "-" + stage + ".log")
	play_button.disabled = true
	cancel_button.show()
	note.text = "Preparing 2K playback… Delivery MP4 is already verified."
	if stage == "verify":
		note.text = "Checking playback format and duration…"
	elif stage == "decode":
		note.text = "Decoding the entire playback copy to check video and audio…"


func _process(delta: float) -> void:
	if not phase.is_empty():
		var space: Dictionary = guard.check(16 * 1024 * 1024, "Preparing playback")
		if not str(space.error).is_empty():
			_fail(str(space.error))
			return
		if Time.get_ticks_msec() - started > 900000:
			_fail("Playback preparation exceeded 15 minutes. Open the MP4 in an external 360 player or retry.")
			return
		if runner.is_running():
			progress_poll += delta
			if phase == "encode" and progress_poll >= 0.25:
				progress_poll = 0.0
				var progress := FileAccess.get_file_as_string(cache_dir.path_join(attempt + "-progress.txt")) if FileAccess.file_exists(cache_dir.path_join(attempt + "-progress.txt")) else ""
				var elapsed := 0.0
				for line in progress.split("\n"):
					if line.begins_with("out_time_us="):
						elapsed = float(line.trim_prefix("out_time_us=")) / 1000000.0
				note.text = "Preparing 2K playback · %d%%. The editor remains available." % mini(99, int(elapsed / duration * 100.0))
			return
		var result: Dictionary = runner.finish()
		runner = null
		if result.code != 0:
			if phase == "decode":
				_fail("Playback copy contains decoding errors. Delivery MP4 is unchanged. Select another FFmpeg build in Tool setup, Check setup, then Retry playback.")
			else:
				_fail("Playback %s failed. Delivery MP4 is unchanged. Open Playback logs; select an FFmpeg build with libtheora and libvorbis, Check setup, then Retry playback." % phase)
			return
		if phase == "encode":
			_start(str(expected.ffprobe), ["-v", "error", "-show_streams", "-show_format", "-of", "json", media_path], "verify")
			return
		if phase == "verify":
			var probe = JSON.parse_string(str(result.output))
			if not probe is Dictionary or not valid_proxy(probe, duration):
				_fail("The playback copy failed its video/audio checks. The delivery file is preserved.")
				return
			# Readable headers and a successful encoder exit do not establish that
			# the actual Theora packets decode. Some Windows builds emit corrupt
			# motion packets while still satisfying the format/duration checks.
			_start(str(expected.ffmpeg), ["-hide_banner", "-loglevel", "error", "-nostdin", "-xerror", "-err_detect", "explode",
				"-i", media_path, "-map", "0:v:0", "-map", "0:a:0", "-f", "null", "-"], "decode")
			note.text = "Checking playback video and audio… You can cancel."
			return
		if source_signature(source) != fingerprint:
			_fail("The delivery video changed during playback preparation. Reopen the export and retry.")
			return
		if not IO.write_json(cache_dir.path_join("ready.json"), {"source": fingerprint, "file": media_path.get_file(), "bytes": _size(media_path)}):
			_fail("Cannot save the playback cache record. Check project folder access and disk space.")
			return
		phase = ""
		cancel_button.hide()
		_load_proxy(media_path)
	if player != null and player.stream != null and not dragging and not ended:
		seek.set_value_no_signal(player.stream_position)
		clock_label.text = _time(player.stream_position) + " / " + _time(duration)


func _load_proxy(path: String) -> void:
	proxy_path = path
	var stream := VideoStreamTheora.new()
	stream.file = path
	player.stream = stream
	if player.get_stream_length() <= 0.0:
		player.stream = null
		proxy_path = ""
		if IO.read_json(cache_dir.path_join("ready.json")).get("file") == path.get_file():
			DirAccess.remove_absolute(cache_dir.path_join("ready.json"))
		_fail("Godot could not open the review copy. Press Play video to rebuild it; the delivery MP4 is preserved.")
		return
	player.play()
	player.paused = not is_visible_in_tree()
	ended = false
	texture_changed.emit(player.get_video_texture())
	seek.editable = true
	sound_button.disabled = false
	play_button.disabled = false
	play_button.text = "Play video" if player.paused else "Pause"
	note.text = "Review copy · Up to 2K / 30 FPS. Inspect the delivery MP4 for full detail."


func cancel() -> void:
	_fail("Playback preparation cancelled. Press Play video to try again.")


func _fail(message: String) -> void:
	_stop_worker()
	last_error = message
	play_button.disabled = source.is_empty()
	play_button.text = "Retry playback"
	cancel_button.hide()
	note.text = message
	note.tooltip_text = message + ("\nLog: " + log_path if not log_path.is_empty() else "")
	error_actions.show()
	log_button.disabled = log_path.is_empty()
	log_button.tooltip_text = log_path


func _stop_worker() -> void:
	if runner != null:
		runner.cancel()
		runner.finish()
		runner = null
	if not phase.is_empty() and not media_path.is_empty() and FileAccess.file_exists(media_path):
		DirAccess.remove_absolute(media_path)
	phase = ""


func _exit_tree() -> void:
	_stop_worker()
	if player != null:
		player.stop()


static func source_signature(path: String) -> String:
	var bytes := _size(path)
	return JSON.stringify([FORMAT, path, bytes, FileAccess.get_modified_time(path)]) if bytes > 0 else ""


static func valid_proxy(probe: Dictionary, seconds: float) -> bool:
	var video := false
	var audio := false
	for stream in probe.get("streams", []):
		if stream.get("codec_type") == "video":
			video = stream.get("codec_name") == "theora" and int(stream.get("width", 0)) <= 2048 and int(stream.get("width", 0)) == 2 * int(stream.get("height", -1)) and int(stream.get("height", 0)) > 0
		if stream.get("codec_type") == "audio":
			audio = stream.get("codec_name") == "vorbis" and int(stream.get("channels", 0)) == 2 and int(stream.get("sample_rate", 0)) == 48000
	return video and audio and absf(float(probe.get("format", {}).get("duration", -1)) - seconds) < 0.15


static func _size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_length() if file != null else 0


static func _time(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]
