extends SceneTree
## Tests actual preset buttons, visible advice, and a compact panel layout.
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1400, 520)
	root.content_scale_size = root.size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	var panel = preload("res://addons/godot360/studio_panel.gd").new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_find_button(panel, "Production · 4K").pressed.emit()
	panel.storage.select(1)
	panel.storage.item_selected.emit(1)
	check(panel.profile.to_dictionary().frame_writer == "png", "Storage choice reaches the serialized export recipe")
	panel.profile.frame_writer = "fast_png"
	panel._refresh_fields()
	check(panel.storage.selected == 0, "Loading a recipe restores the storage control")
	check(panel.recipe_fields.width.text == "4096" and panel.recipe_fields.face_size.text == "2048", "Production button updates output and capture resolution")
	check(panel.profile.crf == 16 and panel.quality_hint.text.contains("1024"), "Production button updates quality and viewing detail advice")
	_find_button(panel, "Detail · 8K").pressed.emit()
	check(panel.recipe_fields.width.text == "7680" and panel.recipe_fields.face_size.text == "3072", "Detail button selects high-resolution cube capture")
	_find_button(panel, "Draft · 2K").pressed.emit()
	check(panel.recipe_fields.width.text == "2048" and panel.profile.crf == 18 and panel.quality_hint.text.contains("Draft resolution"), "Draft button is labeled with its viewing limitation")
	panel.recipe_fields.width.text = "7680"
	panel.recipe_fields.width.text_changed.emit("7680")
	check(panel.quality_hint.text.contains("Cube faces limit detail"), "Changing output alone exposes the capture bottleneck")
	_find_button(panel, "Production · 4K").pressed.emit()
	await process_frame
	await RenderingServer.frame_post_draw
	check(panel.size.y <= root.size.y, "Studio fits a compact bottom panel without extending below the window")
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://.godot360/quality-panel.png"))
	print("QUALITY PANEL CHECKS: 8 checks, %d failures" % failures)
	quit(0 if failures == 0 else 1)


func _find_button(node: Node, label: String) -> Button:
	if node is Button and node.text == label:
		return node
	for child in node.get_children():
		var button := _find_button(child, label)
		if button != null:
			return button
	return null


func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)
