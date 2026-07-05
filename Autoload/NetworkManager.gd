extends Node

signal player_connected(peer_id: int, player_data: Dictionary)
signal player_disconnected(peer_id: int)
signal connection_failed()
signal server_started()

var is_server: bool = false
var is_connected: bool = false
var peer: ENetMultiplayerPeer = null


func _ready():
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)


func start_server(port: int, max_clients: int) -> void:
    peer = ENetMultiplayerPeer.new()
    var error = peer.create_server(port, max_clients)
    if error == OK:
        multiplayer.multiplayer_peer = peer
        is_server = true
        is_connected = true
        server_started.emit()
    else:
        push_error("No se pudo iniciar el servidor en el puerto %d" % port)


func connect_to_server(address: String, port: int) -> void:
    peer = ENetMultiplayerPeer.new()
    var error = peer.create_client(address, port)
    if error == OK:
        multiplayer.multiplayer_peer = peer
    else:
        push_error("No se pudo conectar a %s:%d" % [address, port])


func disconnect_from_server() -> void:
    if multiplayer.multiplayer_peer:
        multiplayer.multiplayer_peer.close()
    is_connected = false


func _on_peer_connected(peer_id: int) -> void:
    if is_server:
        rpc_id(peer_id, "request_player_data")


func _on_peer_disconnected(peer_id: int) -> void:
    player_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
    is_connected = true
    var my_data = _get_local_player_data()
    rpc_id(1, "register_player", my_data)


func _on_connection_failed() -> void:
    is_connected = false
    connection_failed.emit()
    var EM = get_node("/root/EventManager")
    if EM:
        EM.notification_shown.emit("Error de conexión al servidor", "danger")


func _on_server_disconnected() -> void:
    is_connected = false
    var EM = get_node("/root/EventManager")
    if EM:
        EM.notification_shown.emit("Has sido desconectado del servidor", "danger")


@rpc("any_peer", "call_local", "reliable")
func request_player_data() -> void:
    if not is_server:
        var my_data = _get_local_player_data()
        rpc_id(1, "register_player", my_data)


@rpc("any_peer", "call_local", "reliable")
func register_player(player_data: Dictionary) -> void:
    var sender_id = multiplayer.get_remote_sender_id()
    if is_server and sender_id > 0:
        if _validate_player_data(player_data):
            player_connected.emit(sender_id, player_data)
        else:
            if peer:
                peer.disconnect_peer(sender_id)


func _get_local_player_data() -> Dictionary:
    var GM = get_node("/root/GameManager")
    return {
        "name": GM.player.player_id if GM and GM.player else "player_unknown",
        "class": "warrior",
        "level": GM.player.level if GM and GM.player else 1,
        "version": "1.0.0"
    }


func _validate_player_data(data: Dictionary) -> bool:
    if data.get("level", 0) > 1000:
        return false
    if data.get("name", "").length() < 3:
        return false
    return true
