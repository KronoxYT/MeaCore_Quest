extends CharacterBody2D

var speed: float = 130.0
var is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
var current_dir: int = 0
var anim_frame: int = 0
var anim_timer: float = 0.0
const ANIM_SPEED: float = 0.15

var can_attack: bool = true
var attack_cooldowns: Array = [0.0, 0.0, 0.0]

var shake_intensity: float = 0.0
var shake_decay: float = 15.0
@onready var camera: Camera2D = $Camera2D

var class_x_offset: int = 0
var class_y_offset: int = 0

# --- ARCADE: Combo System ---
var combo_count: int = 0
var comboTimer: float = 0.0
const COMBO_WINDOW: float = 0.8
const COMBO_MULTIPLIERS: Array = [1.0, 1.2, 1.5]

# --- ARCADE: Dash ---
var is_dashing: bool = false
var dash_dir: Vector2 = Vector2.ZERO
var dash_speed: float = 600.0
var dash_duration: float = 0.15
var dash_timer: float = 0.0
var dash_cooldown: float = 1.5
var dash_cd_timer: float = 0.0
var is_invulnerable: bool = false

# --- ARCADE: Weapon visual ---
var weapon_node: Node2D
var is_swinging: bool = false

# --- ARCADE: Knockback on player ---
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 10.0

# Input state tracking
var key_1_held: bool = false
var key_2_held: bool = false
var key_3_held: bool = false

func _ready():
	add_to_group("player")
	GameManager.player_stats_changed.connect(setup_class_graphics)
	setup_class_graphics()
	GameManager.target_changed.connect(_on_target_changed)

	var weap_scene = load("res://Scenes/entities/WeaponVisual.gd")
	weapon_node = weap_scene.new()
	weapon_node.name = "WeaponVisual"
	add_child(weapon_node)

	match GameManager.player_class:
		"Warrior":
			weapon_node.weapon_color = Color(0.8, 0.8, 0.9)
			weapon_node.weapon_shape = "sword"
		"Mage":
			weapon_node.weapon_color = Color(0.3, 0.5, 1.0)
			weapon_node.weapon_shape = "staff"
		"Archer":
			weapon_node.weapon_color = Color(0.6, 0.4, 0.2)
			weapon_node.weapon_shape = "bow"

func setup_class_graphics():
	sprite.texture = load("res://Assets/Sprites/characters.png")
	if GameManager.player_class == "Warrior":
		class_x_offset = 0
		class_y_offset = 0
	elif GameManager.player_class == "Mage":
		class_x_offset = 96
		class_y_offset = 0
	elif GameManager.player_class == "Archer":
		class_x_offset = 192
		class_y_offset = 0
	
	sprite.region_enabled = true
	update_sprite_rect()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var t = GameManager.target
		if t and t.is_in_group("enemy") and is_instance_valid(t) and not t.is_dead:
			var dist = global_position.distance_to(t.global_position)
			if dist <= _get_attack_range():
				cast_skill(0)
				get_viewport().set_input_as_handled()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if is_dashing or is_dead or dash_cd_timer > 0.0:
			return
		var dir = (get_global_mouse_position() - global_position).normalized()
		if dir.length() > 0:
			_start_dash(dir)
			get_viewport().set_input_as_handled()

func _physics_process(delta):
	if is_dashing:
		_process_dash(delta)
		return

	if shake_intensity > 0.0:
		shake_intensity = max(0.0, shake_intensity - shake_decay * delta)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
	else:
		camera.offset = Vector2.ZERO

	# Cooldowns
	for i in range(attack_cooldowns.size()):
		if attack_cooldowns[i] > 0.0:
			attack_cooldowns[i] = max(0.0, attack_cooldowns[i] - delta)
			if i < GameManager.skills.size():
				GameManager.skills[i]["current_cooldown"] = attack_cooldowns[i]

	if dash_cd_timer > 0.0:
		dash_cd_timer -= delta

	# Combo timer
	if combo_count > 0:
		comboTimer -= delta
		if comboTimer <= 0.0:
			_reset_combo()

	# Knockback decay
	if knockback_velocity.length() > 0.0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * 60.0 * delta)
		if knockback_velocity.length() < 5.0:
			knockback_velocity = Vector2.ZERO

	# Movement (WASD + Arrows)
	var direction = Vector2.ZERO
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	direction = direction.normalized()

	# Dash input
	if Input.is_action_just_pressed("dash") and dash_cd_timer <= 0.0 and direction.length() > 0 and not is_dashing and not is_dead:
		_start_dash(direction)

	# Skill inputs
	if Input.is_action_just_pressed("skill_1"): cast_skill(0)
	if Input.is_action_just_pressed("skill_2"): cast_skill(1)
	if Input.is_action_just_pressed("skill_3"): cast_skill(2)

	# Interact input (E)
	if Input.is_action_just_pressed("interact"):
		var npcs = get_tree().get_nodes_in_group("npc")
		var closest_npc = null
		var min_dist = 45.0
		for npc in npcs:
			if is_instance_valid(npc):
				var dist = global_position.distance_to(npc.global_position)
				if dist < min_dist:
					closest_npc = npc
					min_dist = dist
		if closest_npc:
			GameManager.target = closest_npc
			closest_npc.interact()

	if Input.is_action_just_pressed("basic_attack"): cast_skill(0)
	if Input.is_action_just_pressed("cycle_target"): _cycle_target()

	velocity = direction * speed + knockback_velocity
	move_and_slide()

	# Animation logic
	if direction.length() > 0:
		if abs(direction.x) > abs(direction.y):
			current_dir = 3 if direction.x > 0 else 2
		else:
			current_dir = 0 if direction.y > 0 else 1
		anim_timer += delta
		if anim_timer >= ANIM_SPEED:
			anim_timer = 0.0
			anim_frame = (anim_frame + 1) % 3
	else:
		anim_frame = 0
		anim_timer = 0.0

	update_sprite_rect()

func _get_attack_range() -> float:
	return 35.0 if GameManager.player_class == "Warrior" else 150.0

func _start_dash(dir: Vector2):
	is_dashing = true
	dash_dir = dir.normalized()
	dash_duration = 0.15
	dash_timer = dash_duration
	is_invulnerable = true
	dash_cd_timer = dash_cooldown

	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.05)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)
	SoundManager.play_sfx("spell")

func _process_dash(delta):
	dash_timer -= delta
	if dash_timer <= 0.0:
		is_dashing = false
		is_invulnerable = false
		velocity = Vector2.ZERO
		return
	velocity = dash_dir * dash_speed
	move_and_slide()

func _on_target_changed(new_target: Node):
	pass

func _cycle_target():
	var enemies = get_tree().get_nodes_in_group("enemy")
	var alive = []
	for e in enemies:
		if not e.is_dead and is_instance_valid(e):
			alive.append(e)
	if alive.size() == 0: return
	if not is_instance_valid(GameManager.target) or GameManager.target == null:
		GameManager.target = alive[0]
		return
	var idx = alive.find(GameManager.target)
	if idx == -1 or idx >= alive.size() - 1:
		GameManager.target = alive[0]
	else:
		GameManager.target = alive[idx + 1]

func update_sprite_rect():
	var frame_size = 32
	var frame_x = class_x_offset + (anim_frame * frame_size)
	var frame_y = class_y_offset + (current_dir * frame_size)
	sprite.region_rect = Rect2(frame_x, frame_y, frame_size, frame_size)
	# Escalamos el sprite para que se vea de tamaño normal en el juego (aprox 32x32 en pantalla)
	sprite.scale = Vector2(32.0 / frame_size, 32.0 / frame_size)

func cast_skill(skill_idx: int):
	if is_dead or is_dashing: return
	if skill_idx >= GameManager.skills.size(): return
	var skill = GameManager.skills[skill_idx]
	if attack_cooldowns[skill_idx] > 0.0: return
	if GameManager.mp < skill["mp_cost"]:
		GameManager.add_chat_msg("[Sistema]", "¡No tienes suficiente Maná!", Color(0.4, 0.6, 1.0))
		return
	var current_target = GameManager.target
	if not is_instance_valid(current_target) or current_target == null or not current_target.is_in_group("enemy") or current_target.is_dead:
		current_target = get_nearest_enemy()
		if current_target: GameManager.target = current_target
		else:
			GameManager.add_chat_msg("[Sistema]", "Necesitas un objetivo para atacar.", Color(1.0, 0.3, 0.3))
			return
	var dist = global_position.distance_to(current_target.global_position)
	if dist > _get_attack_range(): return
	GameManager.mp -= skill["mp_cost"]
	attack_cooldowns[skill_idx] = skill["cooldown"]
	GameManager.skills[skill_idx]["current_cooldown"] = skill["cooldown"]
	GameManager.player_stats_changed.emit()
	var attack_dir = (current_target.global_position - global_position).normalized()
	_play_weapon_swing(attack_dir)
	if GameManager.player_class == "Warrior":
		SoundManager.play_sfx("hit")
	else:
		SoundManager.play_sfx("spell")

	execute_skill_effect(skill, current_target, attack_dir, skill_idx)

	if skill_idx == 0:
		_register_combo_hit()

func _play_weapon_swing(attack_dir: Vector2):
	if is_swinging: return
	is_swinging = true
	weapon_node.position = attack_dir * 14.0
	weapon_node.rotation = attack_dir.angle()
	weapon_node.visible = true
	weapon_node.modulate.a = 1.0
	weapon_node.scale = Vector2.ONE
	var tween = create_tween().set_parallel()
	tween.tween_property(weapon_node, "rotation", weapon_node.rotation + 1.8, 0.08)
	tween.tween_property(weapon_node, "scale", Vector2(0.5, 0.5), 0.08)
	tween.tween_property(weapon_node, "modulate:a", 0.0, 0.08).set_delay(0.06)
	tween.finished.connect(func():
		weapon_node.visible = false
		is_swinging = false
	, CONNECT_ONE_SHOT)
	var punch = create_tween()
	punch.tween_property(sprite, "offset", attack_dir * 6.0, 0.06)
	punch.tween_property(sprite, "offset", Vector2.ZERO, 0.06)

func _register_combo_hit():
	combo_count = min(combo_count + 1, 3)
	comboTimer = COMBO_WINDOW
	GameManager.current_combo = combo_count
	GameManager.combo_changed.emit(combo_count)
	if combo_count >= 2:
		GameManager.add_chat_msg("[Combo]", "Hit x" + str(combo_count) + "!", Color(1.0, 0.7, 0.1))

func _reset_combo():
	combo_count = 0
	GameManager.current_combo = 0
	GameManager.combo_changed.emit(0)

func get_combo_multiplier() -> float:
	return COMBO_MULTIPLIERS[combo_count - 1] if combo_count > 0 else 1.0

func execute_skill_effect(skill: Dictionary, target_node: Node, attack_dir: Vector2, skill_idx: int = 0):
	var combo_mult = get_combo_multiplier() if skill_idx == 0 else 1.0
	var damage = int((GameManager.atk * skill["multiplier"] * combo_mult) - target_node.defense)
	damage = max(1, damage)
	var is_crit = randf() < 0.15
	if is_crit: damage = int(damage * 1.5)
	if GameManager.player_class == "Warrior":
		target_node.take_damage(damage, is_crit)
		GameManager.play_effect.emit(skill["effect"], target_node.global_position)
		if is_instance_valid(target_node): target_node.apply_knockback(attack_dir * 60.0)
		_trigger_hit_stop()
	else:
		var proj_scene = load("res://Scenes/entities/Projectile.tscn")
		var proj = proj_scene.instantiate()
		if skill["effect"] == "atk_fireball": proj.aoe_radius = 40.0
		elif skill["effect"] == "atk_poison": proj.piercing = true
		proj.global_position = global_position
		proj.setup(target_node, damage, is_crit, skill["effect"])
		get_parent().add_child(proj)
		_trigger_hit_stop()

func _trigger_hit_stop():
	if is_dead:
		return
	Engine.time_scale = 0.0
	for _i in range(3):
		await get_tree().process_frame
		if is_dead:
			Engine.time_scale = 1.0
			return
	Engine.time_scale = 1.0

func take_damage(amount: int):
	if is_invulnerable or is_dead:
		return

	var dmg = max(1, amount - GameManager.def)
	GameManager.hp = max(0.0, GameManager.hp - dmg)
	GameManager.show_damage_number.emit(global_position + Vector2(0, -12), str(dmg), Color(1.0, 0.2, 0.2))
	shake_intensity = 6.0

	var tween = create_tween()
	tween.tween_property(sprite, "self_modulate", Color(1, 0.3, 0.3), 0.08)
	tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.08)

	GameManager.player_stats_changed.emit()
	SoundManager.play_sfx("hit", 1.2 if randi() % 5 == 0 else 1.0)

	if GameManager.hp <= 0:
		die()

func die():
	is_dead = true
	GameManager.add_chat_msg("[Sistema]", "¡Has muerto! Resucitas en la Aldea.", Color(1.0, 0.1, 0.1))
	GameManager.gold = int(GameManager.gold * 0.9)
	GameManager.hp = GameManager.max_hp
	GameManager.mp = GameManager.max_mp
	global_position = Vector2(300, 300)
	GameManager.target = null
	is_dead = false
	GameManager.player_stats_changed.emit()

func get_nearest_enemy() -> Node:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest = null
	var min_dist = 99999.0
	for e in enemies:
		if e.is_dead or not is_instance_valid(e): continue
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest
