@tool
extends VBoxContainer
## Project-local history. Listing jobs never scans captures or contacts coordinators.
signal open_requested(path: String)
signal history_changed
const LIMIT := 12
const MAX_METADATA_BYTES := 1024 * 1024
var paths: Array[String] = []
var picker: OptionButton
var open_button: Button
var forget_button: Button
var details: Label
var busy := false


func _ready() -> void:
	var row := HBoxContainer.new()
	add_child(row)
	picker = OptionButton.new()
	picker.fit_to_longest_item = false
	picker.clip_text = true
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(picker)
	picker.item_selected.connect(func(_index: int): _show_selection())
	picker.get_popup().about_to_popup.connect(refresh)
	open_button = Button.new()
	open_button.text = "Open"
	open_button.pressed.connect(_open_selected)
	row.add_child(open_button)
	forget_button = Button.new()
	forget_button.text = "Forget"
	forget_button.tooltip_text = "Remove this entry from recent exports. Files stay on disk."
	forget_button.pressed.connect(_forget_selected)
	row.add_child(forget_button)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(details)
	refresh()


func restore(value: Variant) -> void:
	paths.clear()
	if value is Array or value is PackedStringArray:
		for entry in value:
			if not entry is String:
				continue
			var path := _normalize(entry)
			if not path.is_empty() and _index_of(path) < 0:
				paths.append(path)
			if paths.size() == LIMIT:
				break
	refresh()


func remember(value: String) -> void:
	var path := _normalize(value)
	if path.is_empty():
		return
	var index := _index_of(path)
	if index >= 0:
		paths.remove_at(index)
	paths.push_front(path)
	paths.resize(mini(paths.size(), LIMIT))
	refresh(path)


func refresh(selected: String = "") -> void:
	if picker == null:
		return
	if selected.is_empty():
		selected = _selected_path()
	picker.clear()
	for path in paths:
		var info := describe(path)
		picker.add_item(path.get_file() + " · " + str(info.state))
		picker.set_item_metadata(picker.item_count - 1, path)
		picker.set_item_tooltip(picker.item_count - 1, path)
	if paths.is_empty():
		picker.add_item("No recent exports")
	else:
		picker.select(maxi(_index_of(selected), 0))
	_show_selection()


func set_busy(value: bool) -> void:
	busy = value
	_show_selection()


func _show_selection() -> void:
	var path := _selected_path()
	var info := describe(path) if not path.is_empty() else {}
	picker.disabled = busy or paths.is_empty()
	open_button.disabled = busy or not info.get("can_open", false)
	forget_button.disabled = busy or paths.is_empty()
	details.text = "Your last 12 launched or opened exports appear here." if path.is_empty() else str(info.details)
	details.tooltip_text = path


func _open_selected() -> void:
	if busy:
		return
	# Recheck removable drives and files that may have changed since selection.
	var path := _selected_path()
	refresh(path)
	if not open_button.disabled:
		open_requested.emit(path)


func _forget_selected() -> void:
	if busy:
		return
	var index := _index_of(_selected_path())
	if index < 0:
		return
	paths.remove_at(index)
	refresh()
	history_changed.emit()


func _selected_path() -> String:
	if picker == null or paths.is_empty() or picker.selected < 0:
		return ""
	return str(picker.get_selected_metadata())


func _index_of(path: String) -> int:
	for index in range(paths.size()):
		if paths[index] == path or (OS.get_name() == "Windows" and paths[index].nocasecmp_to(path) == 0):
			return index
	return -1


static func _normalize(value: String) -> String:
	var path := value.strip_edges().replace("\\", "/")
	if path.begins_with("res://"):
		path = ProjectSettings.globalize_path(path)
	if not path.is_absolute_path() or path.begins_with("user://"):
		return ""
	return path.simplify_path().trim_suffix("/")


static func _metadata(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_METADATA_BYTES:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	return value if value is Dictionary else {}


static func describe(path: String) -> Dictionary:
	if not DirAccess.dir_exists_absolute(path):
		return {"can_open": false, "state": "Unavailable", "details": "Folder unavailable. Reconnect the drive or use Open saved job… to locate a moved export.\n" + path}
	var job := _metadata(path.path_join("job.json"))
	if job.is_empty():
		return {"can_open": false, "state": "Invalid job", "details": "job.json is missing, unreadable or invalid. Files are retained.\n" + path}
	var state := _metadata(path.path_join("status.json"))
	var report := _metadata(path.path_join("report.json"))
	var stage: String = state.get("stage", "Unknown") if state.get("stage") is String else "Unknown"
	var label := "Unconfirmed · " + stage
	if report.get("ok") is bool and report.ok and FileAccess.file_exists(path.path_join("video-360.mp4")):
		label = "Complete"
	elif stage == "Complete":
		label = "Incomplete delivery"
	elif stage in ["Failed", "Cancelled"]:
		label = stage
	var saved_mode := str(job.get("mode", "render"))
	var mode := "Re-encode" if saved_mode == "reencode" else "Test" if saved_mode == "test" else "Render"
	var summary := mode + " · " + label
	if job.get("scene_path") is String:
		summary += " · " + str(job.scene_path).get_file()
	if _number(job.get("width")) and _number(job.get("height")):
		summary += "\n%d×%d" % [int(job.width), int(job.height)]
	if _number(job.get("fps")):
		summary += " · " + String.num(float(job.fps), 2).trim_suffix(".0") + " FPS"
	if _number(job.get("duration")):
		summary += " · " + String.num(float(job.duration), 3).trim_suffix(".0") + " s"
	if label.begins_with("Unconfirmed"):
		summary += "\nOpen to check the coordinator and recovery options."
	return {"can_open": true, "state": mode + " · " + label, "details": summary + "\n" + path}


static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
