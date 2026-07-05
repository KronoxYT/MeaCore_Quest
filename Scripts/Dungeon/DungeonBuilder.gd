class_name DungeonBuilder
extends Node2D

@export var floor_layer: TileMapLayer
@export var wall_layer: TileMapLayer
@export var object_layer: Node2D
@export var theme: DungeonThemeResource

var map_data: Dictionary = {}
var floor_tiles: Array[Vector2i] = []

func build_dungeon(data: Dictionary) -> void:
    map_data = data
    floor_tiles.clear()
    floor_layer.clear()
    wall_layer.clear()
    for child in object_layer.get_children():
        child.queue_free()
    for room in map_data.rooms:
        _paint_floor_rect(room)
    for corridor in map_data.corridors:
        _paint_floor_rect(corridor)
    _generate_walls()
    _place_stairs(map_data.boss_room)
    _populate_enemies_and_traps()
    _place_chests()
    if GameManager.player:
        GameManager.player.global_position = floor_layer.map_to_local(map_data.start_pos)

func _paint_floor_rect(rect: Rect2i) -> void:
    for x in range(rect.position.x, rect.end.x):
        for y in range(rect.position.y, rect.end.y):
            var cell = Vector2i(x, y)
            floor_layer.set_cell(cell, 0, theme.floor_tile_id)
            if not floor_tiles.has(cell):
                floor_tiles.append(cell)

func _generate_walls() -> void:
    var floor_set = {}
    for cell in floor_tiles:
        floor_set[cell] = true
    for cell in floor_tiles:
        for x in range(-1, 2):
            for y in range(-1, 2):
                var neighbor = cell + Vector2i(x, y)
                if not floor_set.has(neighbor):
                    wall_layer.set_cell(neighbor, 0, theme.wall_tile_id)

func _place_stairs(boss_room: Rect2i) -> void:
    var stairs_pos = Vector2i(boss_room.get_center().x, boss_room.get_center().y)
    floor_layer.set_cell(stairs_pos, 0, theme.stairs_down_id)
    var stairs_area = Area2D.new()
    var col = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(32, 32)
    col.shape = shape
    stairs_area.add_child(col)
    stairs_area.position = floor_layer.map_to_local(stairs_pos)
    stairs_area.add_to_group("dungeon_stairs")
    object_layer.add_child(stairs_area)

func _populate_enemies_and_traps() -> void:
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var safe_rooms = [map_data.rooms[0], map_data.boss_room]
    for cell in floor_tiles:
        var is_safe = false
        for safe_room in safe_rooms:
            if safe_room.has_point(Vector2(cell.x, cell.y)):
                is_safe = true
                break
        if is_safe:
            continue
        var roll = rng.randf()
        if roll < theme.enemy_density and theme.enemy_scenes.size() > 0:
            _spawn_entity(theme.enemy_scenes[rng.randi_range(0, theme.enemy_scenes.size() - 1)], cell)
        elif roll < theme.enemy_density + theme.trap_density and theme.trap_scenes.size() > 0:
            _spawn_entity(theme.trap_scenes[rng.randi_range(0, theme.trap_scenes.size() - 1)], cell)

func _place_chests() -> void:
    if theme.chest_scenes.is_empty():
        return
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    for room in map_data.treasure_rooms:
        var center = Vector2i(room.get_center().x, room.get_center().y)
        _spawn_entity(theme.chest_scenes[0], center)

func _spawn_entity(scene: PackedScene, cell: Vector2i) -> void:
    if not scene:
        return
    var instance = scene.instantiate()
    instance.global_position = floor_layer.map_to_local(cell)
    object_layer.add_child(instance)
