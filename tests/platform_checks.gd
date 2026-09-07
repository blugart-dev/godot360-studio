extends SceneTree
## Actual child processes, path handling and Unix filesystem behavior.
const Tools = preload("res://addons/godot360/tool_paths.gd")
const Runner = preload("res://addons/godot360/process_runner.gd")
const IO = preload("res://addons/godot360/job_io.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	if IO.argument("child") == "true":
		print(IO.argument("payload"))
		printerr("child stderr")
		quit(7)
	else:
		call_deferred("_run")


func _run() -> void:
	var folder := ProjectSettings.globalize_path("res://.godot360/platform space-é-" + str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(folder)
	var executable := OS.get_executable_path()
	check(Tools.find_executable('"' + executable + '"') == executable, "Quoted executable paths resolve without shell quoting")
	check(Tools.find_executable(folder).is_empty(), "A directory cannot be selected as an executable")
	check(Tools.find_executable("./ffmpeg").is_empty() and Tools.find_executable("res://ffmpeg").is_empty(), "Relative and Godot resource paths cannot become machine tool paths")
	var original_path := OS.get_environment("PATH")
	var path_existed := OS.has_environment("PATH")
	OS.set_environment("PATH", executable.get_base_dir())
	check(Tools.find_executable(executable.get_file()) == executable, "Bare tool names resolve to an absolute path on the real host")
	if path_existed:
		OS.set_environment("PATH", original_path)
	else:
		OS.unset_environment("PATH")
	var mac := Tools.search_directories("macOS", "/custom/bin:/usr/bin")
	check(mac[0] == "/custom/bin" and "/opt/homebrew/bin" in mac and "/usr/local/bin" in mac, "Mac GUI discovery preserves PATH priority and includes both Homebrew prefixes")
	check(not "." in Tools.search_directories(OS.get_name(), "."), "Tool discovery never trusts the current directory")
	var payload := "space é ; & $ literal = values"
	var runner := Runner.new()
	var error: String = runner.start(executable, ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--log-file", folder.path_join("child.log"), "--script", "res://tests/platform_checks.gd", "--", "--child=true", "--payload=" + payload], folder.path_join("process.log"))
	check(error.is_empty(), "The native child process starts with paths containing spaces and Unicode")
	if error.is_empty():
		var deadline := Time.get_ticks_msec() + 15000
		while runner.is_running() and Time.get_ticks_msec() < deadline:
			await process_frame
		if runner.is_running():
			runner.cancel()
		var result: Dictionary = runner.finish()
		check(result.code == 7, "Native child exit codes survive process completion")
		check(str(result.output).contains(payload) and str(result.output).contains("child stderr"), "Arguments are literal and stdout/stderr are both drained")
		check(FileAccess.get_file_as_string(folder.path_join("process.log")).contains(payload), "Process logs retain Unicode output")
	if OS.get_name() in ["Linux", "macOS"]:
		var path := folder.path_join("ExampleTool")
		IO.write_text(path, "#!/bin/sh\nexit 0\n")
		check(FileAccess.set_unix_permissions(path, 384) == OK and Tools.find_executable(path).is_empty(), "Unix files without execute permission are rejected")
		check(FileAccess.set_unix_permissions(path, 448) == OK and Tools.find_executable(path) == path, "Executable Unix files are accepted")
		var link := folder.path_join("linked-tool")
		check(DirAccess.open(folder).create_link(path, link) == OK and Tools.find_executable(link) == link, "Package-manager symlinks resolve to executable tools")
		if OS.get_name() == "Linux":
			check(not FileAccess.file_exists(folder.path_join("exampletool")), "Linux checks run on a case-sensitive filesystem")
	print("PLATFORM CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
