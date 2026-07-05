extends Node2D

@onready var label: Label = $Label

func setup(text: String, color: Color):
	call_deferred("_apply_setup", text, color)

func _apply_setup(text: String, color: Color):
	label.text = text
	label.add_theme_color_override("font_color", color)
	
	# Random direction offset
	var target_pos = position + Vector2(randf_range(-15, 15), randf_range(-30, -45))
	
	# Juiced text popping and rising animation
	var tween = create_tween()
	
	# Pop scale
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)
	
	# Rise up
	tween.parallel().tween_property(self, "position", target_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_delay(0.3)
	
	# Clean up on finish
	tween.finished.connect(queue_free)
