extends "res://Scripts/Core/BaseComponent.gd"

class_name InventoryComponent

signal inventory_updated()
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)

@export var max_slots: int = 30
@export var max_weight: float = 100.0

var items: Array = []
var current_weight: float = 0.0

func _on_ready():
    items.resize(max_slots)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.item_picked_up.connect(_on_global_item_picked_up)

func add_item(resource, quantity: int = 1) -> bool:
    if not resource:
        return false
    if resource.stackable:
        for i in items.size():
            if items[i] and items[i].resource == resource:
                var current_qty = items[i].quantity
                var can_add = min(quantity, resource.max_stack - current_qty)
                if can_add > 0:
                    items[i].quantity += can_add
                    quantity -= can_add
                    item_added.emit(resource.id, can_add)
                    if quantity <= 0:
                        _recalculate_weight()
                        inventory_updated.emit()
                        return true
    while quantity > 0:
        var empty_slot = _find_empty_slot()
        if empty_slot == -1:
            push_warning("Inventario lleno")
            return false
        var qty_to_add = quantity
        if resource.stackable:
            qty_to_add = min(quantity, resource.max_stack)
        items[empty_slot] = {"resource": resource, "quantity": qty_to_add}
        quantity -= qty_to_add
        item_added.emit(resource.id, qty_to_add)
    _recalculate_weight()
    inventory_updated.emit()
    return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
    var remaining_to_remove = quantity
    for i in items.size():
        if items[i] and items[i].resource.id == item_id:
            var current_qty = items[i].quantity
            var to_remove = min(remaining_to_remove, current_qty)
            items[i].quantity -= to_remove
            remaining_to_remove -= to_remove
            if items[i].quantity <= 0:
                items[i] = null
            item_removed.emit(item_id, to_remove)
            if remaining_to_remove <= 0:
                break
    if remaining_to_remove > 0:
        return false
    _recalculate_weight()
    inventory_updated.emit()
    return true

func remove_item_at_slot(slot_index: int, quantity: int = 1):
    if slot_index < 0 or slot_index >= items.size() or not items[slot_index]:
        return null
    var item_data = items[slot_index]
    item_data.quantity -= quantity
    var resource = item_data.resource
    if item_data.quantity <= 0:
        items[slot_index] = null
    _recalculate_weight()
    inventory_updated.emit()
    return resource

func get_item_at_slot(slot_index: int) -> Dictionary:
    if slot_index < 0 or slot_index >= items.size():
        return {}
    return items[slot_index] if items[slot_index] else {}

func has_item(item_id: String, quantity: int = 1) -> bool:
    var total = 0
    for slot in items:
        if slot and slot.resource.id == item_id:
            total += slot.quantity
    return total >= quantity

func _find_empty_slot() -> int:
    for i in items.size():
        if not items[i]:
            return i
    return -1

func _recalculate_weight() -> void:
    current_weight = 0.0
    for slot in items:
        if slot:
            current_weight += slot.resource.weight * slot.quantity

func _on_global_item_picked_up(item_id: String, player_id: String) -> void:
    pass
