extends Node

class_name BaseComponent

var entity = null


func _ready() -> void:
    await get_tree().process_frame
    var p = get_parent()
    if p and p.has_method("get_component"):
        entity = p
        _on_entity_ready()


func _on_entity_ready() -> void:
    pass


func get_component(type_: Variant):
    if not entity:
        return null
    return entity.get_component(type_)
