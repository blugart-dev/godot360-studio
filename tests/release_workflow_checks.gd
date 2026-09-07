extends SceneTree
## Documented calibration, six preview directions, recipes, Motion Lab and diagnostics.
const IO = preload("res://addons/godot360/job_io.gd")
var panel: Control
var checks := 0
var failures := 0
var settings_existed := false
var original_settings := PackedByteArray()
var initialized := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	settings_existed = FileAccess.file_exists("res://.godot360/settings.cfg")
	if settings_existed:
		original_settings = FileAccess.get_file_as_bytes("res://.godot360/settings.cfg")
	initialized = true
	root.size = Vector2i(1400, 600)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	panel = preload("res://addons/godot360/studio_panel.gd").new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.sections.recipes.toggle.button_pressed = true
	_button("Calibration defaults").pressed.emit()
	_button("Draft · 2K").pressed.emit()
	panel.ffmpeg.text = IO.argument("ffmpeg")
	panel.ffprobe.text = IO.argument("ffprobe")
	panel.output.text = ProjectSettings.globalize_path("res://.godot360/release-workflow")
	check(panel.profile.width == "2048" and panel.profile.face_size == 512 and panel.profile.scene_path.ends_with("calibration.tscn"), "Documented calibration and Draft buttons select the expected recipe")
	panel.test_button.pressed.emit()
	await _wait_job()
	check(_delivered(panel.folder), "Documented 2K calibration sample passes all thirteen delivery checks")
	var calibration_folder: String = panel.folder
	check(panel.recent_exports.paths[0] == calibration_folder and panel.recent_exports.picker.get_item_text(0).contains("Test · Complete"), "An actual completed sample appears in recent exports")
	check(panel.planning_label.text.contains("Estimated export:"), "Calibration sample provides an export estimate")
	check(panel.preview_material != null, "Installed addon displays its spherical still preview")
	if panel.preview_material == null:
		_finish()
		return
	var angles := [Vector2.ZERO, Vector2(PI / 2, 0), Vector2(PI, 0), Vector2(-PI / 2, 0), Vector2(0, PI * 0.49), Vector2(0, -PI * 0.49)]
	var names := ["front", "right", "back", "left", "up", "down"]
	var signatures := {}
	for index in range(angles.size()):
		var motion := InputEventMouseMotion.new()
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.relative = Vector2((panel.heading.x - angles[index].x) / 0.006, (angles[index].y - panel.heading.y) / 0.006)
		panel.preview.gui_input.emit(motion)
		await process_frame
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		var view := screenshot.get_region(Rect2i(panel.preview.get_global_rect()))
		var saved := view.save_png("res://.godot360/release-preview-" + names[index] + ".png")
		signatures[preload("res://addons/godot360/diagnostics.gd")._hash(view.get_data())] = true
		check(panel.heading.distance_to(angles[index]) < 0.001 and saved == OK, "Preview drag reaches and renders " + names[index])
	check(signatures.size() == 6, "Six preview directions produce distinct rendered views")
	panel.sections.jobs.toggle.button_pressed = true
	panel._browse("diagnostics")
	var dialog: FileDialog = panel.get_child(panel.get_child_count() - 1)
	check(dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE and dialog.access == FileDialog.ACCESS_FILESYSTEM and dialog.current_file.ends_with(".zip"), "Diagnostics action opens a ZIP save dialog")
	var status_before: String = panel.status.text
	var recipe_before: Dictionary = panel.profile.to_dictionary()
	var selected_before: String = panel.folder
	var bundle := ProjectSettings.globalize_path("res://.godot360/release-completed-diagnostics.zip")
	dialog.file_selected.emit(bundle)
	await process_frame
	check(FileAccess.file_exists(bundle) and panel.diagnostics_result.text.contains("Diagnostics saved:"), "Save dialog produces a completed-job support bundle")
	check(panel.status.text == status_before and panel.profile.to_dictionary() == recipe_before and panel.folder == selected_before, "Diagnostics keeps selected job, status and recipe unchanged")
	var reader := ZIPReader.new()
	reader.open(bundle)
	check(JSON.parse_string(reader.read_file("job/report.json").get_string_from_utf8()).get("ok", false), "Saved bundle contains the real successful export report")
	var environment = JSON.parse_string(reader.read_file("environment.json").get_string_from_utf8())
	check(environment.get("renderer") == RenderingServer.get_current_rendering_method() and not str(environment.get("video_adapter", "")).is_empty(), "Panel diagnostics records actual renderer and GPU")
	reader.close()
	panel._save_diagnostics(bundle)
	check(panel.diagnostics_result.text.contains("already exists") and panel.status.text == status_before, "Failed diagnostics save leaves job completion visible")
	_button("Motion lab").pressed.emit()
	check(panel.profile.duration == 6.0 and panel.profile.scene_path.ends_with("timeline.tscn"), "Installed Motion Lab provides its six-second authored recipe")
	# A low-resolution workflow check; the separately recorded 4K/8K evidence remains unchanged.
	panel.recipe_fields.width.text = "512"
	panel.recipe_fields.face_size.text = "256"
	var recipe := ProjectSettings.globalize_path("res://.godot360/release-recipe.tres")
	panel._selected("save", recipe)
	_button("Calibration defaults").pressed.emit()
	panel._selected("load", recipe)
	check(panel.profile.scene_path.ends_with("timeline.tscn") and panel.profile.width == "512" and panel.profile.duration == 6, "Saved portable recipe restores scene and duration")
	panel.test_button.pressed.emit()
	await _wait_job()
	check(_delivered(panel.folder) and panel.active_job.frames == 30 and panel.profile.duration == 6, "Motion Lab sample preserves the full authored duration")
	panel.render_button.pressed.emit()
	await _wait_job()
	check(_delivered(panel.folder) and panel.active_job.frames == 180, "Installed Motion Lab completes the full six-second workflow")
	check(IO.read_json(panel.folder.path_join("capture-settings.json")).get("timeline_sampling") == "frame_index / fps", "Packaged scene uses the absolute-frame authoring hook")
	panel._save_diagnostics(ProjectSettings.globalize_path("res://.godot360/release-motion-diagnostics.zip"))
	check(panel.diagnostics_result.text.contains("Diagnostics saved:"), "Full authored export also produces a diagnostics bundle")
	var delivery_hash := FileAccess.get_sha256(panel.folder.path_join("video-360.mp4"))
	panel.playback.play_button.pressed.emit()
	var playback_deadline := Time.get_ticks_msec() + 120000
	while not panel.playback.phase.is_empty() and Time.get_ticks_msec() < playback_deadline:
		await create_timer(0.1).timeout
	check(not panel.playback.proxy_path.is_empty() and panel.playback.last_error.is_empty(), "The actual verified Motion Lab export opens in native spherical playback")
	check(FileAccess.get_sha256(panel.folder.path_join("video-360.mp4")) == delivery_hash, "Native playback preserves the verified delivery MP4")
	panel.playback.player.paused = true
	var motion_folder: String = panel.folder
	panel._open_job(calibration_folder)
	panel.recent_exports.picker.select(panel.recent_exports.paths.find(motion_folder))
	panel.recent_exports.picker.item_selected.emit(panel.recent_exports.picker.selected)
	panel.recent_exports.open_button.pressed.emit()
	check(panel.folder == motion_folder and panel.recent_exports.paths[0] == motion_folder and panel.status.text.begins_with("Complete"), "Recent exports reopens the actual Motion Lab delivery after reviewing another job")
	panel.playback.play_button.pressed.emit()
	check(panel.playback.proxy_path != "" and panel.playback.phase.is_empty(), "A delivery reopened from history reuses its native playback cache")
	panel.playback.player.paused = true
	var scroll: ScrollContainer = panel.get_child(0).get_child(0)
	scroll.scroll_vertical = 385
	await process_frame
	await RenderingServer.frame_post_draw
	check(panel.size.y <= root.size.y and panel.size.x <= root.size.x, "New controls fit within the compact scrolling panel")
	root.get_texture().get_image().save_png("res://.godot360/release-panel.png")
	_finish()


func _delivered(folder: String) -> bool:
	var report := IO.read_json(folder.path_join("report.json"))
	return report.get("ok", false) and report.get("checks", {}).size() == 13 and not report.get("checks", {}).values().has(false) and FileAccess.file_exists(folder.path_join("video-360.mp4"))


func _wait_job() -> void:
	check(panel.process_id > 0, "Workflow button launches its job")
	var deadline := Time.get_ticks_msec() + 120000
	while panel.process_id > 0 and Time.get_ticks_msec() < deadline:
		await create_timer(0.2).timeout
	if panel.process_id > 0:
		panel._cancel()
		while panel.process_id > 0 and Time.get_ticks_msec() < deadline + 10000:
			await create_timer(0.2).timeout
		check(false, "Workflow job finishes within two minutes")


func _button(title: String, node: Node = null) -> Button:
	if node == null:
		node = panel
	if node is Button and node.text == title:
		return node
	for child in node.get_children():
		var found := _button(title, child)
		if found != null:
			return found
	return null


func _finish() -> void:
	print("RELEASE WORKFLOW CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _finalize() -> void:
	if initialized:
		if settings_existed:
			FileAccess.open("res://.godot360/settings.cfg", FileAccess.WRITE).store_buffer(original_settings)
		elif FileAccess.file_exists("res://.godot360/settings.cfg"):
			DirAccess.remove_absolute("res://.godot360/settings.cfg")


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
