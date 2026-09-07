@tool
extends RefCounted
## Presentation only. The studio panel retains recipe and job coordination.


static func build(panel: Control) -> void:
	panel.custom_minimum_size = Vector2(0, 350)
	panel.add_theme_constant_override("separation", 20)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(490, 350)
	panel.add_child(left)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(490, 225)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)
	var settings := VBoxContainer.new()
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.add_theme_constant_override("separation", 6)
	scroll.add_child(settings)
	var title := Label.new()
	title.text = "GODOT360 STUDIO   /   0.8.0"
	title.add_theme_font_size_override("font_size", 19)
	settings.add_child(title)
	_scene(panel, settings)
	_export(panel, settings)
	panel._build_audio_controls(settings)
	_advanced(panel, settings)
	_tools(panel, settings)
	_saved(panel, settings)
	var actions := HBoxContainer.new()
	left.add_child(actions)
	panel.test_button = panel._button(actions, "Test 1 second", panel._test_render)
	panel.test_button.tooltip_text = "Render the first second at the selected quality, then estimate the full export."
	panel.render_button = panel._button(actions, "Render 360 video", panel._render)
	panel.cancel_button = panel._button(actions, "Cancel", panel._cancel)
	panel.cancel_button.disabled = true
	_viewer(panel)


static func _scene(panel: Control, parent: Control) -> void:
	_heading(parent, "1  Scene and camera")
	var actions := HBoxContainer.new()
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
	panel.camera_picker.custom_minimum_size.x = 260
	panel.camera_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(panel.camera_picker)
	panel.camera_picker.item_selected.connect(panel._camera_selected)
	_note(parent, "Current scene saves automatically. Other scenes use saved files." if panel.current_scene_provider.is_valid() else "Exports use saved scene files.")


static func _export(panel: Control, parent: Control) -> void:
	_heading(parent, "2  Video")
	var quality := HBoxContainer.new()
	parent.add_child(quality)
	for pair in [["Draft · 2K", "draft"], ["Production · 4K", "production"], ["Detail · 8K", "detail"]]:
		var button: Button = panel._button(quality, pair[0], func():
			panel._update_profile()
			panel.profile.apply_quality_preset(pair[1])
			panel._refresh_fields())
		button.toggle_mode = true
		panel.quality_buttons[pair[1]] = button
	panel.quality_hint = _note(parent, "")
	var grid := _grid(parent)
	panel.recipe_fields.duration = panel._field(grid, "Duration (seconds)", str(panel.profile.duration))
	_label(grid, "Frames per second")
	panel.fps_picker = OptionButton.new()
	for rate in [24, 25, 30, 50, 60]:
		panel.fps_picker.add_item(str(rate), rate)
	grid.add_child(panel.fps_picker)
	panel.fps_picker.item_selected.connect(func(index: int):
		panel.recipe_fields.fps.text = str(panel.fps_picker.get_item_id(index))
		panel._refresh_plan())
	panel.output = panel._field(grid, "Save exports in", ProjectSettings.globalize_path("res://renders"))
	var actions := HBoxContainer.new()
	parent.add_child(actions)
	panel._button(actions, "Choose folder…", panel._browse.bind("folder"))
	_note(actions, "Each export gets its own folder.")


static func _advanced(panel: Control, parent: Control) -> void:
	var section := foldout(panel, parent, "advanced", "Advanced capture and encoding")
	var grid := _grid(section)
	for entry in [["camera_path", "Manual camera path"], ["width", "Output width (2:1)"], ["face_size", "Cube face size"], ["fps", "Custom FPS value"]]:
		panel.recipe_fields[entry[0]] = panel._field(grid, entry[1], str(panel.profile.get(entry[0])))
	# Keep the recipe binding for compatibility, but expose only the supported FPS picker.
	panel.recipe_fields.fps.hide()
	grid.get_child(grid.get_child_count() - 2).hide()
	_note(section, "Manual camera paths are relative to the scene root. Use this for cameras created by scripts at runtime.")
	var renderer_grid := _grid(section)
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
	renderer_grid.add_child(panel.driver_control)
	panel.driver_control.item_selected.connect(func(index: int):
		panel.profile.rendering_driver = panel.Renderer.DRIVERS[index]
		panel._refresh_plan())
	_note(section, "Project preserves the saved project's renderer. Overrides affect new captures; re-encoding keeps the original pixels. A fallback stops capture with a diagnostic.")
	panel._button(section, "Renderer support and scene effects", func(): OS.shell_open(ProjectSettings.globalize_path("res://addons/godot360/RENDERERS.md")))
	var row := HBoxContainer.new()
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
	panel.crf_control.value_changed.connect(func(value: float):
		panel.profile.crf = int(value)
		panel._refresh_plan())


static func _tools(panel: Control, parent: Control) -> void:
	var section := foldout(panel, parent, "tools", "Tool setup")
	_note(section, "FFmpeg encodes the video; FFprobe verifies it. Select their files or find installed tools. Platform setup has download and installation steps.")
	var grid := _grid(section)
	panel.ffmpeg = panel._field(grid, "FFmpeg", "ffmpeg")
	panel.ffprobe = panel._field(grid, "FFprobe", "ffprobe")
	var actions := HBoxContainer.new()
	section.add_child(actions)
	panel._button(actions, "FFmpeg…", panel._browse.bind("ffmpeg"))
	panel._button(actions, "FFprobe…", panel._browse.bind("ffprobe"))
	panel._button(actions, "Find installed tools", panel._detect_tools)
	panel._button(actions, "Platform setup", func(): OS.shell_open(ProjectSettings.globalize_path("res://addons/godot360/PLATFORMS.md")))


static func _saved(panel: Control, parent: Control) -> void:
	var recipes := foldout(panel, parent, "recipes", "Recipes and examples")
	var row := HBoxContainer.new()
	recipes.add_child(row)
	panel._button(row, "Load recipe…", panel._browse.bind("load"))
	panel._button(row, "Save recipe…", panel._browse.bind("save"))
	row = HBoxContainer.new()
	recipes.add_child(row)
	panel._button(row, "Calibration defaults", func():
		panel.profile = panel.Profile.new()
		panel._refresh_fields())
	panel._button(row, "Motion lab", func():
		panel.profile = load("res://addons/godot360/examples/timeline.tres").duplicate()
		panel._refresh_fields())
	_note(recipes, "Calibration checks all six directions. Motion lab demonstrates an animated camera.")
	var jobs := foldout(panel, parent, "jobs", "Saved exports and recovery")
	row = HBoxContainer.new()
	jobs.add_child(row)
	panel.open_job_button = panel._button(row, "Open saved job…", panel._browse.bind("job"))
	panel.reencode_button = panel._button(row, "Re-encode saved…", panel._browse.bind("reencode"))
	panel.reencode_button.tooltip_text = "Change quality or audio using a completed capture, without rendering again."
	panel.reuse_button = panel._button(jobs, "Re-encode this capture", func(): panel._reencode(panel.recovery_source))
	panel.reuse_button.disabled = true
	panel._button(jobs, "Save diagnostics…", panel._browse.bind("diagnostics"))
	panel.diagnostics_result = _note(jobs, "Save reports and logs as a local ZIP. Review it before sharing; paths may be included.")


static func _viewer(panel: Control) -> void:
	var viewer := VBoxContainer.new()
	viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewer.custom_minimum_size.x = 320
	viewer.add_theme_constant_override("separation", 8)
	panel.add_child(viewer)
	var row := HBoxContainer.new()
	viewer.add_child(row)
	var heading := _heading(row, "3  Check and render")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.check_button = panel._button(row, "Check setup", panel._check_readiness)
	var readiness_scroll := ScrollContainer.new()
	readiness_scroll.custom_minimum_size.y = 90
	readiness_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	viewer.add_child(readiness_scroll)
	panel.readiness_label = _note(readiness_scroll, "Choose a scene, then check your setup.")
	panel.readiness_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.planning_label = _note(viewer, "")
	_label(viewer, "360° still preview · Drag to look around")
	panel.preview = ColorRect.new()
	panel.preview.custom_minimum_size = Vector2(320, 130)
	panel.preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.preview.color = Color("101e29")
	panel.preview.gui_input.connect(panel._preview_input)
	panel.preview.resized.connect(func():
		if panel.preview_material != null:
			panel._update_preview())
	viewer.add_child(panel.preview)
	panel.preview_empty = Label.new()
	panel.preview_empty.text = "Your first frame will appear here.\nStart with Test 1 second."
	panel.preview_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.preview_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.preview_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.preview.add_child(panel.preview_empty)
	panel.preview_empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.progress = ProgressBar.new()
	viewer.add_child(panel.progress)
	panel.status = _note(viewer, "Choose a scene or try Calibration under Recipes and examples.")
	row = HBoxContainer.new()
	viewer.add_child(row)
	panel.output_button = panel._button(row, "Open output", func():
		if not panel.folder.is_empty():
			OS.shell_open(panel.folder))
	panel.output_button.disabled = true
	panel._button(row, "Quick start", func():
		OS.shell_open(ProjectSettings.globalize_path("res://addons/godot360/QUICKSTART.md")))


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
	label.add_theme_font_size_override("font_size", 16)
	return label


static func _note(parent: Control, text: String) -> Label:
	var label := _label(parent, text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
