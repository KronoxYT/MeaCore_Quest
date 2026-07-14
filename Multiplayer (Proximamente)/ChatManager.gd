extends Node

signal message_received(sender_name: String, text: String, channel: String, color: Color)

enum Channel { GLOBAL, LOCAL, WHISPER, CLAN, SYSTEM }


@rpc("any_peer", "call_local", "reliable")
func send_chat_request(text: String, channel: int, target_peer_id: int = 0) -> void:
    var NM = get_node("/root/NetworkManager")
    if not NM or not NM.is_server:
        return
    var sender_id = multiplayer.get_remote_sender_id()
    var sender_name = "Desconocido"
    if NM.connected_players.has(sender_id):
        sender_name = NM.connected_players[sender_id].get("name", "Desconocido")
    if _contains_banned_words(text):
        rpc_id(sender_id, "receive_system_message", "Mensaje bloqueado por filtro.")
        return
    match channel:
        Channel.GLOBAL:
            rpc("broadcast_chat", sender_name, text, Channel.GLOBAL, Color.WHITE)
        Channel.LOCAL:
            _broadcast_to_nearby_players(sender_id, sender_name, text, 500.0)
        Channel.WHISPER:
            rpc_id(target_peer_id, "receive_whisper", sender_name, text)
            rpc_id(sender_id, "receive_whisper_sent", sender_name, target_peer_id, text)


@rpc("authority", "call_local", "reliable")
func broadcast_chat(sender_name: String, text: String, channel: int, color: Color) -> void:
    message_received.emit(sender_name, text, _get_channel_name(channel), color)


@rpc("authority", "call_local", "reliable")
func receive_whisper(sender_name: String, text: String) -> void:
    message_received.emit(sender_name, text, "Susurro", Color.MAGENTA)


@rpc("authority", "call_local", "reliable")
func receive_system_message(text: String) -> void:
    message_received.emit("Sistema", text, "Sistema", Color.YELLOW)


@rpc("authority", "call_local", "reliable")
func receive_whisper_sent(sender_name: String, target_id: int, text: String) -> void:
    message_received.emit(sender_name, "-> %d: %s" % [target_id, text], "Susurro", Color.MAGENTA)


func _broadcast_to_nearby_players(sender_id: int, sender_name: String, text: String, radius: float) -> void:
    var NM = get_node("/root/NetworkManager")
    if not NM:
        return
    for peer_id in NM.connected_players:
        rpc_id(peer_id, "broadcast_chat", sender_name, text, Channel.LOCAL, Color.CYAN)


func _contains_banned_words(text: String) -> bool:
    var banned = ["hack", "cheat", "exploit"]
    var lower_text = text.to_lower()
    for word in banned:
        if lower_text.contains(word):
            return true
    return false


func _get_channel_name(channel: int) -> String:
    match channel:
        Channel.GLOBAL:
            return "Global"
        Channel.LOCAL:
            return "Local"
        Channel.CLAN:
            return "Clan"
        _:
            return "Sistema"
