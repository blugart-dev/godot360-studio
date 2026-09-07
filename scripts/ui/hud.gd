extends Control

@export var debug_enabled: bool = false
var detector: GazeDetector
var player: PlayerLook
var target: GazeTarget
var discoveries: int = 0
var message_remaining: float = 0.0
var message_priority: int = 0
var debug_clock: float = 0.0
var cue_remaining: float = 0.0

@onready var crosshair: Control = $Crosshair
@onready var target_label: Label = $TargetLabel
@onready var message_label: Label = $MessagePanel/Message
@onready var message_panel: PanelContainer = $MessagePanel
@onready var status: Label = $BottomBar/Status
@onready var compass: Label = $Compass
@onready var debug_label: Label = $DebugLabel
@onready var released_panel: PanelContainer = $ReleasedPanel
@onready var cue_label: Label = $CueLabel


func _ready() -> void:
	debug_label.visible = debug_enabled
	show_message("You are at the center. Everything else can change.", 5.0)


func bind(gaze: GazeDetector, look: PlayerLook) -> void:
	detector = gaze
	player = look
	detector.target_changed.connect(_on_target_changed)
	detector.progress_changed.connect(_on_progress_changed)
	player.capture_changed.connect(_on_capture_changed)
	_on_capture_changed(player.captured)


func _on_target_changed(value: GazeTarget) -> void:
	target = value
	crosshair.active = is_instance_valid(target)
	crosshair.progress = 0.0
	crosshair.completed = false
	if is_instance_valid(target):
		crosshair.accent = target.accent_color
		target_label.text = target.display_name
	else:
		target_label.text = ""
	crosshair.queue_redraw()


func _on_progress_changed(fraction: float) -> void:
	crosshair.progress = fraction
	crosshair.completed = is_instance_valid(target) and target.completed_this_visit
	if is_instance_valid(target):
		var hint: String = "DISCOVERED" if target.completed_this_visit else "HOLD YOUR GAZE · %.1f s" % target.dwell_time
		target_label.text = target.display_name + "\n" + hint
	crosshair.queue_redraw()


func _on_capture_changed(captured: bool) -> void:
	released_panel.visible = not captured
	crosshair.visible = captured
	target_label.visible = captured


func show_message(words: String, duration: float = 4.0, priority: int = 0) -> void:
	if message_remaining > 0.0 and priority < message_priority:
		return
	message_label.text = words
	message_remaining = duration
	message_priority = priority
	message_panel.modulate.a = 1.0


func mark_discovery() -> void:
	discoveries += 1
	status.text = "%02d / 04   TRACES DISCOVERED" % discoveries


func show_cue(words: String, duration: float = 3.0) -> void:
	cue_label.text = words
	cue_remaining = duration
	cue_label.modulate.a = 1.0


func _process(delta: float) -> void:
	cue_remaining = maxf(0.0, cue_remaining - delta)
	cue_label.modulate.a = minf(cue_remaining * 2.0, 1.0)
	message_remaining = maxf(0.0, message_remaining - delta)
	message_panel.modulate.a = minf(message_remaining * 2.0, 1.0)
	if is_instance_valid(player):
		var angle: float = fposmod(-rad_to_deg(player.rotation.y), 360.0)
		var sectors: Array[String] = ["CORE", "ECHO", "REVERSE", "WITNESS"]
		compass.text = "%03d°   /   %s" % [int(angle), sectors[int(floor((angle + 45.0) / 90.0)) % 4]]
	debug_label.visible = debug_enabled
	if debug_enabled and is_instance_valid(detector):
		debug_clock += delta
		if debug_clock >= 0.15:
			debug_clock = 0.0
			var target_name: String = detector.current_target.name if is_instance_valid(detector.current_target) else "—"
			debug_label.text = "DEBUG   %d FPS\nTarget: %s\nGaze: %.2f s" % [Engine.get_frames_per_second(), target_name, detector.gaze_seconds]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		debug_enabled = not debug_enabled
