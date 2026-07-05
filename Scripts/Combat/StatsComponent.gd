extends "res://Scripts/Core/BaseComponent.gd"

class_name StatsComponent

@export var strength: float = 10.0
@export var dexterity: float = 10.0
@export var intelligence: float = 10.0
@export var vitality: float = 10.0

@export var defense: float = 5.0
@export var magic_defense: float = 5.0
@export var attack_power: float = 10.0
@export var magic_power: float = 10.0

@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 1.5
@export var dodge_chance: float = 0.05
@export var block_chance: float = 0.0

@export var move_speed: float = 200.0
@export var attack_speed: float = 1.0

var modifiers: Dictionary = {}

signal stat_changed(stat_name: String, old_value: float, new_value: float)


func emit_stat_changed(stat_name: String, old_value: float, new_value: float) -> void:
    stat_changed.emit(stat_name, old_value, new_value)


func _on_entity_ready() -> void:
    if entity:
        var HealthScript = load("res://Scripts/Combat/HealthComponent.gd")
        var health = entity.get_component(HealthScript)
        if health:
            health.set("max_health", 80.0 + vitality * 10.0)
            health.set("current", health.get("max_health"))


func apply_modifier(key: String, modifier: Dictionary) -> void:
    modifiers[key] = modifier
    _recalculate_stats()


func remove_modifier(key: String) -> void:
    modifiers.erase(key)
    _recalculate_stats()


func get_modified_stat(stat_name: String, base_value: float) -> float:
    var value := base_value
    for mod in modifiers.values():
        if mod.has(stat_name):
            if mod[stat_name].has("add"):
                value += mod[stat_name]["add"]
            if mod[stat_name].has("mult"):
                value *= mod[stat_name]["mult"]
    return value


func _set_stat_value(stat_name: String, value: float) -> bool:
    match stat_name:
        "strength", "str": strength = value
        "dexterity", "dex": dexterity = value
        "intelligence", "int": intelligence = value
        "vitality", "vit": vitality = value
        "defense": defense = value
        "magic_defense": magic_defense = value
        "attack_power", "attack", "atk": attack_power = value
        "magic_power": magic_power = value
        "move_speed", "speed", "spd": move_speed = value
        "attack_speed": attack_speed = value
        "crit_chance": crit_chance = value
        "crit_multiplier": crit_multiplier = value
        "dodge_chance": dodge_chance = value
        "block_chance": block_chance = value
        "hp": return false
        _: return false
    return true


func get_stat(stat_name: String) -> float:
    match stat_name:
        "strength", "str": return strength
        "dexterity", "dex": return dexterity
        "intelligence", "int": return intelligence
        "vitality", "vit": return vitality
        "defense": return defense
        "magic_defense": return magic_defense
        "attack_power", "attack", "atk": return attack_power
        "magic_power": return magic_power
        "move_speed", "speed", "spd": return move_speed
        "attack_speed": return attack_speed
        "crit_chance": return crit_chance
        "crit_multiplier": return crit_multiplier
        "dodge_chance": return dodge_chance
        "block_chance": return block_chance
        "hp": return entity.get_component(load("res://Scripts/Combat/HealthComponent.gd")).current if entity else 0.0
    return 0.0


func set_base_stat(stat_name: String, value: float) -> void:
    _set_stat_value(stat_name, value)


func _recalculate_stats() -> void:
    strength = get_modified_stat("strength", 10.0)
    dexterity = get_modified_stat("dexterity", 10.0)
    intelligence = get_modified_stat("intelligence", 10.0)
    vitality = get_modified_stat("vitality", 10.0)
    defense = get_modified_stat("defense", 5.0)
    magic_defense = get_modified_stat("magic_defense", 5.0)
    attack_power = get_modified_stat("attack_power", 10.0)
