class_name ConsumableResource
extends ItemResource

@export_group("Survival Effects")
@export var hunger_restored: float = 0.0
@export var thirst_restored: float = 0.0
@export var temperature_change: float = 0.0

@export_group("Buffs Temporales")
@export var buff_id: String = ""
@export var buff_duration: float = 0.0
@export var buff_magnitude: float = 1.0
@export var buff_stat: String = ""

@export_group("Risks")
@export var disease_chance: float = 0.0
@export var disease_id: String = ""
