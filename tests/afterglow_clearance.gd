extends SceneTree
## GPU regression: inspect the actual animated floor inside the pedestal footprint.
const IO = preload("res://addons/godot360/job_io.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var output := IO.argument("output")
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(512, 512)
	root.content_scale_size = root.size
	var scene = load("res://scenes/films/Afterglow.tscn").instantiate()
	scene.prepare_360_capture({})
	root.add_child(scene)
	scene.set_process(false)
	var floor_mesh: MultiMeshInstance3D = scene.get_node("DancingGlass")
	var plinth: MeshInstance3D = scene.get_node("CrownPlinth")
	var plinth_shape := plinth.mesh as CylinderMesh
	var bottom := plinth.position.y - plinth_shape.height * .5
	var original: ShaderMaterial = scene.surfaces.tiles
	var source: String = original.shader.code
	var baseline := IO.argument("shader")
	if not baseline.is_empty():
		source = FileAccess.get_file_as_string(baseline)
	# Keep the production vertex stage. Diagnostic shading reports any tile
	# surface that rises into the conservative cylindrical pedestal envelope.
	var shader := Shader.new()
	shader.code = source.split("void fragment()")[0] + """
uniform vec2 check_center;
uniform float check_radius;
uniform float check_bottom;
void fragment() {
    bool overlaps = length(world_position.xz - check_center) <= check_radius
        && world_position.y >= check_bottom;
    ALBEDO = overlaps ? vec3(1.0, 0.0, 0.0) : vec3(0.0);
}
"""
	var diagnostic: ShaderMaterial = original.duplicate()
	diagnostic.shader = shader
	diagnostic.set_shader_parameter("check_center", Vector2(plinth.position.x, plinth.position.z))
	diagnostic.set_shader_parameter("check_radius", plinth_shape.top_radius)
	diagnostic.set_shader_parameter("check_bottom", bottom - .005)
	floor_mesh.material_override = diagnostic
	scene.surfaces.tiles = diagnostic
	for child in scene.get_children():
		if child is Node3D and child != floor_mesh and child != scene.camera:
			child.visible = false
		if child is WorldEnvironment:
			var environment: Environment = child.environment
			environment.background_color = Color.BLACK
			environment.glow_enabled = false
			environment.fog_enabled = false
			environment.adjustment_enabled = false
			environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	scene.camera.attributes = null
	scene.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	scene.camera.size = 12
	var failures: Array[Dictionary] = []
	var max_overlap_pixels := 0
	for frame in range(1200, 1381):
		var time := frame / 30.0
		scene.sample_360_frame(frame, time, {})
		scene.camera.position = plinth.position + Vector3(0, 16, 0)
		scene.camera.rotation_degrees = Vector3(-90, 0, 0)
		for settle in range(2):
			await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		picture.convert(Image.FORMAT_RGBA8)
		var bytes := picture.get_data()
		var overlap_pixels := 0
		for pixel in range(0, bytes.size(), 4):
			if bytes[pixel] > 128:
				overlap_pixels += 1
		max_overlap_pixels = maxi(max_overlap_pixels, overlap_pixels)
		if overlap_pixels > 0:
			if failures.is_empty():
				picture.save_png(output.path_join("first-overlap.png"))
			failures.append({"time": time, "pixels": overlap_pixels})
	var report := {"ok": failures.is_empty(), "frames": 181, "from": 40, "through": 46,
		"fps": 30, "max_overlap_pixels": max_overlap_pixels, "failures": failures,
		"method": "Production vertex shader, top-down GPU surface test against pedestal envelope"}
	IO.write_json(output.path_join("clearance-review.json"), report)
	print(JSON.stringify({"ok": failures.is_empty(), "frames": 181, "failed_frames": failures.size(), "max_overlap_pixels": max_overlap_pixels}))
	quit(0 if failures.is_empty() else 1)
