@tool
extends RefCounted
## Presentation only. The studio panel retains recipe and job coordination.


static func build(panel: Control) -> void:
	panel.custom_minimum_size = Vector2(0, 350)
	panel.add_theme_constant_override("separation", 16)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(440, 350)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.85
	left.add_theme_constant_override("separation", 8)
	panel.add_child(left)
	var brand := HBoxContainer.new()
	left.add_child(brand)
	var title := _heading(brand, "Godot360 Studio")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var credit := _label(brand, "by Blugart")
	credit.tooltip_text = "Godot360 Studio · Version 1.0.0"
	panel.workspace_tabs = TabContainer.new()
	panel.workspace_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(panel.workspace_tabs)
	var settings := _page(panel.workspace_tabs, "Current recipe")
	var tools_page := _page(panel.workspace_tabs, "Tools")
	var library := _page(panel.workspace_tabs, "Library")
	panel.recipe_feedback = _note(settings, "")
	panel.recipe_feedback.max_lines_visible = 3
	panel.recipe_feedback.hide()
	_scene(panel, settings)
	_export(panel, settings)
	panel._build_audio_controls(settings)
	_destination(panel, settings)
	settings.move_child(panel.sections.audio.toggle, settings.get_child_count() - 1)
	settings.move_child(panel.sections.audio.contents, settings.get_child_count() - 1)
	_advanced(panel, settings)
	_tools(panel, tools_page)
	_saved(panel, library)
	var setup_row := HBoxContainer.new()
	left.add_child(setup_row)
	panel.readiness_summary = _note(setup_row, "Check your recipe before rendering.")
	panel.readiness_summary.max_lines_visible = 2
	panel.check_button = panel._button(setup_row, "Check setup", panel._check_readiness)
	panel.check_button.tooltip_text = "Save the selected open scene, verify tools and check output access. Details are in Tools."
	var actions := HBoxContainer.new()
	left.add_child(actions)
	panel.test_button = panel._button(actions, "Test 1 second", panel._test_render)
	panel.test_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.test_button.tooltip_text = "Render the first second at the selected quality, then estimate the full export."
	panel.render_button = panel._button(actions, "Render 360 video", panel._render)
	panel.render_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.render_button.tooltip_text = "Export the current recipe to a new folder. Existing captures are preserved."
	_viewer(panel)
	panel.resized.connect(func():
		var scale: float = panel.get_theme_default_base_scale()
		left.custom_minimum_size.x = 440 * scale)


static func _page(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	tabs.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 10)
	scroll.add_child(margin)
	var contents := VBoxContainer.new()
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.add_theme_constant_override("separation", 8)
	margin.add_child(contents)
	return contents


static func _scene(panel: Control, parent: Control) -> void:
	_heading(parent, "1  Scene and camera")
	var actions := HFlowContainer.new()
	parent.add_child(actions)
	panel.use_scene_button = panel._button(actions, "Use current scene", panel._use_current_scene)
	panel.use_scene_button.disabled = not panel.current_scene_provider.is_valid()
	panel.use_scene_button.tooltip_text = "Save the open scene and select it for export. New scenes must be saved in Godot first."
	panel._button(actions, "Choose scene…", panel._browse.bind("scene"))
	panel._button(actions, "Refresh cameras", panel._refresh_scene_cameras.bind(false))
	var grid := _grid(parent)
	panel.recipe_fields.scene_path = panel._field(grid, "Saved scene", panel.profile.scene_path)
	_label(grid, "Camera")
	panel.camera_picker = OptionButton.new()
	panel.camera_picker.fit_to_longest_item = false
	panel.camera_picker.custom_minimum_size.x = 180
	panel.camera_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(panel.camera_picker)
	panel.camera_picker.item_selected.connect(panel._camera_selected)
	panel.recipe_fields.scene_path.tooltip_text = "Exports use saved files. Use current scene saves the named scene; save other scene and asset edits in Godot first."


static func _export(panel: Control, parent: Control) -> void:
	_heading(parent, "2  Video")
	var quality := HFlowContainer.new()
	parent.add_child(quality)
	for pair in [["Draft · 2K", "draft"], ["Production · 4K", "production"], ["Detail · 8K", "detail"]]:
		var button: Button = panel._button(quality, pair[0], func():
			panel._update_profile()
			panel.profile.apply_quality_preset(pair[1])
			panel._refresh_fields())
		button.toggle_mode = true
		panel.quality_buttons[pair[1]] = button
	panel.quality_hint = _note(parent, "")
	panel.quality_hint.max_lines_visible = 2
	var timing := HBoxContainer.new()
	parent.add_child(timing)
	panel.recipe_fields.duration = panel._field(timing, "Duration (s)", str(panel.profile.duration))
	panel.recipe_fields.duration.custom_minimum_size.x = 70
	panel.recipe_fields.duration.tooltip_text = "Video length in seconds, from above zero to 3600. Test 1 second keeps this full duration."
	_label(timing, "FPS")
	panel.fps_picker = OptionButton.new()
	for rate in [24, 25, 30, 50, 60]:
		panel.fps_picker.add_item(str(rate), rate)
	timing.add_child(panel.fps_picker)
	panel.fps_picker.tooltip_text = "Frames per second. 30 is a practical starting point; higher rates increase render time and storage."
	panel.fps_picker.item_selected.connect(func(index: int):
		panel.recipe_fields.fps.text = str(panel.fps_picker.get_item_id(index))
		panel._refresh_plan())


static func _destination(panel: Control, parent: Control) -> void:
	var grid := _grid(parent)
	panel.output = panel._field(grid, "Save exports in", ProjectSettings.globalize_path("res://renders"))
	var actions := HBoxContainer.new()
	parent.add_child(actions)
	panel._button(actions, "Choose folder…", panel._browse.bind("folder"))
	_note(actions, "Each export gets its own folder.")
	panel.planning_label = _note(parent, "")
	panel.planning_label.max_lines_visible = 3
	panel.planning_label.tooltip_text = "This estimate describes the current recipe. A one-second sample cannot predict later scene complexity or full-job memory use."


static func _advanced(panel: Control, parent: Control) -> void:
	var section := foldout(panel, parent, "advanced", "Advanced capture and encoding")
	var grid := _grid(section)
	for entry in [["camera_path", "Manual camera path"], ["width", "Output width (2:1)"], ["face_size", "Cube face size"], ["fps", "Custom FPS value"]]:
		panel.recipe_fields[entry[0]] = panel._field(grid, entry[1], str(panel.profile.get(entry[0])))
	_note(section, "Cube face size controls captured detail. Output width covers the whole sphere; a larger output cannot restore missing detail.")
	# Keep the recipe binding for compatibility, but expose only the supported FPS picker.
	panel.recipe_fields.fps.hide()
	grid.get_child(grid.get_child_count() - 2).hide()
	_note(section, "Manual camera paths are relative to the scene root. Use this for cameras created by scripts at runtime.")
	var border_row := HBoxContainer.new()
	section.add_child(border_row)
	_label(border_row, "Capture border per edge (%)")
	panel.border_control = SpinBox.new()
	panel.border_control.min_value = 0.0
	panel.border_control.max_value = 25.0
	panel.border_control.step = 0.5
	panel.border_control.value = panel.profile.capture_border_percent
	border_row.add_child(panel.border_control)
	panel.border_hint = _note(section, "")
	panel.border_control.value_changed.connect(func(value: float):
		panel.profile.capture_border_percent = value
		panel._refresh_quality_hint()
		panel._refresh_plan())
	var renderer_grid := _grid(section)
	_label(renderer_grid, "Capture exposure")
	panel.exposure_control = OptionButton.new()
	panel.exposure_control.add_item("Scene (default)")
	panel.exposure_control.add_item("Fixed (authored)")
	panel.exposure_control.tooltip_text = "Fixed disables auto exposure on all six faces. Authored exposure values and animation remain active. Run a new short test to check brightness."
	renderer_grid.add_child(panel.exposure_control)
	panel.exposure_control.item_selected.connect(func(index: int):
		panel.profile.capture_exposure_mode = preload("capture_exposure.gd").MODES[index]
		panel._refresh_plan())
	_label(renderer_grid, "Capture renderer")
	panel.renderer_control = OptionButton.new()
	for name in ["Project renderer (default)", "Forward+", "Mobile", "Compatibility"]:
		panel.renderer_control.add_item(name)
	renderer_grid.add_child(panel.renderer_control)
	panel.renderer_control.item_selected.connect(func(index: int):
		panel.profile.rendering_method = panel.Renderer.METHODS[index]
		panel._refresh_plan())
	_label(renderer_grid, "Graphics driver")
	panel.driver_control = OptionButton.new()
	for name in ["Project driver (default)", "Vulkan", "Direct3D 12", "Metal", "OpenGL 3", "OpenGL via ANGLE", "OpenGL ES"]:
		panel.driver_control.add_item(name)
	for index in [2, 3, 5, 6]:
		panel.driver_control.set_item_tooltip(index, "Outside the Windows 1.0 launch matrix. See the support note for the complete selection.")
	renderer_grid.add_child(panel.driver_control)
	panel.driver_control.item_selected.connect(func(index: int):
		panel.profile.rendering_driver = panel.Renderer.DRIVERS[index]
		panel._refresh_plan())
	_note(section, "Project preserves the saved project's renderer. Overrides affect new captures; re-encoding keeps the original pixels. A fallback stops capture with a diagnostic.")
	panel.renderer_hint = _note(section, "")
	panel._button(section, "Quality and renderer support", panel._show_help.bind("quality"))
	var row: Container = HBoxContainer.new()
	section.add_child(row)
	_label(row, "Frame storage")
	panel.storage = OptionButton.new()
	panel.storage.add_item("Fast PNG · larger files")
	panel.storage.add_item("Compact PNG · slower")
	panel.storage.tooltip_text = "Both preserve identical pixels. Fast PNG uses more temporary disk space."
	row.add_child(panel.storage)
	panel.storage.item_selected.connect(func(index: int):
		panel.profile.frame_writer = "fast_png" if index == 0 else "png"
		panel._refresh_plan())
	row = HBoxContainer.new()
	section.add_child(row)
	_label(row, "H.264 quality (CRF)")
	panel.crf_control = SpinBox.new()
	panel.crf_control.min_value = 12
	panel.crf_control.max_value = 28
	panel.crf_control.value = panel.profile.crf
	panel.crf_control.tooltip_text = "Lower values retain more detail and increase file size. Presets choose this for you."
	row.add_child(panel.crf_control)
	_note(section, "Lower CRF = more detail and a larger video. Presets choose this for you.")
	panel.crf_control.value_changed.connect(func(value: float):
		panel.profile.crf = int(value)
		panel._refresh_plan())


static func _tools(panel: Control, parent: Control) -> void:
	var section := foldout(panel, parent, "tools", "Tool setup")
	_note(section, "FFmpeg creates your video. FFprobe verifies it. Choose the executables from an extracted installation.")
	var grid := _grid(section)
	panel.ffmpeg = panel._field(grid, "FFmpeg", "ffmpeg")
	panel.ffprobe = panel._field(grid, "FFprobe", "ffprobe")
	var actions := HFlowContainer.new()
	section.add_child(actions)
	panel._button(actions, "FFmpeg…", panel._browse.bind("ffmpeg"))
	panel._button(actions, "FFprobe…", panel._browse.bind("ffprobe"))
	panel._button(actions, "Find missing tools", panel._detect_tools)
	panel._button(actions, "Platform setup", panel._show_help.bind("setup"))
	panel.tool_summary = _note(section, "Selected paths are kept. Clear a field to use automatic discovery.")
	panel.tool_logs_button = panel._button(section, "Open setup logs", panel._open_setup_logs)
	panel.tool_logs_button.disabled = true
	_heading(parent, "Setup details · current recipe")
	panel.readiness_label = _note(parent, "Choose a scene, then check your setup.")
	panel.sections.tools.toggle.button_pressed = true


static func _saved(panel: Control, parent: Control) -> void:
	var recent := foldout(panel, parent, "recent", "Recent exports")
	panel.recent_exports = preload("recent_exports.gd").new()
	recent.add_child(panel.recent_exports)
	var recipes := foldout(panel, parent, "recipes", "Recipes and examples")
	var row: Container = HBoxContainer.new()
	recipes.add_child(row)
	panel._button(row, "Load recipe…", panel._browse.bind("load"))
	panel._button(row, "Save recipe…", panel._browse.bind("save"))
	row = HBoxContainer.new()
	recipes.add_child(row)
	panel._button(row, "Calibration defaults", func():
		panel.profile = panel.Profile.new()
		panel._refresh_fields()
		panel.workspace_tabs.current_tab = 0)
	panel._button(row, "Motion lab", func():
		panel.profile = load("res://addons/godot360/examples/timeline.tres").duplicate()
		panel._refresh_fields()
		panel.workspace_tabs.current_tab = 0)
	_note(recipes, "Calibration checks all six directions. Motion lab demonstrates an animated camera.")
	var jobs := foldout(panel, parent, "jobs", "Saved exports and recovery")
	row = HBoxContainer.new()
	jobs.add_child(row)
	panel.open_job_button = panel._button(row, "Open saved job…", panel._browse.bind("job"))
	panel.reencode_button = panel._button(row, "Re-encode saved…", panel._browse.bind("reencode"))
	panel.reencode_button.tooltip_text = "Change quality or audio using a completed capture, without rendering again."
	panel.reuse_button = panel._button(jobs, "Re-encode this capture", func(): panel._reencode(panel.recovery_source))
	panel.reuse_button.disabled = true
	_note(jobs, "Re-encoding uses the capture's scene, dimensions and frame rate, with the current recipe's quality and audio. It creates a new export.")
	panel._button(jobs, "Save diagnostics…", panel._browse.bind("diagnostics"))
	panel.diagnostics_result = _note(jobs, "Save reports and logs as a local ZIP. Review it before sharing; paths may be included.")
	panel._button(jobs, "Files, storage and recovery", panel._show_help.bind("files"))
	panel.sections.recent.toggle.button_pressed = true
	panel.sections.jobs.toggle.button_pressed = true


static func _viewer(panel: Control) -> void:
	var viewer := VBoxContainer.new()
	viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewer.custom_minimum_size.x = 320
	viewer.add_theme_constant_override("separation", 8)
	panel.add_child(viewer)
	var row: Container = HBoxContainer.new()
	viewer.add_child(row)
	var heading := _heading(row, "Opened export")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel._button(row, "Quick start", panel._show_help.bind("start"))
	panel.export_summary = _note(viewer, "No export open")
	panel.export_summary.max_lines_visible = 2
	panel.export_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row = HBoxContainer.new()
	viewer.add_child(row)
	panel.preview_kind = _label(row, "360° review")
	panel.preview_kind.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.still_button = panel._button(row, "Show still", panel._review_still)
	panel.still_button.disabled = true
	panel.still_button.tooltip_text = "Show the full-resolution opening frame. Playback uses a smaller copy."
	panel._button(row, "Reset view", func():
		panel.heading = Vector2.ZERO
		if panel.preview_material != null:
			panel._update_preview())
	panel.preview = ColorRect.new()
	panel.preview.custom_minimum_size = Vector2(320, 130)
	panel.preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.preview.color = Color("101e29")
	panel.preview.focus_mode = Control.FOCUS_ALL
	panel.preview.tooltip_text = "Drag to look around. With keyboard focus, use arrow keys; Home resets the view."
	panel.preview.gui_input.connect(panel._preview_input)
	panel.preview.resized.connect(func():
		if panel.preview_material != null:
			panel._update_preview())
	viewer.add_child(panel.preview)
	panel.preview_focus = ReferenceRect.new()
	panel.preview_focus.border_color = panel.get_theme_color("accent_color", "Editor") if panel.has_theme_color("accent_color", "Editor") else Color("80bfff")
	panel.preview_focus.border_width = 2.0
	panel.preview_focus.editor_only = false
	panel.preview_focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.preview.add_child(panel.preview_focus)
	panel.preview_focus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.preview_focus.hide()
	panel.preview.focus_entered.connect(func(): panel.preview_focus.show())
	panel.preview.focus_exited.connect(func(): panel.preview_focus.hide())
	panel.preview_empty = Label.new()
	panel.preview_empty.text = "See your scene in 360°\nChoose a scene, then Test 1 second.\nOr open an export from Library."
	panel.preview_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.preview_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.preview_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.preview_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.preview.add_child(panel.preview_empty)
	panel.preview_empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.playback = preload("playback_review.gd").new()
	panel.playback.tools_provider = func(): return {"ffmpeg": panel.ffmpeg.text.strip_edges(), "ffprobe": panel.ffprobe.text.strip_edges()}
	panel.playback.texture_changed.connect(panel._video_texture)
	panel.playback.setup_requested.connect(func(): panel.workspace_tabs.current_tab = 1)
	viewer.add_child(panel.playback)
	panel.effects_scroll = ScrollContainer.new()
	# Scene notes live in the details dialog, with a concise count beside it.
	panel.effects_scroll.hide()
	panel.add_child(panel.effects_scroll)
	panel.effects_label = _note(panel.effects_scroll, "")
	panel.progress = ProgressBar.new()
	panel.progress.show_percentage = true
	panel.progress.hide()
	viewer.add_child(panel.progress)
	row = HBoxContainer.new()
	viewer.add_child(row)
	panel.status = _note(row, "No export open. Your current recipe is on the left.")
	panel.status.max_lines_visible = 3
	panel.status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel.cancel_button = panel._button(row, "Cancel export", panel._cancel)
	panel.cancel_button.disabled = true
	panel.cancel_button.hide()
	row = HFlowContainer.new()
	viewer.add_child(row)
	panel.delivery_button = panel._button(row, "Open delivery MP4", panel._open_delivery)
	panel.delivery_button.disabled = true
	panel.delivery_button.tooltip_text = "Open video-360.mp4 in your default video player. Use a 360° player to look around."
	panel.output_button = panel._button(row, "Open folder", func():
		if not panel.folder.is_empty():
			OS.shell_open(panel.folder))
	panel.output_button.disabled = true
	panel.details_button = panel._button(row, "Export details", panel._show_export_details)
	panel.details_button.disabled = true


static func foldout(panel: Control, parent: Control, key: String, title: String) -> VBoxContainer:
	var toggle := Button.new()
	toggle.text = "+  " + title
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.toggle_mode = true
	parent.add_child(toggle)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 6)
	contents.visible = false
	parent.add_child(contents)
	toggle.toggled.connect(func(open: bool):
		contents.visible = open
		toggle.text = ("−  " if open else "+  ") + title)
	panel.sections[key] = {"toggle": toggle, "contents": contents}
	return contents


static func _grid(parent: Control) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	parent.add_child(grid)
	return grid


static func _label(parent: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	parent.add_child(label)
	return label


static func _heading(parent: Control, text: String) -> Label:
	var label := _label(parent, text)
	label.add_theme_font_size_override("font_size", label.get_theme_font_size("font_size") + 2)
	return label


static func _note(parent: Control, text: String) -> Label:
	var label := _label(parent, text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
