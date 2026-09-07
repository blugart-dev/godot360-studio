extends Node3D
## Procedural appearance lab: native perspective oracle plus retained cube views.
var job: Dictionary
var mode := "lit"
var moving: MeshInstance3D
var environment: Environment
var reference: SubViewport
var reference_camera: Camera3D
var index := 0

func prepare_360_capture(settings: Dictionary) -> void:
	job = settings
	mode = str(job.get("feature", "lit"))

func _ready() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.18, 0.24, 0.32)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.52, 0.62, 0.8)
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC if mode != "color" else Environment.TONE_MAPPER_LINEAR
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	add_child(sun)
	var point := OmniLight3D.new()
	point.position = Vector3(1.0, 0.8, -2.0)
	point.light_color = Color(1.0, 0.28, 0.06)
	point.light_energy = 5.0
	point.omni_range = 8.0
	point.shadow_enabled = true
	add_child(point)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(24, 0.2, 24)
	_mesh(floor_mesh, Vector3(0, -1.3, 0), Color(0.5, 0.5, 0.5)).material_override.roughness = 0.15
	for n in range(16):
		var angle := n * TAU / 16.0
		var sphere := SphereMesh.new()
		sphere.radius = 0.36
		sphere.height = 0.72
		var item := _mesh(sphere, Vector3(sin(angle) * 4, -0.5, -cos(angle) * 4), Color.from_hsv(n / 16.0, 0.7, 0.7))
		item.material_override.metallic = 0.8 if n % 2 else 0.0
		item.material_override.roughness = 0.1 if n % 2 else 0.65
		item.gi_mode = GeometryInstance3D.GI_MODE_STATIC
	for n in range(7):
		var patch := QuadMesh.new()
		patch.size = Vector2(0.5, 0.5)
		var value: float = [0.02, 0.08, 0.18, 0.4, 0.6, 0.8, 1.0][n]
		var card := _mesh(patch, Vector3((n - 3) * 0.57, 0.9, -3.8), Color(value, value, value))
		card.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var glass := QuadMesh.new()
	glass.size = Vector2(1.2, 1.4)
	var pane := _mesh(glass, Vector3(-1.0, -0.1, -2.4), Color(0.1, 0.75, 0.9, 0.35))
	pane.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var ball := SphereMesh.new()
	ball.radius = 0.22
	ball.height = 0.44
	moving = _mesh(ball, Vector3(0, 0.1, -3), Color(1.0, 0.15, 0.02))
	moving.material_override.emission_enabled = true
	moving.material_override.emission = Color(1.0, 0.12, 0.01)
	moving.material_override.emission_energy_multiplier = 5.0
	if mode == "glow":
		environment.glow_enabled = true
		environment.glow_intensity = 1.4
	if mode == "fog":
		environment.fog_enabled = true
		environment.fog_density = 0.12
	if mode == "volumetric":
		environment.volumetric_fog_enabled = true
		environment.volumetric_fog_density = 0.12
	if mode == "screen":
		environment.ssao_enabled = true
		environment.ssil_enabled = true
		environment.ssr_enabled = true
	if mode in ["gi", "gi_off"]:
		environment.ambient_light_energy = 0.0
		environment.background_color = Color(0.03, 0.03, 0.03)
		sun.light_energy = 0.15
		point.light_energy = 3.0
		for side in [-1, 1]:
			var wall_mesh := BoxMesh.new()
			wall_mesh.size = Vector3(0.5, 5.0, 12.0)
			var wall := _mesh(wall_mesh, Vector3(side * 5, 1.0, 0), Color(0.9, 0.08, 0.02) if side < 0 else Color(0.02, 0.15, 0.9))
			wall.gi_mode = GeometryInstance3D.GI_MODE_STATIC
		environment.sdfgi_enabled = mode == "gi"
		environment.sdfgi_min_cell_size = 0.2
		environment.sdfgi_use_occlusion = true
	if mode == "taa":
		get_viewport().use_taa = true
	if mode == "physical":
		var attributes := CameraAttributesPhysical.new()
		attributes.frustum_focal_length = 85.0
		attributes.exposure_multiplier = 1.5
		$Camera3D.attributes = attributes
	if mode == "exposure":
		var attributes := CameraAttributesPractical.new()
		attributes.exposure_multiplier = 1.7
		$Camera3D.attributes = attributes
	if mode == "auto_exposure":
		var attributes := CameraAttributesPractical.new()
		attributes.auto_exposure_enabled = true
		$Camera3D.attributes = attributes
	if mode in ["compositor", "world_compositor"]:
		var compositor := Compositor.new()
		compositor.compositor_effects = [preload("renderer_tint.gd").new()]
		if mode == "compositor":
			$Camera3D.compositor = compositor
		else:
			world.compositor = compositor

func begin_360_capture(_settings: Dictionary) -> void:
	# An ordinary perspective view, outside the capture rig, is the color oracle.
	reference = SubViewport.new()
	reference.name = "NativePerspective"
	reference.size = Vector2i(int(job.face_size), int(job.face_size))
	reference.world_3d = get_world_3d()
	reference.use_hdr_2d = bool(job.get("reference_hdr", false))
	reference.msaa_3d = get_viewport().msaa_3d
	reference.use_taa = get_viewport().use_taa
	reference.positional_shadow_atlas_size = get_viewport().positional_shadow_atlas_size
	reference.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(reference)
	reference_camera = $Camera3D.duplicate()
	reference.add_child(reference_camera)
	reference_camera.set_perspective(90.0, $Camera3D.near, $Camera3D.far)
	reference_camera.current = true
	DirAccess.make_dir_recursive_absolute(str(job.output_dir).path_join("references"))
	RenderingServer.frame_post_draw.connect(_save_references)

func sample_360_frame(frame_index: int, seconds: float, _settings: Dictionary) -> String:
	index = frame_index
	var phase := seconds * TAU
	moving.position = Vector3(sin(phase) * 3, 0.1, -cos(phase) * 3)
	return ""

func _save_references() -> void:
	if index not in [0, int(job.frames) / 2, int(job.frames) - 1]:
		return
	var folder: String = str(job.output_dir).path_join("references")
	var native := reference.get_texture().get_image()
	if reference.use_hdr_2d:
		native.convert(Image.FORMAT_RGBAF)
		FileAccess.open(folder.path_join("native-%03d.rgba32f" % index), FileAccess.WRITE).store_buffer(native.get_data())
	else:
		assert(native.save_png(folder.path_join("native-%03d.png" % index)) == OK)
	for face in ["right", "left", "up", "down", "front", "back"]:
		var viewport := get_tree().root.find_child("Face_" + face, true, false) as SubViewport
		if viewport != null:
			assert(viewport.get_texture().get_image().save_png(folder.path_join("%s-%03d.png" % [face, index])) == OK)

func _mesh(shape: Mesh, location: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	instance.material_override = material
	add_child(instance)
	instance.position = location
	return instance
