extends CharacterBody2D

var pet_id: String = ""
var pet_name: String = ""
var pet_level: int = 1
var max_hp: float = 30.0
var hp: float = 30.0
var atk: int = 5
var defense: int = 2
var speed: float = 120.0
var is_dead: bool = false
var attack_type: String = "melee"
var attack_range: float = 30.0
var attack_cooldown: float = 1.2
var attack_timer: float = 0.0
var follow_distance: float = 50.0
var stop_distance: float = 30.0

var player_node: Node = null
var current_target: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var anim_frame: int = 0
var anim_timer: float = 0.0
var current_dir: int = 0

func _ready():
	add_to_group("pet")

func setup(p_id: String, p_data: Dictionary):
	pet_id = p_id
	pet_name = p_data.get("name", "Mascota")
	attack_type = p_data.get("attack_type", "melee")
	atk = p_data.get("atk", 5)
	defense = p_data.get("def", 2)
	max_hp = p_data.get("max_hp", 30.0)
	hp = max_hp
	speed = p_data.get("speed", 120.0)
	pet_level = GameManager.pet_stats.get("level", 1)
	_sync_stats_with_manager()
	update_sprite_appearance()

func _sync_stats_with_manager():
	var ps = GameManager.pet_stats
	pet_level = ps.get("level", 1)
	max_hp = 30.0 + pet_level * 8.0
	atk = 5 + pet_level * 2
	defense = 2 + pet_level
	speed = 120.0 + pet_level * 5

func update_sprite_appearance():
	var frame_y = 0
	match pet_id:
		"fire_spirit": frame_y = 0
		"shadow_cat": frame_y = 1
		"mini_golem": frame_y = 2
	sprite.region_rect = Rect2(0, frame_y * 32, 32, 32)

func _physics_process(delta):
	if is_dead:
		return
	if player_node == null:
		player_node = get_tree().get_first_node_in_group("player")
		if player_node == null:
			return
	if attack_timer > 0.0:
		attack_timer -= delta
	if current_target == null or not is_instance_valid(current_target) or current_target.is_dead:
		current_target = _find_nearest_enemy()
	if current_target != null:
		var dist = global_position.distance_to(current_target.global_position)
		if dist <= attack_range:
			if attack_timer <= 0.0:
				_attack_target()
			return
	var p_dist = global_position.distance_to(player_node.global_position)
	if p_dist > follow_distance:
		var dir = (player_node.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
	elif p_dist < stop_distance:
		velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
	_animate(delta)

func _find_nearest_enemy() -> Node:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest = null
	var min_dist = 99999.0
	for e in enemies:
		if e.is_dead or not is_instance_valid(e):
			continue
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest

func _attack_target():
	if current_target == null or not is_instance_valid(current_target):
		return
	attack_timer = attack_cooldown
	var raw_damage = atk
	var target_def = current_target.defense
	var damage = int(raw_damage * 100.0 / (100.0 + target_def))
	damage = max(1, damage)
	current_target.take_damage(damage, false)
	var dir = (current_target.global_position - global_position).normalized()
	var tween = create_tween()
	tween.tween_property(sprite, "offset", dir * 8.0, 0.05)
	tween.tween_property(sprite, "offset", Vector2.ZERO, 0.05)

func take_damage(amount: int):
	if is_dead:
		return
	hp -= amount
	var tween = create_tween()
	tween.tween_property(sprite, "self_modulate", Color(1, 0.2, 0.2), 0.05)
	tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.05)
	if hp <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	visible = false
	collision_shape.set_deferred("disabled", true)
	var timer = get_tree().create_timer(10.0)
	await timer.timeout
	_revive()

func _revive():
	is_dead = false
	hp = max_hp * 0.5
	visible = true
	collision_shape.set_deferred("disabled", false)
	global_position = player_node.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))

func _animate(delta):
	if velocity.length() > 2.0:
		if abs(velocity.x) > abs(velocity.y):
			current_dir = 3 if velocity.x > 0 else 2
		else:
			current_dir = 0 if velocity.y > 0 else 1
		anim_timer += delta
		if anim_timer >= 0.15:
			anim_timer = 0.0
			anim_frame = 1 if anim_frame == 2 else 2
	else:
		anim_frame = 0
		anim_timer = 0.0
	var fx = 0
	match pet_id:
		"fire_spirit": fx = 0
		"shadow_cat": fx = 32
		"mini_golem": fx = 64
	sprite.region_rect = Rect2(fx + anim_frame * 32, current_dir * 32, 32, 32)
