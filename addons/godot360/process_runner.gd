extends RefCounted
## Child process with concurrently drained output and explicit cancellation.
const CAPTURE_LIMIT = 4 * 1024 * 1024
var pid: int = -1
var readers: Array[Thread] = []
var cancelled: bool = false
var log_path: String


func start(executable: String, arguments: PackedStringArray, destination: String) -> String:
	log_path = destination
	var stdout_log := FileAccess.open(destination, FileAccess.WRITE)
	var stderr_log := FileAccess.open(destination + ".stderr", FileAccess.WRITE)
	if stdout_log == null or stderr_log == null:
		return "Cannot create process logs."
	var child := OS.execute_with_pipe(executable, arguments, true)
	if child.is_empty():
		return "Could not start: " + executable
	pid = int(child.pid)
	for pair in [[child.stdio, stdout_log], [child.stderr, stderr_log]]:
		var pipe: FileAccess = pair[0]
		var log: FileAccess = pair[1]
		var thread := Thread.new()
		var error := thread.start(func() -> Dictionary:
			var captured := PackedByteArray()
			var write_failed := false
			while true:
				var bytes := pipe.get_buffer(4096)
				if bytes.is_empty():
					break
				log.store_buffer(bytes)
				log.flush()
				write_failed = write_failed or log.get_error() != OK
				if captured.size() < CAPTURE_LIMIT:
					captured.append_array(bytes.slice(0, CAPTURE_LIMIT - captured.size()))
			pipe.close()
			log.flush()
			write_failed = write_failed or log.get_error() != OK
			log.close()
			return {"output": captured.get_string_from_utf8(), "write_failed": write_failed})
		if error != OK:
			OS.kill(pid)
			pipe.close()
			finish()
			return "Could not start a process log reader."
		readers.append(thread)
	return ""


func is_running() -> bool:
	return pid > 0 and OS.is_process_running(pid)


func cancel() -> void:
	cancelled = true
	if is_running():
		OS.kill(pid)


func finish() -> Dictionary:
	var output: Array[String] = []
	var write_failed := false
	for reader in readers:
		var result: Dictionary = reader.wait_to_finish()
		output.append(str(result.output))
		write_failed = write_failed or bool(result.write_failed)
	readers.clear()
	var code: int = OS.get_process_exit_code(pid) if pid > 0 else -1
	pid = -1
	# Keep a combined diagnostic log for compatibility with earlier jobs. The
	# separate stderr file and live log retain output beyond the capture limit.
	if output.size() == 2 and not output[1].is_empty():
		var log := FileAccess.open(log_path, FileAccess.READ_WRITE)
		if log != null:
			log.seek_end()
			log.store_string("\n" + output[1])
			log.flush()
			write_failed = write_failed or log.get_error() != OK
		else:
			write_failed = true
	return {"code": -1 if write_failed else code, "output": "\n".join(output), "cancelled": cancelled,
		"error": "Cannot write process logs. Check output folder access and disk space." if write_failed else ""}
