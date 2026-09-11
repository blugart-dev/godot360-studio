extends SceneTree
## Evaluate the actual product planner against retained probe and full-run jobs.
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	assert(args.size() == 3, "Expected sample capture, target capture, output JSON")
	var io := preload("res://addons/godot360/job_io.gd")
	var planner := preload("res://addons/godot360/job_planner.gd")
	var sample := io.read_json(args[0].path_join("job.json"))
	var target := io.read_json(args[1].path_join("job.json"))
	var report := io.read_json(args[0].path_join("report.json"))
	var result := planner.estimate(sample, report, planner.storage(args[0]), target)
	assert(not result.is_empty(), "Probe and target settings do not match")
	assert(sample.get("benchmark_msaa", 2) == target.get("benchmark_msaa", 2), "Benchmark MSAA differs")
	assert(io.write_json(args[2], result))
	quit()
