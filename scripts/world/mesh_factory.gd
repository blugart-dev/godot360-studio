class_name MeshFactory
extends RefCounted


static func material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


static func mesh_node(parent: Node3D, mesh: Mesh, mat: Material,
		at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	parent.add_child(node)
	return node


static func sphere(parent: Node3D, radius: float, mat: Material,
		at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	return mesh_node(parent, mesh, mat, at)


static func box(parent: Node3D, size: Vector3, mat: Material,
		at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh_node(parent, mesh, mat, at)


static func ring(parent: Node3D, radius: float, thickness: float, mat: Material,
		at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness
	mesh.outer_radius = radius + thickness
	mesh.rings = 64
	mesh.ring_segments = 8
	return mesh_node(parent, mesh, mat, at)


static func label(parent: Node3D, words: String, at: Vector3,
		font_size: int = 32, color: Color = Color("c6d9d2")) -> Label3D:
	var node := Label3D.new()
	node.text = words
	node.position = at
	node.font_size = font_size
	node.pixel_size = 0.007
	node.modulate = color
	node.outline_size = 0
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(node)
	return node
