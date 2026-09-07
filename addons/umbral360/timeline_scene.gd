extends Node3D
## Optional base for a scene authored with AnimationPlayer property tracks.
## Sampling is absolute: delivered frame zero is animation time zero.

@export var animation_player_path: NodePath = NodePath("AnimationPlayer")
@export var animation_name: StringName = &"film"
@export var preview_autoplay: bool = true
var capture_mode: bool = false
var timeline_player: AnimationPlayer
var timeline_animation: Animation
var discrete_tracks: Array[Dictionary] = []


func prepare_360_capture(_job: Dictionary) -> void:
	capture_mode = true


func _ready() -> void:
	if not capture_mode and preview_autoplay:
		var player := get_node_or_null(animation_player_path) as AnimationPlayer
		if player != null and player.has_animation(animation_name):
			player.play(animation_name)


func begin_360_capture(job: Dictionary) -> String:
	timeline_player = get_node_or_null(animation_player_path) as AnimationPlayer
	if timeline_player == null or not timeline_player.has_animation(animation_name):
		return "Timeline requires an AnimationPlayer and a named animation."
	var animation := timeline_player.get_animation(animation_name)
	discrete_tracks.clear()
	timeline_animation = animation
	if animation.loop_mode != Animation.LOOP_NONE:
		return "Capture timelines must not loop. Extend the animation for the requested film."
	if float(int(job.frames) - 1) / float(job.fps) > animation.length + 0.000001:
		return "The requested film extends beyond the capture animation. Shorten the recipe or extend its timeline."
	for track in range(animation.get_track_count()):
		if not animation.track_is_enabled(track):
			continue
		if animation.track_get_type(track) in [Animation.TYPE_METHOD, Animation.TYPE_AUDIO, Animation.TYPE_ANIMATION]:
			return "Capture timelines support property tracks, not method, audio, or nested playback tracks (track %d). Use ordinary scene audio or an explicit capture hook." % track
		if animation.track_get_type(track) == Animation.TYPE_VALUE:
			if animation.value_track_get_update_mode(track) == Animation.UPDATE_CAPTURE:
				return "Capture timelines require explicit property keys instead of Capture update mode."
			if animation.value_track_get_update_mode(track) == Animation.UPDATE_DISCRETE:
				if animation.track_get_key_count(track) == 0 or animation.track_get_key_time(track, 0) != 0.0:
					return "Discrete capture tracks require an initial key at time zero (track %d)." % track
				var path := animation.track_get_path(track)
				var animation_root := timeline_player.get_node_or_null(timeline_player.root_node)
				var target := animation_root.get_node_or_null(NodePath(path.get_concatenated_names())) if animation_root != null else null
				if target == null or path.get_subname_count() == 0:
					return "Discrete capture track has no target property: " + str(path)
				discrete_tracks.append({"track": track, "target": target, "property": NodePath(path.get_concatenated_subnames())})
	timeline_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	timeline_player.play(animation_name)
	return sample_360_frame(0, 0.0, job)


func sample_360_frame(_frame_index: int, time_seconds: float, _job: Dictionary) -> String:
	if timeline_player == null:
		return "The capture timeline has not been initialized."
	timeline_player.seek(time_seconds, true, true)
	# Godot's discrete tracks are event-like when seeking. Apply the last authored
	# value explicitly so backward seeks and repeated warmup samples are idempotent.
	for entry in discrete_tracks:
		var key: int = 0
		for candidate in range(timeline_animation.track_get_key_count(entry.track)):
			if timeline_animation.track_get_key_time(entry.track, candidate) > time_seconds + 0.0000001:
				break
			key = candidate
		entry.target.set_indexed(entry.property, timeline_animation.track_get_key_value(entry.track, key))
	return ""
