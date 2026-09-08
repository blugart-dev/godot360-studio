@tool
extends HBoxContainer

const Profile = preload("export_profile.gd")
const IO = preload("job_io.gd")
const Planner = preload("job_planner.gd")
const Audio = preload("audio_plan.gd")
const Session = preload("job_session.gd")
const Diagnostics = preload("diagnostics.gd")
const Layout = preload("studio_layout.gd")
const Inspector = preload("scene_inspector.gd")
const Setup = preload("setup_check.gd")
const StorageGuard = preload("storage_guard.gd")
const Renderer = preload("renderer_policy.gd")
var renderer_control: OptionButton
var driver_control: OptionButton
var border_control: SpinBox
var border_hint: Label
const AUDIO_MODES = ["scene", "soundtrack", "mix"]
const SETTINGS_PATH = "res://.godot360/settings.cfg"
var profile: Resource = Profile.new()
var recipe_fields: Dictionary = {}
var ffmpeg: LineEdit
var ffprobe: LineEdit
var output: LineEdit
var status: Label
var progress: ProgressBar
var render_button: Button
var cancel_button: Button
var preview: ColorRect
var preview_material: ShaderMaterial
var folder: String = ""
var process_id: int = -1
var poll_time: float = 0.0
var heading := Vector2.ZERO
var quality_hint: Label
var storage: OptionButton
var crf_control: SpinBox
var test_button: Button
var reencode_button: Button
var planning_label: Label
var sample_record: Dictionary = {}
var active_job: Dictionary = {}
var planning_poll: float = 0.0
var refreshing_fields: bool = false
var audio_mode_control: OptionButton
var soundtrack_field: LineEdit
var audio_controls: Dictionary = {}
var open_job_button: Button
var reuse_button: Button
var pending_session: Dictionary = {}
var session_owner: Dictionary = {}
var reconnected := false
var session_started := 0
var recovery_source := ""
var diagnostics_result: Label
var current_scene_provider: Callable
var save_current_scene: Callable
var use_scene_button: Button
var camera_picker: OptionButton
var fps_picker: OptionButton
var quality_buttons := {}
var sections := {}
var readiness_label: Label
var check_button: Button
var output_button: Button
var preview_empty: Label
var setup_checker: Node
var tool_result := {}
var checked_tools: Array = []
var scene_summary := {}
var inspected_scene := ""
var scene_dirty := false
var writable_output := ""
var output_error := ""
var soundtrack_widgets: Array[Control] = []
var inspected_stamp := 0
var playback: Control
var effects_label: Label
var effects_scroll: ScrollContainer
var recent_exports: VBoxContainer


func _ready() -> void:
	Layout.build(self)
	recent_exports.open_requested.connect(_open_job)
	recent_exports.history_changed.connect(_save_settings)
	setup_checker = Setup.new()
	add_child(setup_checker)
	_load_settings()
	_refresh_scene_cameras(false)
	_refresh_quality_hint()
	for field in recipe_fields.values() + [ffmpeg, ffprobe, output]:
		field.text_changed.connect(func(_value: String): _refresh_plan())
	recipe_fields.scene_path.text_changed.connect(func(_value: String): scene_dirty = true)
	recipe_fields.camera_path.text_changed.connect(func(_value: String): _sync_camera_picker())
	_refresh_plan()
	_detect_tools(false)

func _field(parent: Control, label_text: String, value: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var edit := LineEdit.new()
	edit.text = value
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size.x = 240
	parent.add_child(edit)
	return edit


func _button(parent: Control, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _build_audio_controls(parent: Control) -> void:
	var title := Label.new()
	title.text = "Audio"
	parent.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 2
	parent.add_child(grid)
	var label := Label.new()
	label.text = "Audio source"
	grid.add_child(label)
	audio_mode_control = OptionButton.new()
	for text in ["Scene audio", "Soundtrack only", "Scene + soundtrack"]:
		audio_mode_control.add_item(text)
	grid.add_child(audio_mode_control)
	audio_mode_control.item_selected.connect(func(_index: int):
		_update_profile()
		_refresh_audio_enabled()
		_refresh_plan())
	soundtrack_field = _field(grid, "Soundtrack file", "")
	soundtrack_widgets.append(grid.get_child(grid.get_child_count() - 2))
	soundtrack_widgets.append(soundtrack_field)
	soundtrack_field.placeholder_text = "res://audio/music.wav or an absolute path"
	soundtrack_field.text_changed.connect(func(_value: String): _refresh_plan())
	var row := HBoxContainer.new()
	parent.add_child(row)
	soundtrack_widgets.append(row)
	_button(row, "Soundtrack…", _browse.bind("soundtrack"))
	var advanced := Layout.foldout(self, parent, "audio", "Audio timing and levels")
	row = HBoxContainer.new()
	advanced.add_child(row)
	var timing := Label.new()
	timing.text = "Positive offset = later · Negative = earlier"
	row.add_child(timing)
	grid = GridContainer.new()
	grid.columns = 2
	advanced.add_child(grid)
	for entry in [["soundtrack_trim_seconds", "Soundtrack trim (s)"], ["soundtrack_offset_seconds", "Soundtrack offset (s)"],
		["soundtrack_gain_db", "Soundtrack level (dB)"], ["scene_audio_offset_seconds", "Scene offset (s)"], ["scene_audio_gain_db", "Scene level (dB)"]]:
		var field_label := Label.new()
		field_label.text = entry[1]
		grid.add_child(field_label)
		var spin := SpinBox.new()
		var key: String = entry[0]
		spin.min_value = -60.0 if key.ends_with("_db") else 0.0 if key == "soundtrack_trim_seconds" else -3600.0
		spin.max_value = 0.0 if key.ends_with("_db") else 3600.0
		spin.step = 0.1 if key.ends_with("_db") else 0.001
		spin.tooltip_text = "0 dB keeps the source level. Lower values reduce it." if key.ends_with("_db") else "Skip this much from the beginning of the attached file." if key == "soundtrack_trim_seconds" else "Relative to the first delivered video frame. Positive delays sound; negative advances it."
		grid.add_child(spin)
		audio_controls[key] = spin
		spin.value_changed.connect(func(_value: float): _refresh_plan())
	var hint := Label.new()
	hint.text = "Applies to renders and re-encoding. Short audio ends in silence. Mixing uses a peak limiter."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	advanced.add_child(hint)
	_refresh_audio_fields()


func _refresh_audio_fields() -> void:
	if audio_mode_control == null:
		return
	audio_mode_control.select(maxi(0, AUDIO_MODES.find(profile.audio_mode)))
	soundtrack_field.text = profile.soundtrack_path
	for key in audio_controls:
		audio_controls[key].set_value_no_signal(profile.get(key))
	_refresh_audio_enabled()


func _refresh_audio_enabled() -> void:
	var mode: String = AUDIO_MODES[audio_mode_control.selected]
	for widget in soundtrack_widgets:
		widget.visible = mode != "scene"
	soundtrack_field.editable = mode != "scene"
	for key in audio_controls:
		audio_controls[key].editable = mode != "scene" if key.begins_with("soundtrack") else mode != "soundtrack"


func _update_profile() -> void:
	profile.scene_path = recipe_fields.scene_path.text.strip_edges()
	profile.camera_path = NodePath(recipe_fields.camera_path.text.strip_edges())
	profile.width = recipe_fields.width.text
	profile.face_size = int(recipe_fields.face_size.text)
	profile.fps = recipe_fields.fps.text
	profile.duration = float(recipe_fields.duration.text)
	if audio_mode_control != null:
		profile.audio_mode = AUDIO_MODES[audio_mode_control.selected]
		profile.soundtrack_path = soundtrack_field.text.strip_edges()
		for key in audio_controls:
			profile.set(key, audio_controls[key].value)


func _refresh_fields() -> void:
	refreshing_fields = true
	for key in recipe_fields:
		recipe_fields[key].text = str(profile.get(key))
	if storage != null:
		storage.select(0 if profile.frame_writer == "fast_png" else 1)
	if crf_control != null:
		crf_control.set_value_no_signal(profile.crf)
	renderer_control.select(Renderer.METHODS.find(profile.rendering_method))
	driver_control.select(Renderer.DRIVERS.find(profile.rendering_driver))
	border_control.set_value_no_signal(profile.capture_border_percent)
	_refresh_audio_fields()
	_refresh_quality_hint()
	_refresh_scene_cameras(false)
	refreshing_fields = false
	_refresh_plan()


func _refresh_quality_hint() -> void:
	if quality_hint == null:
		return
	var width: int = int(recipe_fields.width.text)
	var advice: Array[String] = IO.quality_advice({"width": width, "face_size": int(recipe_fields.face_size.text)})
	quality_hint.text = "\n".join(advice) if not advice.is_empty() else "Viewing detail: about %d pixels across a 90° view." % (width / 4)
	quality_hint.tooltip_text = "The output covers the whole sphere. Perspective playback and the player's selected quality also affect sharpness."
	for preset in quality_buttons:
		var comparison := Profile.new()
		comparison.apply_quality_preset(preset)
		quality_buttons[preset].set_pressed_no_signal(str(width) == comparison.width and int(recipe_fields.face_size.text) == comparison.face_size and int(crf_control.value) == comparison.crf)
	var index := fps_picker.get_item_index(int(recipe_fields.fps.text))
	if index >= 0:
		fps_picker.select(index)
	if border_hint != null and int(recipe_fields.face_size.text) > 0:
		var geometry := preload("capture_projection.gd").geometry(int(recipe_fields.face_size.text), profile.capture_border_percent)
		border_hint.text = "Extra scene context can reduce glow cuts at face edges. %d px face targets, %.0f%% more face pixels. Render time and GPU memory may increase; run a new short test. Auto-exposure seams remain." % [geometry.texture_size, (geometry.pixel_ratio - 1.0) * 100.0]


func _use_current_scene() -> void:
	if not current_scene_provider.is_valid():
		return
	var scene: Node = current_scene_provider.call()
	if scene == null or scene.scene_file_path.is_empty():
		status.text = "Save your scene in Godot first (%s), then choose Use current scene." % ("Cmd+S" if OS.get_name() == "macOS" else "Ctrl+S")
		return
	if not _save_editor_scene(scene.scene_file_path):
		return
	recipe_fields.scene_path.text = scene.scene_file_path
	_refresh_scene_cameras(true)
	_update_profile()
	_refresh_plan()
	status.text = "Current scene saved and selected. Choose a camera, then Test 1 second."


func _save_editor_scene(path: String) -> bool:
	if not current_scene_provider.is_valid() or not save_current_scene.is_valid():
		return true
	var scene: Node = current_scene_provider.call()
	if scene != null and scene.scene_file_path == path:
		if int(save_current_scene.call()) != OK:
			status.text = "Godot could not save the current scene. Save it successfully before exporting."
			return false
	return true


func _refresh_scene_cameras(choose_camera: bool = false) -> void:
	if camera_picker == null or not recipe_fields.has("camera_path"):
		return
	inspected_scene = recipe_fields.scene_path.text.strip_edges()
	inspected_stamp = FileAccess.get_modified_time(inspected_scene) if FileAccess.file_exists(inspected_scene) else 0
	scene_summary = Inspector.inspect(inspected_scene)
	scene_dirty = false
	if choose_camera:
		recipe_fields.camera_path.text = Inspector.preferred_camera(scene_summary.cameras)
	_sync_camera_picker()
	_refresh_readiness()


func _sync_camera_picker() -> void:
	if camera_picker == null or not recipe_fields.has("camera_path"):
		return
	camera_picker.clear()
	camera_picker.add_item("Choose a camera…")
	camera_picker.set_item_metadata(0, "")
	var selected: String = recipe_fields.camera_path.text.strip_edges()
	var selected_index := 0
	for camera in scene_summary.get("cameras", []):
		var index := camera_picker.item_count
		camera_picker.add_item(str(camera.path) + (" · current" if camera.current else ""))
		camera_picker.set_item_metadata(index, str(camera.path))
		camera_picker.set_item_tooltip(index, str(camera.path))
		if str(camera.path) == selected:
			selected_index = index
	if selected_index == 0 and not selected.is_empty():
		selected_index = camera_picker.item_count
		camera_picker.add_item("Manual · " + selected)
		camera_picker.set_item_metadata(selected_index, selected)
		camera_picker.set_item_tooltip(selected_index, "Not found in saved scene metadata. The capture worker will check this path at runtime.")
	camera_picker.add_item("Enter a runtime camera path…")
	camera_picker.set_item_metadata(camera_picker.item_count - 1, null)
	camera_picker.select(selected_index)


func _camera_selected(index: int) -> void:
	var path = camera_picker.get_item_metadata(index)
	if path == null:
		sections.advanced.toggle.button_pressed = true
		recipe_fields.camera_path.grab_focus()
		recipe_fields.camera_path.select_all()
		_sync_camera_picker()
		return
	recipe_fields.camera_path.text = str(path)
	_update_profile()
	_refresh_plan()


func _detect_tools(explicit: bool = true) -> void:
	var encoder := Setup.find_executable("ffmpeg" if explicit else ffmpeg.text)
	if not encoder.is_empty():
		ffmpeg.text = encoder
	var probe := Setup.find_executable("ffprobe" if explicit else ffprobe.text)
	if probe.is_empty() and not encoder.is_empty():
		probe = Setup.find_executable(encoder.get_base_dir().path_join("ffprobe.exe" if OS.get_name() == "Windows" else "ffprobe"))
	if not probe.is_empty():
		ffprobe.text = probe
	if encoder.is_empty() or probe.is_empty():
		sections.tools.toggle.button_pressed = true
	_refresh_readiness()


func _check_readiness() -> void:
	if setup_checker.busy:
		return
	if not _save_editor_scene(recipe_fields.scene_path.text.strip_edges()):
		return
	_refresh_scene_cameras(inspected_scene != recipe_fields.scene_path.text.strip_edges())
	_check_output_folder()
	var signature := [ffmpeg.text.strip_edges(), ffprobe.text.strip_edges()]
	tool_result = {}
	checked_tools = []
	check_button.disabled = true
	check_button.text = "Checking…"
	_refresh_readiness()
	var result: Dictionary = await setup_checker.check_tools(signature[0], signature[1])
	if signature == [ffmpeg.text.strip_edges(), ffprobe.text.strip_edges()]:
		tool_result = result
		checked_tools = signature
		if not result.ok:
			sections.tools.toggle.button_pressed = true
	check_button.disabled = false
	check_button.text = "Check setup"
	_update_profile()
	_save_settings()
	_refresh_readiness()


func _check_output_folder() -> void:
	writable_output = output.text.strip_edges()
	output_error = ""
	if not writable_output.is_absolute_path() or writable_output.begins_with("res://") or writable_output.begins_with("user://"):
		output_error = "Choose an absolute output folder."
		return
	if FileAccess.file_exists(writable_output):
		output_error = "The output location is a file. Choose a folder instead."
		return
	if DirAccess.make_dir_recursive_absolute(writable_output) != OK:
		output_error = "Cannot create the output folder. Choose a writable location."
		return
	var path := writable_output.path_join(".godot360-write-check-" + str(OS.get_process_id()) + "-" + str(Time.get_ticks_usec()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		output_error = "Output folder is not writable. Choose another folder or check drive access."
		return
	file.store_string("Godot360 write check")
	file.flush()
	var written := file.get_error() == OK
	file.close()
	var removed := DirAccess.remove_absolute(path) == OK
	if not written or not removed:
		output_error = "Output write check failed. Check drive access and available space."


func _numeric_error() -> String:
	for key in ["width", "face_size", "fps"]:
		if not recipe_fields[key].text.strip_edges().is_valid_int():
			return "Enter a whole number for " + {"width": "output width", "face_size": "cube face size", "fps": "frame rate"}[key] + "."
	var duration: String = recipe_fields.duration.text.strip_edges()
	if not duration.is_valid_float() or not is_finite(float(duration)) or float(duration) <= 0 or float(duration) > 3600:
		return "Enter a duration above zero and up to 3600 seconds."
	return ""


func _refresh_readiness() -> void:
	if readiness_label == null or ffmpeg == null:
		return
	var issues: Array[String] = []
	var notes: Array[String] = []
	if scene_dirty or inspected_scene != recipe_fields.scene_path.text.strip_edges():
		issues.append("Scene: refresh cameras or check setup after changing the scene.")
	elif not str(scene_summary.get("error", "")).is_empty():
		issues.append("Scene: " + str(scene_summary.error))
	elif recipe_fields.camera_path.text.strip_edges().is_empty():
		issues.append("Camera: choose a camera, or enter a runtime path under Advanced.")
	else:
		var camera_path: String = recipe_fields.camera_path.text.strip_edges()
		var cameras: Array = scene_summary.get("cameras", [])
		if not cameras.any(func(camera: Dictionary): return str(camera.path) == camera_path):
			notes.append("Manual camera: %s will be checked when the scene runs. Test before a long render." % camera_path)
		for warning in scene_summary.get("warnings", []):
			notes.append(str(warning))
	var numeric := _numeric_error()
	var valid_recipe := false
	if not numeric.is_empty():
		issues.append(numeric)
	else:
		_update_profile()
		var job: Dictionary = profile.to_dictionary()
		job.merge({"ffmpeg": ffmpeg.text.strip_edges(), "ffprobe": ffprobe.text.strip_edges(), "output_dir": output.text.strip_edges().path_join("readiness")})
		var error := IO.validate(job)
		valid_recipe = error.is_empty()
		if not error.is_empty() and not str(scene_summary.get("error", "")).is_empty():
			pass # The scene error above is more useful than a duplicate validation error.
		elif not error.is_empty():
			issues.append(error)
	var signature := [ffmpeg.text.strip_edges(), ffprobe.text.strip_edges()]
	if checked_tools != signature or tool_result.is_empty():
		issues.append("Tools: checking…" if check_button.disabled else "Tools: select Check setup to verify FFmpeg and FFprobe.")
	elif not tool_result.get("ok", false):
		issues.append("Tools: " + str(tool_result.get("error", "Check setup again.")))
	elif profile.frame_writer == "fast_png" and not tool_result.get("png", false):
		issues.append("Tools: this FFmpeg has no PNG encoder. Choose Compact PNG under Advanced.")
	else:
		for filter in Audio.required_filters(profile.to_dictionary()):
			if not str(tool_result.get("filters", "")).contains(" " + str(filter) + " "):
				issues.append("Tools: FFmpeg is missing the %s audio filter. Choose another build." % filter)
				break
	var destination: String = output.text.strip_edges()
	if destination.is_empty() or not destination.is_absolute_path() or destination.begins_with("res://") or destination.begins_with("user://"):
		issues.append("Output: choose an absolute folder on your computer.")
	elif writable_output != destination:
		issues.append("Output: Check setup verifies that this folder is writable.")
	elif not output_error.is_empty():
		issues.append(output_error)
	var directory := DirAccess.open(destination)
	if directory != null:
		var available := directory.get_space_left()
		if available >= 0:
			if valid_recipe and available < StorageGuard.RESERVE + StorageGuard.capture_headroom(profile.to_dictionary()):
				issues.append("Output: not enough free space for capture working headroom. Free space or choose another drive.")
			notes.append("Available space: %.2f GiB. A test estimates the full export's storage." % (float(available) / 1073741824.0))
		else:
			issues.append("Output: available disk space could not be read. Check drive access.")
	elif writable_output == destination and output_error.is_empty():
		issues.append("Output folder is no longer accessible. Check setup again.")
	var renderer := Renderer.resolve(profile.to_dictionary())
	var renderer_name: String = {"forward_plus": "Forward+", "mobile": "Mobile", "gl_compatibility": "Compatibility"}.get(renderer.resolved_method, renderer.resolved_method)
	var renderer_note := "Capture: %s / %s · unexpected fallback stops the job." % [renderer_name, renderer.resolved_driver]
	var heading_text := "Ready for a 1-second test · scene, tools and output checked." if issues.is_empty() else "Before your first render"
	readiness_label.text = heading_text + "\n" + renderer_note + "\n" + "\n".join(issues + notes)


func _render(test_run: bool = false) -> void:
	if process_id > 0 or not pending_session.is_empty():
		return
	if not _save_editor_scene(recipe_fields.scene_path.text.strip_edges()):
		return
	_refresh_scene_cameras(inspected_scene != recipe_fields.scene_path.text.strip_edges())
	var input_error := _numeric_error()
	if not input_error.is_empty():
		status.text = input_error
		return
	if recipe_fields.camera_path.text.strip_edges().is_empty():
		status.text = "Choose a camera before rendering. Runtime-created cameras can use a manual path under Advanced."
		return
	_update_profile()
	var recipe: Dictionary = profile.to_dictionary()
	recipe.merge({"ffmpeg": ffmpeg.text.strip_edges(), "ffprobe": ffprobe.text.strip_edges(),
		"output_dir": _new_folder("test" if test_run else "render"), "mode": "render"})
	if test_run:
		recipe = Planner.test_job(recipe)
	_launch(recipe)


func _test_render() -> void:
	_render(true)


func _new_folder(prefix: String) -> String:
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	return output.text.strip_edges().path_join(prefix + "-" + stamp + "-" + str(Time.get_ticks_usec()))


func _reencode(source: String) -> void:
	if process_id > 0 or not pending_session.is_empty():
		return
	_update_profile()
	var request := {"mode": "reencode", "source_dir": source, "output_dir": _new_folder("reencode"),
		"ffmpeg": ffmpeg.text.strip_edges(), "ffprobe": ffprobe.text.strip_edges(), "crf": int(crf_control.value)}
	request.merge(Audio.settings(profile.to_dictionary()), true)
	var resolved := Planner.resolve_reencode(request)
	if not str(resolved.get("error", "")).is_empty():
		status.text = str(resolved.error)
		return
	_launch(resolved.job)


func _launch(recipe: Dictionary) -> void:
	var error: String = IO.validate(recipe)
	if not error.is_empty():
		status.text = error
		return
	playback.clear()
	_show_effect_notes([])
	folder = str(recipe.output_dir)
	preview.material = null
	preview_material = null
	preview_empty.show()
	reconnected = false
	session_owner = {}
	recovery_source = ""
	active_job = recipe.duplicate(true)
	_save_settings()
	if DirAccess.make_dir_recursive_absolute(folder) != OK or not IO.write_json(folder.path_join("job.json"), recipe):
		status.text = "Cannot write to the output folder."
		return
	recent_exports.remember(folder)
	_save_settings()
	output_button.disabled = false
	process_id = OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--log-file", folder.path_join("pipeline.log"), "--script", "res://addons/godot360/pipeline.gd", "--", "--job=" + folder.path_join("job.json")])
	if process_id <= 0:
		status.text = "Could not start the export coordinator."
		return
	_set_busy(true)
	cancel_button.disabled = false
	status.text = "Starting…"
	progress.value = 0


func _process(delta: float) -> void:
	planning_poll += delta
	if planning_poll >= 1.0:
		planning_poll = 0.0
		var path: String = recipe_fields.scene_path.text.strip_edges()
		if scene_dirty or (FileAccess.file_exists(path) and FileAccess.get_modified_time(path) != inspected_stamp):
			_refresh_scene_cameras(path != inspected_scene)
		_refresh_plan()
	if not pending_session.is_empty():
		_poll_session()
		return
	if process_id <= 0:
		return
	poll_time += delta
	if poll_time < 0.3:
		return
	poll_time = 0.0
	var state: Dictionary = IO.read_json(folder.path_join("status.json"))
	if not state.is_empty():
		progress.value = float(state.get("progress", 0.0)) * 100.0
		status.text = str(state.get("stage", "Starting…")) + "  " + str(state.get("error", ""))
		if state.get("stage") == "Rendering":
			var capture_progress: Dictionary = IO.read_json(folder.path_join("render-progress.json"))
			if capture_progress.has("remaining_seconds"):
				status.text = "Rendering · %d / %d frames · about %s remaining in capture" % [
					int(capture_progress.frame), int(capture_progress.total),
					_duration_label(float(capture_progress.remaining_seconds))]
		elif state.get("stage") == "Encoding H.264 + AAC" and not state.get("encoding", {}).is_empty():
			var encoding: Dictionary = state.encoding
			status.text = "Encoding · %d / %d frames" % [int(encoding.frames), int(encoding.total)]
			# Encoder startup dominates the first few frames; wait for a useful sample.
			if int(encoding.frames) >= maxi(10, ceili(float(encoding.total) * 0.1)) and float(encoding.get("remaining_seconds", -1)) >= 0:
				status.text += " · about " + _duration_label(float(encoding.remaining_seconds)) + " remaining in encode"
	# Reopened coordinators are not children of this editor. Their saved PID
	# cannot establish liveness; rely on fresh replies and terminal evidence.
	if (reconnected and state.get("stage") in Session.TERMINAL) or (not reconnected and not OS.is_process_running(process_id)):
		_finish_saved_job(Session.review(folder))
	elif reconnected and Time.get_ticks_msec() - session_started >= 10000:
		_begin_session("probe")


func _cancel() -> void:
	if process_id <= 0 or not pending_session.is_empty():
		return
	if reconnected:
		_begin_session("cancel")
		return
	if not IO.write_text(folder.path_join("cancel.request"), "Cancel requested by the user."):
		status.text = "Cannot request cancellation: the output folder is not writable. Check drive access and retry."
		return
	status.text = "Cancelling… Capture stops at a frame boundary; an active encoder or verifier is stopped. Files are retained."


func _set_busy(busy: bool) -> void:
	recent_exports.set_busy(busy)
	for button in [render_button, test_button, reencode_button, open_job_button]:
		button.disabled = busy
	reuse_button.disabled = busy or recovery_source.is_empty()
	cancel_button.disabled = not busy


func _open_job(path: String, remember: bool = true) -> void:
	if process_id > 0 or not pending_session.is_empty():
		return
	var record := Session.review(path)
	if record.has("error"):
		status.text = str(record.error)
		return
	playback.clear()
	_show_effect_notes([])
	folder = path
	output_button.disabled = false
	active_job = record.job
	recovery_source = ""
	preview.material = null
	preview_material = null
	preview_empty.show()
	if remember:
		recent_exports.remember(path)
	_save_settings()
	if record.terminal or record.delivered:
		_finish_saved_job(record)
		return
	session_owner = record.owner
	reconnected = true
	_begin_session("probe")


func _begin_session(action: String) -> void:
	pending_session = Session.request(folder, session_owner, action)
	if pending_session.is_empty():
		_finish_saved_job(Session.review(folder))
		return
	session_started = Time.get_ticks_msec()
	_set_busy(true)
	cancel_button.disabled = true
	if action == "cancel":
		status.text = "Requesting cancellation…"
	elif process_id <= 0:
		status.text = "Checking the saved job’s coordinator…"


func _poll_session() -> void:
	var reply := Session.response(folder, pending_session)
	if not reply.is_empty():
		var action: String = pending_session.action
		Session.clear_request(folder, pending_session)
		pending_session = {}
		process_id = int(reply.pid)
		session_started = Time.get_ticks_msec()
		_set_busy(true)
		status.text = "Cancellation acknowledged. Waiting for the export to stop…" if action == "cancel" else "Connected · " + str(reply.get("state", {}).get("stage", "Working"))
		return
	# Terminal files can be written just before the coordinator exits, without a reply.
	var state := IO.read_json(folder.path_join("status.json"))
	if state.get("stage") in Session.TERMINAL or Time.get_ticks_msec() - session_started >= 5000:
		var cancelling: bool = pending_session.action == "cancel"
		Session.clear_request(folder, pending_session)
		pending_session = {}
		_finish_saved_job(Session.review(folder))
		if cancelling and not state.get("stage") in Session.TERMINAL:
			status.text = "Cancellation was not acknowledged. Reopen the job to retry.\n" + status.text


func _finish_saved_job(record: Dictionary) -> void:
	process_id = -1
	reconnected = false
	var state: Dictionary = record.get("state", {})
	var recovery: Dictionary = record.get("recovery", {})
	recovery_source = str(recovery.get("source_dir", "")) if recovery.get("can_reencode", false) else ""
	_set_busy(false)
	progress.value = float(state.get("progress", 0)) * 100.0
	if record.get("delivered", false):
		progress.value = 100
		playback.select_job(folder)
		if FileAccess.file_exists(folder.path_join("preview.png")):
			_show_preview()
		status.text = "Complete · video-360.mp4 and report.json are ready. YouTube playback still needs a manual check."
		if active_job.get("mode") == "test":
			sample_record = Planner.load_sample(folder)
			_refresh_plan()
			_save_settings()
			status.text = "Test complete · Review the sample and estimate before rendering the full video."
		elif active_job.get("mode") == "reencode":
			status.text = "Re-encode complete · Original capture preserved. The new video and report are ready."
		var report := IO.read_json(folder.path_join("report.json"))
		var captured: Dictionary = report.get("capture_settings", {})
		if not captured.is_empty():
			status.text += "\nCaptured with %s / %s." % [captured.get("renderer", "unknown"), captured.get("rendering_driver", "unknown")]
		else:
			status.text += "\nLegacy capture: renderer evidence is in the original capture-settings.json or capture.log."
		_show_effect_notes(report.get("scene_checks", {}).get("warnings", []))
	elif record.get("terminal", false):
		status.text = str(state.get("stage", "Stopped")) + " · " + str(state.get("error", ""))
		if state.get("stage") == "Complete":
			status.text = "Saved completion could not be confirmed: the verified video or successful report is missing."
		status.text += "\n" + str(recovery.get("next_step", ""))
	else:
		status.text = "No live coordinator confirmed. Saved stage: %s.\n%s\nThe exporter may still be working. Reopen this job to check again." % [str(state.get("stage", "Unknown")), str(recovery.get("next_step", ""))]
	if not record.get("delivered", false):
		sections.jobs.toggle.button_pressed = true
	recent_exports.refresh()


func _show_preview() -> void:
	var image := Image.load_from_file(folder.path_join("preview.png"))
	if image == null:
		return
	preview_material = ShaderMaterial.new()
	preview_material.shader = preload("preview.gdshader")
	preview_material.set_shader_parameter("panorama", ImageTexture.create_from_image(image))
	preview.material = preview_material
	preview_empty.hide()
	heading = Vector2.ZERO
	_update_preview()


func _video_texture(texture: Texture2D) -> void:
	preview_material = ShaderMaterial.new()
	preview_material.shader = preload("preview.gdshader")
	preview_material.set_shader_parameter("panorama", texture)
	preview.material = preview_material
	preview_empty.hide()
	_update_preview()


func _show_effect_notes(warnings: Array) -> void:
	var unique: Array[String] = []
	for warning in warnings:
		if not str(warning) in unique:
			unique.append(str(warning))
	effects_label.text = "Scene notes · Review these throughout playback\n" + "\n".join(unique)
	effects_scroll.visible = not unique.is_empty()


func _preview_input(event: InputEvent) -> void:
	if preview_material != null and event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		heading.x -= event.relative.x * 0.006
		heading.y = clampf(heading.y + event.relative.y * 0.006, -PI * 0.49, PI * 0.49)
		_update_preview()


func _update_preview() -> void:
	preview_material.set_shader_parameter("heading", heading)
	preview_material.set_shader_parameter("aspect", preview.size.x / maxf(1.0, preview.size.y))


func _browse(kind: String) -> void:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_RESOURCES if kind in ["scene", "load", "save"] else FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR if kind in ["folder", "reencode", "job"] else FileDialog.FILE_MODE_SAVE_FILE if kind in ["save", "diagnostics"] else FileDialog.FILE_MODE_OPEN_FILE
	if kind == "diagnostics":
		dialog.title = "Save local diagnostics ZIP"
		dialog.add_filter("*.zip", "Diagnostics bundle")
		dialog.current_dir = ProjectSettings.globalize_path("res://")
		dialog.current_file = "godot360-diagnostics-" + Time.get_datetime_string_from_system().replace(":", "-") + ".zip"
	if kind == "scene":
		dialog.add_filter("*.tscn", "Godot scene")
	if kind == "soundtrack":
		dialog.add_filter("*.wav,*.mp3,*.ogg,*.flac,*.m4a,*.aac", "Audio files")
	if kind in ["load", "save"]:
		dialog.add_filter("*.tres", "Export recipe")
	dialog.file_selected.connect(func(path: String): _selected(kind, path))
	dialog.dir_selected.connect(func(path: String): _selected(kind, path))
	dialog.canceled.connect(dialog.queue_free)
	dialog.file_selected.connect(func(_path: String): dialog.queue_free())
	dialog.dir_selected.connect(func(_path: String): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered_ratio(0.65)


func _selected(kind: String, path: String) -> void:
	match kind:
		"diagnostics": _save_diagnostics(path)
		"scene":
			recipe_fields.scene_path.text = path
			_refresh_scene_cameras(true)
			_update_profile()
			_refresh_plan()
		"soundtrack":
			soundtrack_field.text = ProjectSettings.localize_path(path)
			if audio_mode_control.selected == 0:
				audio_mode_control.select(1)
			_update_profile()
			_refresh_audio_enabled()
			_refresh_plan()
		"ffmpeg":
			ffmpeg.text = path
			var sibling := path.get_base_dir().path_join("ffprobe.exe" if OS.get_name() == "Windows" else "ffprobe")
			if FileAccess.file_exists(sibling):
				ffprobe.text = sibling
		"ffprobe": ffprobe.text = path
		"folder": output.text = path
		"reencode": _reencode(path)
		"job": _open_job(path)
		"load":
			var loaded = load(path)
			if loaded != null and loaded.get_script() == Profile:
				profile = loaded.duplicate()
				_refresh_fields()
			else:
				status.text = "Select a Godot360 export recipe."
		"save":
			var error := _numeric_error()
			if not error.is_empty():
				status.text = error
				return
			_update_profile()
			status.text = "Recipe saved." if ResourceSaver.save(profile, path) == OK else "Could not save recipe."


func _save_diagnostics(path: String) -> void:
	var result := Diagnostics.build(folder, path)
	diagnostics_result.text = str(result.error) if not str(result.error).is_empty() else "Diagnostics saved: " + str(result.path) + "\nReview the ZIP contents before sharing."


func _save_settings() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot360"))
	var config := ConfigFile.new()
	config.set_value("tools", "ffmpeg", ffmpeg.text)
	config.set_value("tools", "ffprobe", ffprobe.text)
	config.set_value("export", "output", output.text)
	config.set_value("export", "last_folder", folder)
	config.set_value("export", "sample_folder", sample_record.get("folder", ""))
	config.set_value("export", "recent_folders", recent_exports.paths)
	for key in ["crf", "random_seed", "warmup_frames", "frame_writer", "rendering_method", "rendering_driver", "capture_border_percent"]:
		config.set_value("advanced", key, profile.get(key))
	for key in Audio.DEFAULTS:
		config.set_value("audio", key, profile.get(key))
	for key in recipe_fields:
		config.set_value("recipe", key, recipe_fields[key].text)
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	ffmpeg.text = str(config.get_value("tools", "ffmpeg", "ffmpeg"))
	ffprobe.text = str(config.get_value("tools", "ffprobe", "ffprobe"))
	output.text = str(config.get_value("export", "output", output.text))
	for key in recipe_fields:
		recipe_fields[key].text = str(config.get_value("recipe", key, recipe_fields[key].text))
	for key in ["crf", "random_seed", "warmup_frames", "frame_writer", "rendering_method", "rendering_driver", "capture_border_percent"]:
		profile.set(key, config.get_value("advanced", key, profile.get(key)))
	for key in Audio.DEFAULTS:
		profile.set(key, config.get_value("audio", key, profile.get(key)))
	_refresh_audio_fields()
	storage.select(0 if profile.frame_writer == "fast_png" else 1)
	crf_control.set_value_no_signal(profile.crf)
	renderer_control.select(Renderer.METHODS.find(profile.rendering_method))
	driver_control.select(Renderer.DRIVERS.find(profile.rendering_driver))
	border_control.set_value_no_signal(profile.capture_border_percent)
	sample_record = Planner.load_sample(str(config.get_value("export", "sample_folder", "")))
	folder = str(config.get_value("export", "last_folder", ""))
	# Migrate the previous single-job preference only when history is absent.
	recent_exports.restore(config.get_value("export", "recent_folders", [folder]))
	if not folder.is_empty():
		_open_job(folder, false)


func _duration_label(seconds: float) -> String:
	var rounded: int = ceili(seconds)
	return "%dm %02ds" % [rounded / 60, rounded % 60] if rounded >= 60 else "%ds" % rounded


func _refresh_plan() -> void:
	if planning_label == null or refreshing_fields:
		return
	_refresh_quality_hint()
	_refresh_readiness()
	if sample_record.is_empty():
		planning_label.text = "Test the first second to estimate export time and disk space at these settings."
		return
	if not _numeric_error().is_empty():
		planning_label.text = "Correct the video settings to update the estimate."
		return
	_update_profile()
	var target: Dictionary = profile.to_dictionary()
	target.merge({"ffmpeg": ffmpeg.text.strip_edges(), "ffprobe": ffprobe.text.strip_edges()})
	var sample: Dictionary = sample_record.job
	var scene_changed: bool = int(sample.get("scene_modified_time", 0)) != FileAccess.get_modified_time(str(sample.scene_path))
	var folder_changed: bool = str(sample_record.folder).get_base_dir().replace("\\", "/").simplify_path() != output.text.strip_edges().replace("\\", "/").simplify_path()
	var estimate := Planner.estimate(sample, sample_record.report, sample_record.storage, target)
	if estimate.is_empty() or scene_changed or folder_changed:
		planning_label.text = "Settings, renderer, engine, soundtrack, saved project/scene, or output folder changed. Run Test 1 second again for a current estimate."
		return
	var available: int = -1
	var directory := DirAccess.open(output.text.strip_edges())
	if directory != null:
		available = directory.get_space_left()
	planning_label.text = "Estimated export: %s · Retained files: %.2f GiB\nSuggested free space: %.2f GiB" % [
		_duration_label(float(estimate.estimated_total_seconds)), float(estimate.estimated_retained_bytes) / 1073741824.0,
		float(estimate.suggested_free_bytes) / 1073741824.0]
	if available > 0:
		planning_label.text += " · Available: %.2f GiB" % (available / 1073741824.0)
		if available < int(estimate.suggested_free_bytes):
			planning_label.text += "\nAvailable space is below the estimate."
	planning_label.text += "\nBased on the first second; later content may differ. Re-test after scene or asset edits."
