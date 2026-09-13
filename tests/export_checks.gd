extends SceneTree
## Headless contract tests for validation and the constrained MP4 metadata writer.

const IO = preload("res://addons/godot360/job_io.gd")
const Metadata = preload("res://addons/godot360/spherical_metadata.gd")
const Pipeline = preload("res://addons/godot360/pipeline.gd")
var checks: int = 0
var failures: int = 0
var folder: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	folder = ProjectSettings.globalize_path("res://.godot360/tests-" + str(Time.get_ticks_usec()))
	DirAccess.make_dir_recursive_absolute(folder)
	var recipe: Dictionary = preload("res://addons/godot360/export_profile.gd").new().to_dictionary()
	recipe.merge({"output_dir": folder, "ffmpeg": "ffmpeg", "ffprobe": "ffprobe"})
	check(IO.validate(recipe).is_empty(), "Default export recipe is valid")
	for change in [{"width": 2049}, {"height": 1023}, {"frames": 0}, {"fps": 29}, {"face_size": 64},
		{"output_dir": "relative/path"}, {"scene_path": "res://missing.tscn"}, {"warmup_frames": -1}, {"crf": 40}, {"frame_writer": "unknown"}]:
		var invalid := recipe.duplicate()
		invalid.merge(change, true)
		check(not IO.validate(invalid).is_empty(), "Invalid recipe is rejected: " + str(change))
	var empty: Dictionary = {}
	check(not IO.validate(empty).is_empty(), "Missing job fields are rejected")
	for border in [-0.5, 26.0, "12.5", true]:
		var invalid := recipe.duplicate()
		invalid.capture_border_percent = border
		check(not IO.validate(invalid).is_empty(), "Coordinator rejects invalid capture border: " + str(border))
	check(not IO.quality_advice(recipe).is_empty(), "Draft resolution reports limited viewing detail")
	check(not IO.quality_advice({"width": 7680, "face_size": 512}).is_empty(), "Increasing output size alone warns about low-resolution cube faces")
	check(IO.quality_advice({"width": 4096, "face_size": 2048}).is_empty(), "Production sampling has no draft or face-resolution warning")
	var quality_profile = preload("res://addons/godot360/export_profile.gd").new()
	quality_profile.apply_quality_preset("detail")
	check(quality_profile.to_dictionary().width == 7680 and quality_profile.face_size == 3072 and quality_profile.crf == 16, "Detail preset raises actual capture detail as well as output size")
	check(IO.write_json(folder.path_join("roundtrip.json"), recipe), "Job JSON writes successfully")
	for invalid in ["", "{", "[]", "null"]:
		IO.write_text(folder.path_join("unavailable.json"), invalid)
		check(IO.read_json(folder.path_join("unavailable.json")).is_empty(), "Unavailable or non-object JSON stays pending: " + invalid)
	check(IO.read_json(folder.path_join("missing.json")).is_empty(), "Missing JSON stays pending")
	var output := folder.path_join("output")
	DirAccess.make_dir_recursive_absolute(output)
	check(IO.exclude_output_from_import(output) and FileAccess.file_exists(output.path_join(".gdignore")), "Export folder is excluded from asset import")
	IO.write_text(output.path_join(".gdignore"), "Existing marker")
	check(IO.exclude_output_from_import(output) and FileAccess.get_file_as_string(output.path_join(".gdignore")) == "Existing marker", "Existing import-ignore marker is preserved")
	check(not IO.exclude_output_from_import(folder.path_join("missing-output")), "Unwritable import marker prevents output preparation")
	var restored: Dictionary = IO.read_json(folder.path_join("roundtrip.json"))
	check(IO.validate(restored).is_empty() and int(restored.frames) == 300 and restored.camera_path == "Camera3D", "Serialized recipe preserves its export settings")
	_test_metadata()
	_test_verification(recipe)
	await _test_startup_cancellation(recipe)
	print("EXPORT CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_startup_cancellation(recipe: Dictionary) -> void:
	for occupied in [false, true]:
		var destination := folder.path_join("early-cancel-occupied" if occupied else "early-cancel")
		DirAccess.make_dir_recursive_absolute(destination)
		var job := recipe.duplicate(true)
		job.output_dir = destination
		# No tool should be started for a cancellation already waiting at launch.
		job.ffmpeg = "missing-encoder-for-startup-cancellation-check"
		job.ffprobe = "missing-probe-for-startup-cancellation-check"
		IO.write_json(destination.path_join("job.json"), job)
		IO.write_text(destination.path_join("cancel.request"), "Cancel before coordinator initialization")
		if occupied:
			IO.write_text(destination.path_join("existing-source.png"), "Preserve existing source")
		var runner = preload("res://addons/godot360/process_runner.gd").new()
		var error: String = runner.start(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
			"--log-file", destination.path_join("pipeline.log"), "--script", "res://addons/godot360/pipeline.gd", "--",
			"--job=" + destination.path_join("job.json")], folder.path_join("startup-occupied.log" if occupied else "startup-cancel.log"))
		check(error.is_empty(), "Startup cancellation coordinator launches: occupied=" + str(occupied))
		if not error.is_empty():
			continue
		var deadline := Time.get_ticks_msec() + 20000
		while runner.is_running() and Time.get_ticks_msec() < deadline:
			await process_frame
		check(not runner.is_running(), "Startup cancellation coordinator exits promptly: occupied=" + str(occupied))
		if runner.is_running():
			runner.cancel()
		runner.finish()
		var state := IO.read_json(destination.path_join("status.json"))
		if occupied:
			check(state.is_empty() and FileAccess.get_file_as_string(destination.path_join("existing-source.png")) == "Preserve existing source", "An early cancel does not bypass existing-output protection")
		else:
			check(state.get("stage") == "Cancelled" and FileAccess.file_exists(destination.path_join("recovery.json")), "Cancellation before initialization writes a reopenable terminal state and recovery guidance")
			check(not FileAccess.file_exists(destination.path_join("ffmpeg-check.log")) and not DirAccess.dir_exists_absolute(destination.path_join("frames")), "Early cancellation starts no external tools or scene capture")
		check(not FileAccess.file_exists(destination.path_join("video-360.mp4")), "Startup cancellation cannot publish a delivery: occupied=" + str(occupied))


func _test_metadata() -> void:
	var track := preload("res://tests/fixtures/mp4.gd").track([24])
	var prefix := Metadata.atom("ftyp", "isom0000".to_ascii_buffer()) + Metadata.atom("mdat", PackedByteArray([2, 4, 6, 8, 10]))
	var moov := Metadata.atom("moov", track)
	_write("plain.mp4", prefix + moov)
	var input_path := folder.path_join("plain.mp4")
	var output_path := folder.path_join("spherical.mp4")
	check(Metadata.inject(input_path, output_path, 2048, 1024).is_empty(), "Spherical metadata injection succeeds")
	var output := FileAccess.get_file_as_bytes(output_path)
	var new_moov := Metadata.child(Metadata.atom("root", output), "moov")
	check(output.slice(16 + new_moov.size()) == prefix.slice(16), "Media bytes stay unchanged after relocation")
	check(output.slice(20, 24).get_string_from_ascii() == "moov", "Rebuilt moov precedes media for fast-start")
	var new_track := Metadata.child(new_moov, "trak")
	var uuid := Metadata.child(new_track, "uuid")
	check(uuid.slice(8, 24).hex_encode() == Metadata.SPHERICAL_UUID, "UUID matches the published spherical video specification")
	check(uuid.slice(24).get_string_from_utf8().contains("<GSpherical:StereoMode>mono</GSpherical:StereoMode>"), "Metadata describes mono projection")
	check(FileAccess.get_file_as_bytes(input_path) == prefix + moov, "Source MP4 is unchanged")
	check(not Metadata.inject(input_path, output_path, 2048, 1024).is_empty(), "Existing output is never overwritten")
	check(not Metadata.inject(input_path, input_path, 2048, 1024).is_empty(), "In-place mutation is rejected")
	check(not Metadata.inject(output_path, folder.path_join("duplicate.mp4"), 2048, 1024).is_empty(), "Duplicate spherical injection is rejected")
	_write("fast-start.mp4", Metadata.atom("ftyp", "isom0000".to_ascii_buffer()) + moov + Metadata.atom("mdat", PackedByteArray([1, 2, 3])))
	check(not Metadata.inject(folder.path_join("fast-start.mp4"), folder.path_join("unsupported.mp4"), 2048, 1024).is_empty(), "Fast-start input is rejected before writing output")
	check(not FileAccess.file_exists(folder.path_join("unsupported.mp4")), "Rejected input leaves no output file")
	_write("broken.mp4", PackedByteArray([0, 0, 0, 100, 109, 100, 97, 116]))
	check(not Metadata.inject(folder.path_join("broken.mp4"), folder.path_join("broken-output.mp4"), 2048, 1024).is_empty(), "Truncated MP4 is rejected")
	check(Metadata.children(PackedByteArray([0, 0, 0, 0]), 0).is_empty(), "Short atom headers are rejected")


func _test_verification(recipe: Dictionary) -> void:
	var video := {"codec_type": "video", "width": 2048, "height": 1024, "nb_read_frames": 300,
		"r_frame_rate": "30/1", "duration": 10.0, "codec_name": "h264", "pix_fmt": "yuv420p",
		"color_space": "bt709", "color_transfer": "bt709", "color_primaries": "bt709", "color_range": "tv",
		"side_data_list": [{"side_data_type": "Spherical Mapping", "projection": "equirectangular"}]}
	var audio := {"codec_type": "audio", "codec_name": "aac", "channels": 2, "sample_rate": "48000", "duration": 10.0}
	var probe := {"streams": [video, audio]}
	var result: Dictionary = Pipeline.verify(probe, recipe)
	check(not result.values().has(false), "A matching probe passes all export checks")
	video.nb_read_frames = 299
	check(not Pipeline.verify(probe, recipe).frame_count, "A dropped frame fails verification")
	video.side_data_list = []
	check(not Pipeline.verify(probe, recipe).spherical_metadata, "Missing spherical metadata fails verification")
	audio.channels = 1
	check(not Pipeline.verify(probe, recipe).aac_stereo_48k, "Mono audio fails the stereo profile check")
	audio.duration = 9.0
	check(not Pipeline.verify(probe, recipe).audio_duration, "Audio shorter than the film fails verification")
	check(Pipeline.verify({}, recipe).values().has(false), "Empty probe cannot pass verification")


func _write(name: String, data: PackedByteArray) -> void:
	var file := FileAccess.open(folder.path_join(name), FileAccess.WRITE)
	file.store_buffer(data)


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
