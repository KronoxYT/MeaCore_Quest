extends Node

signal active_quests_updated()
signal completed_quests_updated()
signal quest_notification(message: String, type: String)

const MAX_ACTIVE_QUESTS = 20
const MAX_TRACKED_COMPLETED = 500

var active_quests: Array = []
var completed_quests: Array = []
var abandoned_quests: Array = []


func _ready():
    process_mode = PROCESS_MODE_ALWAYS
    _connect_to_events()


func _connect_to_events() -> void:
    var EM = get_node("/root/EventManager")
    if EM:
        EM.enemy_killed.connect(_on_enemy_killed)
        EM.item_picked_up.connect(_on_item_picked_up)
        EM.npc_interacted.connect(_on_npc_interacted)


func can_accept_quest(quest) -> bool:
    if not quest:
        return false
    if active_quests.size() >= MAX_ACTIVE_QUESTS:
        var EM = get_node("/root/EventManager")
        if EM:
            EM.notification_shown.emit("Demasiadas misiones activas", "danger")
        return false
    for active_quest in active_quests:
        if active_quest.id == quest.id:
            return false
    if quest.id in completed_quests:
        return false
    var GM = get_node("/root/GameManager")
    if GM and GM.player and GM.player.level < quest.level_requirement:
        var EM = get_node("/root/EventManager")
        if EM:
            EM.notification_shown.emit("Nivel insuficiente", "danger")
        return false
    for pre_req_id in quest.prerequisite_quests:
        if pre_req_id not in completed_quests:
            return false
    return true


func accept_quest(quest) -> bool:
    if not can_accept_quest(quest):
        return false
    active_quests.append(quest)
    active_quests_updated.emit()
    var EM = get_node("/root/EventManager")
    if EM:
        EM.quest_accepted.emit(quest.id, _get_player_id())
        quest_notification.emit("Misión aceptada: %s" % quest.display_name, "success")
        if quest.start_dialogue:
            var UM = get_node("/root/UIManager")
            if UM:
                UM.open_dialogue(quest.start_dialogue)
    return true


func abandon_quest(quest_id: String) -> void:
    for i in active_quests.size():
        if active_quests[i].id == quest_id:
            active_quests.remove_at(i)
            abandoned_quests.append(quest_id)
            active_quests_updated.emit()
            var EM = get_node("/root/EventManager")
            if EM:
                EM.quest_abandoned.emit(quest_id)
                quest_notification.emit("Misión abandonada", "info")
            return


func try_complete_quest(quest, player) -> bool:
    if not quest or not quest.is_complete():
        return false
    if player:
        player.gain_xp(quest.xp_reward)
        player.gold += quest.gold_reward
        if player.inventory_comp:
            for item_reward in quest.item_rewards:
                pass
    active_quests.erase(quest)
    completed_quests.append(quest.id)
    completed_quests = completed_quests.slice(0, MAX_TRACKED_COMPLETED)
    completed_quests_updated.emit()
    var EM = get_node("/root/EventManager")
    if EM:
        EM.quest_completed.emit(quest.id, _get_player_id())
        quest_notification.emit("¡Misión completada: %s!" % quest.display_name, "success")
    return true


func get_active_quests() -> Array:
    return active_quests


func is_quest_completed(quest_id: String) -> bool:
    return quest_id in completed_quests


func is_quest_active(quest_id: String) -> bool:
    for quest in active_quests:
        if quest.id == quest_id:
            return true
    return false


func _update_objective_progress(objective_type: String, target_id: String, amount: int = 1) -> void:
    var progress_made: bool = false
    for quest in active_quests:
        for objective in quest.objectives:
            if objective.get("type") == objective_type and objective.get("target_id") == target_id:
                var current = objective.get("current", 0)
                var required = objective.get("required_amount", 1)
                if current < required:
                    objective.current = current + amount
                    var EM = get_node("/root/EventManager")
                    if EM:
                        if objective.current >= required:
                            EM.quest_objective_completed.emit(quest.id, objective.id)
                        EM.quest_objective_progress.emit(quest.id, objective.id, objective.current, required)
                    progress_made = true
    if progress_made:
        active_quests_updated.emit()


func _on_enemy_killed(enemy_id: String, killer_id: String) -> void:
    if killer_id != _get_player_id():
        return
    _update_objective_progress("kill", enemy_id)


func _on_item_picked_up(item_id: String, player_id: String) -> void:
    if player_id != _get_player_id():
        return
    _update_objective_progress("collect", item_id)


func _on_npc_interacted(npc_id: String) -> void:
    _update_objective_progress("talk", npc_id)


func _get_player_id() -> String:
    var GM = get_node("/root/GameManager")
    if GM and GM.player and GM.player.has_method("_setup_player_id"):
        return GM.player.player_id
    return ""
