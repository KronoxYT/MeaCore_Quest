class_name DungeonThemeResource
extends Resource

## Define los assets, tiles y pools de enemigos para un bioma de mazmorra específico

@export var theme_name: String = "Catacombas"
@export var background_music: AudioStream

@export_group("TileMap Configuration (IDs del TileSet)")
@export var floor_tile_id: Vector2i = Vector2i(0, 0)
@export var wall_tile_id: Vector2i = Vector2i(1, 0)
@export var door_tile_id: Vector2i = Vector2i(2, 0)
@export var stairs_down_id: Vector2i = Vector2i(3, 0)
@export var trap_tile_id: Vector2i = Vector2i(4, 0)

@export_group("Spawn Pools")
@export var enemy_scenes: Array[PackedScene] = []
@export var chest_scenes: Array[PackedScene] = []
@export var trap_scenes: Array[PackedScene] = []
@export var boss_scene: PackedScene = null

@export_group("Difficulty Scaling")
@export var base_enemy_level: int = 1
@export var level_per_depth: float = 1.5
@export var enemy_density: float = 0.15
@export var trap_density: float = 0.02