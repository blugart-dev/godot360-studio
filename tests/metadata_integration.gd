extends SceneTree
## Metadata-only integration driver for a retained encoded.mp4 (no scene capture).
const IO = preload("res://addons/godot360/job_io.gd")
const M = preload("res://addons/godot360/spherical_metadata.gd")


func _initialize() -> void:
	var error := M.inject(IO.argument("source"), IO.argument("output"), int(IO.argument("width")), int(IO.argument("height")))
	if not error.is_empty():
		push_error(error)
		quit(1)
		return
	var result := M.inspect(IO.argument("output"))
	print(JSON.stringify(result))
	quit(0 if result.get("error", "").is_empty() and result.get("fast_start", false) and result.get("spherical_v2", false) else 1)
