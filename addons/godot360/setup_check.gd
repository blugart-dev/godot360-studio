@tool
extends Node
## Bounded asynchronous tool checks; the editor keeps responding throughout.
const Runner = preload("process_runner.gd")
const Tools = preload("tool_paths.gd")
var runner: RefCounted
var busy := false


static func find_executable(command: String) -> String:
	return Tools.find_executable(command)


func check_tools(ffmpeg: String, ffprobe: String) -> Dictionary:
	if busy:
		return {"ok": false, "error": "A tool check is already running."}
	busy = true
	var result := {"ok": false, "error": "", "png": false, "filters": "", "playback": false}
	var encoder := find_executable(ffmpeg)
	var probe := find_executable(ffprobe)
	if encoder.is_empty() or probe.is_empty():
		result.error = Tools.missing_message("FFmpeg" if encoder.is_empty() else "FFprobe")
	else:
		var folder := ProjectSettings.globalize_path("res://.godot360/setup-" + str(Time.get_ticks_usec()))
		if DirAccess.make_dir_recursive_absolute(folder) != OK:
			result.error = "Cannot save setup logs in .godot360. Check project folder access."
		else:
			var encoder_version := await _execute(encoder, ["-version"], folder.path_join("ffmpeg.log"))
			result.ffmpeg_version = _version_label(str(encoder_version.output), "ffmpeg")
			var encoders := await _execute(encoder, ["-hide_banner", "-encoders"], folder.path_join("encoders.log"))
			result.playback = str(encoders.output).contains("libtheora") and str(encoders.output).contains("libvorbis")
			if encoder_version.code != 0 or not str(encoder_version.output).contains("ffmpeg version"):
				result.error = "FFmpeg could not be verified. Select ffmpeg in Tool setup."
			elif encoders.code != 0 or not str(encoders.output).contains("libx264") or not str(encoders.output).contains(" aac "):
				result.error = "FFmpeg needs H.264 (libx264) and AAC encoders. Choose another build in Tool setup."
			else:
				result.png = str(encoders.output).contains(" png ")
				var filters := await _execute(encoder, ["-hide_banner", "-filters"], folder.path_join("filters.log"))
				result.filters = str(filters.output)
				if filters.code != 0 or not result.filters.contains(" scale ") or not result.filters.contains(" colorspace "):
					result.error = "FFmpeg needs scale and colorspace filters. Choose another build in Tool setup."
				else:
					var version := await _execute(probe, ["-version"], folder.path_join("ffprobe.log"))
					result.ffprobe_version = _version_label(str(version.output), "ffprobe")
					if version.code != 0 or not str(version.output).contains("ffprobe version"):
						result.error = "FFprobe could not be verified. Select ffprobe in Tool setup."
					else:
						result.ok = true
			result.logs = folder
	busy = false
	return result


static func _version_label(output: String, tool: String) -> String:
	for line in output.split("\n"):
		if line.begins_with(tool + " version "):
			return ("FFmpeg" if tool == "ffmpeg" else "FFprobe") + " · " + line.get_slice(" ", 2)
	return tool + " · version unavailable"


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
