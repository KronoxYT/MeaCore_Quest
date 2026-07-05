extends Node

var spawn_points: Dictionary = {}


func _ready():
    _find_all_spawn_points()


func _find_all_spawn_points() -> void:
    var all_nodes = get_tree().get_nodes_in_group("spawn_points")
    for node in all_nodes:
        if node.name != "":
            spawn_points[node.name.to_lower()] = node.global_position


func get_spawn_point(id: String) -> Vector2:
    var point_id = id.to_lower()
    if point_id in spawn_points:
        return spawn_points[point_id]
    if spawn_points.size() > 0:
        return spawn_points.values()[0]
    return Vector2(640, 360)


func register_spawn_point(id: String, position: Vector2) -> void:
    spawn_points[id.to_lower()] = position


func position_player_at_spawn_point(player: Node2D, spawn_id: String) -> void:
    if player and player.is_inside_tree():
        var pos = get_spawn_point(spawn_id)
        player.global_position = pos
