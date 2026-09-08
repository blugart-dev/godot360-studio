extends SceneTree
const Policy = preload("res://addons/godot360/renderer_policy.gd")
const Planner = preload("res://addons/godot360/job_planner.gd")
const Profile = preload("res://addons/godot360/export_profile.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var recipe: Dictionary = Profile.new().to_dictionary()
	check(recipe.rendering_method == "project" and recipe.rendering_driver == "project", "New recipes use the project renderer and driver")
	check(Policy.resolve({}).resolved_method == ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method"), "Legacy JSON resolves the saved project, not the coordinator renderer")
	for method in ["forward_plus", "mobile", "gl_compatibility"]:
		var driver := "opengl3" if method == "gl_compatibility" else "vulkan"
		check(Policy.validate({"rendering_method": method, "rendering_driver": driver}).is_empty(), "Valid explicit pair: " + method)
	check(not Policy.validate({"rendering_method": "mobile", "rendering_driver": "opengl3"}).is_empty(), "Invalid driver/method rejected")
	check(not Policy.validate({"rendering_method": "dummy"}).is_empty(), "Dummy capture rejected")
	var selection := Policy.resolve({"rendering_method": "forward_plus", "rendering_driver": "vulkan"})
	check(Policy.mismatch(selection, "forward_plus", "vulkan").is_empty(), "Matching worker accepted")
	check(Policy.mismatch(selection, "gl_compatibility", "opengl3").contains("fallback"), "Renderer fallback is a visible failure")
	check(Policy.mismatch(selection, "forward_plus", "d3d12").contains("fallback"), "Driver fallback is also a visible failure")
	var sample := Planner.test_job(recipe)
	check(Planner.matches(sample, recipe), "Fresh renderer sample matches")
	var old_sample := sample.duplicate(true)
	old_sample.erase("rendering_signature")
	check(not Planner.matches(old_sample, recipe), "Pre-renderer estimates cannot be reused")
	var changed := recipe.duplicate(true)
	changed.rendering_method = "mobile" if Policy.resolve(recipe).resolved_method != "mobile" else "forward_plus"
	check(not Planner.matches(sample, changed), "Changing renderer invalidates estimates")
	changed = recipe.duplicate(true)
	changed.rendering_driver = "d3d12"
	check(not Planner.matches(sample, changed), "Changing driver invalidates estimates")
	check(recipe.capture_border_percent == 0.0, "Default recipes preserve the original capture without borders")
	var legacy_sample := sample.duplicate(true)
	legacy_sample.erase("capture_border_percent")
	check(Planner.matches(legacy_sample, recipe), "A missing legacy border is equivalent to zero for estimates")
	changed = recipe.duplicate(true)
	changed.capture_border_percent = 12.5
	check(not Planner.matches(sample, changed), "Changing the border invalidates measured render estimates")
	var projection_policy = preload("res://addons/godot360/capture_projection.gd")
	for value in [-1, 25.1, INF, NAN, "12.5", true, null, {}, []]:
		check(not projection_policy.validate({"capture_border_percent": value}).is_empty(), "Invalid border rejected: " + str(value))
		changed = recipe.duplicate(true)
		changed.capture_border_percent = value
		var corrupt_sample := sample.duplicate(true)
		corrupt_sample.capture_border_percent = value
		check(not Planner.matches(sample, changed) and not Planner.matches(corrupt_sample, recipe), "Malformed border settings cannot reuse estimates or crash the panel")
	for value in [0, 12.5, 25]:
		check(projection_policy.validate({"capture_border_percent": value}).is_empty(), "Valid border accepted: " + str(value))
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(1, 2, 3)
	camera.h_offset = 0.4
	camera.v_offset = 0.2
	camera.environment = Environment.new()
	camera.attributes = CameraAttributesPractical.new()
	camera.compositor = Compositor.new()
	root.mesh_lod_threshold = 2.5
	root.positional_shadow_atlas_size = 1024
	var rig := preload("res://addons/godot360/capture_rig.gd").new()
	root.add_child(rig)
	rig.build(camera, 128, Vector2i(256, 128))
	check(rig.cameras.size() == 6, "Six simultaneous cameras")
	check(rig.settings().mesh_lod_threshold == 2.5 and rig.settings().positional_shadow_atlas_size == 1024, "Source LOD and shadow atlas preserved")
	check(rig.cameras[4].global_position.is_equal_approx(camera.get_camera_transform().origin), "Camera h/v offset contributes to common capture origin")
	check(rig.cameras.all(func(c): return c.compositor == camera.compositor and c.environment == camera.environment and c.attributes == camera.attributes), "Camera compositor, environment and attributes preserved")
	camera.environment = Environment.new()
	camera.cull_mask = 3
	camera.near = 0.25
	camera.far = 123.0
	rig.sync_camera()
	check(rig.cameras.all(func(c): return c.environment == camera.environment and c.cull_mask == 3 and c.near == 0.25 and c.far == 123.0), "Animated environment, cull mask and clipping synchronized")
	var physical := CameraAttributesPhysical.new()
	physical.frustum_focal_length = 85.0
	camera.attributes = physical
	rig.sync_camera()
	check(rig.cameras.all(func(c): return is_equal_approx(c.fov, 90.0) and is_equal_approx(c.get_camera_projection().get_fov(), 90.0)), "Physical lens cannot replace square 90-degree face projection")
	physical.frustum_focal_length = 35.0
	rig.sync_camera()
	check(rig.cameras.all(func(c): return is_equal_approx(c.get_camera_projection().get_fov(), 90.0)), "Animated physical lens retains square projection")
	rig.free()
	for percent in [12.5, 25.0]:
		rig = preload("res://addons/godot360/capture_rig.gd").new()
		root.add_child(rig)
		rig.build(camera, 128, Vector2i(256, 128), percent)
		var size := 160 if percent == 12.5 else 192
		check(rig.cameras.all(func(c): return c.get_viewport().size == Vector2i(size, size)), "Border increases all six target dimensions without reducing core density")
		check(rig.cameras.all(func(c): return is_equal_approx(tan(deg_to_rad(c.get_camera_projection().get_fov() * 0.5)), float(size) / 128.0)), "Actual physical-camera projection includes the requested border")
		check(is_equal_approx(float(rig.material.get_shader_parameter("face_uv_scale")), 128.0 / size), "Assembler scales face coordinates to the expanded projection")
		physical.frustum_focal_length += 5.0
		rig.sync_camera()
		check(rig.cameras.all(func(c): return is_equal_approx(tan(deg_to_rad(c.get_camera_projection().get_fov() * 0.5)), float(size) / 128.0)), "Animated physical lens preserves expanded projection")
		rig.free()
	var odd := projection_policy.geometry(511, 12.5)
	check(odd.texture_size == 639 and odd.border_pixels == 64 and is_equal_approx(odd.uv_scale, 511.0 / 639.0), "Odd face sizes round the border symmetrically and retain core density")
	camera.free()
	print("RENDERER CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS: " if ok else "FAIL: ") + description)
