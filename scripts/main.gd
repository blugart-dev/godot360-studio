extends Node3D

@onready var player: PlayerLook = $Player
@onready var detector: GazeDetector = $Player/GazeDetector
@onready var sequence: SequenceController = $SequenceController
@onready var hud: Control = $UI/HUD
@onready var core: GazeTarget = $World/GazeTargets/Core
@onready var rear: GazeTarget = $World/GazeTargets/RearBloom
@onready var witness: GazeTarget = $World/GazeTargets/Witness
@onready var right: GazeTarget = $World/GazeTargets/RightSignal

var discovered: Dictionary = {}
var capture_mode: bool = false
var capture_elapsed: float = 0.0
var capture_stage: int = 0
var capture_cutouts: Array[Node3D] = []


func prepare_360_capture(_job: Dictionary) -> void:
	$Player.auto_capture = false
	capture_mode = true


func begin_360_capture(_job: Dictionary) -> void:
	# A linear film uses authored events instead of a viewer's live gaze.
	player.set_process(false)
	player.set_process_unhandled_input(false)
	detector.set_input_enabled(false)
	witness.set_physics_process(false)
	process_priority = 10
	_collect_capture_cutouts($World)


func _collect_capture_cutouts(node: Node) -> void:
	if node is SpriteBase3D or node is Label3D:
		if node.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
			node.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			capture_cutouts.append(node)
	for child in node.get_children():
		_collect_capture_cutouts(child)


func _process(delta: float) -> void:
	if not capture_mode:
		return
	capture_elapsed += delta
	if capture_stage == 0 and capture_elapsed >= 3.5:
		capture_stage = 1
		core.get_node("Visual").awaken()
	if capture_stage == 1 and capture_elapsed >= 6.0:
		capture_stage = 2
		right.get_node("Visual").pulse()
	if capture_stage == 2 and capture_elapsed >= 9.0:
		capture_stage = 3
		rear.get_node("Visual").open_bloom()
	var arc: float = -PI / 2.0 + clampf(capture_elapsed - 3.5, 0.0, 4.0) * 0.13
	witness.position = Vector3(sin(arc) * 7.1, 1.6, -cos(arc) * 7.1)
	for cutout in capture_cutouts:
		# All cube cameras see the same geometry, facing the common capture origin.
		cutout.look_at(player.camera.global_position, Vector3.UP, true)


func _ready() -> void:
	player.capture_changed.connect(_on_capture_changed)
	detector.set_input_enabled(player.captured)
	hud.bind(detector, player)
	witness.watched_target = core
	witness.detector = detector
	core.gaze_activated.connect(_on_core_activated)
	rear.gaze_activated.connect(_on_rear_activated)
	witness.gaze_activated.connect(_on_witness_activated)
	right.gaze_activated.connect(_on_right_activated)
	sequence.front_cue.connect(_on_front_cue)
	sequence.right_cue.connect(_on_right_cue)
	sequence.rear_cue.connect(_on_rear_cue)


func _on_capture_changed(captured: bool) -> void:
	detector.set_input_enabled(captured)


func _discover(target: GazeTarget, words: String) -> void:
	if not discovered.has(target.name):
		discovered[target.name] = true
		hud.mark_discovery()
	if discovered.size() == 4:
		words += "\nFour traces. A space that responds to your attention."
	hud.show_message(words, 6.0, 1)


func _on_core_activated() -> void:
	core.get_node("Visual").awaken()
	_discover(core, "You found something. The core remembers your gaze.")


func _on_rear_activated() -> void:
	rear.get_node("Visual").open_bloom()
	_discover(rear, "Behind you, what was closed has bloomed.")


func _on_witness_activated() -> void:
	witness.acknowledge()
	var words: String = "The witness moved closer while you watched the core. Now it stands still."
	if not witness.motion_seen:
		words = "The witness waits. Look at the core, then back: its position will have changed."
	_discover(witness, words)


func _on_right_activated() -> void:
	right.get_node("Visual").pulse()
	_discover(right, "An echo. Look away and back to make it resonate again.")


func _on_front_cue() -> void:
	core.enabled = true
	core.get_node("Visual").reveal()
	hud.show_message("A presence ahead. Hold your gaze for one second.", 4.0)


func _on_right_cue() -> void:
	right.get_node("Visual").pulse()
	hud.show_cue("SOMETHING STIRS TO YOUR RIGHT   →", 3.0)


func _on_rear_cue() -> void:
	rear.get_node("Visual").signal_presence()
	$World/Props.cue_rear()
	hud.show_cue("THE LIGHT CONTINUES BEHIND YOU   /   TURN TO FOLLOW IT", 5.0)
