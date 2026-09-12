extends SceneTree
## Actual review-copy encoding, cache, failure cleanup and native seeking.
const IO = preload("res://addons/godot360/job_io.gd")
const Playback = preload("res://addons/godot360/playback_review.gd")
var checks := 0
var failures := 0
var review: Control
var panel: Control
var job_dir := ""
var original_settings := PackedByteArray()
var had_settings := false
var saved_settings := false
var audio_capture: AudioEffectCapture
var settings_path := "res://.godot360/settings.cfg"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	job_dir = ProjectSettings.globalize_path("res://.godot360/playback-check-" + str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(job_dir)
	var source := job_dir.path_join("video-360.mp4")
	var ffmpeg := IO.argument("ffmpeg")
	var ffprobe := IO.argument("ffprobe")
	# Distinct full-frame colors make backward/forward seeks independently visible.
	var patch := Image.create(128, 128, false, Image.FORMAT_RGB8)
	patch.fill(Color8(102, 153, 204))
	for index in range(3):
		var picture := Image.create(512, 256, false, Image.FORMAT_RGB8)
		picture.fill([Color.RED, Color.GREEN, Color.BLUE][index])
		picture.blit_rect(patch, Rect2i(0, 0, 128, 128), Vector2i.ZERO)
		picture.save_png(job_dir.path_join("source-%d.png" % index))
	var result: Array = []
	var code := OS.execute(ffmpeg, ["-hide_banner", "-loglevel", "error", "-nostdin", "-n", "-framerate", "1/2", "-i", job_dir.path_join("source-%d.png"),
		"-f", "lavfi", "-i", "sine=frequency=660:sample_rate=48000:duration=6",
		"-vf", "fps=30,scale=in_range=full:out_range=tv:out_color_matrix=bt709,format=yuv444p,colorspace=iall=bt709:itrc=srgb:irange=tv:all=bt709:range=tv:format=yuv420p",
		"-c:v", "libx264", "-pix_fmt", "yuv420p", "-colorspace", "bt709", "-color_trc", "bt709", "-color_primaries", "bt709",
		"-c:a", "aac", "-ac", "2", "-movflags", "+faststart", "-t", "6", source], result, true)
	check(code == 0, "Creates a real six-second MP4 with distinct visual intervals and audio")
	if code != 0:
		print(result)
		_finish()
		return
	IO.write_json(job_dir.path_join("job.json"), {"frames": 180, "fps": 30})
	IO.write_json(job_dir.path_join("report.json"), {"ok": true, "scene_checks": {"warnings": ["Auto exposure can create brightness seams."]}})
	var source_hash := FileAccess.get_sha256(source)
	had_settings = FileAccess.file_exists(settings_path)
	original_settings = FileAccess.get_file_as_bytes(settings_path) if had_settings else PackedByteArray()
	saved_settings = true
	root.size = Vector2i(1100, 720)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	panel = preload("res://addons/godot360/studio_panel.gd").new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.ffmpeg.text = ffmpeg
	panel.ffprobe.text = ffprobe
	panel._open_job(job_dir)
	review = panel.playback
	audio_capture = AudioEffectCapture.new()
	audio_capture.buffer_length = 0.2
	AudioServer.add_bus_effect(0, audio_capture)
	check(not review.play_button.disabled and review.source == source, "Opening a completed export enables playback")
	check(panel.details_button.text.contains("notes") and panel.effects_label.text.contains("brightness seams"), "Export details exposes actual capture warnings without opening JSON")
	review.toggle()
	check(review.phase == "encode", "Play starts asynchronous review preparation")
	await _wait_ready()
	check(review.last_error.is_empty() and not review.proxy_path.is_empty(), "Theora/Vorbis review copy passes actual FFprobe verification")
	if review.proxy_path.is_empty():
		print(review.last_error)
		_finish()
		return
	check(FileAccess.get_sha256(source) == source_hash, "Review preparation preserves the original MP4")
	check(review.player.get_stream_length() > 5.9, "Godot loads the full native review stream")
	audio_capture.clear_buffer()
	await create_timer(0.3).timeout
	check(review.player.stream_position > 0.1, "Native video clock advances during playback")
	var samples := audio_capture.get_buffer(audio_capture.get_frames_available())
	var peak := 0.0
	for sample in samples:
		peak = maxf(peak, sample.abs().x)
	check(peak > 0.01, "The native player actually delivers decoded audio to the mix bus")
	review.toggle()
	check(review.player.paused, "Pause stops native playback")
	var position: float = review.player.stream_position
	await create_timer(0.2).timeout
	check(absf(review.player.stream_position - position) < 0.05, "Pause holds the video clock")
	await _seek_color(3.0, 1, "Forward seek reaches the green interval while paused")
	await _seek_color(0.5, 0, "Backward seek reaches the red interval while paused")
	await _seek_color(5.0, 2, "Seek near the end reaches the blue interval")
	review.sound_button.button_pressed = true
	check(review.player.volume == 0.0, "Mute controls native review audio")
	review.sound_button.button_pressed = false
	check(review.player.volume == 1.0, "Sound can be restored")
	root.size = Vector2i(1100, 600)
	root.content_scale_size = root.size
	await process_frame
	await process_frame
	print("PLAYBACK LAYOUT: ", panel.size, " minimum ", panel.get_combined_minimum_size(), " window ", root.size)
	check(panel.size.x <= root.size.x and panel.size.y <= root.size.y, "Completed playback and scene notes fit a compact 1100 by 600 panel")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(job_dir.path_join("playback-panel.png"))
	var proxy: String = review.proxy_path
	var proxy_stamp := FileAccess.get_modified_time(proxy)
	review.select_job(job_dir)
	review.toggle()
	check(review.cache_hit and review.proxy_path == proxy and review.phase.is_empty(), "Reopening reuses the completed local copy without an encoder")
	check(FileAccess.get_modified_time(proxy) == proxy_stamp, "Cache reuse leaves the proxy unchanged")
	review.hide()
	check(review.player.paused, "Hiding the playback controls pauses sound and motion")
	review.show()
	review.player.paused = false
	review.seek_to(5.8)
	await create_timer(0.4).timeout
	check(review.ended and review.play_button.text == "Replay", "Reaching the end offers replay")
	review.toggle()
	await create_timer(0.15).timeout
	check(not review.ended and not review.player.paused and review.player.stream_position < 0.5, "Replay restarts the full video")
	# A changed master invalidates its cache. Use a fresh copy, preserving the original.
	var second := job_dir.path_join("second")
	DirAccess.make_dir_recursive_absolute(second)
	DirAccess.copy_absolute(source, second.path_join("video-360.mp4"))
	DirAccess.copy_absolute(job_dir.path_join("job.json"), second.path_join("job.json"))
	DirAccess.copy_absolute(job_dir.path_join("report.json"), second.path_join("report.json"))
	review.select_job(second)
	review.toggle()
	var cancelled_pid: int = review.runner.pid if review.runner != null else -1
	var partial: String = review.media_path
	review.cancel()
	check(review.phase.is_empty() and review.runner == null and review.last_error.contains("cancelled"), "Preparation cancellation releases the worker and restores controls")
	check(cancelled_pid > 0 and not OS.is_process_running(cancelled_pid) and not FileAccess.file_exists(partial), "Cancellation stops its own encoder and removes only its incomplete review copy")
	check(FileAccess.file_exists(proxy) and FileAccess.get_sha256(source) == source_hash, "Cancellation preserves prior playback and delivered media")
	review.tools_provider = func(): return {"ffmpeg": job_dir.path_join("missing.exe"), "ffprobe": ffprobe}
	review.toggle()
	check(review.last_error.contains("Tool setup") and review.phase.is_empty(), "Missing tools receive actionable playback guidance")
	review.tools_provider = func(): return {"ffmpeg": ffprobe, "ffprobe": ffprobe}
	review.toggle()
	await _wait_ready()
	check(review.last_error.contains("encode failed") and review.proxy_path.is_empty(), "An actual codec-process failure never becomes playable output")
	review.tools_provider = func(): return {"ffmpeg": ffmpeg, "ffprobe": ffprobe}
	review.toggle()
	check(review.note.tooltip_text.is_empty(), "Retry clears stale failure tooltips before preparing a new copy")
	if review.guard != null:
		review.guard.space_reader = func(): return 0
		review.guard.sample_interval_msec = 0
	await _wait_ready()
	check(review.last_error.contains("Insufficient disk space") and review.phase.is_empty(), "Low-space detection cancels preview preparation without filling the drive")
	review.hide()
	review.toggle()
	await _wait_ready()
	check(review.last_error.is_empty() and review.player.paused, "Preparation completed in a hidden panel does not start playing sound")
	review.show()
	await _check_corrupt_playback(source, source_hash, proxy, ffprobe)
	IO.write_json(second.path_join("report.json"), {"ok": false})
	review.select_job(second)
	check(review.play_button.disabled and review.source.is_empty(), "Unverified jobs cannot be offered as completed playback")
	check(not Playback.valid_proxy({"streams": [], "format": {"duration": "6"}}, 6.0), "Missing audio/video streams fail preview validation")
	_check_scene_warnings()
	print("PLAYBACK EVIDENCE: " + job_dir)
	_finish()


func _check_corrupt_playback(source: String, source_hash: String, valid_copy: String, ffprobe: String) -> void:
	var broken := job_dir.path_join("broken-playback")
	DirAccess.make_dir_recursive_absolute(broken)
	for name in ["video-360.mp4", "job.json", "report.json"]:
		DirAccess.copy_absolute(job_dir.path_join(name), broken.path_join(name))
	review.select_job(broken)
	# Pause polling so a deterministic malformed video packet can replace one
	# encoder result before the normal verification path examines it.
	review.set_process(false)
	review.toggle()
	var deadline := Time.get_ticks_msec() + 120000
	while review.runner != null and review.runner.is_running() and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	if review.runner == null or review.runner.is_running():
		review.cancel()
		review.set_process(true)
		check(false, "Corruption fixture encoder finishes")
		return
	var data := FileAccess.get_file_as_bytes(valid_copy)
	check(_corrupt_video_packet(data), "Corruption fixture changes a video packet while retaining valid Ogg page checksums")
	var file := FileAccess.open(review.media_path, FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
	var output: Array = []
	var code := OS.execute(ffprobe, ["-v", "error", "-show_streams", "-show_format", "-of", "json", review.media_path], output, true)
	var probe = JSON.parse_string("".join(output))
	check(code == 0 and probe is Dictionary and Playback.valid_proxy(probe, 6.0), "Corrupt motion packets still pass the old format and duration checks")
	var rejected_path: String = review.media_path
	var rejected_cache: String = review.cache_dir
	review.set_process(true)
	await _wait_ready()
	check(review.last_error.contains("decoding errors") and review.last_error.contains("Tool setup"), "Full decoding rejects corrupt playback and explains how to rebuild it")
	check(review.player.stream == null and review.proxy_path.is_empty() and not FileAccess.file_exists(rejected_path), "Corrupt playback is never loaded and its failed copy is removed")
	check(not FileAccess.file_exists(rejected_cache.path_join("ready.json")), "Corrupt playback never receives a reusable cache record")
	check(FileAccess.get_sha256(source) == source_hash and FileAccess.file_exists(valid_copy), "Rejecting corruption preserves the delivery and earlier valid playback")
	review.toggle()
	deadline = Time.get_ticks_msec() + 120000
	while review.phase not in ["", "decode"] and Time.get_ticks_msec() < deadline:
		await process_frame
	check(review.phase == "decode", "A valid retry reaches the asynchronous full-decode stage")
	var decode_pid: int = review.runner.pid if review.runner != null else -1
	var cancelled_copy: String = review.media_path
	review.cancel()
	check(review.phase.is_empty() and review.runner == null and decode_pid > 0 and not OS.is_process_running(decode_pid)
		and not FileAccess.file_exists(cancelled_copy) and not FileAccess.file_exists(rejected_cache.path_join("ready.json")), "Cancel during full decoding stops its worker and leaves no playable cache")
	review.toggle()
	await _wait_ready()
	check(review.last_error.is_empty() and not review.proxy_path.is_empty(), "Retry can build a valid playback copy after rejection")


func _corrupt_video_packet(data: PackedByteArray) -> bool:
	# The first Ogg stream is Theora. Keep the identification/setup headers,
	# lacing and timestamps; damage a complete data packet and recompute CRC.
	var serial := data.decode_u32(14)
	var offset := 0
	while offset + 27 < data.size():
		var segments := int(data[offset + 26])
		var payload := offset + 27 + segments
		var length := 0
		for index in range(segments):
			length += data[offset + 27 + index]
		var end := payload + length
		if end > data.size():
			return false
		if data.decode_u32(offset + 14) == serial and data.decode_u32(offset + 18) > 1 and length > 8:
			var packet_length := 0
			for index in range(segments):
				packet_length += data[offset + 27 + index]
				if data[offset + 27 + index] < 255:
					break
			for index in range(packet_length):
				data[payload + index] = 0x7f if index == 0 else 0xff
			data.encode_u32(offset + 22, 0)
			var crc := 0
			for index in range(offset, end):
				crc ^= int(data[index]) << 24
				for bit in range(8):
					crc = ((crc << 1) ^ (0x04c11db7 if crc & 0x80000000 else 0)) & 0xffffffff
			data.encode_u32(offset + 22, crc)
			return true
		offset = end
	return false


func _wait_ready() -> void:
	var deadline := Time.get_ticks_msec() + 120000
	while not review.phase.is_empty() and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	if not review.phase.is_empty():
		review.cancel()
		check(false, "Playback preparation finishes before the test timeout")


func _seek_color(seconds: float, channel: int, description: String) -> void:
	review.seek_to(seconds)
	await create_timer(0.15).timeout
	check(absf(review.player.stream_position - seconds) < 0.1 and review.player.paused, description + " (clock)")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image: Image = review.player.get_video_texture().get_image()
		var color := image.get_pixel(image.get_width() / 2, image.get_height() / 2)
		check(color[channel] > 0.7 and color[(channel + 1) % 3] < 0.2 and color[(channel + 2) % 3] < 0.2, description + " (decoded pixels)")
		var sample := image.get_pixel(48, 48)
		var target := Color8(102, 153, 204)
		check(absf(sample.r - target.r) < 0.032 and absf(sample.g - target.g) < 0.032 and absf(sample.b - target.b) < 0.032, "Native review restores authored sRGB color after the BT.709 delivery conversion")


func _check_scene_warnings() -> void:
	var scene := Node3D.new()
	var world := WorldEnvironment.new()
	world.name = "World"
	world.environment = Environment.new()
	world.environment.glow_enabled = true
	world.environment.fog_enabled = true
	world.environment.sdfgi_enabled = true
	world.camera_attributes = CameraAttributesPractical.new()
	world.camera_attributes.auto_exposure_enabled = true
	scene.add_child(world)
	world.owner = scene
	var packed := PackedScene.new()
	packed.pack(scene)
	var path := job_dir.path_join("effects.tscn")
	ResourceSaver.save(packed, path)
	scene.free()
	var notes: Array = preload("res://addons/godot360/scene_inspector.gd").inspect(path).warnings
	for term in ["Glow", "Fog", "SDFGI", "Auto exposure"]:
		check(notes.any(func(note: String): return note.contains(term)), "Saved-scene check explains " + term + " before capture")


func _finish() -> void:
	if panel != null:
		panel.free()
		panel = null
	if saved_settings:
		if had_settings:
			var file := FileAccess.open(settings_path, FileAccess.WRITE)
			file.store_buffer(original_settings)
			file.close()
		else:
			DirAccess.remove_absolute(settings_path)
	print("PLAYBACK CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
