extends "res://Scripts/Core/BaseEntity.gd"

class_name PlayerBase

@export var move_speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 800.0
@export var dodge_speed: float = 400.0
@export var dodge_duration: float = 0.3
@export var attack_duration: float = 0.4
@export var block_damage_reduction: float = 0.6
@export var character_resource: Node

var input_direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var is_dodging: bool = false
var is_blocking: bool = false
var is_attacking: bool = false

var player_id: String = ""
var xp: int = 0
var level: int = 1
var xp_to_next_level: int = 100
var gold: int = 0
var inventory: Dictionary = {}
var inventory_comp = null
var equipment = null
var skills = null
var player_input = null


func _ready() -> void:
    super()
    _setup_player_id()
    _setup_references()
    var GM = get_node("/root/GameManager")
    if GM:
        GM.register_player(self)
    _apply_character_resource()


func _setup_references() -> void:
    inventory_comp = get_node_or_null("InventoryComponent")
    equipment = get_node_or_null("EquipmentComponent")
    skills = get_node_or_null("SkillComponent")
    player_input = get_node_or_null("PlayerInput")


func _apply_character_resource() -> void:
    if not character_resource:
        return
    var HealthScript = load("res://Scripts/Combat/HealthComponent.gd")
    var health = get_component(HealthScript)
    if health:
        health.max_health = character_resource.get("max_health")
        health.current = character_resource.get("max_health")
    var StatsScript = load("res://Scripts/Combat/StatsComponent.gd")
    var stats = get_component(StatsScript)
    if stats:
        stats.strength = character_resource.get("strength")
        stats.dexterity = character_resource.get("dexterity")
        stats.intelligence = character_resource.get("intelligence")
        stats.vitality = character_resource.get("vitality")
        stats.defense = character_resource.get("defense")
        stats.magic_defense = character_resource.get("magic_defense")
        stats.attack_power = character_resource.get("attack_power")
        stats.magic_power = character_resource.get("magic_power")
    if character_resource.get("move_speed"):
        move_speed = character_resource.get("move_speed")


func _setup_player_id() -> void:
    player_id = "player_%d" % get_instance_id()
    add_to_group("players")


func gain_xp(amount: int) -> void:
    xp += amount
    _check_level_up()


func _check_level_up() -> void:
    while xp >= xp_to_next_level:
        xp -= xp_to_next_level
        level += 1
        xp_to_next_level = _calculate_xp_for_level(level)
        var EM = get_node("/root/EventManager")
        if EM:
            EM.emit_event("player_level_up", {"level": level, "player_id": player_id})
        _on_level_up()


func _calculate_xp_for_level(lvl: int) -> int:
    return int(100 * pow(lvl, 1.5))


func _on_level_up() -> void:
    var HealthScript = load("res://Scripts/Combat/HealthComponent.gd")
    var health = get_component(HealthScript)
    if health:
        var new_max = health.max_health + 10.0
        health.set_max(new_max, 1.0)
    var StatsScript = load("res://Scripts/Combat/StatsComponent.gd")
    var stats = get_component(StatsScript)
    if stats:
        stats.vitality += 1.0


func pickup_item(item_id: String, quantity: int) -> void:
    if item_id == "gold":
        gold += quantity
        var EM = get_node("/root/EventManager")
        if EM:
            EM.emit_event("notification_shown", {"message": "+%d oro" % quantity, "type": "info"})
    elif inventory_comp:
        var res = _get_item_resource(item_id)
        if res:
            inventory_comp.add_item(res, quantity)
        else:
            if item_id in inventory:
                inventory[item_id] += quantity
            else:
                inventory[item_id] = quantity
    else:
        if item_id in inventory:
            inventory[item_id] += quantity
        else:
            inventory[item_id] = quantity


func _get_item_resource(item_id: String):
    var paths = {
        "iron_sword": "res://Resources/Items/Weapons/iron_sword.tres",
        "health_potion_small": "res://Resources/Items/Consumables/health_potion_small.tres",
        "goblin_ear": null,
        "rusty_dagger": null,
        "leather_scrap": null
    }
    var path = paths.get(item_id)
    if path:
        return load(path)
    return null


func has_item(item_id: String, quantity: int = 1) -> bool:
    return inventory.get(item_id, 0) >= quantity


func remove_item(item_id: String, quantity: int = 1) -> bool:
    if not has_item(item_id, quantity):
        return false
    inventory[item_id] -= quantity
    if inventory[item_id] <= 0:
        inventory.erase(item_id)
    return true


func _process(delta: float) -> void:
    if fsm and fsm.has_method("update"):
        fsm.update(delta)


func _physics_process(delta: float) -> void:
    # Leer input desde el nodo PlayerInput si existe
    if player_input:
        input_direction = player_input.move_direction
    else:
        # Fallback: leer directamente si no hay PlayerInput
        var dir := Vector2.ZERO
        dir.x = Input.get_axis("move_left", "move_right")
        dir.y = Input.get_axis("move_up", "move_down")
        input_direction = dir.normalized()
    if fsm and fsm.has_method("physics_update"):
        fsm.physics_update(delta)


func _input(event: InputEvent) -> void:
    if fsm and fsm.has_method("handle_input"):
        fsm.handle_input(event)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_inventory"):
        _toggle_inventory()
    elif event.is_action_pressed("skill_1"):
        _use_skill_slot(0)
    elif event.is_action_pressed("skill_2"):
        _use_skill_slot(1)


func _toggle_inventory() -> void:
    var GM = get_node("/root/GameManager")
    var UM = get_node("/root/UIManager")
    if not GM or not UM:
        return
    if GM.current_state == GameManager.GameState.PLAYING:
        UM.open_ui("inventory")
    elif GM.current_state == GameManager.GameState.INVENTORY:
        UM.close_ui()


func _use_skill_slot(slot_index: int) -> void:
    if not skills or slot_index >= skills.known_skills.size():
        return
    var skill = skills.known_skills[slot_index]
    var target = _find_closest_enemy()
    skills.use_skill(skill, target)


func _find_closest_enemy() -> Node:
    var enemies = get_tree().get_nodes_in_group("enemies")
    var closest: Node = null
    var min_dist: float = 9999.0
    for enemy in enemies:
        var dist = global_position.distance_to(enemy.global_position)
        if dist < min_dist and dist < 200.0:
            min_dist = dist
            closest = enemy
    return closest


func setup_animation_tree() -> void:
    var anim_tree = $AnimationTree
    if anim_tree:
        anim_tree.active = true


func apply_server_movement(dir: Vector2, sprinting: bool) -> void:
    var speed = move_speed * (1.5 if sprinting else 1.0)
    set("velocity", dir * speed)
    call("move_and_slide")
    var anim_player = get_node_or_null("AnimationPlayer")
    if dir.length() > 0.1:
        if anim_player and anim_player.has_animation("walk"):
            anim_player.play("walk")
    else:
        if anim_player and anim_player.has_animation("idle"):
            anim_player.play("idle")
