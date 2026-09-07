extends Control

var progress: float = 0.0
var active: bool = false
var completed: bool = false
var accent: Color = Color("f2bd7e")


func _draw() -> void:
	var center: Vector2 = size / 2.0
	draw_circle(center, 3.0, Color("e7eee3"))
	if active:
		draw_arc(center, 16.0, 0, TAU, 64, Color(0.8, 0.9, 0.85, 0.18), 2.0, true)
		if progress > 0.0:
			draw_arc(center, 16.0, -PI / 2.0, -PI / 2.0 + progress * TAU, 64, accent, 2.5, true)
		if completed:
			draw_line(center + Vector2(-4, 29), center + Vector2(-1, 32), accent, 1.5, true)
			draw_line(center + Vector2(-1, 32), center + Vector2(5, 26), accent, 1.5, true)
	else:
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			draw_line(center + direction * 11.0, center + direction * 14.0, Color(0.8, 0.9, 0.85, 0.3), 1.0)
