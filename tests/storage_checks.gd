extends SceneTree
const IO = preload("res://addons/umbral360/job_io.gd")
const Storage = preload("res://addons/umbral360/storage_guard.gd")
const Writer = preload("res://addons/umbral360/frame_writer.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var folder := ProjectSettings.globalize_path("res://.umbral360/storage-contracts-" + str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(folder)
	var guard := Storage.new(folder)
	check(str(guard.check(0, "test", true).error).is_empty(), "Actual output drive reports usable headroom")
	guard.space_reader = func() -> int: return Storage.RESERVE + 1024
	check(str(guard.check(1024, "test", true).error).is_empty(), "Exact working headroom is accepted")
	check(not str(guard.check(1025, "test", true).error).is_empty(), "One-byte headroom shortfall is rejected")
	guard.space_reader = func() -> int: return 0
	check(not str(guard.check(0, "test", true).error).is_empty(), "A zero free-space report cannot disable protection")
	guard.space_reader = func() -> int: return -1
	check(str(guard.check(0, "test", true).error).contains("Cannot determine"), "Unavailable capacity produces an explicit access diagnostic")
	var job := {"width": 7680, "height": 3840, "frames": 900, "fps": 30, "warmup_frames": 2}
	check(Storage.capture_headroom(job) > 4 * 7680 * 3840 * 4 + 30 * 48000 * 8, "Capture budget includes four images, PNG overhead and full-duration PCM")
	var path := folder.path_join("state.json")
	check(IO.write_json(path, {"generation": 1}), "Initial JSON checkpoint is saved")
	DirAccess.make_dir_recursive_absolute(path + ".tmp")
	check(not IO.write_json(path, {"generation": 2}), "Blocked temporary file is a reported write failure")
	check(IO.read_json(path).get("generation") == 1, "Failed checkpoint preserves the previous complete JSON")
	var directory_path := folder.path_join("directory.json")
	DirAccess.make_dir_recursive_absolute(directory_path)
	check(not IO.write_json(directory_path, {"value": true}), "Atomic rename failure is reported")
	check(DirAccess.dir_exists_absolute(directory_path), "Checkpoint failure leaves an existing directory intact")
	check(not IO.write_text(directory_path, "unwritable"), "Cancellation marker writer detects an unwritable destination")
	var session := preload("res://addons/umbral360/job_session.gd").new()
	var control := folder.path_join("control-write")
	session.start(control)
	DirAccess.make_dir_recursive_absolute(control.path_join("cancel.request"))
	var pending: Dictionary = session.request(control, session.identity, "cancel")
	session.serve({"stage": "Rendering"})
	check(session.response(control, pending).is_empty(), "A failed cancellation write never produces accepted control proof")
	check(IO.read_json(control.path_join("control").path_join(str(pending.nonce) + ".reply.json")).get("accepted") == false, "Coordinator explicitly rejects an unwritable cancellation marker")
	session.clear_request(control, pending)
	var panel := preload("res://addons/umbral360/studio_panel.gd").new()
	root.add_child(panel)
	panel.folder = control
	panel.process_id = OS.get_process_id()
	panel._cancel()
	check(panel.status.text.contains("Cannot request cancellation"), "Panel reports a cancellation write failure instead of claiming to cancel")
	panel.process_id = -1
	panel.free()
	for backend in ["png", "fast_png"]:
		var output := folder.path_join(backend)
		DirAccess.make_dir_recursive_absolute(output.path_join("frames/frame00000000.png"))
		var writer := Writer.new()
		writer.configure({"width": 256, "height": 128, "fps": 30, "frame_writer": backend, "output_dir": output, "ffmpeg": IO.argument("ffmpeg")})
		var frame := Image.create(256, 128, false, Image.FORMAT_RGBA8)
		frame.fill(Color.CORNFLOWER_BLUE)
		var accepted := writer.write_frame(frame)
		var finished := writer.finish()
		check(not accepted or not finished, backend + ": real PNG output failure is detected")
		check(not writer.last_error.is_empty(), backend + ": failed writer provides a diagnostic")
		writer.abort()
		check(DirAccess.dir_exists_absolute(output.path_join("frames/frame00000000.png")), backend + ": failed encoder preserves the existing directory")
	var blocked_log := folder.path_join("process-log-write")
	DirAccess.make_dir_recursive_absolute(blocked_log)
	IO.write_json(blocked_log.path_join("job.json"), {"scene_path": "res://tests/fixtures/storage_scene.tscn", "camera_path": "Camera3D",
		"width": 512, "height": 256, "face_size": 128, "frames": 30, "fps": 30, "output_dir": blocked_log,
		"ffmpeg": IO.argument("ffmpeg"), "ffprobe": "ffprobe"})
	var child := OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--log-file", blocked_log.path_join("pipeline.log"), "--script", "res://tests/fixtures/storage_pipeline.gd",
		"--", "--job=" + blocked_log.path_join("job.json"), "--case=process-log-write"])
	var started := Time.get_ticks_msec()
	while OS.is_process_running(child) and Time.get_ticks_msec() - started < 15000:
		await create_timer(0.05).timeout
	check(not OS.is_process_running(child) and OS.get_process_exit_code(child) != 0, "A blocked process-log path stops the coordinator")
	check(str(IO.read_json(blocked_log.path_join("status.json")).get("error", "")).contains("Cannot create process logs"), "Log creation failure preserves its real cause instead of blaming missing codecs")
	check(not FileAccess.file_exists(blocked_log.path_join("capture.log")), "Unwritable preflight logs launch no capture worker")
	if OS.is_process_running(child):
		OS.kill(child)
	print("STORAGE CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
