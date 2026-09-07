extends SceneTree
## Real GUI + GPU + encoder integration test. Paths are passed after --.
## --ffmpeg=/absolute/ffmpeg --ffprobe=/absolute/ffprobe
const IO = preload("res://addons/umbral360/job_io.gd")
var panel: Control
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings_path := "res://.umbral360/settings.cfg"
	var had_settings := FileAccess.file_exists(settings_path)
	var original_settings := FileAccess.get_file_as_bytes(settings_path) if had_settings else PackedByteArray()
	root.size = Vector2i(1500, 680)
	root.content_scale_size = Vector2i(1500, 680)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.title = "Godot360 Studio · Integration check"
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(margin)
	panel = preload("res://addons/umbral360/studio_panel.gd").new()
	margin.add_child(panel)
	panel.profile = preload("res://addons/umbral360/export_profile.gd").new()
	panel._refresh_fields()
	panel.recipe_fields.width.text = "2048"
	panel.recipe_fields.face_size.text = "512"
	panel.recipe_fields.duration.text = "2"
	panel.ffmpeg.text = IO.argument("ffmpeg")
	panel.ffprobe.text = IO.argument("ffprobe")
	panel.output.text = ProjectSettings.globalize_path("res://renders/studio-checks")
	panel._render()
	check(panel.process_id > 0, "Panel starts an export process")
	var deadline: int = Time.get_ticks_msec() + 180000
	while panel.process_id > 0 and Time.get_ticks_msec() < deadline:
		await create_timer(0.3).timeout
	check(panel.process_id <= 0, "Panel observes export completion")
	var report: Dictionary = IO.read_json(panel.folder.path_join("report.json"))
	check(report.get("ok", false), "Panel export passes independent MP4 verification")
	check(panel.preview_material != null, "Spherical preview is loaded")
	if panel.preview_material != null:
		var motion := InputEventMouseMotion.new()
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.relative = Vector2(-100, -20)
		panel._preview_input(motion)
		check(panel.heading.x > 0.0 and panel.heading.y < 0.0, "Preview responds to a drag")
		panel.heading = Vector2.ZERO
		panel._update_preview()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://.umbral360/studio-preview.png"))
	print("STUDIO EXPORT FOLDER: " + panel.folder)
	await _check_cancellation()
	print("STUDIO CHECKS: %d failures" % failures)
	if had_settings:
		var saved := FileAccess.open(settings_path, FileAccess.WRITE)
		saved.store_buffer(original_settings)
		saved.close()
	else:
		DirAccess.remove_absolute(settings_path)
	quit(0 if failures == 0 else 1)


func _check_cancellation() -> void:
	panel.recipe_fields.duration.text = "60"
	panel.recipe_fields.width.text = "512"
	panel.recipe_fields.face_size.text = "128"
	panel._render()
	var deadline: int = Time.get_ticks_msec() + 30000
	while panel.process_id > 0 and Time.get_ticks_msec() < deadline:
		var state: Dictionary = IO.read_json(panel.folder.path_join("status.json"))
		var capture_progress: Dictionary = IO.read_json(panel.folder.path_join("render-progress.json"))
		if state.get("stage") == "Rendering" and int(capture_progress.get("frame", 0)) >= 10:
			break
		await create_timer(0.1).timeout
	panel._cancel()
	while panel.process_id > 0 and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	var final_state: Dictionary = IO.read_json(panel.folder.path_join("status.json"))
	check(panel.process_id <= 0 and str(final_state.get("error", "")).contains("Cancelled"), "Cancellation stops the rendering job cleanly")
	check(not FileAccess.file_exists(panel.folder.path_join("video-360.mp4")), "Cancelled render does not publish a final MP4")


func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
