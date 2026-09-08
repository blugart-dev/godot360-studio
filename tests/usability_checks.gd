extends SceneTree
## Saved-scene discovery, editor save boundary, preflight and compact UI behavior.
const Inspector = preload("res://addons/godot360/scene_inspector.gd")
const IO = preload("res://addons/godot360/job_io.gd")
var panel: Control
var checks := 0
var failures := 0
var settings_existed := false
var original_settings := PackedByteArray()
var initialized := false
var fixture_root: Node3D
var save_calls := 0
var save_error := OK
var fixture := ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	settings_existed = FileAccess.file_exists("res://.godot360/settings.cfg")
	if settings_existed:
		original_settings = FileAccess.get_file_as_bytes("res://.godot360/settings.cfg")
	initialized = true
	fixture = "res://.godot360/usability-" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(fixture)
	_create_scenes()
	var inspected := Inspector.inspect(fixture.path_join("inherited.tscn"))
	check(inspected.error.is_empty() and inspected.cameras.size() == 3, "Discovery includes inherited, instanced and root cameras")
	check(Inspector.preferred_camera(inspected.cameras) == "Rig/Lens", "Inherited camera-current overrides determine the preferred camera")
	check(not FileAccess.file_exists(fixture.path_join("instantiated.txt")), "Camera discovery does not instantiate user scene scripts")
	check(inspected.warnings.size() == 2, "Saved CanvasLayer and billboard risks are visible before capture")
	check(Inspector.inspect(fixture.path_join("missing.tscn")).error.contains("saved"), "Missing scenes receive actionable guidance")
	check(Inspector.preferred_camera([{"path": "A", "current": false}]) == "A", "A single camera is selected automatically")
	check(Inspector.preferred_camera([{"path": "A", "current": false}, {"path": "B", "current": false}]).is_empty(), "Multiple cameras without a current camera require a choice")
	check(Inspector.preferred_camera([{"path": "A", "current": true}, {"path": "B", "current": true}]).is_empty(), "Ambiguous current cameras also require a choice")
	root.size = Vector2i(1100, 600)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	fixture_root = Node3D.new()
	panel = preload("res://addons/godot360/studio_panel.gd").new()
	panel.current_scene_provider = func(): return fixture_root
	panel.save_current_scene = _save_scene
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel._use_current_scene()
	check(panel.status.text.contains("Save your scene") and save_calls == 0, "An unnamed editor scene cannot silently export a different scene")
	fixture_root.scene_file_path = fixture.path_join("inherited.tscn")
	save_error = ERR_CANT_CREATE
	panel._use_current_scene()
	check(panel.status.text.contains("could not save"), "Failed editor saves stop scene selection with an explanation")
	save_error = OK
	panel._use_current_scene()
	check(save_calls == 2 and panel.recipe_fields.scene_path.text == fixture_root.scene_file_path and panel.recipe_fields.camera_path.text == "Rig/Lens", "Use current scene saves and selects its preferred camera")
	panel._selected("scene", fixture.path_join("base.tscn"))
	check(panel.recipe_fields.camera_path.text == "MainCamera", "Choosing another scene replaces the previous camera path")
	panel._selected("scene", fixture.path_join("ambiguous.tscn"))
	check(panel.recipe_fields.camera_path.text.is_empty() and panel.readiness_label.text.contains("choose a camera"), "The panel requests a choice for ambiguous cameras")
	panel._render()
	check(panel.process_id <= 0 and panel.status.text.contains("Choose a camera"), "Render refuses an empty camera selection before launching")
	panel._camera_selected(2)
	check(panel.recipe_fields.camera_path.text == "Second", "Selecting a camera updates the exported recipe")
	panel._camera_selected(panel.camera_picker.item_count - 1)
	check(panel.sections.advanced.contents.visible, "Runtime-camera option opens the manual path control")
	panel.recipe_fields.camera_path.text = "Generated/Camera"
	panel._refresh_plan()
	check(panel.readiness_label.text.contains("checked when the scene runs"), "Runtime paths remain available with an explicit deferred-check note")
	panel.profile = preload("res://addons/godot360/examples/timeline.tres").duplicate()
	panel._refresh_fields()
	check(panel.recipe_fields.camera_path.text == "CameraPath/Follow/Camera3D" and panel.camera_picker.get_selected_metadata() == panel.recipe_fields.camera_path.text, "Loading a recipe preserves its authored camera selection")
	panel.border_control.value = 12.5
	check(panel.profile.to_dictionary().capture_border_percent == 12.5 and panel.border_hint.text.contains("56%"), "Capture border reaches the recipe and explains the extra pixel cost")
	panel._save_settings()
	panel.border_control.value = 0.0
	panel._load_settings()
	check(panel.profile.capture_border_percent == 12.5 and panel.border_control.value == 12.5, "Nonzero capture border survives project-local settings reload")
	panel.profile = preload("res://addons/godot360/examples/timeline.tres").duplicate()
	panel._refresh_fields()
	check(panel.border_control.value == 0.0, "Loading a legacy recipe restores its zero-border default")
	panel.recipe_fields.duration.text = "12seconds"
	panel._render()
	check(panel.process_id <= 0 and panel.status.text.contains("duration"), "Invalid numeric text cannot silently become a valid render duration")
	panel.recipe_fields.duration.text = "6"
	panel.recipe_fields.width.text = "4K"
	check(panel._numeric_error().contains("whole number"), "Custom dimensions reject malformed numeric text")
	panel.profile.apply_quality_preset("production")
	panel._refresh_fields()
	panel.recipe_fields.fps.text = "0"
	panel._refresh_plan()
	check(panel.readiness_label.text.contains("Choose 24"), "Unsupported zero FPS reports an error without running storage calculations")
	panel.fps_picker.select(panel.fps_picker.get_item_index(24))
	panel.fps_picker.item_selected.emit(panel.fps_picker.selected)
	check(panel.recipe_fields.fps.text == "24" and panel.profile.to_dictionary().fps == 24, "FPS selection reaches the recipe")
	check(not panel.soundtrack_field.visible, "Scene audio hides unused soundtrack controls")
	panel.audio_mode_control.select(1)
	panel.audio_mode_control.item_selected.emit(1)
	check(panel.soundtrack_field.visible and panel.readiness_label.text.contains("soundtrack"), "Soundtrack mode reveals its file control and missing-file guidance")
	panel.audio_mode_control.select(0)
	panel.audio_mode_control.item_selected.emit(0)
	panel.output.text = "relative-output"
	panel._check_output_folder()
	check(not panel.output_error.is_empty() and not DirAccess.dir_exists_absolute("res://relative-output"), "Preflight rejects relative output without creating it")
	panel.output.text = ProjectSettings.globalize_path(fixture.path_join("base.tscn"))
	panel._check_output_folder()
	check(panel.output_error.contains("Choose a folder"), "A file cannot pass as an output directory")
	panel.output.text = ProjectSettings.globalize_path(fixture.path_join("output"))
	panel._check_output_folder()
	check(panel.output_error.is_empty() and DirAccess.get_files_at(panel.output.text).is_empty(), "Writable output is checked and the disposable probe is removed")
	panel._selected("scene", "res://addons/godot360/examples/calibration.tscn")
	panel.ffmpeg.text = IO.argument("ffmpeg")
	panel.ffprobe.text = IO.argument("ffprobe")
	if panel.ffprobe.text.is_empty():
		panel.ffprobe.text = panel.ffmpeg.text.get_base_dir().path_join("ffprobe.exe" if OS.get_name() == "Windows" else "ffprobe")
	await panel._check_readiness()
	check(panel.tool_result.get("ok", false) and panel.readiness_label.text.begins_with("Ready for"), "Real FFmpeg/FFprobe capabilities and writable output produce a ready state")
	check(panel.setup_checker.runner == null and not panel.setup_checker.busy, "Tool checks finish and release their child process")
	panel.ffprobe.text = fixture.path_join("missing-ffprobe")
	panel._refresh_plan()
	check(not panel.readiness_label.text.begins_with("Ready for"), "Editing a tool path invalidates the previous ready state immediately")
	await panel._check_readiness()
	check(not panel.tool_result.ok and panel.sections.tools.contents.visible, "Missing tools open setup and provide an actionable error")
	panel.ffprobe.text = panel.ffmpeg.text
	await panel._check_readiness()
	check(not panel.tool_result.ok and panel.tool_result.error.contains("FFprobe"), "Selecting FFmpeg in the FFprobe field cannot pass verification")
	panel.ffprobe.text = IO.argument("ffprobe")
	if panel.ffprobe.text.is_empty():
		panel.ffprobe.text = panel.ffmpeg.text.get_base_dir().path_join("ffprobe.exe" if OS.get_name() == "Windows" else "ffprobe")
	await panel._check_readiness()
	panel.output.text += "-changed"
	panel._refresh_plan()
	check(not panel.readiness_label.text.begins_with("Ready for"), "Changing the output folder invalidates its write check")
	panel.output.text = panel.writable_output
	panel.tool_result.png = false
	panel._refresh_plan()
	check(panel.readiness_label.text.contains("Compact PNG"), "Missing PNG capability explains the available storage fallback")
	panel.storage.select(1)
	panel.storage.item_selected.emit(1)
	check(panel.readiness_label.text.begins_with("Ready for"), "Compact PNG removes the Fast PNG capability requirement")
	panel.tool_result.png = true
	panel.storage.select(0)
	panel.storage.item_selected.emit(0)
	for section in panel.sections.values():
		section.toggle.button_pressed = false
	panel.folder = ""
	panel.preview.material = null
	panel.preview_material = null
	panel.preview_empty.show()
	panel.progress.value = 0
	panel.status.text = "Setup checked. Start with Test 1 second."
	panel.sample_record = {}
	panel._refresh_plan()
	await process_frame
	await process_frame
	check(panel.size.x <= root.size.x and panel.size.y <= root.size.y, "The basic workflow fits a 1100 by 600 panel")
	check(not panel.sections.advanced.contents.visible and not panel.sections.tools.contents.visible and not panel.sections.jobs.contents.visible, "Advanced, setup and recovery controls stay collapsed during the basic workflow")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot360/usability-panel.png")
	fixture_root.free()
	print("USABILITY CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _save_scene() -> int:
	save_calls += 1
	return save_error


func _create_scenes() -> void:
	var script := "extends Node3D\nfunc _init():\n\tFileAccess.open(\"%s\", FileAccess.WRITE).store_string(\"instantiated\")\n" % fixture.path_join("instantiated.txt")
	IO.write_text(fixture.path_join("never_run.gd"), script)
	IO.write_text(fixture.path_join("rig.tscn"), '[gd_scene format=3]\n[node name="Rig" type="Node3D"]\n[node name="Lens" type="Camera3D" parent="."]\n')
	IO.write_text(fixture.path_join("base.tscn"), '[gd_scene load_steps=3 format=3]\n[ext_resource type="Script" path="%s" id="1"]\n[ext_resource type="PackedScene" path="%s" id="2"]\n[node name="Root" type="Node3D"]\nscript = ExtResource("1")\n[node name="MainCamera" type="Camera3D" parent="."]\ncurrent = true\n[node name="Rig" parent="." instance=ExtResource("2")]\n[node name="UI" type="CanvasLayer" parent="."]\n[node name="Title" type="Label3D" parent="."]\nbillboard = 1\n' % [fixture.path_join("never_run.gd"), fixture.path_join("rig.tscn")])
	IO.write_text(fixture.path_join("inherited.tscn"), '[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="%s" id="1"]\n[node name="Root" instance=ExtResource("1")]\n[node name="MainCamera" parent="." index="0"]\ncurrent = false\n[node name="Lens" parent="Rig" index="0"]\ncurrent = true\n[node name="Extra" type="Camera3D" parent="."]\n[editable path="Rig"]\n' % fixture.path_join("base.tscn"))
	IO.write_text(fixture.path_join("ambiguous.tscn"), '[gd_scene format=3]\n[node name="Root" type="Node3D"]\n[node name="First" type="Camera3D" parent="."]\n[node name="Second" type="Camera3D" parent="."]\n')


func _finalize() -> void:
	if initialized:
		if settings_existed:
			FileAccess.open("res://.godot360/settings.cfg", FileAccess.WRITE).store_buffer(original_settings)
		elif FileAccess.file_exists("res://.godot360/settings.cfg"):
			DirAccess.remove_absolute("res://.godot360/settings.cfg")


func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
