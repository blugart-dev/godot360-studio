extends SceneTree
## Native panel integration and screenshots in a disposable review project.
## This drives controls and input events; it is not a human click-through.
const IO = preload("res://addons/godot360/job_io.gd")
var panel: Control
var checks := 0
var failures := 0
var evidence := "res://.godot360/ui-evidence"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if ProjectSettings.get_setting("application/config/name") != "Godot360 UI review":
		push_error("Use a disposable Godot360 UI review project.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(evidence)
	root.size = Vector2i(1100, 600)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	var margin := MarginContainer.new()
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 12)
	panel = preload("res://addons/godot360/studio_panel.gd").new()
	margin.add_child(panel)
	panel.workspace_tabs.current_tab = 0
	panel._selected("scene", "res://missing-scene.tscn")
	await _shot("empty-1100")
	check(panel.delivery_button.disabled and panel.playback.play_button.disabled, "Empty review cannot open or play a nonexistent delivery")
	panel.ffmpeg.text = IO.argument("ffmpeg")
	panel._selected("ffprobe", IO.argument("ffprobe"))
	var selected: Array = [panel.ffmpeg.text, panel.ffprobe.text]
	panel._detect_tools()
	check(selected == [panel.ffmpeg.text, panel.ffprobe.text], "Explicit discovery preserves the deliberately selected executable pair")
	panel._selected("ffprobe", ProjectSettings.globalize_path("res://chosen-but-offline/ffprobe.exe"))
	var missing: String = panel.ffprobe.text
	panel._selected("ffmpeg", IO.argument("ffmpeg"))
	panel._detect_tools()
	check(panel.ffprobe.text == missing, "Discovery and choosing FFmpeg preserve an unavailable deliberate FFprobe path")
	panel._load_settings()
	check(panel.ffprobe.text == missing and panel.ffprobe_deliberate, "Deliberate tools are saved immediately and survive settings reload")
	panel.ffprobe.text = ""
	panel.ffprobe.text_changed.emit("")
	panel._selected("ffmpeg", IO.argument("ffmpeg"))
	check(panel.ffprobe.text.replace("\\", "/") == IO.argument("ffprobe").replace("\\", "/"), "Clearing FFprobe permits sibling discovery again")
	panel._selected("scene", "res://addons/godot360/examples/calibration.tscn")
	panel.profile.apply_quality_preset("draft")
	panel._refresh_fields()
	panel.recipe_fields.duration.text = "3"
	panel.output.text = ProjectSettings.globalize_path("res://renders")
	await panel._check_readiness()
	check(panel.tool_summary.text.contains("FFmpeg ·") and panel.tool_summary.text.contains("FFprobe ·") and panel.tool_result.get("playback", false), "Setup identifies real tool versions and separate playback capabilities")
	check(not panel.tool_logs_button.disabled, "Detailed tool logs remain accessible")
	panel.workspace_tabs.current_tab = 1
	panel.sections.tools.toggle.button_pressed = true
	await _shot("tools-1100")
	panel.workspace_tabs.current_tab = 0
	await _shot("ready-1100")
	check(panel.preview.size.y >= 250 and panel.size.x <= root.size.x and panel.size.y <= root.size.y, "Ready 1100×600 panel retains at least 250 pixels of preview height without overflow")
	panel.test_button.pressed.emit()
	check(panel.readiness_summary.text.begins_with("Export running"), "Launch updates recipe action state immediately without waiting for the periodic refresh")
	await create_timer(0.8).timeout
	await _shot("running-1100")
	check(panel.render_button.disabled and panel.cancel_button.visible, "An active sample disables another launch and exposes cancellation beside export progress")
	await _wait_job()
	check(not panel.readiness_summary.text.begins_with("Export running"), "Completion removes the running message in the same state transition")
	check(IO.read_json(panel.folder.path_join("report.json")).get("ok", false), "Native one-second capture delivers verified spherical MP4 and audio")
	check(panel.profile.duration == 3.0 and panel.export_summary.text.contains("1 s"), "One-second sample metadata is distinct from the editable three-second recipe")
	var source: String = panel.folder
	var delivery_hash := FileAccess.get_sha256(source.path_join("video-360.mp4"))
	var saved_summary: String = panel.export_summary.text
	panel.recipe_fields.duration.text = "8"
	panel._refresh_plan()
	check(panel.export_summary.text == saved_summary and panel.profile.duration == 8.0, "Editing the next duration does not relabel the opened export")
	check(panel.status.text.begins_with("Test complete") and panel.readiness_summary.text.begins_with("Ready"), "Export completion and recipe readiness coexist without replacing each other")
	var complete_status: String = panel.status.text
	panel._selected("load", "res://addons/godot360/examples/timeline.tres")
	check(panel.status.text == complete_status and panel.export_summary.text == saved_summary, "Loading a different scene recipe preserves the opened sample's status and metadata")
	panel._selected("scene", "res://addons/godot360/examples/calibration.tscn")
	panel.profile.apply_quality_preset("draft")
	panel._refresh_fields()
	panel.recipe_fields.duration.text = "8"
	panel._refresh_plan()
	panel._open_job("res://no-such-export")
	check(panel.status.text == complete_status and panel.folder == source, "An invalid Open displays its own error without replacing the prior export state")
	panel.get_child(panel.get_child_count() - 1).queue_free()
	await process_frame
	panel._show_export_details()
	await _shot("details-1100")
	panel.get_child(panel.get_child_count() - 1).queue_free()
	await _shot("completed-1100")
	panel.preview.grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_RIGHT
	key.pressed = true
	panel.preview.gui_input.emit(key)
	check(panel.heading.x > 0 and panel.preview_focus.visible, "Focused sphere exposes focus and supports keyboard look")
	key.keycode = KEY_HOME
	panel.preview.gui_input.emit(key)
	check(panel.heading == Vector2.ZERO, "Home resets the spherical view")
	panel.playback.toggle()
	while not panel.playback.phase.is_empty():
		await create_timer(0.1).timeout
	check(panel.playback.last_error.is_empty() and not panel.playback.proxy_path.is_empty(), "Actual export prepares a fully decoded playback copy")
	panel.playback.player.paused = true
	panel._review_still()
	check(panel.preview_kind.text.begins_with("Full-resolution still"), "Show still returns to the original opening frame")
	panel.playback.toggle()
	check(panel.preview_kind.text.begins_with("Playback copy"), "Playing again restores the video texture after inspecting the still")
	panel.playback.player.paused = true
	panel.playback._fail("Playback copy contains decoding errors. Delivery MP4 is unchanged. Select another FFmpeg build in Tool setup, Check setup, then Retry playback.")
	await _shot("playback-failed-1100")
	check(not panel.delivery_button.disabled and panel.status.text.begins_with("Test complete") and panel.playback.error_actions.visible, "Playback failure preserves verified delivery actions and supplies separate recovery controls")
	panel.workspace_tabs.current_tab = 2
	check(panel.recent_exports.details.text.contains("1 s"), "Recent exports derives the actual duration from frame count and FPS")
	await _shot("library-1100")
	panel._open_job(source)
	check(panel.profile.duration == 8.0 and panel.export_summary.text == saved_summary, "Reopening an export preserves the current editable recipe")
	check(FileAccess.get_sha256(source.path_join("video-360.mp4")) == delivery_hash, "Playback and reopening leave the delivery bytes unchanged")
	panel.workspace_tabs.current_tab = 0
	root.size = Vector2i(1440, 900)
	root.content_scale_size = root.size
	await _shot("completed-1440")
	root.content_scale_factor = 1.25
	await _shot("scaled-125-percent")
	check(panel.get_global_rect().end.x <= root.size.x / 1.25 + 1 and panel.get_global_rect().end.y <= root.size.y / 1.25 + 1, "125% window scaling keeps the panel within its usable viewport")
	root.content_scale_factor = 1.0
	root.size = Vector2i(1100, 600)
	root.content_scale_size = root.size
	panel.recipe_fields.duration.text = "90"
	panel.render_button.pressed.emit()
	await create_timer(1.0).timeout
	panel.cancel_button.pressed.emit()
	await _shot("cancelling-1100")
	await _wait_job()
	check(IO.read_json(panel.folder.path_join("status.json")).get("stage") == "Cancelled", "Cancellation of a native capture reaches the retained terminal state")
	await _shot("cancelled-1100")
	panel._open_job(source)
	panel._reencode(source)
	await _wait_job()
	check(IO.read_json(panel.folder.path_join("report.json")).get("ok", false) and not DirAccess.dir_exists_absolute(panel.folder.path_join("frames")), "Re-encoding produces a new verified delivery without capturing again")
	check(FileAccess.get_sha256(source.path_join("video-360.mp4")) == delivery_hash, "Re-encoding preserves the original delivery")
	var failed := ProjectSettings.globalize_path(evidence.path_join("failed-job"))
	DirAccess.make_dir_recursive_absolute(failed)
	IO.write_json(failed.path_join("job.json"), IO.read_json(source.path_join("job.json")))
	IO.write_json(failed.path_join("status.json"), {"stage": "Failed", "progress": 0.5, "error": "Capture stopped: output drive is unavailable. Reconnect it and render again."})
	panel._open_job(failed)
	await _shot("export-failed-1100")
	check(panel.delivery_button.disabled and panel.playback.play_button.disabled, "Failed capture cannot expose delivery or playback from the preceding export")
	IO.write_json(evidence.path_join("result.json"), {"checks": checks, "failures": failures, "source": source, "delivery_sha256": delivery_hash, "kind": "Native automated integration; failed-job and playback-error screenshots are controlled states"})
	print("UI WORKFLOW CHECKS: %d checks, %d failures" % [checks, failures])
	panel.free()
	quit(0 if failures == 0 else 1)


func _wait_job() -> void:
	var start := Time.get_ticks_msec()
	while panel.process_id > 0 or not panel.pending_session.is_empty():
		if Time.get_ticks_msec() - start > 180000:
			panel._cancel()
			check(false, "Job completes within three minutes")
			break
		await create_timer(0.2).timeout


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(name + ".png"))


func check(ok: bool, description: String) -> bool:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + description)
	if not ok:
		failures += 1
	return ok
