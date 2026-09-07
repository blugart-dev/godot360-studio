extends SceneTree
## Actual reopened panel, absent editor/coordinator, stale identity and source reuse.
const IO = preload("res://addons/umbral360/job_io.gd")
const Session = preload("res://addons/umbral360/job_session.gd")
const Studio = preload("res://addons/umbral360/studio_panel.gd")
var panel: Control
var folder: String
var checks := 0
var failures := 0
var settings_existed := false
var original_settings := PackedByteArray()
var restore_settings := false
var owned_jobs: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	folder = IO.argument("output").replace("\\", "/").simplify_path()
	if not folder.is_absolute_path() or DirAccess.dir_exists_absolute(folder):
		push_error("Pass a fresh absolute --output folder.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	settings_existed = FileAccess.file_exists(Studio.SETTINGS_PATH)
	if settings_existed:
		original_settings = FileAccess.get_file_as_bytes(Studio.SETTINGS_PATH)
	restore_settings = true
	_protocol_checks()
	root.size = Vector2i(1400, 600)
	panel = Studio.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Allow automatic inspection of an earlier compatibility sample to settle.
	await _wait_panel()
	panel.profile = preload("res://addons/umbral360/export_profile.gd").new()
	panel.profile.width = "512"
	panel.profile.face_size = 128
	panel.profile.duration = 1.0
	panel._refresh_fields()
	panel.ffmpeg.text = IO.argument("ffmpeg")
	panel.ffprobe.text = IO.argument("ffprobe")
	panel.output.text = folder
	panel._test_render()
	owned_jobs.append(panel.folder)
	await _wait_panel()
	var source: String = panel.folder
	check(IO.read_json(source.path_join("report.json")).get("ok", false), "Fresh sample completes with verified media")
	var before := _snapshot(source)
	panel.free()
	panel = Studio.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check(panel.folder == source and panel.status.text.contains("Test complete"), "Panel restart restores the last completed job and planning")
	check(not panel.reuse_button.disabled and panel.recovery_source == source, "Completed capture offers a direct re-encode action")
	check(before == _snapshot(source), "Inspecting a completed job leaves every source file unchanged")
	var evidence := folder.path_join("saved-evidence")
	DirAccess.make_dir_recursive_absolute(evidence)
	IO.write_json(evidence.path_join("job.json"), {"mode": "reencode", "source_dir": source})
	IO.write_json(evidence.path_join("status.json"), {"stage": "Complete"})
	IO.write_json(evidence.path_join("report.json"), {"ok": true})
	panel._open_job(evidence)
	check(panel.status.text.contains("could not be confirmed") and panel.process_id == -1, "Saved Complete without delivered media is not shown as a verified output")
	DirAccess.copy_absolute(source.path_join("video-360.mp4"), evidence.path_join("video-360.mp4"))
	DirAccess.copy_absolute(source.path_join("report.json"), evidence.path_join("report.json"))
	IO.write_json(evidence.path_join("status.json"), {"stage": "Verifying output"})
	panel._open_job(evidence)
	check(panel.status.text.contains("Re-encode complete") and panel.process_id == -1, "Verified media and report recover completion despite stale status and absent session")

	# This coordinator has a different parent process, which exits before reconnecting.
	var orphan := folder.path_join("editor-closed")
	var job := IO.read_json(source.path_join("job.json"))
	job.merge({"output_dir": orphan, "mode": "render", "frames": 5400}, true)
	job.erase("target_frames")
	DirAccess.make_dir_recursive_absolute(orphan)
	IO.write_json(orphan.path_join("job.json"), job)
	owned_jobs.append(orphan)
	var launcher := OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--log-file", folder.path_join("launcher.log"), "--script", "res://tests/fixtures/session_launcher.gd", "--", "--job=" + orphan.path_join("job.json")])
	var started := Time.get_ticks_msec()
	while (OS.is_process_running(launcher) or IO.read_json(orphan.path_join("session.json")).is_empty()) and Time.get_ticks_msec() - started < 10000:
		await create_timer(0.05).timeout
	check(not OS.is_process_running(launcher), "Original launcher exits before the panel reconnects")
	panel.folder = orphan
	panel._save_settings()
	panel.free()
	panel = Studio.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check(panel.cancel_button.disabled, "Cancellation is disabled while ownership is unconfirmed")
	started = Time.get_ticks_msec()
	while not panel.pending_session.is_empty() and Time.get_ticks_msec() - started < 8000:
		await create_timer(0.05).timeout
	var coordinator: int = int(IO.read_json(orphan.path_join("session.json")).get("pid", -1))
	check(panel.reconnected and panel.process_id == coordinator and coordinator > 0, "Restarted panel confirms a live coordinator after its parent exits")
	check(not panel.cancel_button.disabled and panel.render_button.disabled, "Confirmed job enables cancellation and blocks a second panel launch")
	# Two clients must not overwrite one another's challenges.
	var second := Session.request(orphan, IO.read_json(orphan.path_join("session.json")))
	await create_timer(0.5).timeout
	check(not Session.response(orphan, second).is_empty(), "A second client independently confirms the same job")
	Session.clear_request(orphan, second)
	while not panel.pending_session.is_empty():
		await create_timer(0.05).timeout
	started = Time.get_ticks_msec()
	while int(IO.read_json(orphan.path_join("render-progress.json")).get("frame", 0)) < 10 and Time.get_ticks_msec() - started < 10000:
		await create_timer(0.05).timeout
	check(IO.read_json(orphan.path_join("status.json")).get("stage") == "Rendering", "Reconnected job reaches actual GPU capture")
	panel._cancel()
	await _wait_panel()
	check(IO.read_json(orphan.path_join("status.json")).get("stage") == "Cancelled", "Reconnected cancellation reaches the actual exporter")
	check(IO.read_json(orphan.path_join("worker-exit.json")).has("exit_code"), "Coordinator records the cancelled worker's exit")
	check(not FileAccess.file_exists(orphan.path_join("video-360.mp4")), "Cancelled job publishes no final video")

	# Kill only a coordinator created by this test, then stop its worker through
	# the job's cooperative marker. Preserve the coordinator's stale status.
	job.output_dir = folder.path_join("coordinator-lost")
	panel._launch(job)
	var lost: String = panel.folder
	owned_jobs.append(lost)
	var owned_pid: int = panel.process_id
	started = Time.get_ticks_msec()
	while int(IO.read_json(lost.path_join("render-progress.json")).get("frame", 0)) < 10 and OS.is_process_running(owned_pid) and Time.get_ticks_msec() - started < 15000:
		await create_timer(0.05).timeout
	var saved_state := IO.read_json(lost.path_join("status.json"))
	check(saved_state.get("stage") == "Rendering", "Coordinator loss is injected during real GPU capture")
	OS.kill(owned_pid)
	await _wait_exit(owned_pid)
	var status_hash := FileAccess.get_sha256(lost.path_join("status.json"))
	FileAccess.open(lost.path_join("cancel.request"), FileAccess.WRITE).store_string("Disposable worker cleanup after coordinator loss")
	await _wait_exit(int(saved_state.get("worker_pid", -1)))
	await _wait_panel()
	panel._open_job(lost)
	await _wait_panel()
	check(panel.process_id == -1 and panel.cancel_button.disabled and panel.status.text.contains("No live coordinator confirmed"), "Coordinator loss offers honest offline guidance without reconnecting")
	check(panel.reuse_button.disabled and not FileAccess.file_exists(lost.path_join("recovery.json")), "Unfinished capture stays ineligible even without a recovery file")
	check(FileAccess.get_sha256(lost.path_join("status.json")) == status_hash, "Reopening an interrupted job preserves original status evidence")

	# Simulate a stale PID now belonging to an unrelated live process (this test).
	var stale := folder.path_join("stale-reencode")
	DirAccess.make_dir_recursive_absolute(stale.path_join("control"))
	IO.write_json(stale.path_join("job.json"), {"mode": "reencode", "source_dir": source})
	IO.write_json(stale.path_join("status.json"), {"stage": "Encoding H.264 + AAC", "pid": OS.get_process_id()})
	var owner := {"protocol": 1, "session_id": Session.token(), "pid": OS.get_process_id()}
	IO.write_json(stale.path_join("session.json"), owner)
	panel._open_job(stale)
	var pending: Dictionary = panel.pending_session.duplicate()
	var old_reply := pending.duplicate()
	old_reply.merge({"nonce": Session.token(), "accepted": true}, true)
	IO.write_json(stale.path_join("control").path_join(str(pending.nonce) + ".reply.json"), old_reply)
	await _wait_panel()
	check(panel.process_id == -1 and panel.cancel_button.disabled, "Live reused PID and stale reply cannot establish ownership")
	panel._cancel()
	check(not FileAccess.file_exists(stale.path_join("cancel.request")), "Unconfirmed job cannot receive cancellation")
	check(panel.recovery_source == source and not panel.reuse_button.disabled, "Interrupted re-encode finds the original completed capture without recovery.json")
	panel.reuse_button.pressed.emit()
	owned_jobs.append(panel.folder)
	await _wait_panel()
	check(IO.read_json(panel.folder.path_join("report.json")).get("ok", false), "Recovered source re-encodes into a fresh verified video")
	check(before == _snapshot(source), "Recovery and re-encoding preserve all original source bytes")
	var scroll: ScrollContainer = panel.get_child(0).get_child(0)
	scroll.scroll_vertical = 285
	await process_frame
	await RenderingServer.frame_post_draw
	check(panel.size.y <= root.size.y, "Saved-job controls fit the existing panel")
	root.get_texture().get_image().save_png(folder.path_join("recovery-panel.png"))
	IO.write_json(folder.path_join("recovery-review.json"), {"ok": failures == 0, "checks": checks, "failures": failures, "source": source, "output": panel.folder})
	print("RECOVERY STUDIO CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _protocol_checks() -> void:
	var path := folder.path_join("protocol")
	var session := Session.new()
	check(session.start(path), "Coordinator writes a new per-run identity")
	var first := Session.request(path, session.identity)
	session.serve({"stage": "Rendering"})
	check(not Session.response(path, first).is_empty(), "Fresh challenge receives matching proof")
	var wrong := first.duplicate()
	wrong.pid = int(first.pid) + 1
	check(Session.response(path, wrong).is_empty(), "Reply PID must match the challenged identity")
	wrong = first.duplicate()
	wrong.session_id = Session.token()
	check(Session.response(path, wrong).is_empty(), "Reply must match the exact coordinator session")
	Session.clear_request(path, first)
	check(DirAccess.get_files_at(path.path_join("control")).is_empty(), "Client clears only its own challenge and reply")
	var expired := Session.request(path, session.identity, "cancel")
	expired.expires = Time.get_unix_time_from_system() - 1.0
	IO.write_json(path.path_join("control").path_join(str(expired.nonce) + ".request.json"), expired)
	session.serve({"stage": "Rendering"})
	check(not FileAccess.file_exists(path.path_join("cancel.request")), "Expired cancellation cannot act later")
	wrong = session.identity.duplicate()
	wrong.session_id = Session.token()
	var bad := Session.request(path, wrong, "cancel")
	session.serve({"stage": "Rendering"})
	check(Session.response(path, bad).is_empty() and not FileAccess.file_exists(path.path_join("cancel.request")), "Wrong session cannot cancel this job")
	var cancel := Session.request(path, session.identity, "cancel")
	session.serve({"stage": "Rendering"})
	check(FileAccess.file_exists(path.path_join("cancel.request")) and not Session.response(path, cancel).is_empty(), "Matching cancellation is acknowledged after writing the job marker")
	Session.clear_request(path, cancel)
	check(Session.review(folder.path_join("missing")).has("error"), "Missing job is rejected without starting a process")


func _wait_panel() -> void:
	var started := Time.get_ticks_msec()
	while (panel.process_id > 0 or not panel.pending_session.is_empty()) and Time.get_ticks_msec() - started < 90000:
		await create_timer(0.05).timeout
	check(panel.process_id <= 0 and panel.pending_session.is_empty(), "Panel operation finishes within its timeout")


func _wait_exit(pid: int) -> void:
	var started := Time.get_ticks_msec()
	while pid > 0 and OS.is_process_running(pid) and Time.get_ticks_msec() - started < 10000:
		await create_timer(0.05).timeout


func _snapshot(path: String) -> Dictionary:
	var result := {}
	for file in DirAccess.get_files_at(path):
		result[file] = FileAccess.get_sha256(path.path_join(file))
	for directory in DirAccess.get_directories_at(path):
		result[directory] = _snapshot(path.path_join(directory))
	return result


func _finalize() -> void:
	for path in owned_jobs:
		if not IO.read_json(path.path_join("status.json")).get("stage") in Session.TERMINAL:
			var file := FileAccess.open(path.path_join("cancel.request"), FileAccess.WRITE)
			if file != null:
				file.store_string("Disposable recovery test cleanup")
	if restore_settings:
		if settings_existed:
			FileAccess.open(Studio.SETTINGS_PATH, FileAccess.WRITE).store_buffer(original_settings)
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(Studio.SETTINGS_PATH))


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
