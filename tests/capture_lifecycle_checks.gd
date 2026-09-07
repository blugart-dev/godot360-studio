extends SceneTree
## Disposable jobs exercise capture failure, interruption, and retained diagnostics.
const IO = preload("res://addons/umbral360/job_io.gd")
var folder: String
var checks := 0
var failures := 0
var cases: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Normalize before localizing paths embedded in generated scene text. Older
	# Godot versions otherwise keep Windows backslashes as TSCN escape sequences.
	folder = IO.argument("output").replace("\\", "/").simplify_path()
	if not folder.is_absolute_path() or DirAccess.dir_exists_absolute(folder):
		push_error("Pass a fresh absolute --output folder.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	var settings_before := FileAccess.get_sha256("res://.umbral360/settings.cfg")
	var broken := folder.path_join("broken.tscn")
	FileAccess.open(broken, FileAccess.WRITE).store_string("[gd_scene format=3]\n[node name=\"Broken\" type=\"Node3D\"]\nposition = Vector3(0, 0,\n")
	var hook := folder.path_join("hook.gd")
	FileAccess.open(hook, FileAccess.WRITE).store_string("extends Node3D\nfunc sample_360_frame(index: int, _seconds: float, _job: Dictionary) -> String:\n\treturn \"Injected sample hook failure.\" if index >= 12 else \"\"\n")
	var hook_scene := folder.path_join("hook.tscn")
	FileAccess.open(hook_scene, FileAccess.WRITE).store_string("[gd_scene load_steps=2 format=3]\n[ext_resource type=\"Script\" path=\"" + ProjectSettings.localize_path(hook) + "\" id=\"1\"]\n[node name=\"Hook\" type=\"Node3D\"]\nscript = ExtResource(\"1\")\n[node name=\"Camera3D\" type=\"Camera3D\" parent=\".\"]\n")
	var invalid := await _job("invalid-scene", {"scene_path": ProjectSettings.localize_path(broken), "frames": 60})
	check(invalid.capture.has("error") and str(invalid.capture.error).contains("instantiate"), "Invalid scene produces a specific capture result")
	var failed := await _job("sample-hook", {"scene_path": ProjectSettings.localize_path(hook_scene), "frames": 120})
	check(str(failed.capture.get("error", "")).contains("Injected sample hook failure"), "Hook failure survives into capture diagnostics")
	check(int(failed.capture.get("rendered", -1)) == 14, "Failure records the number of submitted frames, including warmup")
	var closing := folder.path_join("close.gd")
	FileAccess.open(closing, FileAccess.WRITE).store_string("extends Node3D\nfunc sample_360_frame(index: int, _seconds: float, _job: Dictionary) -> String:\n\tif index >= 12:\n\t\tget_tree().quit()\n\treturn \"\"\n")
	var close_scene := folder.path_join("close.tscn")
	FileAccess.open(close_scene, FileAccess.WRITE).store_string(FileAccess.get_file_as_string(hook_scene).replace(ProjectSettings.localize_path(hook), ProjectSettings.localize_path(closing)))
	var closed := await _job("early-quit", {"scene_path": ProjectSettings.localize_path(close_scene), "frames": 120})
	check(str(closed.capture.get("error", "")).contains("closed before"), "Graceful early shutdown saves an incomplete capture result")
	var cancelled := await _job("cancel", {}, "cancel")
	check(cancelled.state.get("stage") == "Cancelled", "Requested cancellation has a terminal Cancelled state")
	check(int(cancelled.capture.get("rendered", -1)) >= 10, "Cancelled capture records submitted frames")
	var killed := await _job("worker-killed", {}, "kill-worker")
	check(str(killed.state.get("error", "")).contains("exit"), "Unexpected worker exit is diagnosed explicitly")
	if IO.argument("writer-check") == "true":
		var writer := await _job("writer-killed", {}, "kill-writer")
		check(str(writer.capture.get("error", "")).contains("PNG writer"), "Killed PNG encoder fails through capture diagnostics")
	check(FileAccess.get_sha256("res://.umbral360/settings.cfg") == settings_before, "Lifecycle tests preserve studio settings")
	IO.write_json(folder.path_join("lifecycle-review.json"), {"ok": failures == 0, "checks": checks, "failures": failures, "cases": cases})
	print("CAPTURE LIFECYCLE CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _job(name: String, overrides: Dictionary, action: String = "") -> Dictionary:
	var output := folder.path_join(name)
	DirAccess.make_dir_recursive_absolute(output)
	var job := {"scene_path": "res://addons/umbral360/examples/calibration.tscn", "camera_path": "Camera3D", "width": 512, "height": 256,
		"face_size": 128, "fps": 60, "frames": 5400, "warmup_frames": 2, "frame_writer": "fast_png", "crf": 18,
		"ffmpeg": IO.argument("ffmpeg"), "ffprobe": IO.argument("ffprobe"), "output_dir": output}
	job.merge(overrides, true)
	IO.write_json(output.path_join("job.json"), job)
	var pid := OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--log-file", output.path_join("pipeline.log"), "--script", "res://addons/umbral360/pipeline.gd", "--", "--job=" + output.path_join("job.json")])
	var started := Time.get_ticks_msec()
	var acted := false
	var worker_pid := -1
	var writer_pid := -1
	while OS.is_process_running(pid) and Time.get_ticks_msec() - started < 25000:
		var state := IO.read_json(output.path_join("status.json"))
		worker_pid = int(state.get("worker_pid", worker_pid)) if int(state.get("worker_pid", -1)) > 0 else worker_pid
		var progress := IO.read_json(output.path_join("render-progress.json"))
		writer_pid = int(progress.get("writer_pid", writer_pid))
		if not acted and int(progress.get("frame", 0)) >= 10:
			if action == "cancel":
				FileAccess.open(output.path_join("cancel.request"), FileAccess.WRITE).store_string("Lifecycle test cancellation")
				acted = true
			elif action == "kill-worker" and worker_pid > 0:
				OS.kill(worker_pid)
				acted = true
			elif action == "kill-writer" and writer_pid > 0:
				OS.kill(writer_pid)
				acted = true
		await create_timer(0.05).timeout
	var finished := not OS.is_process_running(pid)
	if not finished:
		FileAccess.open(output.path_join("cancel.request"), FileAccess.WRITE).store_string("Test timeout cleanup")
		await create_timer(2).timeout
		for owned_pid in [writer_pid, worker_pid, pid]:
			if owned_pid > 0 and OS.is_process_running(owned_pid):
				OS.kill(owned_pid)
	await create_timer(0.2).timeout
	check(finished, name + ": coordinator exits within the test limit")
	check(action.is_empty() or acted, name + ": requested interruption was exercised")
	check(worker_pid <= 0 or not OS.is_process_running(worker_pid), name + ": worker is no longer running")
	if writer_pid > 0:
		check(not OS.is_process_running(writer_pid), name + ": PNG writer is no longer running")
	var state := IO.read_json(output.path_join("status.json"))
	check(state.get("stage") in ["Failed", "Cancelled"], name + ": terminal failure state is saved")
	check(not FileAccess.file_exists(output.path_join("video-360.mp4")), name + ": failure publishes no final video")
	var capture := IO.read_json(output.path_join("capture-result.json"))
	var recovery := IO.read_json(output.path_join("recovery.json"))
	check(recovery.get("can_reencode") == false and str(recovery.get("next_step", "")).contains("new render"), name + ": incomplete capture has explicit recovery guidance")
	var result := {"state": state, "capture": capture, "seconds": (Time.get_ticks_msec() - started) / 1000.0,
		"worker_pid": worker_pid, "writer_pid": writer_pid, "recovery": recovery}
	cases[name] = result
	return result


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
