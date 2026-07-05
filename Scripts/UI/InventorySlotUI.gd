extends PanelContainer

class_name InventorySlotUI

var slot_index: int = -1
var item_resource = null

@onready var icon: TextureRect = $MarginContainer/Icon
@onready var qty_label: Label = $MarginContainer/QtyLabel
@onready var border: StyleBoxFlat = get_theme_stylebox("panel").duplicate()


func _ready():
    add_theme_stylebox_override("panel", border)
    clear()


func setup(res, quantity: int) -> void:
    item_resource = res
    if icon:
        icon.texture = res.icon if res.icon else null
        icon.visible = true
    if quantity > 1 and qty_label:
        qty_label.text = str(quantity)
        qty_label.visible = true
    elif qty_label:
        qty_label.visible = false
    if border:
        border.border_color = res.get_rarity_color()
        border.border_width_bottom = 2
        border.border_width_top = 2
        border.border_width_left = 2
        border.border_width_right = 2


func clear() -> void:
    item_resource = null
    if icon:
        icon.texture = null
        icon.visible = false
    if qty_label:
        qty_label.visible = false
    if border:
        border.border_color = Color(0.2, 0.2, 0.2, 0.5)
