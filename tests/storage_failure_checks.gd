extends SceneTree
const IO = preload("res://addons/umbral360/job_io.gd")
var checks := 0
var failures := 0
var cases := {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var base := IO.argument("output").replace("\\", "/").simplify_path()
	if not base.is_absolute_path() or DirAccess.dir_exists_absolute(base):
		push_error("Pass a fresh absolute --output folder.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(base)
	for scenario in ["preflight-space", "capture-space", "encode-space", "metadata-space", "status-write", "capture-progress-write", "capture-result-write", "report-write", "preview-write"]:
		var folder := base.path_join(scenario)
		DirAccess.make_dir_recursive_absolute(folder)
		IO.write_json(folder.path_join("job.json"), {"scene_path": "res://tests/fixtures/storage_scene.tscn", "camera_path": "Camera3D", "width": 512, "height": 256,
			"face_size": 128, "frames": 60, "fps": 30, "warmup_frames": 2, "frame_writer": "fast_png", "crf": 18,
			"output_dir": folder, "ffmpeg": IO.argument("ffmpeg"), "ffprobe": IO.argument("ffprobe")})
		var pid := OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--log-file", folder.path_join("pipeline.log"), "--script", "res://tests/fixtures/storage_pipeline.gd", "--", "--job=" + folder.path_join("job.json"), "--case=" + scenario])
		var started := Time.get_ticks_msec()
		while OS.is_process_running(pid) and Time.get_ticks_msec() - started < 40000:
			await create_timer(0.05).timeout
		var finished := not OS.is_process_running(pid)
		if not finished:
			IO.write_text(folder.path_join("cancel.request"), "Disposable storage test timeout")
			await create_timer(2).timeout
			OS.kill(pid)
		check(finished and OS.get_process_exit_code(pid) != 0, scenario + ": job stops with failure")
		var state := IO.read_json(folder.path_join("status.json"))
		var recovery := IO.read_json(folder.path_join("recovery.json"))
		var log := FileAccess.get_file_as_string(folder.path_join("pipeline.log"))
		check(not FileAccess.file_exists(folder.path_join("video-360.mp4")), scenario + ": failure publishes no final video")
		check(not recovery.is_empty(), scenario + ": recovery evidence is retained")
		if scenario == "status-write":
			check(state.get("stage") == "Rendering" and log.contains("Cannot save status.json"), "Blocked status preserves its last complete state and logs the write error")
		else:
			check(state.get("stage") == "Failed" and not str(state.get("error", "")).is_empty(), scenario + ": explicit terminal failure survives")
		if scenario in ["preflight-space", "capture-space", "encode-space", "metadata-space"]:
			check(str(state.get("error", "")).contains("disk space"), scenario + ": low capacity is diagnosed as a storage failure")
		if scenario == "preflight-space":
			check(not FileAccess.file_exists(folder.path_join("capture.log")) and not FileAccess.file_exists(folder.path_join("ffmpeg-check.log")), "Low preflight space launches no GPU or codec process")
		if scenario == "capture-space":
			check(IO.read_json(folder.path_join("capture-result.json")).get("rendered") == 12, "Capture stops before submitting another frame below its space threshold")
		if scenario == "encode-space":
			check(FileAccess.file_exists(folder.path_join("encode.log")), "Encoding-space failure interrupts an actual launched encoder")
		if scenario == "metadata-space":
			check(FileAccess.file_exists(folder.path_join("encoded.mp4")) and FileAccess.file_exists(folder.path_join("staged-360.mp4")), "Metadata-space failure retains the encoded input and partial staged copy")
		var reusable: bool = scenario in ["encode-space", "metadata-space", "report-write", "preview-write"]
		check(bool(recovery.get("can_reencode", false)) == reusable, scenario + ": recovery eligibility matches finalized capture evidence")
		cases[scenario] = {"state": state, "recovery": recovery, "exit_code": OS.get_process_exit_code(pid)}
	var source := base.path_join("report-write")
	var before := _snapshot(source)
	var retry := base.path_join("recovered-report-write")
	DirAccess.make_dir_recursive_absolute(retry)
	IO.write_json(retry.path_join("job.json"), {"mode": "reencode", "source_dir": source, "output_dir": retry, "ffmpeg": IO.argument("ffmpeg"), "ffprobe": IO.argument("ffprobe")})
	var retry_pid := OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--log-file", retry.path_join("pipeline.log"), "--script", "res://addons/umbral360/pipeline.gd", "--", "--job=" + retry.path_join("job.json")])
	var retry_started := Time.get_ticks_msec()
	while OS.is_process_running(retry_pid) and Time.get_ticks_msec() - retry_started < 30000:
		await create_timer(0.05).timeout
	check(not OS.is_process_running(retry_pid) and OS.get_process_exit_code(retry_pid) == 0, "A capture retained after a failed report write re-encodes successfully")
	check(IO.read_json(retry.path_join("report.json")).get("ok", false) and FileAccess.file_exists(retry.path_join("video-360.mp4")), "Recovered capture produces a verified final output")
	check(before == _snapshot(source), "Recovery leaves every file in the failed source job unchanged")
	if OS.is_process_running(retry_pid):
		IO.write_text(retry.path_join("cancel.request"), "Disposable recovery timeout")
	IO.write_json(base.path_join("storage-failure-review.json"), {"ok": failures == 0, "checks": checks, "failures": failures, "cases": cases, "space_values_injected": true})
	print("STORAGE FAILURE CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _snapshot(folder: String) -> Dictionary:
	var result := {}
	for name in DirAccess.get_files_at(folder):
		result[name] = FileAccess.get_sha256(folder.path_join(name))
	for name in DirAccess.get_directories_at(folder):
		result[name] = _snapshot(folder.path_join(name))
	return result


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
