class_name EnemyResource
extends Resource

## Recurso que define las propiedades de un tipo de enemigo

@export var id: String
@export var display_name: String
@export var description: String
@export var enemy_type: String = "basic"  # basic, ranged, tank, agile, magical, boss

@export_group("Stats")
@export var base_hp: int = 50
@export var base_attack: int = 5
@export var base_defense: int = 3
@export var base_magic: int = 0
@export var base_speed: float = 80.0
@export var xp_reward: int = 10
@export var level_range: Vector2i = Vector2i(1, 10)

@export_group("AI Behavior")
@export var patrol_radius: float = 100.0
@export var detection_radius: float = 150.0
@export var attack_radius: float = 40.0
@export var chase_radius: float = 250.0
@export var attack_cooldown: float = 1.5
@export var flee_hp_percent: float = 0.2
@export var aggro_group: bool = true

@export_group("Drops")
@export var loot_table_id: String = ""
@export var guaranteed_drops: Array[String] = []
@export var gold_min: int = 5
@export var gold_max: int = 15

@export_group("Visual")
@export var sprite_sheet: Texture2D
@export var animations: Dictionary = {}
@export var scale: Vector2 = Vector2(1, 1)

func get_stat_for_level(level: int, stat_name: String) -> float:
    var level_multiplier = 1.0 + (level * 0.1)
    match stat_name:
        "hp": return base_hp * level_multiplier
        "attack": return base_attack * level_multiplier
        "defense": return base_defense * level_multiplier
        "speed": return base_speed * (1.0 + level * 0.02)
        _: return 0.0