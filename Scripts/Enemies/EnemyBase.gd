class_name EnemyBase
extends CharacterBody2D

## Clase base para todos los enemigos
## Maneja IA, combate y drops

signal died(enemy_id: String)
signal aggro_started(target: Node)
signal aggro_lost()

@export var enemy_resource = null
@export var spawn_point: Vector2 = Vector2.ZERO

var enemy_id: String = ""
var level: int = 1
var last_attacker: Node = null
var home_position: Vector2 = Vector2.ZERO

var health
var stats
var fsm
var ai
var animation_player
var sprite
var loot_drop
var nav_agent

func _ready():
    _setup_references()
    _setup_enemy_id()
    _load_from_resource()
    add_to_group("enemies")
    home_position = global_position
    
    if spawn_point != Vector2.ZERO:
        global_position = spawn_point
        home_position = spawn_point

func _setup_references() -> void:
    health = get_node_or_null("HealthComponent")
    stats = get_node_or_null("StatsComponent")
    fsm = get_node_or_null("FSM")
    ai = get_node_or_null("EnemyAI")
    animation_player = get_node_or_null("AnimationPlayer")
    sprite = get_node_or_null("Sprite2D")
    loot_drop = get_node_or_null("LootDropComponent")
    nav_agent = get_node_or_null("NavigationAgent2D")
    
    # Conectar señales
    if health:
        health.depleted.connect(_on_health_depleted)
        health.damaged.connect(_on_damaged)

func _setup_enemy_id() -> void:
    enemy_id = "%s_%d" % [enemy_resource.id if enemy_resource else "enemy", get_instance_id()]

func _load_from_resource() -> void:
    if not enemy_resource:
        push_warning("EnemyBase: No se asignó EnemyResource")
        return
    
    level = randi_range(enemy_resource.level_range.x, enemy_resource.level_range.y)
    
    if stats:
        stats.set_base_stat("hp", enemy_resource.get_stat_for_level(level, "hp"))
        stats.set_base_stat("attack", enemy_resource.get_stat_for_level(level, "attack"))
        stats.set_base_stat("defense", enemy_resource.get_stat_for_level(level, "defense"))
        stats.set_base_stat("speed", enemy_resource.get_stat_for_level(level, "speed"))
    
    if health:
        health.max_health = int(enemy_resource.get_stat_for_level(level, "hp"))
        health.current_health = health.max_health
    
    if sprite and enemy_resource.sprite_sheet:
        sprite.texture = enemy_resource.sprite_sheet
        sprite.scale = enemy_resource.scale

func take_damage(amount: float, source: Node = null) -> void:
    if not health:
        return
    
    last_attacker = source
    var actual_damage = health.take_damage(amount, source)
    
    if actual_damage > 0:
        EventManager.damage_dealt.emit(
            enemy_id,
            source.get_instance_id() if source else "",
            actual_damage
        )
        _show_damage_number(actual_damage, source)

func _show_damage_number(amount: float, source: Node) -> void:
    var damage_scene = preload("res://Scenes/Effects/DamageNumber.tscn")
    var damage_instance = damage_scene.instantiate()
    damage_instance.setup(amount, false)
    damage_instance.global_position = global_position + Vector2(0, -40)
    get_tree().current_scene.add_child(damage_instance)

func _on_damaged(amount: float, source: Node) -> void:
    if fsm and fsm.is_in_state("patrol") or fsm.is_in_state("idle"):
        if fsm.has_method("transition_to"):
            fsm.transition_to("hurt")

func _on_health_depleted() -> void:
    if fsm:
        fsm.transition_to("death")

func die() -> void:
    # Generar loot
    if loot_drop and enemy_resource:
        loot_drop.drop_loot(enemy_resource)
    
    # Otorgar XP al atacante
    if last_attacker and last_attacker.has_method("gain_xp"):
        last_attacker.gain_xp(enemy_resource.xp_reward)
    
    # Notificar al sistema
    EventManager.enemy_killed.emit(enemy_id, last_attacker.get_instance_id() if last_attacker else "")
    
    # Animación de muerte y eliminación
    if animation_player and animation_player.has_animation("death"):
        animation_player.play("death")
        await animation_player.animation_finished
    
    queue_free()

func play_animation(anim_name: String) -> void:
    if animation_player and animation_player.has_animation(anim_name):
        animation_player.play(anim_name)

func play_hurt_animation() -> void:
    play_animation("hurt")

func face_direction(direction: Vector2) -> void:
    if sprite:
        sprite.flip_h = direction.x < 0
