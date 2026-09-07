@tool
extends RefCounted
## Resolve external tools to absolute paths before starting any child process.


static func search_directories(platform: String, path_value: String) -> PackedStringArray:
	var directories := PackedStringArray()
	for entry in path_value.split(";" if platform == "Windows" else ":", false):
		var directory := entry.strip_edges().trim_prefix('"').trim_suffix('"')
		# Empty/relative PATH entries would search a changing working directory.
		if directory.is_absolute_path() and not directory in directories:
			directories.append(directory)
	var defaults: Array[String] = []
	if platform == "macOS":
		# Finder-launched editors may not inherit a shell's Homebrew PATH.
		defaults = ["/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin", "/usr/bin", "/bin"]
	elif platform == "Linux":
		defaults = ["/usr/local/bin", "/usr/bin", "/bin"]
	for directory in defaults:
		if not directory in directories:
			directories.append(directory)
	return directories


static func is_executable(path: String) -> bool:
	if not FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
		return false
	if OS.get_name() in ["Linux", "macOS"]:
		var execute_bits := FileAccess.UNIX_EXECUTE_OWNER | FileAccess.UNIX_EXECUTE_GROUP | FileAccess.UNIX_EXECUTE_OTHER
		return (FileAccess.get_unix_permissions(path) & execute_bits) != 0
	return true


static func find_executable(command: String) -> String:
	var selected := command.strip_edges().trim_prefix('"').trim_suffix('"')
	if selected.is_empty() or selected.begins_with("res://") or selected.begins_with("user://"):
		return ""
	if selected.is_absolute_path():
		return selected if is_executable(selected) else ""
	if selected.contains("/") or selected.contains("\\"):
		return ""
	var names := [selected]
	if OS.get_name() == "Windows" and not selected.to_lower().ends_with(".exe"):
		names.push_front(selected + ".exe")
	for directory in search_directories(OS.get_name(), OS.get_environment("PATH")):
		for name in names:
			var path := directory.path_join(name)
			if is_executable(path):
				return path
	return ""


static func missing_message(label: String) -> String:
	var message := "Locate %s in Tool setup. Select the executable file or use Find installed tools." % label
	if OS.get_name() in ["Linux", "macOS"]:
		message += " The file must have execute permission; choose a build for your operating system and CPU. See Platform setup."
	return message
