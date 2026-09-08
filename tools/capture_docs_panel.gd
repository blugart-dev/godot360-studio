extends SceneTree
## Run only in a disposable copy named "Godot360 documentation capture".
## See docs/media/README.md. Uses the actual panel and a verified playback cache.

const IO = preload("res://addons/godot360/job_io.gd")


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	if ProjectSettings.get_setting("application/config/name") != "Godot360 documentation capture":
		push_error("Use a disposable documentation project; this script opens jobs and saves local panel settings.")
		quit(1)
		return
	root.size = Vector2i(1440, 900)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	var margin := MarginContainer.new()
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	var panel = preload("res://addons/godot360/studio_panel.gd").new()
	margin.add_child(panel)
	panel.profile = load("res://export_profiles/threshold-8k.tres").duplicate()
	panel._refresh_fields()
	panel._refresh_scene_cameras(false)
	panel.output.text = "res://renders"
	panel.ffmpeg.text = IO.argument("ffmpeg")
	panel.ffprobe.text = IO.argument("ffprobe")
	panel._open_job(IO.argument("source"))
	panel.playback.toggle()
	var started := Time.get_ticks_msec()
	while not panel.playback.phase.is_empty() and Time.get_ticks_msec() - started < 600000:
		await create_timer(0.2).timeout
	if not panel.playback.last_error.is_empty() or panel.playback.proxy_path.is_empty():
		push_error("Playback failed: " + panel.playback.last_error)
		quit(1)
		return
	panel.playback.player.paused = true
	panel.playback.seek_to(35.0)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(IO.argument("output"))
	print("DOCUMENTATION PANEL: " + str(error))
	panel.free()
	quit(0 if error == OK else 1)
