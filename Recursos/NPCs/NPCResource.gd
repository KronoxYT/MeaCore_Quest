class_name NPCResource
extends Resource

@export var id: String
@export var display_name: String
@export var title: String = ""
@export var description: String = ""
@export var faction: String = ""

@export_group("Visual")
@export var sprite_sheet: Texture2D
@export var portrait: Texture2D
@export var npc_icon: Texture2D
@export var animation_set: Dictionary = {}

@export_group("Dialogue")
@export var starting_dialogue: DialogueResource = null
@export var shop_inventory_id: String = ""

@export_group("Routines")
@export var has_routine: bool = true
@export var work_position: Vector2 = Vector2.ZERO
@export var rest_position: Vector2 = Vector2.ZERO
@export var home_position: Vector2 = Vector2.ZERO
@export var work_hours: Vector2i = Vector2i(8, 18)
@export var rest_hours: Vector2i = Vector2i(18, 22)
