extends Node2D

var weapon_color: Color = Color(1.0, 0.9, 0.2)
var weapon_shape: String = "sword"

func _ready():
	pass

func _draw():
	var angle = rotation
	var color = modulate * weapon_color
	color.a = modulate.a

	# Blade/sword shape
	var blade_len = 16.0
	var blade_width = 3.0
	var handle_len = 4.0

	match weapon_shape:
		"sword":
			draw_line(Vector2(0, -handle_len), Vector2(0, blade_len), color, blade_width)
			draw_line(Vector2(-2, blade_len - 2), Vector2(2, blade_len - 2), color, 2.0)
			draw_circle(Vector2(0, -handle_len), 1.5, color * 1.3)
		"staff":
			draw_line(Vector2(0, -handle_len), Vector2(0, blade_len), color, 2.0)
			draw_circle(Vector2(0, blade_len), 3.0, color)
			draw_circle(Vector2(0, blade_len), 1.5, Color.WHITE)
		"bow":
			draw_arc(Vector2(0, 2), 8.0, -PI * 0.4, PI * 0.4, 4, color, 1.5)
			draw_line(Vector2(0, -4), Vector2(0, 8), color, 1.0)
