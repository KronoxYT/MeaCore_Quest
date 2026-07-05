class_name WorldTransitionArea
extends Area2D

signal transition_ready(target_scene_path: String)
signal transition_completed(target_scene_path: String)

@export var target_scene_path: String = ""
@export var spawn_point_id: String = "spawn_default"
@export var transition_type: String = "door"
@export var require_level: int = 1
@export var required_item_id: String = ""

var player_inside: bool = false


func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("players"):
        return
    player_inside = true
    if transition_type == "portal":
        _trigger_transition()


func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("players"):
        player_inside = false


func _unhandled_input(event: InputEvent) -> void:
    if not player_inside:
        return
    if event.is_action_pressed("interact"):
        _trigger_transition()


func _trigger_transition() -> void:
    if target_scene_path == "":
        push_warning("WorldTransitionArea: No hay escena de destino")
        return
    var GM = get_node("/root/GameManager")
    var EM = get_node("/root/EventManager")
    if GM and GM.player and GM.player.level < require_level:
        if EM:
            EM.notification_shown.emit("Requiere nivel %d" % require_level, "danger")
        return
    if required_item_id != "":
        var player = GM.player if GM else null
        if player and not player.has_item(required_item_id):
            if EM:
                EM.notification_shown.emit("Se necesita: %s" % required_item_id, "danger")
            return
    if EM:
        EM.world_transition_started.emit(_get_current_scene_name(), target_scene_path)
    await get_tree().create_timer(0.2).timeout
    if target_scene_path.contains("Dungeon.tscn"):
        _load_dungeon()
    else:
        _load_normal_scene()


func _load_dungeon() -> void:
    var dungeon_scene = load(target_scene_path)
    var dungeon_instance = dungeon_scene.instantiate()
    var current = get_tree().current_scene
    current.queue_free()
    get_tree().root.add_child(dungeon_instance)
    get_tree().current_scene = dungeon_instance
    var generator = dungeon_instance.get_node("DungeonGenerator")
    var builder = dungeon_instance.get_node("DungeonBuilder")
    builder.theme = load("res://Resources/Dungeons/catacombs_theme.tres")
    var map_data = generator.generate_dungeon()
    builder.build_dungeon(map_data)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.dungeon_entered.emit("dungeon_01", 1)
    transition_completed.emit(target_scene_path)


func _load_normal_scene() -> void:
    var load_result = get_tree().change_scene_to_file(target_scene_path)
    if load_result == OK:
        transition_completed.emit(target_scene_path)
        var EM = get_node("/root/EventManager")
        if EM:
            EM.world_transition_finished.emit(target_scene_path)


func _get_current_scene_name() -> String:
    var scene_path = get_tree().current_scene.scene_file_path
    return scene_path.get_file().replace(".tscn", "")
