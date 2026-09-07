@tool
extends RefCounted
## Local support snapshot. Never traverse media folders or paths found in job files.
const JSON_LIMIT := 1024 * 1024
const LOG_LIMIT := 512 * 1024
const JSON_FILES := ["job.json", "status.json", "report.json", "recovery.json",
	"capture-settings.json", "capture-result.json", "capture-timings.json", "worker-exit.json",
	"render-progress.json", "planning.json", "storage.json", "storage-checks.json",
	"scene-checks.json", "quality-checks.json", "probe.json", "soundtrack-probe.json"]
const LOG_FILES := ["pipeline.log", "capture.log", "encode.log", "frame-writer.log",
	"ffmpeg-check.log", "ffprobe-check.log", "ffmpeg-filters.log", "ffmpeg-encoders.log",
	"probe.json.stderr", "soundtrack-probe.json.stderr", "encode-progress.txt",
	"encode.log.stderr", "ffmpeg-check.log.stderr", "ffprobe-check.log.stderr",
	"ffmpeg-filters.log.stderr", "capture.log.stderr", "frame-writer.log.stderr"]


static func environment() -> Dictionary:
	var config := ConfigFile.new()
	config.load("res://addons/umbral360/plugin.cfg")
	var result := {"addon_version": config.get_value("plugin", "version", "unknown"),
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"os": OS.get_name(), "os_version": OS.get_version(), "cpu": OS.get_processor_name(),
		"display_server": DisplayServer.get_name(),
		"scope": "Collecting process, not necessarily the process that exported this saved job."}
	if DisplayServer.get_name() != "headless":
		result["renderer"] = RenderingServer.get_current_rendering_method()
		result["video_adapter"] = RenderingServer.get_video_adapter_name()
		result["video_vendor"] = RenderingServer.get_video_adapter_vendor()
	else:
		result["renderer"] = "unavailable (headless collector); see capture.log for export hardware"
	return result


static func build(job_folder: String, destination: String) -> Dictionary:
	var target := ProjectSettings.globalize_path(destination).replace("\\", "/").simplify_path()
	var source := ProjectSettings.globalize_path(job_folder).replace("\\", "/").simplify_path() if not job_folder.is_empty() else ""
	if not target.is_absolute_path() or target.get_extension().to_lower() != "zip":
		return {"error": "Choose an absolute path ending in .zip."}
	if not source.is_empty():
		if not DirAccess.dir_exists_absolute(source):
			return {"error": "The selected job folder is unavailable. Reconnect its drive or choose another job."}
		if target.to_lower().begins_with(source.trim_suffix("/").to_lower() + "/"):
			return {"error": "Save diagnostics outside the selected job folder to preserve its files."}
	var temporary := target + ".partial"
	if FileAccess.file_exists(target) or DirAccess.dir_exists_absolute(target) or FileAccess.file_exists(temporary) or DirAccess.dir_exists_absolute(temporary):
		return {"error": "That destination or its .partial file already exists. Choose a new ZIP name."}
	if not DirAccess.dir_exists_absolute(target.get_base_dir()):
		return {"error": "The destination folder is unavailable. Choose an existing writable folder."}
	var entries := {}
	var records := {}
	var omitted := []
	if not source.is_empty():
		for name in JSON_FILES + LOG_FILES:
			var path := source.path_join(name)
			if not FileAccess.file_exists(path):
				omitted.append({"file": name, "reason": "missing or not a regular file"})
				continue
			var file := FileAccess.open(path, FileAccess.READ)
			if file == null:
				omitted.append({"file": name, "reason": "cannot open for reading"})
				continue
			var length := file.get_length()
			var is_log: bool = name in LOG_FILES
			if not is_log and length > JSON_LIMIT:
				omitted.append({"file": name, "reason": "exceeds JSON size limit", "source_bytes": length})
				file.close()
				continue
			var offset := maxi(0, length - LOG_LIMIT) if is_log else 0
			file.seek(offset)
			var data := file.get_buffer(length - offset)
			file.close()
			if data.size() != length - offset:
				omitted.append({"file": name, "reason": "short read; file may be changing"})
				continue
			var member: String = "job/" + name
			entries[member] = data
			records[member] = {"source_bytes": length, "offset_bytes": offset, "truncated": offset > 0}
	entries["environment.json"] = (JSON.stringify(environment(), "\t") + "\n").to_utf8_buffer()
	entries["READ-ME.txt"] = ("Godot360 local diagnostics\n\nReview all contents before sharing: reports and logs can contain local paths,\nproject names, media tags, scene messages, and other text written by your scene.\nNo upload is performed. No source scenes, images, audio, video, executables,\nsettings.cfg, session files, or cancellation requests are collected.\nOnly fixed diagnostic filenames in the selected folder are read; referenced\nsource captures and soundtracks are not followed.\n\nLogs retain at most their last 512 KiB; JSON files over 1 MiB are omitted.\nmanifest.json lists omissions, truncated logs, and SHA-256 for included bytes.\nThis is a snapshot: files from an active job may represent different moments.\nThe environment describes the collecting process; capture.log records export\nhardware and ffprobe-check.log records the probe version when available.\nInclude your FFmpeg version separately if needed; collection does not execute tools.\nFor an independent beta report, describe your steps, expected/actual result,\nand whether this used a different machine/GPU from the development tests.\n").to_utf8_buffer()
	var manifest := {"schema_version": 1, "created_utc": Time.get_datetime_string_from_system(true),
		"selected_job": source, "environment_only": source.is_empty(), "files": {}, "omitted": omitted,
		"json_limit_bytes": JSON_LIMIT, "log_tail_limit_bytes": LOG_LIMIT}
	for name in entries:
		var record: Dictionary = records.get(name, {})
		record.merge({"bytes": entries[name].size(), "sha256": _hash(entries[name])})
		manifest.files[name] = record
	entries["manifest.json"] = (JSON.stringify(manifest, "\t") + "\n").to_utf8_buffer()
	var writer := ZIPPacker.new()
	if writer.open(temporary) != OK:
		return {"error": "Cannot create the diagnostics ZIP. Check folder access and free space."}
	var error := ""
	for name in entries:
		if writer.start_file(name) != OK or writer.write_file(entries[name]) != OK or writer.close_file() != OK:
			error = "Could not write the diagnostics ZIP. Check drive access and free space."
			break
	var closed := writer.close()
	if closed != OK:
		error = "Could not finish the diagnostics ZIP. Check drive access and free space."
	if error.is_empty():
		var reader := ZIPReader.new()
		if reader.open(temporary) != OK:
			error = "Could not verify the diagnostics ZIP."
		else:
			# Godot 4.7 exposes an explicit parent directory for nested ZIP files;
			# older readers list only payloads. Validate every payload in either form.
			var members := reader.get_files()
			members.erase("job/")
			if members.size() != entries.size():
				error = "Diagnostics ZIP inventory verification failed."
			for name in members:
				if not entries.has(name):
					error = "Diagnostics ZIP contains an unexpected file."
			for name in entries:
				if reader.read_file(name) != entries[name]:
					error = "Diagnostics ZIP content verification failed."
					break
			reader.close()
	if error.is_empty():
		if FileAccess.file_exists(target) or DirAccess.dir_exists_absolute(target) or DirAccess.rename_absolute(temporary, target) != OK:
			error = "Could not publish the diagnostics ZIP. Choose a new name in a writable folder."
	if not error.is_empty():
		DirAccess.remove_absolute(temporary)
		return {"error": error}
	return {"error": "", "path": target, "files": entries.size(), "omitted": omitted.size(), "sha256": FileAccess.get_sha256(target)}


static func _hash(data: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	if not data.is_empty():
		context.update(data)
	return context.finish().hex_encode()
