@tool
extends Resource
## A portable export recipe. Executable paths belong to local editor settings.

@export_file("*.tscn") var scene_path: String = "res://addons/godot360/examples/calibration.tscn"
@export var camera_path: NodePath = NodePath("Camera3D")
@export_enum("project", "forward_plus", "mobile", "gl_compatibility") var rendering_method: String = "project"
@export_enum("project", "vulkan", "d3d12", "metal", "opengl3", "opengl3_angle", "opengl3_es") var rendering_driver: String = "project"
@export_enum("2048", "4096", "7680") var width: String = "2048"
@export_range(128, 4096, 128) var face_size: int = 512
@export_range(0.0, 25.0, 0.5) var capture_border_percent: float = 0.0
@export_enum("24", "25", "30", "50", "60") var fps: String = "30"
@export_range(0.1, 3600.0, 0.1) var duration: float = 10.0
@export var random_seed: int = 360
@export_range(0, 10, 1) var warmup_frames: int = 2
@export_range(12, 28, 1) var crf: int = 18
@export_enum("fast_png", "png") var frame_writer: String = "fast_png"
@export_enum("scene", "soundtrack", "mix") var audio_mode: String = "scene"
@export_file("*.wav", "*.mp3", "*.ogg", "*.flac", "*.m4a", "*.aac") var soundtrack_path: String = ""
@export_range(0.0, 3600.0, 0.001) var soundtrack_trim_seconds: float = 0.0
@export_range(-3600.0, 3600.0, 0.001) var soundtrack_offset_seconds: float = 0.0
@export_range(-60.0, 0.0, 0.1) var soundtrack_gain_db: float = 0.0
@export_range(-3600.0, 3600.0, 0.001) var scene_audio_offset_seconds: float = 0.0
@export_range(-60.0, 0.0, 0.1) var scene_audio_gain_db: float = 0.0


func apply_quality_preset(preset: String) -> void:
	match preset:
		"draft":
			width = "2048"
			face_size = 512
			crf = 18
		"production":
			width = "4096"
			face_size = 2048
			crf = 16
		"detail":
			width = "7680"
			face_size = 3072
			crf = 16


func to_dictionary() -> Dictionary:
	return {"scene_path": scene_path, "camera_path": str(camera_path),
		"rendering_method": rendering_method, "rendering_driver": rendering_driver,
		"width": int(width), "height": int(width) / 2, "face_size": face_size,
		"capture_border_percent": capture_border_percent,
		"fps": int(fps), "frames": roundi(duration * int(fps)),
		"random_seed": random_seed, "warmup_frames": warmup_frames, "crf": crf,
		"frame_writer": frame_writer, "audio_mode": audio_mode, "soundtrack_path": soundtrack_path,
		"soundtrack_trim_seconds": soundtrack_trim_seconds, "soundtrack_offset_seconds": soundtrack_offset_seconds,
		"soundtrack_gain_db": soundtrack_gain_db, "scene_audio_offset_seconds": scene_audio_offset_seconds,
		"scene_audio_gain_db": scene_audio_gain_db}
