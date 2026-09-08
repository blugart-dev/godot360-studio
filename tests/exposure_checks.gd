extends SceneTree
const Exposure = preload("res://addons/godot360/capture_exposure.gd")
const Profile = preload("res://addons/godot360/export_profile.gd")
const Planner = preload("res://addons/godot360/job_planner.gd")
const IO = preload("res://addons/godot360/job_io.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var recipe: Dictionary = Profile.new().to_dictionary()
	check(recipe.capture_exposure_mode == "scene", "New recipes retain authored scene behavior")
	check(Exposure.validate({}).is_empty(), "Legacy jobs default to scene exposure")
	var sample := Planner.test_job(recipe)
	sample.erase("capture_exposure_mode")
	check(Planner.matches(sample, recipe), "Missing legacy exposure does not invalidate an otherwise matching sample")
	recipe.capture_exposure_mode = "fixed"
	check(not Planner.matches(sample, recipe), "Exposure change invalidates the estimate")
	for invalid in ["unknown", "", 0, true, null, [], {}]:
		var malformed := recipe.duplicate()
		malformed.capture_exposure_mode = invalid
		check(not Exposure.validate(malformed).is_empty(), "Invalid exposure rejected: " + str(invalid))
		check(not Planner.matches(Planner.test_job(malformed), malformed), "Invalid saved exposure never matches a sample")
	var camera := Camera3D.new()
	root.add_child(camera)
	var world := WorldEnvironment.new()
	root.add_child(world)
	var policy := Exposure.new()
	check(policy.resolve(camera) == null, "Default camera has no override")
	for physical in [false, true]:
		var authored: CameraAttributes = CameraAttributesPhysical.new() if physical else CameraAttributesPractical.new()
		authored.auto_exposure_enabled = true
		authored.exposure_multiplier = 1.7
		camera.attributes = authored
		policy.mode = "scene"
		check(policy.resolve(camera) == authored, "Scene mode retains exact source resource")
		policy.mode = "fixed"
		var owned := policy.resolve(camera)
		check(owned != authored and owned.get_class() == authored.get_class(), "Fixed mode owns matching practical/physical attributes")
		check(not owned.auto_exposure_enabled and authored.auto_exposure_enabled, "Only worker-owned metering is disabled")
		check(owned.exposure_multiplier == authored.exposure_multiplier, "Authored exposure preserved")
		authored.exposure_multiplier = 0.8
		authored.exposure_sensitivity = 250.0
		if physical:
			authored.exposure_aperture = 4.0
			authored.frustum_focal_length = 85.0
		else:
			authored.dof_blur_far_enabled = true
			authored.dof_blur_far_distance = 17.0
		check(policy.resolve(camera) == owned, "Frames reuse one owned resource")
		check(is_equal_approx(owned.exposure_multiplier, 0.8) and owned.exposure_sensitivity == 250.0, "Exposure animation copied in the same frame")
		check(owned.exposure_aperture == 4.0 and owned.frustum_focal_length == 85.0 if physical else owned.dof_blur_far_enabled and owned.dof_blur_far_distance == 17.0, "Physical lens or practical DOF animation retained")
		world.camera_attributes = authored
		camera.attributes = null
		check(policy.resolve(camera) == owned, "World attributes used when camera has no override")
		var replacement := CameraAttributesPractical.new()
		replacement.exposure_multiplier = 2.5
		camera.attributes = replacement
		check(policy.resolve(camera).exposure_multiplier == 2.5, "Runtime camera override takes precedence over world")
		camera.attributes = null
		world.camera_attributes = replacement
		check(policy.resolve(camera).exposure_multiplier == 2.5, "Runtime world attribute replacement is followed")
		world.camera_attributes = null
		check(policy.resolve(camera) == null, "Removing all attributes clears the owned override")
	var physical := CameraAttributesPhysical.new()
	physical.auto_exposure_enabled = true
	camera.attributes = physical
	var rig := preload("res://addons/godot360/capture_rig.gd").new()
	root.add_child(rig)
	rig.build(camera, 128, Vector2i(256, 128), 12.5, "fixed")
	var owned: CameraAttributes = rig.cameras[0].attributes
	check(rig.cameras.all(func(c): return c.attributes == owned and not c.attributes.auto_exposure_enabled), "Six faces share fixed exposure")
	physical.frustum_focal_length = 120.0
	physical.exposure_multiplier = 0.9
	rig.sync_camera()
	check(rig.cameras.all(func(c): return is_equal_approx(c.attributes.exposure_multiplier, 0.9) and is_equal_approx(tan(deg_to_rad(c.get_camera_projection().get_fov() * 0.5)), 1.25)), "Animated exposure and physical lens retain the border projection")
	check(physical.auto_exposure_enabled and physical.frustum_focal_length == 120.0, "Authored physical attributes untouched")
	rig.free()
	camera.free()
	world.free()
	_test_reencode(recipe)
	print("EXPOSURE CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_reencode(recipe: Dictionary) -> void:
	var folder := ProjectSettings.globalize_path("res://.godot360/exposure-contract-" + str(Time.get_ticks_usec()))
	var source := folder.path_join("source")
	DirAccess.make_dir_recursive_absolute(source.path_join("frames"))
	recipe.output_dir = source
	IO.write_json(source.path_join("capture-result.json"), {"ok": true})
	IO.write_json(source.path_join("job.json"), recipe)
	var request := {"source_dir": source, "output_dir": folder.path_join("encoded")}
	check(Planner.resolve_reencode(request).job.capture_exposure_mode == "fixed", "Re-encode retains original fixed policy")
	request.capture_exposure_mode = "scene"
	check(Planner.resolve_reencode(request).error.contains("new render"), "Re-encode cannot relabel exposure")
	request.capture_exposure_mode = "fixed"
	check(Planner.resolve_reencode(request).error.is_empty(), "Explicitly unchanged exposure accepted")
	for invalid in ["bad", null, [], {}]:
		recipe.capture_exposure_mode = "fixed"
		IO.write_json(source.path_join("job.json"), recipe)
		request.capture_exposure_mode = invalid
		check(not Planner.resolve_reencode(request).error.is_empty(), "Malformed re-encode request rejected")
		request.erase("capture_exposure_mode")
		recipe.capture_exposure_mode = invalid
		IO.write_json(source.path_join("job.json"), recipe)
		check(Planner.resolve_reencode(request).error.begins_with("Saved capture:"), "Malformed saved exposure rejected safely")
	recipe.erase("capture_exposure_mode")
	IO.write_json(source.path_join("job.json"), recipe)
	check(Planner.resolve_reencode(request).error.is_empty(), "Legacy retained capture stays usable")
	var profile := Profile.new()
	profile.capture_exposure_mode = "fixed"
	var path := folder.path_join("fixed.tres")
	check(ResourceSaver.save(profile, path) == OK and load(path).capture_exposure_mode == "fixed", "Portable recipe saves and reloads fixed exposure")


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS: " if ok else "FAIL: ") + description)
