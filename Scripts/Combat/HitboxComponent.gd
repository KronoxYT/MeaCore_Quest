extends "res://Scripts/Core/BaseComponent.gd"

class_name HitboxComponent

@export var damage: float = 10.0
@export var damage_type = 0
@export var knockback_force: float = 200.0
@export var hitbox_shape: Node

var already_hit: Array[Node] = []
var _area_parent: Area2D

signal hit_connected(target: Node2D)


func activate() -> void:
    enable()


func deactivate() -> void:
    disable()


func _ready() -> void:
    var parent = get_parent()
    if parent is Area2D:
        parent.body_entered.connect(_on_body_entered)
        _area_parent = parent
    if not hitbox_shape:
        hitbox_shape = get_node_or_null("CollisionShape2D")
    if hitbox_shape:
        hitbox_shape.set("disabled", true)


func enable() -> void:
    already_hit.clear()
    if hitbox_shape:
        hitbox_shape.set("disabled", false)
    if _area_parent:
        _area_parent.monitoring = true


func disable() -> void:
    if hitbox_shape:
        hitbox_shape.set("disabled", true)
    if _area_parent:
        _area_parent.monitoring = false
    already_hit.clear()


func _on_body_entered(body: Node2D) -> void:
    if body == entity:
        return
    if body in already_hit:
        return
    already_hit.append(body)
    if body.has_method("take_damage"):
        body.take_damage(damage, damage_type)
    _apply_knockback(body)
    hit_connected.emit(body)


func _apply_knockback(target: Node2D) -> void:
    if not entity or not target:
        return
    var dir = (target.global_position - entity.global_position).normalized()
    if target is RigidBody2D:
        target.apply_central_impulse(dir * knockback_force)
