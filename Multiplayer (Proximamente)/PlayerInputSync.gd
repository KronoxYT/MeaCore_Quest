class_name PlayerInputSync
extends Node

var input_direction: Vector2 = Vector2.ZERO
var is_sprinting: bool = false


func _physics_process(_delta: float) -> void:
    if not is_multiplayer_authority():
        return
    var new_dir = Vector2(
        Input.get_axis("move_left", "move_right"),
        Input.get_axis("move_up", "move_down")
    )
    var new_sprint = Input.is_action_pressed("sprint")
    if new_dir != input_direction or new_sprint != is_sprinting:
        input_direction = new_dir
        is_sprinting = new_sprint
        # Solo enviar RPC si hay sesión multijugador activa y no somos el servidor
        var mp = multiplayer
        if mp and mp.has_multiplayer_peer() and mp.get_unique_id() != 1:
            send_input_to_server.rpc_id(1, input_direction, is_sprinting)


@rpc("any_peer", "unreliable")
func send_input_to_server(dir: Vector2, sprinting: bool) -> void:
    var NM = get_node("/root/NetworkManager")
    if NM and NM.is_server:
        var sender_id = multiplayer.get_remote_sender_id()
        var player_node = get_tree().current_scene.get_node_or_null(str(sender_id))
        if player_node and player_node.has_method("apply_server_movement"):
            player_node.apply_server_movement(dir, sprinting)
