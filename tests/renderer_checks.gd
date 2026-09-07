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
	camera.free()
	print("RENDERER CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS: " if ok else "FAIL: ") + description)
