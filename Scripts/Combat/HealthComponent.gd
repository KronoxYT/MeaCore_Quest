extends "res://Scripts/Core/BaseComponent.gd"

class_name HealthComponent

@export var max_health: float = 100.0
@export var current: float = 100.0
@export var invulnerability_time: float = 0.5

var is_invulnerable: bool = false

signal health_changed(new_health: float, delta: float)
signal depleted()
signal replenished()
signal damaged(amount: float, source: Node)

var current_health: float:
    get:
        return current
    set(value):
        current = value


func _ready() -> void:
    super()
    current = min(current, max_health)


func reduce(amount: float) -> bool:
    if is_invulnerable or current <= 0.0:
        return false
    current = max(0.0, current - amount)
    health_changed.emit(current, -amount)
    damaged.emit(amount, null)
    _start_invulnerability()
    if current <= 0.0:
        depleted.emit()
    return true


func take_damage(amount: float, source: Node = null) -> float:
    reduce(amount)
    damaged.emit(amount, source)
    return amount


func heal(amount: float) -> void:
    increase(amount)


func increase(amount: float) -> float:
    var prev := current
    current = min(max_health, current + amount)
    var healed := current - prev
    if healed > 0.0:
        health_changed.emit(current, healed)
        if current >= max_health:
            replenished.emit()
    return healed


func set_max(new_max: float, heal_percentage: float = 0.0) -> void:
    max_health = max(1.0, new_max)
    current = max_health * clampf(heal_percentage, 0.0, 1.0)
    health_changed.emit(current, 0.0)


func _start_invulnerability() -> void:
    if invulnerability_time <= 0.0:
        return
    is_invulnerable = true
    await get_tree().create_timer(invulnerability_time).timeout
    is_invulnerable = false


func get_health_percentage() -> float:
    return clampf(current / max_health, 0.0, 1.0)


func get_health_percent() -> float:
    return get_health_percentage()
