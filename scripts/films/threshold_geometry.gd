extends RefCounted
## Original procedural geometry shared by the four Threshold worlds.

static func material(hex: String, unlit: bool = false, metal: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(hex)
	result.roughness = 0.65
	result.metallic = metal
	result.vertex_color_use_as_albedo = true
	if unlit:
		result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return result


static func node(parent: Node3D, shape: Mesh, surface: Material, at: Vector3 = Vector3.ZERO, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.mesh = shape
	result.material_override = surface
	result.position = at
	result.scale = scale_value
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(result)
	return result


static func sphere(parent: Node3D, radius: float, surface: Material, at: Vector3 = Vector3.ZERO, proportions: Vector3 = Vector3.ONE, detail: int = 32) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2
	shape.radial_segments = detail
	shape.rings = detail / 2
	return node(parent, shape, surface, at, proportions)


static func cylinder(parent: Node3D, bottom: float, top: float, height: float, surface: Material, at: Vector3 = Vector3.ZERO, detail: int = 12) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius = bottom
	shape.top_radius = top
	shape.height = height
	shape.radial_segments = detail
	return node(parent, shape, surface, at)


static func ring(parent: Node3D, radius: float, width: float, surface: Material, at: Vector3 = Vector3.ZERO, detail: int = 96) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = radius - width
	shape.outer_radius = radius + width
	shape.rings = detail
	shape.ring_segments = 8
	return node(parent, shape, surface, at)


static func box(parent: Node3D, dimensions: Vector3, surface: Material, at: Vector3) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = dimensions
	return node(parent, shape, surface, at)


static func batch(parent: Node3D, shape: Mesh, surface: Material, transforms: Array[Transform3D], colors: Array[Color] = []) -> MultiMeshInstance3D:
	var data := MultiMesh.new()
	data.transform_format = MultiMesh.TRANSFORM_3D
	data.use_colors = true
	data.mesh = shape
	data.instance_count = transforms.size()
	for i in range(transforms.size()):
		data.set_instance_transform(i, transforms[i])
		data.set_instance_color(i, colors[i] if not colors.is_empty() else Color.WHITE)
	var result := MultiMeshInstance3D.new()
	result.multimesh = data
	result.material_override = surface
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(result)
	return result


static func tube(parent: Node3D, path: PackedVector3Array, radius: float, surface: Material, sides: int = 6) -> MeshInstance3D:
	var build := SurfaceTool.new()
	build.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(path.size()):
		var tangent := (path[mini(i + 1, path.size() - 1)] - path[maxi(0, i - 1)]).normalized()
		var reference := Vector3.RIGHT if absf(tangent.y) > 0.9 else Vector3.UP
		var u := tangent.cross(reference).normalized()
		var v := tangent.cross(u).normalized()
		for side in range(sides):
			var theta := float(side) / sides * TAU
			var normal := u * cos(theta) + v * sin(theta)
			build.set_normal(normal)
			build.add_vertex(path[i] + normal * radius)
	for i in range(path.size() - 1):
		for side in range(sides):
			var a := i * sides + side
			var b := i * sides + (side + 1) % sides
			for index in [a, a + sides, b, b, a + sides, b + sides]:
				build.add_index(index)
	return node(parent, build.commit(), surface)


static func dunes(parent: Node3D, surface: Material, mode: int) -> MeshInstance3D:
	var build := SurfaceTool.new()
	build.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 140
	var span := 220.0
	for z in range(count + 1):
		for x in range(count + 1):
			var px := (float(x) / count - 0.5) * span
			var pz := (float(z) / count - 0.5) * span
			var h := height_at(px, pz, mode)
			var normal := Vector3(height_at(px - 0.1, pz, mode) - height_at(px + 0.1, pz, mode), 0.2, height_at(px, pz - 0.1, mode) - height_at(px, pz + 0.1, mode)).normalized()
			build.set_normal(normal)
			build.add_vertex(Vector3(px, h, pz))
	for z in range(count):
		for x in range(count):
			var a := z * (count + 1) + x
			for index in [a, a + 1, a + count + 1, a + 1, a + count + 2, a + count + 1]:
				build.add_index(index)
	return node(parent, build.commit(), surface)


static func height_at(x: float, z: float, mode: int) -> float:
	if mode == 0:
		return -5.0 + sin(x * 0.085) * cos(z * 0.075) * 0.9
	return -5.5 + (sin(x * 0.075 + sin(z * 0.038) * 2.1) * 2.8 + cos(z * 0.045 + x * 0.035) * 1.1) * smoothstep(7.0, 30.0, Vector2(x, z).length())


static func rock(parent: Node3D, radius: float, surface: Material, at: Vector3, proportions: Vector3, seed_value: int) -> MeshInstance3D:
	var build := SurfaceTool.new()
	build.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices := PackedVector3Array()
	for level in range(7):
		var y := float(level) / 6.0 * PI
		for side in range(17):
			var a := float(side) / 16.0 * TAU
			var variation := 1.0 + sin(a * 3.0 + seed_value + level * 1.7) * 0.17 + cos(a * 5.0 + seed_value * 3.0) * 0.10
			vertices.append(Vector3(sin(a) * sin(y) * variation, cos(y) * (0.9 + variation * 0.1), cos(a) * sin(y) * variation) * radius)
	for level in range(6):
		for side in range(16):
			var a := level * 17 + side
			for index in [a, a + 1, a + 17, a + 1, a + 18, a + 17]:
				build.set_smooth_group(-1)
				build.add_vertex(vertices[index])
	build.generate_normals()
	return node(parent, build.commit(), surface, at, proportions)


static func text(parent: Node3D, words: String, at: Vector3, size: int, pixel: float, tint: Color) -> Label3D:
	var result := Label3D.new()
	result.text = words
	result.font_size = size
	result.pixel_size = pixel
	result.modulate = tint
	result.outline_size = 0
	result.no_depth_test = false
	result.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	result.position = at
	parent.add_child(result)
	return result
