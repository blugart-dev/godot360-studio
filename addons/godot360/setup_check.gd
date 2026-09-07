@tool
extends Node
## Bounded asynchronous tool checks; the editor keeps responding throughout.
const Runner = preload("process_runner.gd")
var runner: RefCounted
var busy := false


static func find_executable(command: String) -> String:
	var selected := command.strip_edges().trim_prefix('"').trim_suffix('"')
	if selected.is_empty():
		return ""
	if selected.is_absolute_path():
		return selected if FileAccess.file_exists(selected) else ""
	# Bare command names only. Relative filesystem paths are ambiguous in a worker.
	if selected.contains("/") or selected.contains("\\"):
		return ""
	var names := [selected]
	if OS.get_name() == "Windows" and not selected.to_lower().ends_with(".exe"):
		names.push_front(selected + ".exe")
	for entry in OS.get_environment("PATH").split(";" if OS.get_name() == "Windows" else ":", false):
		var directory := entry.strip_edges().trim_prefix('"').trim_suffix('"')
		for name in names:
			var path := directory.path_join(name)
			if directory.is_absolute_path() and FileAccess.file_exists(path):
				return path
	return ""


func check_tools(ffmpeg: String, ffprobe: String) -> Dictionary:
	if busy:
		return {"ok": false, "error": "A tool check is already running."}
	busy = true
	var result := {"ok": false, "error": "", "png": false, "filters": ""}
	var encoder := find_executable(ffmpeg)
	var probe := find_executable(ffprobe)
	if encoder.is_empty() or probe.is_empty():
		result.error = "Locate FFmpeg and FFprobe in Tool setup, then check again."
	else:
		var folder := ProjectSettings.globalize_path("res://.godot360/setup-" + str(Time.get_ticks_usec()))
		if DirAccess.make_dir_recursive_absolute(folder) != OK:
			result.error = "Cannot save setup logs in .godot360. Check project folder access."
		else:
			var encoders := await _execute(encoder, ["-hide_banner", "-encoders"], folder.path_join("encoders.log"))
			if encoders.code != 0 or not str(encoders.output).contains("libx264") or not str(encoders.output).contains(" aac "):
				result.error = "FFmpeg needs H.264 (libx264) and AAC encoders. Choose another build in Tool setup."
			else:
				result.png = str(encoders.output).contains(" png ")
				var filters := await _execute(encoder, ["-hide_banner", "-filters"], folder.path_join("filters.log"))
				result.filters = str(filters.output)
				if filters.code != 0 or not result.filters.contains(" scale ") or not result.filters.contains(" colorspace "):
					result.error = "FFmpeg needs scale and colorspace filters. Choose another build in Tool setup."
				else:
					var version := await _execute(probe, ["-version"], folder.path_join("ffprobe.log"))
					if version.code != 0 or not str(version.output).contains("ffprobe version"):
						result.error = "FFprobe could not be verified. Select ffprobe in Tool setup."
					else:
						result.ok = true
			result.logs = folder
	busy = false
	return result


func _execute(executable: String, arguments: PackedStringArray, path: String) -> Dictionary:
	runner = Runner.new()
	var error: String = runner.start(executable, arguments, path)
	if not error.is_empty():
		return {"code": -1, "output": error}
	var deadline := Time.get_ticks_msec() + 15000
	while runner.is_running() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if runner.is_running():
		runner.cancel()
	var result: Dictionary = runner.finish()
	runner = null
	return result


func _exit_tree() -> void:
	if runner != null:
		runner.cancel()
		runner.finish()
		runner = null
