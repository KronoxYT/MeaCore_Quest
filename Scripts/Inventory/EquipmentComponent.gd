extends "res://Scripts/Core/BaseComponent.gd"

class_name EquipmentComponent

signal equipment_changed(slot_name: String)

var equipped_items: Dictionary = {}
var stats_comp = null
var inv_comp = null

const SLOT_NAMES = [
    "MAIN_HAND", "OFF_HAND", "HEAD", "CHEST", "HANDS",
    "LEGS", "RING_1", "RING_2", "AMULET", "CAPE", "PET"
]

func _on_ready():
    stats_comp = entity.get_node_or_null("StatsComponent")
    inv_comp = entity.get_node_or_null("InventoryComponent")
    var ItemResScript = load("res://Resources/Items/ItemResource.gd")
    for slot in ItemResScript.EquipSlot.values():
        if slot != ItemResScript.EquipSlot.NONE:
            equipped_items[ItemResScript.EquipSlot.keys()[slot]] = null

func equip_item(item_resource, from_inv_slot: int) -> bool:
    if not item_resource or not item_resource.is_equippable():
        return false
    if entity.level < item_resource.level_requirement:
        var EM = get_node("/root/EventManager")
        if EM:
            EM.notification_shown.emit("Nivel insuficiente", "danger")
        return false
    var ItemResScript = load("res://Resources/Items/ItemResource.gd")
    var slot_name = ItemResScript.EquipSlot.keys()[item_resource.equip_slot]
    if equipped_items[slot_name]:
        unequip_item(slot_name)
    if inv_comp:
        inv_comp.remove_item_at_slot(from_inv_slot, 1)
    equipped_items[slot_name] = item_resource
    _apply_stats(item_resource, true)
    equipment_changed.emit(slot_name)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.item_equipped.emit(item_resource.id, slot_name, entity.player_id)
    return true

func unequip_item(slot_name: String) -> bool:
    var item_resource = equipped_items.get(slot_name)
    if not item_resource:
        return false
    if inv_comp:
        var success = inv_comp.add_item(item_resource, 1)
        if not success:
            var EM = get_node("/root/EventManager")
            if EM:
                EM.notification_shown.emit("Inventario lleno", "danger")
            return false
    equipped_items[slot_name] = null
    _apply_stats(item_resource, false)
    equipment_changed.emit(slot_name)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.item_unequipped.emit(item_resource.id, slot_name, entity.player_id)
    return true

func _apply_stats(item, is_equipping: bool) -> void:
    if not stats_comp or not item.stats_bonus:
        return
    for stat_name in item.stats_bonus:
        var value = item.stats_bonus[stat_name]
        if is_equipping:
            stats_comp._set_stat_value(stat_name, stats_comp.get_stat(stat_name) + value)
        else:
            stats_comp._set_stat_value(stat_name, stats_comp.get_stat(stat_name) - value)
    if "hp" in item.stats_bonus and entity.health:
        var hp_change = item.stats_bonus["hp"]
        if not is_equipping:
            hp_change = -hp_change
        entity.health.max_health += hp_change
        entity.health.current = min(entity.health.current, entity.health.max_health)

func get_equipped_item(slot_name: String):
    return equipped_items.get(slot_name)
