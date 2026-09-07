@tool
extends HBoxContainer

const Profile = preload("export_profile.gd")
const IO = preload("job_io.gd")
const Planner = preload("job_planner.gd")
const Audio = preload("audio_plan.gd")
const Session = preload("job_session.gd")
const Diagnostics = preload("diagnostics.gd")
const AUDIO_MODES = ["scene", "soundtrack", "mix"]
const SETTINGS_PATH = "res://.umbral360/settings.cfg"
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


func _ready() -> void:
	custom_minimum_size = Vector2(0, 350)
	add_theme_constant_override("separation", 24)
	var left_column := VBoxContainer.new()
	left_column.custom_minimum_size = Vector2(545, 350)
	add_child(left_column)
	var settings_scroll := ScrollContainer.new()
	settings_scroll.custom_minimum_size = Vector2(545, 225)
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_child(settings_scroll)
	var settings := VBoxContainer.new()
	settings.custom_minimum_size.x = 520
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scroll.add_child(settings)
	var title := Label.new()
	title.text = "GODOT360 STUDIO   /   0.8.0"
	title.add_theme_font_size_override("font_size", 19)
	settings.add_child(title)
	var hint := Label.new()
	hint.text = "Mono 360 · SDR · Stereo audio · Compatibility renderer"
	settings.add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 2
	settings.add_child(grid)
	for entry in [["scene_path", "Scene (.tscn)"], ["camera_path", "Camera node path"],
		["width", "Output width (2:1)"], ["face_size", "Cube face size"], ["fps", "Frames per second"], ["duration", "Duration (seconds)"]]:
		var field := _field(grid, entry[1], str(profile.get(entry[0])))
		recipe_fields[entry[0]] = field
	ffmpeg = _field(grid, "FFmpeg executable", "ffmpeg")
	ffprobe = _field(grid, "FFprobe executable", "ffprobe")
	output = _field(grid, "Output parent folder", ProjectSettings.globalize_path("res://renders"))
	var browse_row := HBoxContainer.new()
	settings.add_child(browse_row)
	for pair in [["Scene…", "scene"], ["FFmpeg…", "ffmpeg"], ["FFprobe…", "ffprobe"], ["Folder…", "folder"]]:
		_button(browse_row, pair[0], _browse.bind(pair[1]))
	var quality_row := HBoxContainer.new()
	settings.add_child(quality_row)
	for pair in [["Draft · 2K", "draft"], ["Production · 4K", "production"], ["Detail · 8K", "detail"]]:
		_button(quality_row, pair[0], func():
			_update_profile()
			profile.apply_quality_preset(pair[1])
			_refresh_fields())
	quality_hint = Label.new()
	quality_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quality_hint.custom_minimum_size.x = 480
	settings.add_child(quality_hint)
	for key in ["width", "face_size"]:
		recipe_fields[key].text_changed.connect(func(_value: String): _refresh_quality_hint())
	var storage_row := HBoxContainer.new()
	settings.add_child(storage_row)
	var storage_label := Label.new()
	storage_label.text = "Frame storage"
	storage_row.add_child(storage_label)
	storage = OptionButton.new()
	storage.add_item("Fast PNG · larger files")
	storage.add_item("Compact PNG · slower")
	storage.tooltip_text = "Both preserve identical pixels. Fast PNG uses FFmpeg compression and more temporary disk space."
	storage_row.add_child(storage)
	storage.item_selected.connect(func(index: int): profile.frame_writer = "fast_png" if index == 0 else "png")
	storage.item_selected.connect(func(_index: int): _refresh_plan())
	var encoding_row := HBoxContainer.new()
	settings.add_child(encoding_row)
	var crf_label := Label.new()
	crf_label.text = "H.264 CRF"
	encoding_row.add_child(crf_label)
	crf_control = SpinBox.new()
	crf_control.min_value = 12
	crf_control.max_value = 28
	crf_control.value = profile.crf
	crf_control.tooltip_text = "Lower values retain more detail and increase video size. Applies to renders and re-encoding."
	crf_control.value_changed.connect(func(value: float):
		profile.crf = int(value)
		_refresh_plan())
	encoding_row.add_child(crf_control)
	reencode_button = _button(encoding_row, "Re-encode saved…", _browse.bind("reencode"))
	reencode_button.tooltip_text = "Choose a completed original capture folder. Its video timing is preserved; current CRF and audio controls apply to the new video."
	var jobs_row := HBoxContainer.new()
	settings.add_child(jobs_row)
	open_job_button = _button(jobs_row, "Open saved job…", _browse.bind("job"))
	open_job_button.tooltip_text = "Inspect an earlier export or reconnect to its running coordinator."
	reuse_button = _button(jobs_row, "Re-encode this capture", func(): _reencode(recovery_source))
	reuse_button.disabled = true
	var diagnostics_row := VBoxContainer.new()
	settings.add_child(diagnostics_row)
	_button(diagnostics_row, "Save diagnostics…", _browse.bind("diagnostics"))
	diagnostics_result = Label.new()
	diagnostics_result.text = "Local ZIP of this job's reports and logs. Review before sharing; paths may be included."
	diagnostics_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostics_result.custom_minimum_size.x = 480
	diagnostics_row.add_child(diagnostics_result)
	_build_audio_controls(settings)
	var actions := HBoxContainer.new()
	left_column.add_child(actions)
	test_button = _button(actions, "Test 1 second", _test_render)
	test_button.tooltip_text = "Render up to the first second, using the selected production settings."
	render_button = _button(actions, "Render 360 video", _render)
	cancel_button = _button(actions, "Cancel", _cancel)
	cancel_button.disabled = true
	_button(actions, "Open output", func():
		if not folder.is_empty():
			OS.shell_open(folder))
	var presets := HBoxContainer.new()
	settings.add_child(presets)
	_button(presets, "Load recipe…", _browse.bind("load"))
	_button(presets, "Save recipe…", _browse.bind("save"))
	_button(presets, "Calibration defaults", func():
		profile = Profile.new()
		_refresh_fields())
	_button(presets, "Motion lab", func():
		profile = load("res://addons/umbral360/examples/timeline.tres").duplicate()
		_refresh_fields())
	var viewer := VBoxContainer.new()
	viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(viewer)
	var preview_title := Label.new()
	preview_title.text = "SPHERICAL STILL PREVIEW · Drag to look around after rendering"
	viewer.add_child(preview_title)
	planning_label = Label.new()
	planning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	viewer.add_child(planning_label)
	preview = ColorRect.new()
	preview.custom_minimum_size = Vector2(350, 225)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.color = Color("101e29")
	preview.gui_input.connect(_preview_input)
	preview.resized.connect(func():
		if preview_material != null:
			_update_preview())
	viewer.add_child(preview)
	progress = ProgressBar.new()
	progress.show_percentage = true
	viewer.add_child(progress)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text = "Ready. Select a scene and its Camera3D. Each export gets a new folder."
	viewer.add_child(status)
	var note := Label.new()
	note.text = "FFmpeg with libx264 + AAC and FFprobe are required. Frames and logs are retained."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	viewer.add_child(note)
	_load_settings()
	_refresh_quality_hint()
	for field in recipe_fields.values() + [ffmpeg, ffprobe, output]:
		field.text_changed.connect(func(_value: String): _refresh_plan())
	_refresh_plan()


func _field(parent: Control, label_text: String, value: String) -> LineEdit:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var edit := LineEdit.new()
	edit.text = value
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size.x = 280
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
	title.text = "Audio and synchronization"
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
	soundtrack_field.placeholder_text = "res://audio/music.wav or an absolute path"
	soundtrack_field.text_changed.connect(func(_value: String): _refresh_plan())
	var row := HBoxContainer.new()
	parent.add_child(row)
	_button(row, "Soundtrack…", _browse.bind("soundtrack"))
	var timing := Label.new()
	timing.text = "Positive offset = later · Negative = earlier"
	row.add_child(timing)
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
	hint.custom_minimum_size.x = 480
	parent.add_child(hint)
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
	_refresh_audio_fields()
	_refresh_quality_hint()
	refreshing_fields = false
	_refresh_plan()


func _refresh_quality_hint() -> void:
	if quality_hint == null:
		return
	var width: int = int(recipe_fields.width.text)
	var advice: Array[String] = IO.quality_advice({"width": width, "face_size": int(recipe_fields.face_size.text)})
	quality_hint.text = "\n".join(advice) if not advice.is_empty() else "About %d source columns across a 90-degree view. Playback quality also depends on the player." % (width / 4)


func _render(test_run: bool = false) -> void:
	if process_id > 0 or not pending_session.is_empty():
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
	folder = str(recipe.output_dir)
	reconnected = false
	session_owner = {}
	recovery_source = ""
	active_job = recipe.duplicate(true)
	_save_settings()
	if DirAccess.make_dir_recursive_absolute(folder) != OK or not IO.write_json(folder.path_join("job.json"), recipe):
		status.text = "Cannot write to the output folder."
		return
	process_id = OS.create_process(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--log-file", folder.path_join("pipeline.log"), "--script", "res://addons/umbral360/pipeline.gd", "--", "--job=" + folder.path_join("job.json")])
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
	for button in [render_button, test_button, reencode_button, open_job_button]:
		button.disabled = busy
	reuse_button.disabled = busy or recovery_source.is_empty()
	cancel_button.disabled = not busy


func _open_job(path: String) -> void:
	if process_id > 0 or not pending_session.is_empty():
		return
	var record := Session.review(path)
	if record.has("error"):
		status.text = str(record.error)
		return
	folder = path
	active_job = record.job
	recovery_source = ""
	preview.material = null
	preview_material = null
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
	elif record.get("terminal", false):
		status.text = str(state.get("stage", "Stopped")) + " · " + str(state.get("error", ""))
		if state.get("stage") == "Complete":
			status.text = "Saved completion could not be confirmed: the verified video or successful report is missing."
		status.text += "\n" + str(recovery.get("next_step", ""))
	else:
		status.text = "No live coordinator confirmed. Saved stage: %s.\n%s\nThe exporter may still be working. Reopen this job to check again." % [str(state.get("stage", "Unknown")), str(recovery.get("next_step", ""))]


func _show_preview() -> void:
	var image := Image.load_from_file(folder.path_join("preview.png"))
	if image == null:
		return
	preview_material = ShaderMaterial.new()
	preview_material.shader = preload("preview.gdshader")
	preview_material.set_shader_parameter("panorama", ImageTexture.create_from_image(image))
	preview.material = preview_material
	heading = Vector2.ZERO
	_update_preview()


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
		"scene": recipe_fields.scene_path.text = path
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
			_update_profile()
			status.text = "Recipe saved." if ResourceSaver.save(profile, path) == OK else "Could not save recipe."


func _save_diagnostics(path: String) -> void:
	var result := Diagnostics.build(folder, path)
	diagnostics_result.text = str(result.error) if not str(result.error).is_empty() else "Diagnostics saved: " + str(result.path) + "\nReview the ZIP contents before sharing."


func _save_settings() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.umbral360"))
	var config := ConfigFile.new()
	config.set_value("tools", "ffmpeg", ffmpeg.text)
	config.set_value("tools", "ffprobe", ffprobe.text)
	config.set_value("export", "output", output.text)
	config.set_value("export", "last_folder", folder)
	config.set_value("export", "sample_folder", sample_record.get("folder", ""))
	for key in ["crf", "random_seed", "warmup_frames", "frame_writer"]:
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
	for key in ["crf", "random_seed", "warmup_frames", "frame_writer"]:
		profile.set(key, config.get_value("advanced", key, profile.get(key)))
	for key in Audio.DEFAULTS:
		profile.set(key, config.get_value("audio", key, profile.get(key)))
	_refresh_audio_fields()
	storage.select(0 if profile.frame_writer == "fast_png" else 1)
	crf_control.set_value_no_signal(profile.crf)
	sample_record = Planner.load_sample(str(config.get_value("export", "sample_folder", "")))
	folder = str(config.get_value("export", "last_folder", ""))
	if not folder.is_empty():
		_open_job(folder)


func _duration_label(seconds: float) -> String:
	var rounded: int = ceili(seconds)
	return "%dm %02ds" % [rounded / 60, rounded % 60] if rounded >= 60 else "%ds" % rounded


func _refresh_plan() -> void:
	if planning_label == null or refreshing_fields:
		return
	if sample_record.is_empty():
		planning_label.text = "Test the first second to estimate export time and disk space at these settings."
		return
	_update_profile()
	var target: Dictionary = profile.to_dictionary()
	target.merge({"ffmpeg": ffmpeg.text.strip_edges(), "ffprobe": ffprobe.text.strip_edges()})
	var sample: Dictionary = sample_record.job
	var scene_changed: bool = int(sample.get("scene_modified_time", 0)) != FileAccess.get_modified_time(str(sample.scene_path))
	var folder_changed: bool = str(sample_record.folder).get_base_dir().replace("\\", "/").simplify_path() != output.text.strip_edges().replace("\\", "/").simplify_path()
	var estimate := Planner.estimate(sample, sample_record.report, sample_record.storage, target)
	if estimate.is_empty() or scene_changed or folder_changed:
		planning_label.text = "Settings, soundtrack, saved scene, or output folder changed. Run Test 1 second again for a current estimate."
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
