extends "res://Scripts/Core/BaseComponent.gd"

class_name HurtboxComponent

@export var faction = 0

signal damage_received(amount: float, type_: int, source: Node2D)
signal invulnerability_started()
signal invulnerability_ended()


func _ready() -> void:
    var parent = get_parent()
    if parent is Area2D:
        parent.area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
    if not entity:
        return
    var dmg = area.get("damage")
    var dmg_type = area.get("damage_type")
    if dmg != null and dmg_type != null:
        entity.take_damage(dmg, dmg_type)
        damage_received.emit(dmg, dmg_type, area)
