class_name DungeonGenerator
extends Node

signal generation_completed(map_data: Dictionary)

@export var map_width: int = 80
@export var map_height: int = 80
@export var max_depth: int = 5

func generate_dungeon() -> Dictionary:
    var root = BSPNode.new(Rect2i(0, 0, map_width, map_height))
    var queue: Array[BSPNode] = [root]
    for i in max_depth:
        var next_queue: Array[BSPNode] = []
        for node in queue:
            if node.split():
                next_queue.append(node.left_child)
                next_queue.append(node.right_child)
        queue = next_queue
        if queue.is_empty():
            break
    root.create_rooms()
    var rooms = root.get_all_rooms()
    var corridors = root.get_all_corridors()
    var start_room = rooms[0]
    var boss_room = rooms[-1]
    var treasure_rooms = rooms.slice(1, rooms.size() - 1).filter(func(r): return randf() < 0.3)
    var map_data = {
        "width": map_width,
        "height": map_height,
        "rooms": rooms,
        "corridors": corridors,
        "start_pos": Vector2i(start_room.get_center().x, start_room.get_center().y),
        "boss_pos": Vector2i(boss_room.get_center().x, boss_room.get_center().y),
        "boss_room": boss_room,
        "treasure_rooms": treasure_rooms
    }
    generation_completed.emit(map_data)
    return map_data
