class_name SequenceController
extends Node

signal front_cue
signal right_cue
signal rear_cue
signal sequence_finished

@export var autoplay: bool = true
var elapsed: float = 0.0
var stage: int = 0
var playing: bool = false


func _ready() -> void:
	playing = autoplay


func _process(delta: float) -> void:
	if not playing:
		return
	elapsed += delta
	# Independent conditions preserve every cue even across a long frame.
	if stage == 0 and elapsed >= 2.0:
		stage = 1
		front_cue.emit()
	if stage == 1 and elapsed >= 5.0:
		stage = 2
		right_cue.emit()
	if stage == 2 and elapsed >= 8.0:
		stage = 3
		rear_cue.emit()
		playing = false
		sequence_finished.emit()
