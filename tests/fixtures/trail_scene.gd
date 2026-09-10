extends "res://tests/fixtures/smoke_scene.gd"
## Native skinned particle trails, observed by an independent diagonal viewport.
var reference_view: SubViewport
var reference_camera: Camera3D
var drawn := 0


func _ready() -> void:
	super._ready()
	for emitter in emitters:
		var trail: PrimitiveMesh
		if job.get("trail_shape", "tube") == "ribbon":
			trail = RibbonTrailMesh.new()
			trail.size = 0.12
			trail.section_segments = 3
		else:
			trail = TubeTrailMesh.new()
			trail.radius = 0.06
			trail.radial_steps = 8
			trail.section_rings = 3
		trail.sections = 6
		trail.section_length = 0.1
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.85, 0.42, 0.12)
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.use_particle_trails = not job.get("trail_disabled", false)
		trail.material = material
		emitter.draw_pass_1 = trail
		emitter.trail_enabled = not job.get("trail_disabled", false)
		emitter.trail_lifetime = 0.4
		emitter.fixed_fps = 30
	initial_settings = _settings()
	reference_view = SubViewport.new()
	reference_view.size = Vector2i(512, 512)
	reference_view.world_3d = get_world_3d()
	reference_view.msaa_3d = get_viewport().msaa_3d
	reference_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(reference_view)
	reference_camera = Camera3D.new()
	reference_camera.fov = 60
	reference_camera.current = true
	reference_view.add_child(reference_camera)
	DirAccess.make_dir_recursive_absolute(str(job.output_dir).path_join("direct"))


func sample_360_frame(frame: int, time: float, settings: Dictionary) -> String:
	var error := super.sample_360_frame(frame, time, settings)
	reference_camera.global_transform = camera.transform * Transform3D(Basis.looking_at(Vector3(1, 0, -1), Vector3.UP), Vector3.ZERO)
	return error


func _after_draw() -> void:
	super._after_draw()
	if drawn >= int(job.warmup_frames):
		var path := str(job.output_dir).path_join("direct/frame%08d.png" % sampled_frame)
		if reference_view.get_texture().get_image().save_png(path) != OK:
			push_error("Cannot save single-view trail reference.")
	drawn += 1


func _settings() -> Array[Dictionary]:
	var result := super._settings()
	for index in range(emitters.size()):
		var emitter: GPUParticles3D = emitters[index]
		result[index].merge({"trail_enabled": emitter.trail_enabled, "trail_lifetime": emitter.trail_lifetime,
			"interpolate": emitter.interpolate, "mesh": emitter.draw_pass_1.get_class()})
	return result
