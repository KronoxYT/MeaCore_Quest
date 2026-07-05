extends Node2D

class_name BaseEntity

@export var entity_name: String = "Entity"
@export var faction = 0
@export var stats: Node

var components: Dictionary = {}
var is_alive: bool = true
var fsm = null
var _health_cache = null
var _stats_cache = null

var health:
    get:
        if not _health_cache:
            var Script = load("res://Scripts/Combat/HealthComponent.gd")
            _health_cache = get_component(Script)
        return _health_cache


func _ready() -> void:
    _collect_components()
    _setup_fsm()
    _ready_components()


func _collect_components() -> void:
    _health_cache = null
    _stats_cache = null
    components.clear()
    for child in get_children():
        if child.has_method("_on_entity_ready"):
            var script = child.get_script()
            if script:
                components[script.get_global_name()] = child


func _setup_fsm() -> void:
    var existing = get_node_or_null("FSM")
    if existing:
        fsm = existing
        return
    var FsmScript = load("res://Scripts/Core/FSM.gd")
    if FsmScript:
        fsm = FsmScript.new()
        fsm.name = "FSM"
        add_child(fsm)


func _ready_components() -> void:
    for comp in components.values():
        if comp.has_method("_on_entity_ready"):
            comp._on_entity_ready()


func get_component(type_: Variant):
    for comp in components.values():
        if is_instance_of(comp, type_):
            return comp
    return null


func get_all_components() -> Array:
    return components.values()


func take_damage(amount: float, type_ = 0) -> void:
    var HealthScript = load("res://Scripts/Combat/HealthComponent.gd")
    var health = get_component(HealthScript)
    if health and health.get("is_invulnerable"):
        return

    var StatsScript = load("res://Scripts/Combat/StatsComponent.gd")
    var stats_comp = get_component(StatsScript)
    var DamageCalcScript = load("res://Scripts/Combat/DamageCalculator.gd")
    var final_damage = DamageCalcScript.calculate_damage(amount, type_, stats_comp)
    if health:
        health.reduce(final_damage)
        if health.get("current") <= 0:
            die()


func die() -> void:
    if not is_alive:
        return
    is_alive = false
    if fsm and fsm.has_method("change_state"):
        fsm.change_state("death")
    var EM = get_node("/root/EventManager")
    if EM:
        EM.emit_event("entity_died", self)


func heal(amount: float) -> void:
    var HealthScript = load("res://Scripts/Combat/HealthComponent.gd")
    var health = get_component(HealthScript)
    if health:
        health.increase(amount)
