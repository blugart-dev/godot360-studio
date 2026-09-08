extends RefCounted
## Add context around a 90-degree face without reducing its core pixel density.
const MAX_BORDER_PERCENT := 25.0


static func validate(job: Dictionary) -> String:
	var value = job.get("capture_border_percent", 0.0)
	if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0.0 or float(value) > MAX_BORDER_PERCENT:
		return "Capture border must be a finite number between 0 and 25 percent per edge."
	return ""


static func geometry(face_size: int, percent: float = 0.0) -> Dictionary:
	var border := ceili(face_size * percent / 100.0)
	var texture_size := face_size + border * 2
	var scale := float(face_size) / float(texture_size)
	return {"border_pixels": border, "texture_size": texture_size,
		"uv_scale": scale, "fov": rad_to_deg(2.0 * atan(1.0 / scale)),
		"pixel_ratio": pow(float(texture_size) / face_size, 2)}
