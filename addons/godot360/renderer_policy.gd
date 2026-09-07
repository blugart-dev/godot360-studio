@tool
extends RefCounted
## Resolve before launching the headless coordinator's graphical child. Never
## infer a capture renderer from the coordinator's dummy RenderingServer.
const METHODS = ["project", "forward_plus", "mobile", "gl_compatibility"]
const DRIVERS = ["project", "vulkan", "d3d12", "metal", "opengl3", "opengl3_angle", "opengl3_es"]
const CONTRACT = "six-face-sdr-v2"


static func resolve(job: Dictionary) -> Dictionary:
	var method := str(job.get("rendering_method", "project"))
	var driver := str(job.get("rendering_driver", "project"))
	var resolved := method
	if resolved == "project":
		resolved = str(ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method"))
	var resolved_driver := driver
	if driver == "project":
		resolved_driver = str(ProjectSettings.get_setting_with_override("rendering/gl_compatibility/driver" if resolved == "gl_compatibility" else "rendering/rendering_device/driver"))
	return {"requested_method": method, "requested_driver": driver,
		"resolved_method": resolved, "resolved_driver": resolved_driver, "contract": CONTRACT}


static func validate(job: Dictionary) -> String:
	if not str(job.get("rendering_method", "project")) in METHODS:
		return "Choose Project, Forward+, Mobile or Compatibility for capture."
	if not str(job.get("rendering_driver", "project")) in DRIVERS:
		return "Choose a supported graphics driver or Project."
	var selection := resolve(job)
	var gl: bool = str(selection.resolved_driver).begins_with("opengl3")
	if (selection.resolved_method == "gl_compatibility") != gl:
		return "Renderer and graphics driver do not match. Choose Project driver or a compatible explicit override."
	return ""


static func stamp(job: Dictionary) -> void:
	job.renderer_selection = resolve(job)
	job.rendering_signature = signature(job)


static func signature(job: Dictionary) -> String:
	# Conservative: all saved project settings (including platform overrides),
	# engine, host and explicit selection invalidate a measured capture estimate.
	return JSON.stringify([resolve(job), FileAccess.get_sha256("res://project.godot"),
		Engine.get_version_info().string, OS.get_name(), OS.get_processor_name()])


static func mismatch(selection: Dictionary, method: String, driver: String) -> String:
	if method != str(selection.resolved_method) or driver != str(selection.resolved_driver):
		return "Renderer fallback: requested %s / %s, started %s / %s. Capture stopped to preserve appearance. Check capture.log, fix the graphics driver or explicitly select the renderer/driver you intend to use, then run a new test." % [selection.resolved_method, selection.resolved_driver, method, driver]
	return ""
