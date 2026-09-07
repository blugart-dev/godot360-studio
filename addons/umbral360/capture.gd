extends SceneTree
## Internal GPU worker. Start through pipeline.gd, not with --headless.

const IO = preload("job_io.gd")
const Storage = preload("storage_guard.gd")
var storage: RefCounted
var job: Dictionary
var destination: String
var scene: Node
var rendered: int = 0
var total: int
var started_usec: int
var readback_usec: int = 0
var image_write_usec: int = 0
var frame_samples: Array[Dictionary] = []
var writer: RefCounted
var stopped: bool = false
var rig: Node


func _initialize() -> void:
	job = IO.read_json(IO.argument("job"))
	if job.is_empty():
		quit(1)
		return
	destination = str(job.output_dir)
	storage = Storage.new(destination)
	var output_size := Vector2i(int(job.width), int(job.height))
	root.content_scale_size = output_size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.size = Vector2i(960, 480)
	root.title = "Umbral360 · Rendering"
	root.disable_3d = true
	root.audio_listener_enable_3d = true
	root.audio_listener_enable_2d = false
	total = int(job.frames) + int(job.get("warmup_frames", 2))
	seed(int(job.get("random_seed", 360)))
	call_deferred("_start")


func _start() -> void:
	# SceneTree initialization applies project window settings after _initialize.
	# Set the actual render size here, before the first rendered frame.
	root.content_scale_size = Vector2i(int(job.width), int(job.height))
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.size = Vector2i(960, 480)
	var packed := load(str(job.scene_path)) as PackedScene
	if packed == null:
		_fail("Could not load or instantiate the selected scene. See capture.log.")
		return
	scene = packed.instantiate()
	if scene == null:
		_fail("Could not instantiate the selected scene. See capture.log.")
		return
	# A scene can replace live interaction with its own authored timeline here.
	if scene.has_method("prepare_360_capture"):
		scene.prepare_360_capture(job)
	root.add_child(scene)
	current_scene = scene
	var camera := scene.get_node_or_null(NodePath(str(job.camera_path))) as Camera3D
	if camera == null:
		_fail("Camera path must point to a Camera3D in the selected scene.")
		return
	if scene.has_method("begin_360_capture"):
		var hook_error = scene.begin_360_capture(job)
		if hook_error is String and not hook_error.is_empty():
			_fail(hook_error)
			return
	var warnings: Array[String] = []
	_inspect(scene, warnings)
	if not IO.write_json(destination.path_join("scene-checks.json"), {"warnings": warnings}):
		_fail("Cannot save scene-checks.json. Check output folder access and disk space.")
		return
	var listener := AudioListener3D.new()
	camera.add_child(listener)
	listener.make_current()
	rig = preload("capture_rig.gd").new()
	if scene.has_method("sample_360_frame"):
		rig.before_sync = _before_frame
	root.add_child(rig)
	rig.build(camera, int(job.face_size), Vector2i(int(job.width), int(job.height)))
	if stopped:
		return
	if not IO.write_json(destination.path_join("capture-settings.json"), {
		"output_width": int(job.width), "output_height": int(job.height),
		"face_size": int(job.face_size), "msaa_3d": camera.get_viewport().msaa_3d,
		"renderer": RenderingServer.get_current_rendering_method(),
		"frame_writer": str(job.get("frame_writer", "png")),
		"timeline_sampling": "frame_index / fps" if scene.has_method("sample_360_frame") else "scene processing"}):
		_fail("Cannot save capture-settings.json. Check output folder access and disk space.")
		return
	writer = preload("frame_writer.gd").new()
	writer.configure(job)
	scene.process_mode = Node.PROCESS_MODE_DISABLED if int(job.get("warmup_frames", 2)) > 0 else Node.PROCESS_MODE_INHERIT
	RenderingServer.frame_post_draw.connect(_after_frame)
	started_usec = Time.get_ticks_usec()


func _before_frame() -> void:
	if stopped:
		return
	# The rig calls this at process priority 1000, before synchronizing its cameras.
	# Node3D transform notifications must flush before drawing; frame_pre_draw is
	# too late for that. Warmup repeatedly samples zero without advancing time.
	var index: int = maxi(0, rendered - int(job.get("warmup_frames", 2)))
	var hook_error = scene.sample_360_frame(index, float(index) / float(job.fps), job)
	if hook_error is String and not hook_error.is_empty():
		_fail(hook_error)
		return


func _after_frame() -> void:
	if stopped:
		return
	if FileAccess.file_exists(destination.path_join("cancel.request")):
		_fail("Cancelled. Partial frames have been retained.")
		return
	var space: Dictionary = storage.check(Storage.capture_headroom(job), "Rendering")
	if not str(space.error).is_empty():
		IO.write_json(destination.path_join("capture-storage.json"), space)
		_fail(str(space.error))
		return
	# Movie Maker fixes its image dimensions before this script configures the
	# viewport. Save the full-resolution texture ourselves; use its clock/audio.
	var read_started: int = Time.get_ticks_usec()
	var frame := root.get_texture().get_image()
	var read_elapsed: int = Time.get_ticks_usec() - read_started
	readback_usec += read_elapsed
	if frame.get_size() != Vector2i(int(job.width), int(job.height)):
		_fail("Capture viewport dimensions do not match the export recipe.")
		return
	var write_started: int = Time.get_ticks_usec()
	if not writer.write_frame(frame):
		_fail(writer.last_error)
		return
	rendered += 1
	var write_elapsed: int = Time.get_ticks_usec() - write_started
	image_write_usec += write_elapsed
	frame_samples.append({"frame": rendered - 1, "readback_usec": read_elapsed, "image_write_usec": write_elapsed})
	# Remove only the previous Movie Maker scratch image, after it was written.
	var scratch := destination.path_join("movie/audio%08d.png" % (rendered - 2))
	if rendered > 1 and FileAccess.file_exists(scratch):
		DirAccess.remove_absolute(scratch)
	var warmup: int = int(job.get("warmup_frames", 2))
	if rendered >= warmup:
		scene.process_mode = Node.PROCESS_MODE_INHERIT
	if rendered % 10 == 0 or rendered == total:
		var elapsed: float = (Time.get_ticks_usec() - started_usec) / 1000000.0
		if not IO.write_json(destination.path_join("render-progress.json"), {"frame": rendered, "total": total,
			"elapsed_seconds": elapsed, "remaining_seconds": elapsed / rendered * (total - rendered),
			"writer_pid": writer.process_id, "storage_guard": space}):
			_fail("Cannot save render-progress.json. Check output folder access and disk space.")
			return
	if FileAccess.file_exists(destination.path_join("cancel.request")):
		_fail("Cancelled. Partial frames have been retained.")
	elif rendered >= total:
		if not writer.finish():
			_fail(writer.last_error)
			return
		if not _write_result(true):
			_fail("Cannot save capture results. Check output folder access and disk space.")
			return
		stopped = true


func _inspect(node: Node, warnings: Array[String]) -> void:
	if node is CanvasLayer:
		node.visible = false
	if node is SpriteBase3D and node.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
		warnings.append("Camera-facing sprite may produce seams: " + str(scene.get_path_to(node)))
	if node is Label3D and node.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
		warnings.append("Camera-facing label may produce seams: " + str(scene.get_path_to(node)))
	if node is WorldEnvironment and node.environment != null:
		var environment: Environment = node.environment
		if environment.glow_enabled or environment.ssao_enabled or environment.ssr_enabled or environment.ssil_enabled:
			warnings.append("Screen-space environment effects may differ across cube faces.")
	for child in node.get_children():
		_inspect(child, warnings)


func _fail(message: String) -> void:
	if stopped:
		return
	stopped = true
	if writer != null:
		writer.abort()
	_write_result(false, message)
	push_error(message)
	quit(1)


func _finalize() -> void:
	# Also close the child process when the worker window is closed early.
	if writer != null:
		writer.abort()
	if not stopped and not destination.is_empty():
		_write_result(false, "Capture worker closed before completing all frames. Partial files have been retained.")


func _write_result(success: bool, message: String = "") -> bool:
	# On failure these are submitted frames, not a guarantee that the encoder
	# finalized every PNG. Only ok:true certifies a completed PNG sequence.
	var timings_saved := IO.write_json(destination.path_join("capture-timings.json"), {
		"frames": rendered, "elapsed_usec": Time.get_ticks_usec() - started_usec if started_usec > 0 else 0,
		"readback_usec": readback_usec, "image_write_usec": image_write_usec,
		"frame_writer": str(job.get("frame_writer", "png")), "samples": frame_samples, "storage_guard": storage.latest})
	return IO.write_json(destination.path_join("capture-result.json"), {"ok": success and timings_saved,
		"error": message if timings_saved else "Cannot save capture timing diagnostics.",
		"rendered": rendered, "expected": total, "frame_count_kind": "submitted", "worker_pid": OS.get_process_id()}) and timings_saved
