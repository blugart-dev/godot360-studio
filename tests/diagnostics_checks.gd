extends SceneTree
const Diagnostics = preload("res://addons/umbral360/diagnostics.gd")
const IO = preload("res://addons/umbral360/job_io.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output := ProjectSettings.globalize_path("res://.umbral360/diagnostics-checks-" + str(Time.get_ticks_usec()))
	var source := output.path_join("failed-job")
	DirAccess.make_dir_recursive_absolute(source.path_join("frames"))
	IO.write_json(source.path_join("job.json"), {"scene_path": "res://private-scene.tscn", "source_dir": output.path_join("other-capture"), "width": 4096})
	IO.write_json(source.path_join("status.json"), {"stage": "Failed", "error": "Encoder unavailable"})
	IO.write_text(source.path_join("report.json"), "{incomplete diagnostic JSON")
	IO.write_text(source.path_join("encode.log.stderr"), "")
	var log_text := "old log\n".repeat(80000) + "FINAL FAILURE: encoder unavailable\n"
	IO.write_text(source.path_join("encode.log"), log_text)
	IO.write_text(source.path_join("probe.json"), "x".repeat(Diagnostics.JSON_LIMIT + 1))
	for name in ["video-360.mp4", "preview.png", "frames/frame00000000.png", "frames/frame.wav", "settings.cfg", "session.json", "cancel.request", "secret.txt"]:
		IO.write_text(source.path_join(name), "excluded fixture")
	DirAccess.make_dir_recursive_absolute(output.path_join("other-capture"))
	IO.write_text(output.path_join("other-capture/capture.log"), "REFERENCED SOURCE MUST NOT BE READ")
	var before := _snapshot(source)
	var destination := output.path_join("support.zip")
	var result := Diagnostics.build(source, destination)
	check(result.get("error", "missing").is_empty() and FileAccess.file_exists(destination), "A failed job creates a verified diagnostics ZIP")
	if not result.get("error", "missing").is_empty():
		print("DIAGNOSTICS BUILD RESULT: " + JSON.stringify(result))
		print("DIAGNOSTICS CHECKS: %d checks, %d failures" % [checks, failures])
		quit(1)
		return
	check(not FileAccess.file_exists(destination + ".partial"), "Successful bundle leaves no staging file")
	check(result.get("sha256") == FileAccess.get_sha256(destination), "Result identifies the finished ZIP by hash")
	var reader := ZIPReader.new()
	check(reader.open(destination) == OK, "A separate ZIP reader opens the bundle")
	var manifest = JSON.parse_string(reader.read_file("manifest.json").get_string_from_utf8())
	check(manifest is Dictionary and manifest.get("schema_version") == 1, "Manifest is valid versioned JSON")
	check(manifest.get("selected_job") == source and not manifest.get("environment_only"), "Snapshot identifies the selected job")
	check(reader.read_file("job/status.json") == FileAccess.get_file_as_bytes(source.path_join("status.json")), "Original terminal failure bytes are preserved")
	check(reader.read_file("job/report.json").get_string_from_utf8() == "{incomplete diagnostic JSON", "Malformed diagnostic JSON is retained as evidence")
	check(reader.read_file("job/encode.log").size() == Diagnostics.LOG_LIMIT and reader.read_file("job/encode.log").get_string_from_utf8().ends_with("FINAL FAILURE: encoder unavailable\n"), "Oversized logs keep their bounded tail and final error")
	check(manifest.files["job/encode.log"].truncated and manifest.files["job/encode.log"].offset_bytes > 0, "Manifest discloses the exact truncated log offset")
	check(not reader.file_exists("job/probe.json") and str(manifest.omitted).contains("exceeds JSON size limit"), "Oversized JSON is explicitly omitted without returning invalid truncation")
	check(str(manifest.omitted).contains("capture.log"), "Missing files are reported for incomplete jobs")
	var payloads := reader.get_files()
	payloads.erase("job/")
	check(payloads.size() == 8, "Only five selected diagnostics and three generated files are bundled, regardless of directory entries")
	check(manifest.files["job/encode.log.stderr"].sha256 == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "Empty live stderr logs use the standard empty SHA-256 digest")
	var hashes_ok := true
	for name in manifest.files:
		var data := reader.read_file(name)
		hashes_ok = hashes_ok and Diagnostics._hash(data) == manifest.files[name].sha256 and data.size() == manifest.files[name].bytes
	check(hashes_ok, "Manifest hashes and sizes match every included payload")
	var environment = JSON.parse_string(reader.read_file("environment.json").get_string_from_utf8())
	check(environment.godot_version == Engine.get_version_info().string and environment.has("addon_version") and environment.scope.contains("Collecting"), "Environment distinguishes collecting engine from saved export")
	check(reader.read_file("READ-ME.txt").get_string_from_utf8().contains("Review all contents before sharing"), "Bundle explains local paths, omitted media and review before sharing")
	reader.close()
	check(_snapshot(source) == before, "Collecting diagnostics does not modify any original job file")
	var bundle_hash := FileAccess.get_sha256(destination)
	check(not Diagnostics.build(source, destination).error.is_empty() and FileAccess.get_sha256(destination) == bundle_hash, "Existing ZIP cannot be overwritten")
	var partial := output.path_join("occupied.zip.partial")
	IO.write_text(partial, "retained staging evidence")
	check(not Diagnostics.build(source, output.path_join("occupied.zip")).error.is_empty() and FileAccess.get_file_as_string(partial) == "retained staging evidence", "Existing staging evidence cannot be overwritten")
	check(not Diagnostics.build(source, source.path_join("inside.zip")).error.is_empty() and _snapshot(source) == before, "Writing inside the selected source is refused")
	check(not Diagnostics.build(output.path_join("missing"), output.path_join("missing-source.zip")).error.is_empty(), "Missing selected job is reported instead of silently dropping evidence")
	check(not Diagnostics.build(source, output.path_join("missing/destination.zip")).error.is_empty(), "Unavailable destination fails clearly")
	check(not Diagnostics.build(source, output.path_join("wrong.txt")).error.is_empty(), "Non-ZIP destination is rejected")
	DirAccess.make_dir_recursive_absolute(output.path_join("blocked.zip"))
	check(not Diagnostics.build(source, output.path_join("blocked.zip")).error.is_empty(), "Directory at destination is preserved")
	var setup := output.path_join("setup.zip")
	check(Diagnostics.build("", setup).error.is_empty(), "Setup failures can collect environment without a selected job")
	reader.open(setup)
	check(reader.get_files().size() == 3 and JSON.parse_string(reader.read_file("manifest.json").get_string_from_utf8()).environment_only, "Environment-only bundles contain no job data")
	reader.close()
	print("DIAGNOSTICS CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _snapshot(folder: String) -> Dictionary:
	var result := {}
	for file in DirAccess.get_files_at(folder):
		result[file] = FileAccess.get_sha256(folder.path_join(file))
	for directory in DirAccess.get_directories_at(folder):
		result[directory] = _snapshot(folder.path_join(directory))
	return result


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
