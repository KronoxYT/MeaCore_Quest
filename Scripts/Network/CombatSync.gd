class_name CombatSync
extends Node


@rpc("any_peer", "reliable")
func request_attack(target_node_path: String, combo_index: int) -> void:
    var NM = get_node("/root/NetworkManager")
    if not NM or not NM.is_server:
        return
    var sender_id = multiplayer.get_remote_sender_id()
    var attacker = get_tree().current_scene.get_node_or_null(str(sender_id))
    var target = get_tree().current_scene.get_node_or_null(target_node_path)
    if not attacker or not target:
        return
    var distance = attacker.global_position.distance_to(target.global_position)
    if distance > 60.0:
        rpc_id(sender_id, "notify_attack_failed", "Fuera de rango")
        return
    if attacker.stats and attacker.stats.get_stat("stamina") < 10.0:
        rpc_id(sender_id, "notify_attack_failed", "Sin stamina")
        return
    var damage = _calculate_damage(attacker, target, combo_index)
    if target.has_method("take_damage"):
        target.take_damage(damage, attacker)
    rpc("broadcast_attack_success", attacker.name, target.name, damage, combo_index)


func _calculate_damage(attacker, target, combo_index: int) -> int:
    var atk = attacker.stats.get_stat("attack") if attacker.stats else 10
    var def = target.stats.get_stat("defense") if target.stats else 5
    var base = max(1, atk - def * 0.5)
    var combo_bonus = 1.0 + (combo_index * 0.1)
    return int(base * combo_bonus)


@rpc("authority", "call_local", "reliable")
func broadcast_attack_success(attacker_name: String, target_name: String, damage: int, combo: int) -> void:
    var attacker_node = get_tree().current_scene.get_node_or_null(attacker_name)
    if attacker_node and attacker_node.has_method("play_animation"):
        attacker_node.play_animation("attack_%d" % (combo + 1))
    _spawn_local_vfx(target_name, damage)


func _spawn_local_vfx(target_name: String, damage: int) -> void:
    var target = get_tree().current_scene.get_node_or_null(target_name)
    if not target:
        return
    var damage_scene = preload("res://Scenes/Effects/DamageNumber.tscn")
    if damage_scene:
        var instance = damage_scene.instantiate()
        if instance.has_method("setup"):
            instance.setup(damage, false)
        instance.global_position = target.global_position + Vector2(0, -40)
        get_tree().current_scene.add_child(instance)


@rpc("authority", "call_local", "reliable")
func notify_attack_failed(reason: String) -> void:
    var EM = get_node("/root/EventManager")
    if EM:
        EM.notification_shown.emit("Ataque fallido: %s" % reason, "danger")
