extends SceneTree
## Actual Motion lab button and complete authored export. GPU/FFmpeg required.
const IO = preload("res://addons/godot360/job_io.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings := "res://.godot360/settings.cfg"
	var existed := FileAccess.file_exists(settings)
	var original := FileAccess.get_file_as_bytes(settings) if existed else PackedByteArray()
	root.size = Vector2i(1500, 720)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	var panel = preload("res://addons/godot360/studio_panel.gd").new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_find_button(panel, "Motion lab").pressed.emit()
	check(panel.profile.scene_path.ends_with("timeline.tscn") and str(panel.profile.camera_path) == "CameraPath/Follow/Camera3D", "Motion lab button selects its scene and path camera")
	check(panel.profile.width == "4096" and panel.profile.face_size == 2048 and panel.profile.duration == 6.0, "Motion lab includes a six-second production recipe")
	panel.ffmpeg.text = IO.argument("ffmpeg")
	panel.ffprobe.text = IO.argument("ffprobe")
	panel.output.text = ProjectSettings.globalize_path("res://renders/timeline-studio-checks")
	if not IO.argument("width").is_empty():
		panel.recipe_fields.width.text = IO.argument("width")
		panel.recipe_fields.face_size.text = str(maxi(128, int(IO.argument("width")) / 2))
	panel.render_button.pressed.emit()
	check(panel.process_id > 0, "Panel launches the authored film")
	var deadline := Time.get_ticks_msec() + 180000
	while panel.process_id > 0 and Time.get_ticks_msec() < deadline:
		await create_timer(0.3).timeout
	check(panel.process_id <= 0, "Panel observes authored export completion")
	if panel.process_id > 0:
		panel._cancel()
	var report := IO.read_json(panel.folder.path_join("report.json"))
	check(report.get("ok", false), "Authored output passes all MP4 checks")
	var capture := IO.read_json(panel.folder.path_join("capture-settings.json"))
	check(capture.get("timeline_sampling") == "frame_index / fps", "Capture records frame-index timeline sampling")
	check(panel.preview_material != null, "The completed authored film has a spherical still preview")
	await process_frame
	await RenderingServer.frame_post_draw
	check(panel.size.y <= root.size.y, "Motion lab actions fit the studio panel")
	root.get_texture().get_image().save_png("res://.godot360/motion-lab-panel.png")
	print("TIMELINE STUDIO FOLDER: " + panel.folder)
	if existed:
		var file := FileAccess.open(settings, FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	else:
		DirAccess.remove_absolute(settings)
	print("TIMELINE STUDIO CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _find_button(node: Node, title: String) -> Button:
	if node is Button and node.text == title:
		return node
	for child in node.get_children():
		var button := _find_button(child, title)
		if button != null:
			return button
	return null


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)
