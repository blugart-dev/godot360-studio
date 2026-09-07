extends SceneTree
## History persistence, stale filesystem state and existing panel coordination.
const Recent = preload("res://addons/godot360/recent_exports.gd")
const IO = preload("res://addons/godot360/job_io.gd")
const SETTINGS := "res://.godot360/settings.cfg"
var checks := 0
var failures := 0
var initialized := false
var settings_existed := false
var original_settings := PackedByteArray()
var fixture := ""
var opened := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	settings_existed = FileAccess.file_exists(SETTINGS)
	if settings_existed:
		original_settings = FileAccess.get_file_as_bytes(SETTINGS)
	initialized = true
	fixture = ProjectSettings.globalize_path("res://.godot360/recent-" + str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(fixture)
	var complete := _job("Export with spaces ñ", "render", "Complete")
	var failed := _job("failed", "test", "Failed")
	var cancelled := _job("cancelled", "reencode", "Cancelled")
	var stale := _job("stale", "render", "Rendering")
	var missing := fixture.path_join("moved-away")
	var invalid := fixture.path_join("invalid")
	DirAccess.make_dir_recursive_absolute(invalid)
	IO.write_text(invalid.path_join("job.json"), "[]")
	var recent := Recent.new()
	root.add_child(recent)
	recent.open_requested.connect(func(path: String): opened = path)
	check(recent.open_button.disabled and recent.forget_button.disabled, "Empty history has no open or forget action")
	recent.restore([complete, 12, null, "relative/path", complete + "/../" + complete.get_file() + "/", failed, missing])
	check(recent.paths == [complete, failed, missing], "Restored history filters malformed entries and deduplicates normalized paths")
	if OS.get_name() == "Windows":
		recent.remember(complete.to_upper().replace("/", "\\"))
		check(recent.paths.size() == 3, "Windows slash and case variants do not duplicate an export")
	recent.restore({"bad": complete})
	check(recent.paths.is_empty(), "A malformed history container is ignored")
	for index in range(15):
		recent.remember(fixture.path_join(str(index)))
	check(recent.paths.size() == 12 and recent.paths[0].ends_with("/14") and recent.paths[-1].ends_with("/3"), "History retains the twelve most recently used folders")
	recent.remember(recent.paths[-1])
	check(recent.paths.size() == 12 and recent.paths[0].ends_with("/3"), "Reopening an older entry promotes it without duplication")
	check(Recent.describe(complete).state == "Render · Complete", "Successful report plus delivery establishes completion")
	check(Recent.describe(failed).state == "Test · Failed" and Recent.describe(cancelled).state == "Re-encode · Cancelled", "Test, re-encode and terminal states are distinguished")
	check(Recent.describe(stale).state.contains("Unconfirmed") and Recent.describe(stale).details.contains("Open to check"), "Saved progress never claims that a coordinator is still running")
	check(not DirAccess.dir_exists_absolute(stale.path_join("control")), "Listing an unconfirmed job does not contact its coordinator")
	check(not Recent.describe(missing).can_open and Recent.describe(missing).state == "Unavailable", "Moved or offline folders remain identifiable and cannot be opened")
	check(not Recent.describe(invalid).can_open, "Non-object job metadata disables opening")
	IO.write_text(invalid.path_join("job.json"), "{" + " ".repeat(Recent.MAX_METADATA_BYTES))
	check(not Recent.describe(invalid).can_open, "Oversized metadata is rejected before parsing")
	IO.write_json(invalid.path_join("job.json"), {"mode": {}, "fps": [], "width": "wide", "scene_path": 1})
	IO.write_json(invalid.path_join("status.json"), {"stage": {}})
	IO.write_json(invalid.path_join("report.json"), {"ok": {}})
	check(Recent.describe(invalid).state == "Render · Unconfirmed · Unknown", "Unexpected metadata field types cannot break the history list")
	DirAccess.remove_absolute(complete.path_join("report.json"))
	check(Recent.describe(complete).state.ends_with("Incomplete delivery"), "A Complete status without a successful report is not labeled complete")
	IO.write_json(complete.path_join("report.json"), {"ok": true})
	DirAccess.remove_absolute(complete.path_join("video-360.mp4"))
	check(Recent.describe(complete).state.ends_with("Incomplete delivery"), "A successful report without delivery is not labeled complete")
	IO.write_text(complete.path_join("video-360.mp4"), "metadata fixture, not playable media")
	IO.write_json(complete.path_join("status.json"), {"stage": "Rendering"})
	check(Recent.describe(complete).state.ends_with("Complete"), "Delivery evidence overrides stale saved progress")
	check(Recent.describe(complete).details.contains("512×256 · 30 FPS · 1 s"), "Selected exports show their scene and video settings")
	recent.restore([missing, complete, failed])
	recent.picker.select(1)
	recent.picker.item_selected.emit(1)
	check(opened.is_empty() and not recent.open_button.disabled, "Browsing history does not switch the current job")
	recent.refresh()
	check(recent.picker.get_selected_metadata() == complete, "Metadata refresh preserves the user's selection")
	recent.set_busy(true)
	recent.open_button.pressed.emit()
	recent.forget_button.pressed.emit()
	check(opened.is_empty() and recent.paths.size() == 3 and recent.picker.disabled, "Active jobs block history opening and forgetting, including direct signals")
	recent.set_busy(false)
	recent.open_button.pressed.emit()
	check(opened == complete, "Open sends the exact selected folder, including spaces and Unicode")
	opened = ""
	recent.remember(failed)
	DirAccess.remove_absolute(failed.path_join("job.json"))
	recent.open_button.pressed.emit()
	check(opened.is_empty() and recent.open_button.disabled, "Open rechecks a job removed after it was listed")
	recent.free()

	# Exercise real panel persistence and existing reopen/recovery boundaries.
	var config := ConfigFile.new()
	config.set_value("export", "last_folder", complete)
	config.set_value("recipe", "duration", "12")
	config.save(SETTINGS)
	root.size = Vector2i(1100, 600)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	var panel = preload("res://addons/godot360/studio_panel.gd").new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check(panel.recent_exports.paths == [complete], "Legacy last-folder settings migrate into recent exports")
	check(panel.folder == complete and panel.status.text.begins_with("Complete"), "Restored history retains the existing completed-job reopen behavior")
	var recipe_before: Dictionary = panel.profile.to_dictionary()
	panel._open_job(cancelled)
	check(panel.recent_exports.paths == [cancelled, complete] and panel.folder == cancelled, "Opening a saved job persists it at the front of history")
	panel.recent_exports.picker.select(1)
	panel.recent_exports.picker.item_selected.emit(1)
	panel.recent_exports.open_button.pressed.emit()
	check(panel.folder == complete and panel.profile.to_dictionary() == recipe_before and panel.recipe_fields.duration.text == "12", "History opening uses normal job review and preserves recipe controls")
	panel.pending_session = {"test": true}
	panel._set_busy(true)
	panel._open_job(cancelled)
	check(panel.folder == complete and panel.recent_exports.open_button.disabled, "An in-progress identity challenge prevents switching jobs")
	panel.pending_session = {}
	panel._set_busy(false)
	var media_hash := FileAccess.get_sha256(complete.path_join("video-360.mp4"))
	panel.recent_exports.forget_button.pressed.emit()
	check(panel.folder == complete and not complete in panel.recent_exports.paths and FileAccess.get_sha256(complete.path_join("video-360.mp4")) == media_hash, "Forgetting the current entry preserves selected job and media bytes")
	config.load(SETTINGS)
	check(config.get_value("export", "recent_folders") == [cancelled], "Forget is saved to project-local settings immediately")
	panel.free()
	panel = preload("res://addons/godot360/studio_panel.gd").new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check(panel.folder == complete and panel.recent_exports.paths == [cancelled], "Restart restores the last job without resurrecting a forgotten entry")
	panel.recent_exports.forget_button.pressed.emit()
	panel.free()
	panel = preload("res://addons/godot360/studio_panel.gd").new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check(panel.recent_exports.paths.is_empty(), "An explicitly empty history stays empty after restart")
	panel.recent_exports.remember(missing)
	panel.recent_exports.remember(complete)
	panel.sections.recent.toggle.button_pressed = true
	await process_frame
	await process_frame
	check(panel.size.x <= root.size.x and panel.size.y <= root.size.y, "Expanded recent exports fit the 1100 by 600 panel")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(fixture.path_join("recent-panel.png"))
	panel.free()
	print("RECENT EXPORTS CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _job(name: String, mode: String, stage: String) -> String:
	var path := fixture.path_join(name)
	DirAccess.make_dir_recursive_absolute(path)
	IO.write_json(path.path_join("job.json"), {"mode": mode, "scene_path": "res://addons/godot360/examples/calibration.tscn", "width": 512, "height": 256, "fps": 30, "duration": 1})
	IO.write_json(path.path_join("status.json"), {"stage": stage})
	if stage == "Complete":
		IO.write_json(path.path_join("report.json"), {"ok": true})
		IO.write_text(path.path_join("video-360.mp4"), "metadata fixture, not playable media")
	return path


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + message)


func _finalize() -> void:
	if not initialized:
		return
	if settings_existed:
		FileAccess.open(SETTINGS, FileAccess.WRITE).store_buffer(original_settings)
	elif FileAccess.file_exists(SETTINGS):
		DirAccess.remove_absolute(SETTINGS)
