extends Node

const SERVER_PORT = 8910
const MAX_PLAYERS = 100

var server_world: Node = null
var connected_players: Dictionary = {}


func _ready():
    print("[SERVER] Iniciando Servidor Dedicado MeaCoreQuest...")
    var NM = get_node("/root/NetworkManager")
    if NM:
        NM.start_server(SERVER_PORT, MAX_PLAYERS)
    _load_world_state()
    var NM2 = get_node("/root/NetworkManager")
    if NM2:
        NM2.player_connected.connect(_on_player_connected)
        NM2.player_disconnected.connect(_on_player_disconnected)
    print("[SERVER] Servidor escuchando en el puerto %d" % SERVER_PORT)


func _load_world_state() -> void:
    var world_scene = preload("res://Scenes/World/WorldMap.tscn")
    server_world = world_scene.instantiate()
    add_child(server_world)
    print("[SERVER] Mundo cargado exitosamente.")


func _on_player_connected(peer_id: int, player_data: Dictionary) -> void:
    connected_players[peer_id] = player_data
    print("[SERVER] Jugador conectado: %s (ID: %d)" % [player_data.get("name", "Unknown"), peer_id])
    _spawn_player_in_world(peer_id, player_data)
    rpc("broadcast_player_joined", peer_id, player_data)


func _on_player_disconnected(peer_id: int) -> void:
    if connected_players.has(peer_id):
        var player_name = connected_players[peer_id].get("name", "Unknown")
        print("[SERVER] Jugador desconectado: %s" % player_name)
        connected_players.erase(peer_id)
        _despawn_player_in_world(peer_id)
        rpc("broadcast_player_left", peer_id)


func _spawn_player_in_world(peer_id: int, player_data: Dictionary) -> void:
    var player_scene = preload("res://Scenes/Player/PlayerBase.tscn")
    var player_instance = player_scene.instantiate()
    player_instance.name = str(peer_id)
    player_instance.set_multiplayer_authority(peer_id)
    var spawn_pos = Vector2(640, 360)
    var SM = get_node("/root/SpawnManager")
    if SM:
        spawn_pos = SM.get_spawn_point("player_spawn")
    player_instance.global_position = spawn_pos
    server_world.add_child(player_instance)


func _despawn_player_in_world(peer_id: int) -> void:
    var player_node = server_world.get_node_or_null(str(peer_id))
    if player_node:
        player_node.queue_free()


@rpc("authority", "call_local", "reliable")
func broadcast_player_joined(peer_id: int, player_data: Dictionary) -> void:
    pass


@rpc("authority", "call_local", "reliable")
func broadcast_player_left(peer_id: int) -> void:
    pass
