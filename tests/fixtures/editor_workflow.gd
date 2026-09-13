@tool
extends EditorPlugin
## Native-editor integration driver in a disposable prepare_walkthrough project.
## Signals exercise the real panel; this is not a human click-through review.
const IO = preload("res://addons/godot360/job_io.gd")
var panel: Control
var checks: Dictionary = {}
var evidence: Dictionary = {}
var phase := ""
var deadline := 0


func _enter_tree() -> void:
	if ProjectSettings.get_setting("application/config/name") != "Godot360 clean walkthrough":
		push_error("Use only the disposable clean walkthrough project.")
		return
	phase = IO.argument("review-phase")
	# Opening retained evidence normally must not launch another test sequence.
	if not phase in ["first", "reopen"]:
		return
	deadline = Time.get_ticks_msec() + 600000
	_run.call_deferred()


func _process(_delta: float) -> void:
	if deadline > 0 and Time.get_ticks_msec() > deadline:
		deadline = 0
		if panel != null and panel.process_id > 0:
			panel._cancel()
		check(false, "Editor workflow completed within ten minutes")
		_finish()


func _run() -> void:
	for i in range(30):
		await get_tree().process_frame
	while EditorInterface.get_resource_filesystem().is_scanning():
		await get_tree().process_frame
	var panels := EditorInterface.get_base_control().find_children("Godot360", "Control", true, false)
	check(panels.size() == 1, "Packaged plugin creates one panel in the native editor")
	if panels.size() != 1:
		_finish()
		return
	panel = panels[0]
	DirAccess.make_dir_recursive_absolute("res://.godot360/editor-review")
	make_bottom_panel_item_visible(panel)
	await _help()
	if phase == "first":
		await _first()
	else:
		await _reopen()
	_finish()


func _help() -> void:
	var before: Dictionary = panel.profile.to_dictionary()
	panel._show_help("setup")
	var dialog = panel.help_dialog
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	dialog.get_texture().get_image().save_png("res://.godot360/editor-review/help-" + phase + ".png")
	check(dialog.visible and dialog.body.selection_enabled and dialog.download_button.visible, "Native editor displays selectable offline setup help and its download-page action")
	dialog.setup_button.pressed.emit()
	check(not dialog.visible and panel.workspace_tabs.current_tab == 1 and panel.ffmpeg.has_focus(), "Native editor help returns keyboard focus to Tool setup")
	panel._show_help("files")
	await get_tree().process_frame
	await get_tree().process_frame
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	escape.window_id = dialog.get_window_id()
	# Native dialog close shortcuts are handled before Viewport.push_input.
	Input.parse_input_event(escape)
	await get_tree().process_frame
	escape.pressed = false
	Input.parse_input_event(escape)
	check(not dialog.visible, "Escape dismisses native help")
	dialog.hide() # Leave later checks independent if keyboard dismissal regresses.
	check(panel.profile.to_dictionary() == before, "Native help preserves the recipe across editor sessions")
	panel.workspace_tabs.current_tab = 0


func _first() -> void:
	check(not FileAccess.file_exists("res://.godot360/settings.cfg"), "Addon starts without saved settings")
	EditorInterface.open_scene_from_path("res://room.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	var scene := EditorInterface.get_edited_scene_root()
	check(scene != null and scene.scene_file_path == "res://room.tscn", "Ordinary authored scene opens outside the addon")
	if scene == null:
		return
	panel.use_scene_button.pressed.emit()
	check(panel.recipe_fields.scene_path.text == "res://room.tscn" and panel.recipe_fields.camera_path.text == "Camera3D", "Use current scene saves it and discovers its sole camera")
	# Exercise the actual file-dialog callback and sibling FFprobe discovery.
	panel._browse("ffmpeg")
	var dialog: FileDialog = panel.get_child(panel.get_child_count() - 1)
	dialog.file_selected.emit(IO.argument("ffmpeg"))
	await get_tree().process_frame
	check(panel.ffprobe.text.replace("\\", "/") == IO.argument("ffprobe").replace("\\", "/"), "Choosing FFmpeg automatically fills its sibling FFprobe")
	scene.get_node("FRONT").text = "FRONT -Z / SAVED"
	panel.recipe_fields.duration.text = "4"
	panel.output.text = ProjectSettings.globalize_path("res://renders")
	panel.quality_buttons.production.pressed.emit()
	await panel._check_readiness()
	check(panel.readiness_label.text.begins_with("Ready for"), "Native tools, ordinary scene and output pass Check setup")
	# Read serialized bytes without reloading resources owned by the open editor.
	check(FileAccess.get_file_as_string("res://room.tscn").contains('text = "FRONT -Z / SAVED"'), "Check setup saves an unsaved editor scene change")
	panel.test_button.pressed.emit()
	await _wait_job()
	evidence.sample = panel.folder
	check(_delivered(panel.folder), "One-second 4K sample passes all thirteen delivery checks")
	check(FileAccess.file_exists(panel.folder.path_join(".gdignore")), "New sample is excluded from Godot asset import")
	check(float(panel.recipe_fields.duration.text) == 4.0 and panel.profile.duration == 4.0, "Short test preserves the requested full duration")
	check(panel.planning_label.text.contains("Estimated export:"), "Short test displays a usable full-job estimate")
	panel.render_button.pressed.emit()
	await _wait_job()
	evidence.source = panel.folder
	check(_delivered(panel.folder), "Full authored 4K scene export passes all thirteen delivery checks")
	check(IO.read_json(panel.folder.path_join("job.json")).get("frames") == 120, "Full render delivers the requested four seconds")
	check(panel.preview_material != null, "Full export loads the spherical still preview")
	if not _delivered(panel.folder):
		return
	await _views("still")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2.0
	var effect_index := AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0, capture)
	panel.playback.toggle()
	await _wait_playback()
	check(panel.playback.last_error.is_empty() and not panel.playback.proxy_path.is_empty(), "Play video creates and verifies the local Theora/Vorbis copy")
	if not panel.playback.proxy_path.is_empty():
		capture.clear_buffer()
		await get_tree().create_timer(1.2).timeout
		var samples := capture.get_buffer(capture.get_frames_available())
		var peak := Vector2.ZERO
		for sample in samples:
			peak = peak.max(sample.abs())
		evidence.audio_mix_peak = [peak.x, peak.y]
		check(peak.x > 0.01 and peak.y > 0.01, "Native editor video playback sends both stereo channels to the mix bus")
		panel.playback.toggle()
		check(panel.playback.player.paused, "Pause stops native review playback")
		var clock: float = panel.playback.player.stream_position
		await get_tree().create_timer(0.25).timeout
		check(absf(panel.playback.player.stream_position - clock) < 0.05, "Paused review holds its clock")
		var signatures := []
		for second in [0.3, 2.3, 0.3]:
			panel.playback.seek_to(second)
			await get_tree().create_timer(0.35).timeout
			# An idle editor can stop drawing between paused seeks. Explicitly
			# request the evidence frame instead of waiting for unrelated input.
			panel.preview.queue_redraw()
			await RenderingServer.frame_post_draw
			var picture: Image = panel.playback.player.get_video_texture().get_image()
			picture.save_png("res://.godot360/editor-review/seek-%d.png" % signatures.size())
			signatures.append(preload("res://addons/godot360/diagnostics.gd")._hash(picture.get_data()))
		check(signatures[0] != signatures[1], "Forward seek changes the actual decoded authored image")
		check(signatures[0] == signatures[2], "Backward seek restores the same paused decoded image")
		evidence.proxy = panel.playback.proxy_path
		panel.playback.clear()
	AudioServer.remove_bus_effect(0, effect_index)
	panel._open_job(evidence.source)
	panel._save_settings()
	evidence.scene_sha256 = FileAccess.get_sha256("res://room.tscn")
	evidence.source_hashes = _snapshot(evidence.source)


func _reopen() -> void:
	var previous := IO.read_json("res://editor-first.json")
	evidence.source = previous.get("evidence", {}).get("source", "")
	if not check(not str(evidence.source).is_empty(), "First editor session retained a source export"):
		return
	await _wait_job()
	check(panel.folder == evidence.source and panel.status.text.contains("Complete"), "A fresh editor process restores the completed job")
	check(panel.recent_exports.paths.has(evidence.source), "Recent exports survives the editor restart")
	check(not FileAccess.file_exists(str(evidence.source).path_join("preview.png.import")), "Editor restart does not import retained export images")
	check(panel.profile.duration == 4.0 and panel.profile.width == "4096", "Recipe survives the editor restart")
	panel.playback.toggle()
	await _wait_playback()
	check(panel.playback.cache_hit and panel.playback.proxy_path == previous.evidence.proxy, "Restarted editor reuses the verified playback cache")
	panel.playback.clear()
	panel.quality_buttons.draft.pressed.emit()
	panel.recipe_fields.duration.text = "120"
	panel.render_button.pressed.emit()
	await _wait_stage("Rendering", 30000)
	while IO.read_json(panel.folder.path_join("render-progress.json")).get("frame", 0) < 10 and panel.process_id > 0:
		await get_tree().create_timer(0.1).timeout
	panel.cancel_button.pressed.emit()
	await _wait_job()
	evidence.cancelled_capture = panel.folder
	check(IO.read_json(panel.folder.path_join("status.json")).get("stage") == "Cancelled", "Cancel stops a real active capture")
	check(panel.recovery_source.is_empty() and panel.reuse_button.disabled, "Partial capture requires a fresh render")
	panel._open_job(evidence.source)
	panel.reuse_button.pressed.emit()
	await _wait_stage("Encoding H.264 + AAC", 30000)
	# The stage precedes tool/audio preparation, and the saved process PID is
	# refreshed only when FFmpeg emits frame progress. Its MP4 header proves the
	# encoder has started even while frame progress is still buffered.
	var encoder_deadline := Time.get_ticks_msec() + 10000
	var encoder_started := false
	while Time.get_ticks_msec() < encoder_deadline and panel.process_id > 0:
		var encoded := FileAccess.open(panel.folder.path_join("encoded.mp4"), FileAccess.READ)
		encoder_started = encoded != null and encoded.get_length() > 0 and IO.read_json(panel.folder.path_join("status.json")).get("stage") == "Encoding H.264 + AAC"
		if encoded != null:
			encoded.close()
		if encoder_started:
			break
		await get_tree().create_timer(0.05).timeout
	check(encoder_started, "Recovery control reaches the actual encoder")
	panel.cancel_button.pressed.emit()
	await _wait_job()
	evidence.cancelled_encode = panel.folder
	check(IO.read_json(panel.folder.path_join("status.json")).get("stage") == "Cancelled", "Cancel stops an actual re-encode")
	check(panel.recovery_source == evidence.source and not panel.reuse_button.disabled, "Interrupted re-encode offers the original completed capture")
	panel.reuse_button.pressed.emit()
	await _wait_job()
	evidence.recovered = panel.folder
	check(_delivered(panel.folder) and not DirAccess.dir_exists_absolute(panel.folder.path_join("frames")), "Recovery delivers verified video without recapturing")
	panel._save_diagnostics(ProjectSettings.globalize_path("res://recovered-diagnostics.zip"))
	check(FileAccess.file_exists("res://recovered-diagnostics.zip"), "Recovered job exports a diagnostic bundle")
	check(_snapshot(evidence.source) == previous.evidence.source_hashes, "Playback, restart and recovery preserve every original capture file")
	check(FileAccess.get_sha256("res://room.tscn") == previous.evidence.scene_sha256, "Recovery preserves the authored scene")
	await _views("recovered")


func _views(prefix: String) -> void:
	var headings := [Vector2.ZERO, Vector2(PI / 2, 0), Vector2(PI, 0), Vector2(-PI / 2, 0), Vector2(0, PI * 0.49), Vector2(0, -PI * 0.49)]
	for index in range(headings.size()):
		var motion := InputEventMouseMotion.new()
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.relative = Vector2((panel.heading.x - headings[index].x) / 0.006, (headings[index].y - panel.heading.y) / 0.006)
		panel.preview.gui_input.emit(motion)
		await RenderingServer.frame_post_draw
		var picture := panel.get_viewport().get_texture().get_image()
		picture.save_png("res://.godot360/editor-review/%s-%d.png" % [prefix, index])
	panel.heading = Vector2.ZERO
	panel._update_preview()


func _wait_job() -> void:
	var start := Time.get_ticks_msec()
	while (panel.process_id > 0 or not panel.pending_session.is_empty()) and Time.get_ticks_msec() - start < 300000:
		await get_tree().create_timer(0.1).timeout
	check(panel.process_id <= 0 and panel.pending_session.is_empty(), "Job returns control to the editor: " + panel.folder.get_file())
	# Editor save pumps the main loop. Leave the timer callback before the next
	# button can save a scene, avoiding reentrant SceneTreeTimer list processing.
	await get_tree().process_frame


func _wait_playback() -> void:
	var start := Time.get_ticks_msec()
	while not panel.playback.phase.is_empty() and Time.get_ticks_msec() - start < 120000:
		await get_tree().create_timer(0.1).timeout


func _wait_stage(stage: String, timeout: int) -> void:
	var start := Time.get_ticks_msec()
	while IO.read_json(panel.folder.path_join("status.json")).get("stage") != stage and panel.process_id > 0 and Time.get_ticks_msec() - start < timeout:
		await get_tree().create_timer(0.05).timeout
	check(IO.read_json(panel.folder.path_join("status.json")).get("stage") == stage, "Job reaches " + stage)


func _delivered(folder: String) -> bool:
	var report := IO.read_json(folder.path_join("report.json"))
	return report.get("ok", false) and report.get("checks", {}).size() == 13 and not report.checks.values().has(false)


func _snapshot(folder: String, relative: String = "") -> Dictionary:
	var result := {}
	var directory := folder.path_join(relative)
	for file in DirAccess.get_files_at(directory):
		result[relative.path_join(file)] = FileAccess.get_sha256(directory.path_join(file))
	for child in DirAccess.get_directories_at(directory):
		result.merge(_snapshot(folder, relative.path_join(child)))
	return result


func check(ok: bool, description: String) -> bool:
	checks[description] = ok
	print(("PASS: " if ok else "FAIL: ") + description)
	return ok


func _finish() -> void:
	deadline = 0
	var ok := not checks.is_empty() and not checks.values().has(false)
	IO.write_json("res://editor-" + phase + ".json", {"ok": ok, "checks": checks, "evidence": evidence, "kind": "native editor integration; no UI click-through claim"})
	print("EDITOR WORKFLOW: ", phase, " ", checks.size(), " checks; ", ok)
	get_tree().quit(0 if ok else 1)
