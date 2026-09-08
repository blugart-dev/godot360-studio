@tool
extends RefCounted
## Worker-owned attributes: never change an authored camera or WorldEnvironment.
const MODES = ["scene", "fixed"]
var mode := "scene"
var original: CameraAttributes
var owned: CameraAttributes
var properties: Array[StringName] = []


static func validate(job: Dictionary) -> String:
	var value = job.get("capture_exposure_mode", "scene")
	if not value is String or value not in MODES:
		return "Choose Scene or Fixed (authored) capture exposure."
	return ""


func resolve(camera: Camera3D) -> CameraAttributes:
	if mode == "scene":
		return camera.attributes
	var authored := camera.attributes
	if authored == null:
		authored = camera.get_world_3d().camera_attributes
	if authored == null:
		original = null
		owned = null
		return null
	if authored != original:
		original = authored
		owned = authored.duplicate() as CameraAttributes
		properties.clear()
		for property in authored.get_property_list():
			if int(property.usage) & PROPERTY_USAGE_STORAGE and not str(property.name).begins_with("resource_") and property.name != "script" and property.name != "auto_exposure_enabled":
				properties.append(property.name)
	# Copy current authored values after absolute-frame sampling, including DOF,
	# physical attributes and animated exposure. Reuse one resource for six views.
	for property in properties:
		var value = authored.get(property)
		if owned.get(property) != value:
			owned.set(property, value)
	owned.auto_exposure_enabled = false
	return owned
