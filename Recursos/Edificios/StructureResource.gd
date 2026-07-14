class_name StructureResource
extends Resource

enum StructureCategory { FLOOR, WALL, DOOR, ROOF, STATION, FURNITURE, DEFENSE, DECORATION }

@export var id: String
@export var display_name: String
@export var category: StructureCategory
@export var icon: Texture2D
@export var scene: PackedScene

@export_group("Placement Rules")
@export var size: Vector2i = Vector2i(1, 1)
@export var requires_floor: bool = false
@export var requires_support: bool = false
@export var can_rotate: bool = true
@export var allowed_biomes: Array[String] = []

@export_group("Cost")
@export var materials_required: Array[Dictionary] = []
@export var gold_cost: int = 0
@export var build_time: float = 2.0

@export_group("Stats")
@export var max_health: int = 0
@export var provides_station: String = ""
@export var storage_slots: int = 0
