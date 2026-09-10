extends SceneTree
const Notes = preload("res://addons/godot360/particle_notes.gd")
const Inspector = preload("res://addons/godot360/scene_inspector.gd")
var checks := 0
var failures := 0


func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)


func _initialize() -> void:
	var mesh := QuadMesh.new()
	var material := StandardMaterial3D.new()
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	check(Notes.has_face_billboard([null, mesh]), "Draw mesh particle billboards are detected")
	check(not Notes.has_face_billboard([mesh], StandardMaterial3D.new()), "Opaque override replaces billboard mesh material")
	check(Notes.has_face_billboard([], null, material), "Overlay billboard is detected")
	var passes := StandardMaterial3D.new()
	passes.next_pass = material
	check(Notes.has_face_billboard([], passes), "Billboards in next passes are detected")
	var shader := ShaderMaterial.new()
	shader.shader = preload("res://addons/godot360/examples/spherical_smoke.gdshader")
	check(not Notes.has_face_billboard([mesh], shader), "Authored point shader does not get a native billboard warning")
	check(material.billboard_mode == BaseMaterial3D.BILLBOARD_PARTICLES and material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "Inspection preserves authored material")
	var scene := Node3D.new()
	var cpu := CPUParticles3D.new()
	cpu.name = "CPU"
	cpu.mesh = mesh
	scene.add_child(cpu)
	cpu.owner = scene
	var gpu := GPUParticles3D.new()
	gpu.name = "GPU"
	gpu.draw_passes = 2
	gpu.draw_pass_2 = mesh
	gpu.trail_enabled = true
	scene.add_child(gpu)
	gpu.owner = scene
	var packed := PackedScene.new()
	check(packed.pack(scene) == OK, "Saved particle fixture packs")
	var path := "res://.godot360/particle-notes-%d.tscn" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute("res://.godot360")
	check(ResourceSaver.save(packed, path) == OK, "Saved particle fixture writes")
	var result := Inspector.inspect(path)
	check(result.error.is_empty() and result.warnings.size() == 3, "Saved CPU, second GPU draw pass and trails receive notes")
	check(result.warnings[0].contains("CPU") and result.warnings[1].contains("GPU"), "Notes identify both emitter paths")
	check(result.warnings[2].contains("Compatibility") and result.warnings[2].contains("GPU"), "Saved trails explain the renderer requirement")
	DirAccess.remove_absolute(path)
	scene.free()
	print("CHECKS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
