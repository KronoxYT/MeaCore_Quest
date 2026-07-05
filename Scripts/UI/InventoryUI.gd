extends Control

class_name InventoryUI

@export var slot_scene: PackedScene
@onready var grid_container: GridContainer = $Panel/MarginContainer/VBoxContainer/GridContainer
@onready var close_btn: Button = $Panel/Header/CloseButton

var player_inv = null


func _ready():
    close_btn.pressed.connect(_on_close_pressed)
    var player = get_node("/root/GameManager").player if get_node("/root/GameManager") else null
    if player:
        player_inv = player.inventory
        if player_inv:
            player_inv.inventory_updated.connect(_refresh_ui)
    _setup_slots()
    _refresh_ui()


func _setup_slots() -> void:
    if not slot_scene or not player_inv:
        return
    for child in grid_container.get_children():
        child.queue_free()
    for i in player_inv.max_slots:
        var slot = slot_scene.instantiate()
        grid_container.add_child(slot)
        slot.slot_index = i
        slot.gui_input.connect(_on_slot_gui_input.bind(i))


func _refresh_ui() -> void:
    if not player_inv:
        return
    for i in grid_container.get_child_count():
        var slot_ui = grid_container.get_child(i)
        var item_data = player_inv.get_item_at_slot(i)
        if item_data.has("resource"):
            slot_ui.setup(item_data.resource, item_data.quantity)
        else:
            slot_ui.clear()


func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var item_data = player_inv.get_item_at_slot(slot_index)
        if item_data.has("resource"):
            var res = item_data.resource
            if res.is_consumable():
                _use_consumable(res, slot_index)
            elif res.is_equippable():
                _equip_item(res, slot_index)


func _equip_item(res, slot_index: int) -> void:
    var player = get_node("/root/GameManager").player if get_node("/root/GameManager") else null
    if player and player.equipment:
        player.equipment.equip_item(res, slot_index)


func _use_consumable(res, slot_index: int) -> void:
    var player = get_node("/root/GameManager").player if get_node("/root/GameManager") else null
    if not player:
        return
    if res.heal_amount > 0 and player.health:
        player.health.heal(res.heal_amount)
    if res.mana_amount > 0 and player.stats:
        player.stats._set_stat_value("mp", player.stats.get_stat("mp") + res.mana_amount)
    player_inv.remove_item_at_slot(slot_index, 1)


func _on_close_pressed() -> void:
    var UM = get_node("/root/UIManager")
    if UM:
        UM.close_ui()
