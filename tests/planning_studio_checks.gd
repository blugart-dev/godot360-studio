extends SceneTree
## Actual panel test -> estimate -> re-encode -> cancellation integration.
## --ffmpeg=PATH --ffprobe=PATH [--cancel-source=COMPLETED_CAPTURE_FOLDER]
const IO = preload("res://addons/godot360/job_io.gd")
const Planner = preload("res://addons/godot360/job_planner.gd")
var panel: Control
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings_path := "res://.godot360/settings.cfg"
	var existed := FileAccess.file_exists(settings_path)
	var original := FileAccess.get_file_as_bytes(settings_path) if existed else PackedByteArray()
	root.size = Vector2i(1500, 800)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	panel = preload("res://addons/godot360/studio_panel.gd").new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.profile = preload("res://addons/godot360/export_profile.gd").new()
	panel.profile.width = "512"
	panel.profile.face_size = 128
	panel.profile.duration = 3.0
	panel._refresh_fields()
	panel.ffmpeg.text = IO.argument("ffmpeg")
	panel.ffprobe.text = IO.argument("ffprobe")
	panel.output.text = ProjectSettings.globalize_path("res://renders/planning-studio-checks")
	panel.test_button.pressed.emit()
	check(panel.process_id > 0 and panel.active_job.mode == "test", "Test button launches a sample job")
	check(panel.active_job.frames == 30 and panel.active_job.target_frames == 90 and panel.profile.duration == 3.0, "Sample preserves the requested full duration")
	check(panel.test_button.disabled and panel.render_button.disabled and panel.reencode_button.disabled, "Job actions cannot launch overlapping work")
	await _wait_for_job()
	var source: String = panel.folder
	check(IO.read_json(source.path_join("report.json")).get("ok", false), "Sample passes the complete output validation")
	check(not IO.read_json(source.path_join("planning.json")).is_empty(), "Sample saves a planning report")
	check(panel.planning_label.text.contains("Estimated export:"), "Panel shows measured time and storage estimates")
	var initial_estimate: String = panel.planning_label.text
	panel.recipe_fields.duration.text = "6"
	panel._refresh_plan()
	check(panel.planning_label.text.contains("Estimated export:") and panel.planning_label.text != initial_estimate, "Changing duration recalculates the estimate")
	panel.recipe_fields.width.text = "1024"
	panel._refresh_plan()
	check(panel.planning_label.text.contains("changed"), "Changing resolution marks the old estimate stale")
	panel.profile.apply_quality_preset("production")
	panel._refresh_fields()
	check(panel.recipe_fields.width.text == "4096" and panel.recipe_fields.face_size.text == "2048", "Presets remain intact while a prior sample is loaded")
	panel.recipe_fields.width.text = "512"
	panel.recipe_fields.face_size.text = "128"
	panel._refresh_plan()
	# Select a different CRF for the re-encode. Scene/size fields are deliberately
	# changed; captured settings, rather than current authoring fields, must win.
	var before := _snapshot(source)
	panel.crf_control.value = 25
	panel.recipe_fields.scene_path.text = "res://not-installed.tscn"
	panel.recipe_fields.width.text = "4096"
	panel._reencode(source)
	check(panel.process_id > 0 and panel.active_job.width == 512 and panel.active_job.crf == 25, "Re-encode uses saved dimensions and selected CRF")
	await _wait_for_job()
	var encoded_folder: String = panel.folder
	var report := IO.read_json(encoded_folder.path_join("report.json"))
	check(report.get("ok", false) and report.get("capture_reused", false), "Re-encoded video passes validation and records its capture source")
	check(not FileAccess.file_exists(encoded_folder.path_join("capture.log")) and not DirAccess.dir_exists_absolute(encoded_folder.path_join("frames")), "Re-encode starts no capture and copies no source sequence")
	check(before == _snapshot(source), "All source files are byte-for-byte unchanged")
	print("PLANNING SAMPLE FOLDER: " + source)
	print("RE-ENCODE FOLDER: " + encoded_folder)
	var cancel_source := IO.argument("cancel-source")
	if not cancel_source.is_empty():
		await _cancel_encoding(cancel_source)
	else:
		print("Encoding cancellation integration skipped: pass --cancel-source with a longer capture.")
	if existed:
		var config := FileAccess.open(settings_path, FileAccess.WRITE)
		config.store_buffer(original)
		config.close()
	else:
		DirAccess.remove_absolute(settings_path)
	print("PLANNING STUDIO CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _cancel_encoding(source: String) -> void:
	panel._reencode(source)
	var deadline: int = Time.get_ticks_msec() + 60000
	var encode_pid: int = -1
	while panel.process_id > 0 and Time.get_ticks_msec() < deadline:
		var state := IO.read_json(panel.folder.path_join("status.json"))
		if state.get("stage") == "Encoding H.264 + AAC" and int(state.get("encoding", {}).get("frames", 0)) > 0:
			encode_pid = int(state.get("process_pid", -1))
			break
		await create_timer(0.05).timeout
	check(encode_pid > 0, "Real encoding publishes live progress before completion")
	await create_timer(0.35).timeout
	check(panel.status.text.contains("Encoding ·"), "Panel displays live encoding frame counts")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://.godot360/planning-encoding.png"))
	var started: int = Time.get_ticks_msec()
	panel.cancel_button.pressed.emit()
	await _wait_for_job()
	var final_state := IO.read_json(panel.folder.path_join("status.json"))
	check(final_state.get("stage") == "Cancelled" and Time.get_ticks_msec() - started < 10000, "Cancel stops the active encode promptly")
	check(encode_pid > 0 and not OS.is_process_running(encode_pid), "Cancelled encoder leaves no running process")
	check(not FileAccess.file_exists(panel.folder.path_join("video-360.mp4")), "Cancelled encode publishes no final video")
	print("CANCELLED ENCODE FOLDER: " + panel.folder)


func _wait_for_job() -> void:
	var deadline: int = Time.get_ticks_msec() + 120000
	while panel.process_id > 0 and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	check(panel.process_id <= 0, "Panel observes job exit")
	if panel.process_id > 0:
		panel._cancel()


func _snapshot(folder: String) -> Dictionary:
	var result: Dictionary = {}
	for file in DirAccess.get_files_at(folder):
		result[file] = FileAccess.get_sha256(folder.path_join(file))
	for directory in DirAccess.get_directories_at(folder):
		result[directory + "/"] = _snapshot(folder.path_join(directory))
	return result


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
