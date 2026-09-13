extends SceneTree
## Actual panel audio controls, persistence, one-second capture and re-encode.
const IO = preload("res://addons/godot360/job_io.gd")
const Audio = preload("res://addons/godot360/audio_plan.gd")
var panel: Control
var original_settings := PackedByteArray()
var settings_existed := false
var restore_settings := false
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	settings_existed = FileAccess.file_exists("res://.godot360/settings.cfg")
	if settings_existed:
		original_settings = FileAccess.get_file_as_bytes("res://.godot360/settings.cfg")
	restore_settings = true
	root.size = Vector2i(1400, 600)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	panel = preload("res://addons/godot360/studio_panel.gd").new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.profile = preload("res://addons/godot360/export_profile.gd").new()
	panel.profile.width = "512"
	panel.profile.face_size = 128
	panel.profile.duration = 1.5
	panel._refresh_fields()
	check(panel.audio_mode_control.selected == 0 and not panel.soundtrack_field.editable and panel.audio_controls.scene_audio_offset_seconds.editable, "Scene mode enables only scene audio controls")
	panel._selected("soundtrack", IO.argument("soundtrack"))
	check(panel.audio_mode_control.selected == 1 and panel.soundtrack_field.editable and not panel.audio_controls.scene_audio_offset_seconds.editable, "Choosing a soundtrack selects replacement mode and its controls")
	panel.audio_mode_control.select(2)
	panel.audio_mode_control.item_selected.emit(2)
	panel.audio_controls.soundtrack_offset_seconds.value = 0.125
	panel.audio_controls.soundtrack_gain_db.value = -6.0
	panel.audio_controls.scene_audio_offset_seconds.value = -0.05
	panel._update_profile()
	check(panel.profile.audio_mode == "mix" and is_equal_approx(panel.profile.soundtrack_offset_seconds, 0.125) and is_equal_approx(panel.profile.scene_audio_offset_seconds, -0.05), "Mix mode serializes independent scene and soundtrack timing")
	var recipe_path := ProjectSettings.globalize_path("res://.godot360/audio-panel-recipe.tres")
	panel._selected("save", recipe_path)
	panel.profile = preload("res://addons/godot360/export_profile.gd").new()
	panel._refresh_fields()
	panel._selected("load", recipe_path)
	check(panel.audio_mode_control.selected == 2 and panel.audio_controls.soundtrack_gain_db.value == -6.0, "Recipe loading restores audio controls")
	panel._save_settings()
	panel.profile.audio_mode = "scene"
	panel.profile.soundtrack_path = ""
	panel._refresh_fields()
	panel._load_settings()
	check(panel.audio_mode_control.selected == 2 and panel.audio_controls.soundtrack_offset_seconds.value == 0.125, "Local settings restore the audio selection and offsets")
	panel.ffmpeg.text = IO.argument("ffmpeg")
	panel.ffprobe.text = IO.argument("ffprobe")
	panel.output.text = ProjectSettings.globalize_path("res://renders/audio-studio-06")
	panel._test_render()
	check(panel.process_id > 0 and panel.active_job.audio_mode == "mix" and panel.active_job.frames == 30, "Test render carries audio settings into the real pipeline")
	await _wait_job()
	var source: String = panel.folder
	var report := IO.read_json(source.path_join("report.json"))
	check(report.get("ok", false) and report.get("checks", {}).size() == 13, "Actual captured sample passes all thirteen output checks")
	check(panel.planning_label.text.contains("Estimated export:"), "Audio sample produces a planning estimate")
	panel.audio_controls.soundtrack_gain_db.value = -8.0
	panel._refresh_plan()
	check(panel.planning_label.text.contains("changed"), "Changing audio makes the estimate stale")
	var before := _snapshot(source)
	panel.audio_controls.soundtrack_offset_seconds.value = -0.125
	panel._reencode(source)
	check(panel.process_id > 0 and panel.active_job.soundtrack_offset_seconds == -0.125 and panel.active_job.width == 512, "Re-encode applies current audio while preserving captured video settings")
	await _wait_job()
	var final_report := IO.read_json(panel.folder.path_join("report.json"))
	check(final_report.get("ok", false) and final_report.get("audio", {}).get("settings", {}).get("soundtrack_gain_db", 0) == -8, "Panel re-encode completes with requested audio levels")
	check(before == _snapshot(source), "Panel re-encode preserves every file in the original capture")
	# Review the audio controls in their current recipe tab, after layout settles.
	panel.workspace_tabs.current_tab = 0
	panel.sections.audio.toggle.button_pressed = true
	var scroll := panel.workspace_tabs.get_current_tab_control() as ScrollContainer
	await process_frame
	await process_frame
	scroll.ensure_control_visible(panel.audio_controls.soundtrack_gain_db)
	await process_frame
	await RenderingServer.frame_post_draw
	check(panel.size.y <= root.size.y, "Audio controls fit within a scrolling bottom panel")
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://.godot360/audio-panel-06.png"))
	print("AUDIO STUDIO SOURCE: " + source)
	print("AUDIO STUDIO OUTPUT: " + panel.folder)
	# A failed encode can reuse the completed capture. The panel must point to
	# that original folder, not the failed re-encode's empty output directory.
	panel.ffmpeg.text = ProjectSettings.globalize_path("res://.godot360/missing-ffmpeg.exe")
	panel._reencode(source)
	await _wait_job()
	var recovery := IO.read_json(panel.folder.path_join("recovery.json"))
	check(recovery.get("can_reencode", false) and recovery.get("source_dir") == source, "Failed re-encode identifies the reusable original capture")
	check(panel.status.text.contains("Re-encode saved"), "Panel shows the recovery action after failure")
	check(before == _snapshot(source) and not FileAccess.file_exists(panel.folder.path_join("video-360.mp4")), "Failed re-encode preserves source files and publishes no video")
	var failure_before := _snapshot(panel.folder)
	var failure_status: String = panel.status.text
	var bundle := ProjectSettings.globalize_path("res://.godot360/audio-failure-diagnostics.zip")
	panel._selected("diagnostics", bundle)
	check(FileAccess.file_exists(bundle) and panel.diagnostics_result.text.contains("Diagnostics saved:"), "Failed panel job can save a diagnostics bundle")
	var reader := ZIPReader.new()
	reader.open(bundle)
	check(JSON.parse_string(reader.read_file("job/status.json").get_string_from_utf8()).get("stage") == "Failed" and reader.file_exists("job/recovery.json"), "Failure bundle retains terminal status and recovery guidance")
	reader.close()
	check(panel.status.text == failure_status and failure_before == _snapshot(panel.folder) and before == _snapshot(source), "Diagnostics preserves failed-job state and original capture bytes")
	print("AUDIO STUDIO CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _wait_job() -> void:
	var started := Time.get_ticks_msec()
	while panel.process_id > 0 and Time.get_ticks_msec() - started < 90000:
		await create_timer(0.2).timeout
	if panel.process_id > 0:
		panel._cancel()
		check(false, "Audio studio job must finish within 90 seconds")
		while panel.process_id > 0 and Time.get_ticks_msec() - started < 100000:
			await create_timer(0.2).timeout


func _snapshot(folder: String) -> Dictionary:
	var result := {}
	for file in DirAccess.get_files_at(folder):
		result[file] = FileAccess.get_sha256(folder.path_join(file))
	for directory in DirAccess.get_directories_at(folder):
		result[directory] = _snapshot(folder.path_join(directory))
	return result


func _finalize() -> void:
	if restore_settings:
		if settings_existed:
			FileAccess.open("res://.godot360/settings.cfg", FileAccess.WRITE).store_buffer(original_settings)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path("res://.godot360/settings.cfg"))


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
