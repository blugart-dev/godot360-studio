@tool
extends RefCounted
## Inspect authored draw materials without instantiating or rewriting an effect.


static func has_face_billboard(meshes: Array, material_override: Material = null, material_overlay: Material = null) -> bool:
	if _billboard(material_overlay):
		return true
	if material_override != null:
		return _billboard(material_override)
	for mesh in meshes:
		if mesh is Mesh:
			for surface in range(mesh.get_surface_count()):
				if _billboard(mesh.surface_get_material(surface)):
					return true
	return false


static func _billboard(material: Material) -> bool:
	var seen: Array[Material] = []
	while material != null and material not in seen:
		seen.append(material)
		if material is BaseMaterial3D and material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
			return true
		material = material.next_pass
	return false


static func billboard_note(path: String) -> String:
	return "Particle billboard on %s turns separately for each cube face and can split smoke at edges. Review a short export; a point-facing shader such as examples/spherical_smoke.gdshader keeps one orientation across faces." % path


static func trail_note(path: String) -> String:
	return "Particle trails on %s require Forward+ or Mobile. Compatibility cannot render the trail history." % path
