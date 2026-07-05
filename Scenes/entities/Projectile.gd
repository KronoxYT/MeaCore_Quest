extends Area2D

var target: Node = null
var speed: float = 500.0
var damage: int = 0
var is_crit: bool = false
var effect_type: String = ""
var piercing: bool = false
var aoe_radius: float = 0.0
var hit_targets: Array = []

var trail_points: Array[Vector2] = []
@onready var trail: Line2D = $Line2D

func setup(p_target: Node, p_damage: int, p_is_crit: bool, p_effect: String):
	target = p_target
	damage = p_damage
	is_crit = p_is_crit
	effect_type = p_effect

func _ready():
	if effect_type == "atk_fireball":
		trail.default_color = Color(1.0, 0.5, 0.1)
	elif effect_type == "atk_spell":
		trail.default_color = Color(0.2, 0.8, 1.0)
	elif effect_type == "atk_poison":
		trail.default_color = Color(0.3, 0.9, 0.3)
	elif effect_type == "atk_bow":
		trail.default_color = Color(0.8, 0.6, 0.4)
	else:
		trail.default_color = Color.WHITE

func _process(delta):
	if not is_instance_valid(target) or target.is_dead:
		if piercing and is_instance_valid(target) and target.is_dead:
			pass
		else:
			if aoe_radius <= 0.0:
				queue_free()
				return

	var target_pos = target.global_position + Vector2(0, -6)
	var dir = (target_pos - global_position).normalized()
	global_position += dir * speed * delta

	trail_points.push_front(global_position)
	if trail_points.size() > 10:
		trail_points.pop_back()

	var local_points = PackedVector2Array()
	for p in trail_points:
		local_points.append(p - global_position)
	trail.points = local_points

	queue_redraw()

	if global_position.distance_to(target_pos) < 8.0:
		impact()

func _draw():
	if effect_type == "atk_fireball":
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.3, 0.1))
		draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.8, 0.2))
	elif effect_type == "atk_spell":
		draw_circle(Vector2.ZERO, 4.0, Color(0.1, 0.7, 1.0))
		draw_circle(Vector2.ZERO, 2.0, Color.WHITE)
	elif effect_type == "atk_poison":
		draw_line(Vector2(-4, 0), Vector2(4, 0), Color(0.2, 0.9, 0.2), 2.0)
	else:
		draw_line(Vector2(-5, 0), Vector2(5, 0), Color(0.8, 0.6, 0.4), 2.0)

func impact():
	if aoe_radius > 0.0:
		_aoe_explosion()
		return

	if is_instance_valid(target) and not target.is_dead:
		target.take_damage(damage, is_crit)
		if is_instance_valid(target):
			var dir = (target.global_position - global_position).normalized()
			target.apply_knockback(dir * 50.0)
		GameManager.play_effect.emit(effect_type + "_impact", global_position)

	if not piercing:
		queue_free()

func _aoe_explosion():
	GameManager.play_effect.emit(effect_type + "_impact", global_position)
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if not e.is_dead and is_instance_valid(e):
			var dist = global_position.distance_to(e.global_position)
			if dist <= aoe_radius:
				e.take_damage(damage, is_crit)
				var dir = (e.global_position - global_position).normalized()
				e.apply_knockback(dir * 40.0)
	queue_free()
