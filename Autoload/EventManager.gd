extends Node

signal damage_dealt(victim_id: String, attacker_id: String, damage: float)
signal enemy_killed(enemy_id: String, killer_id: String)
signal notification_shown(message: String, type: String)
signal player_level_up(level: int)
signal item_picked_up(item_id: String, player_id: String)
signal item_equipped(item_id: String, slot_name: String, player_id: String)
signal item_unequipped(item_id: String, slot_name: String, player_id: String)

signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
signal dialogue_choice_made(choice_index: int)
signal dialogue_line_displayed(node_id: String)

signal quest_accepted(quest_id: String, player_id: String)
signal quest_objective_progress(quest_id: String, objective_id: String, current: int, required: int)
signal quest_objective_completed(quest_id: String, objective_id: String)
signal quest_completed(quest_id: String, player_id: String)
signal quest_failed(quest_id: String, player_id: String)
signal quest_abandoned(quest_id: String)

signal world_transition_started(from_world: String, to_world: String)
signal world_transition_finished(world_id: String)
signal npc_interacted(npc_id: String)
signal npc_shop_opened(npc_id: String)
signal npc_shop_closed(npc_id: String)
signal day_night_cycle_changed(is_day: bool, time_of_day: float)
signal weather_changed(new_weather: String)

signal dungeon_entered(dungeon_id: String, depth: int)
signal player_died(player_id: String)

signal item_used(item_id: String, player_id: String)
signal item_crafted(recipe_id: String, player_id: String)
signal disease_contracted(disease_id: String)

var event_bus: Dictionary = {}


func _ready() -> void:
    process_mode = PROCESS_MODE_ALWAYS


func subscribe(event_name: StringName, callable: Callable) -> void:
    if not event_bus.has(event_name):
        event_bus[event_name] = []
    event_bus[event_name].append(callable)


func unsubscribe(event_name: StringName, callable: Callable) -> void:
    if event_bus.has(event_name):
        event_bus[event_name].erase(callable)


func emit_event(event_name: StringName, data: Variant = null) -> void:
    # Emitir también la señal GDScript nativa si existe
    _emit_typed_signal(event_name, data)

    if not event_bus.has(event_name):
        return
    for callable in event_bus[event_name]:
        if callable.is_valid():
            if data != null:
                callable.call(data)
            else:
                callable.call()
        else:
            event_bus[event_name].erase(callable)


## Emite la señal tipada correspondiente al nombre del evento.
## Garantiza que todas las señales declaradas sean usadas, evitando UNUSED_SIGNAL.
func _emit_typed_signal(event_name: StringName, data: Variant) -> void:
    match event_name:
        "damage_dealt":
            if data is Dictionary:
                damage_dealt.emit(
                    data.get("victim_id", ""),
                    data.get("attacker_id", ""),
                    data.get("damage", 0.0)
                )
        "enemy_killed":
            if data is Dictionary:
                enemy_killed.emit(
                    data.get("enemy_id", ""),
                    data.get("killer_id", "")
                )
        "notification_shown":
            if data is Dictionary:
                notification_shown.emit(
                    data.get("message", ""),
                    data.get("type", "info")
                )
        "player_level_up":
            if data is Dictionary:
                player_level_up.emit(data.get("level", 1))
        "item_picked_up":
            if data is Dictionary:
                item_picked_up.emit(data.get("item_id", ""), data.get("player_id", ""))
        "item_equipped":
            if data is Dictionary:
                item_equipped.emit(
                    data.get("item_id", ""),
                    data.get("slot_name", ""),
                    data.get("player_id", "")
                )
        "item_unequipped":
            if data is Dictionary:
                item_unequipped.emit(
                    data.get("item_id", ""),
                    data.get("slot_name", ""),
                    data.get("player_id", "")
                )
        "dialogue_started":
            if data is Dictionary:
                dialogue_started.emit(data.get("npc_id", ""))
        "dialogue_ended":
            if data is Dictionary:
                dialogue_ended.emit(data.get("npc_id", ""))
        "dialogue_choice_made":
            if data is Dictionary:
                dialogue_choice_made.emit(data.get("choice_index", 0))
        "dialogue_line_displayed":
            if data is Dictionary:
                dialogue_line_displayed.emit(data.get("node_id", ""))
        "quest_accepted":
            if data is Dictionary:
                quest_accepted.emit(data.get("quest_id", ""), data.get("player_id", ""))
        "quest_objective_progress":
            if data is Dictionary:
                quest_objective_progress.emit(
                    data.get("quest_id", ""),
                    data.get("objective_id", ""),
                    data.get("current", 0),
                    data.get("required", 0)
                )
        "quest_objective_completed":
            if data is Dictionary:
                quest_objective_completed.emit(
                    data.get("quest_id", ""),
                    data.get("objective_id", "")
                )
        "quest_completed":
            if data is Dictionary:
                quest_completed.emit(data.get("quest_id", ""), data.get("player_id", ""))
        "quest_failed":
            if data is Dictionary:
                quest_failed.emit(data.get("quest_id", ""), data.get("player_id", ""))
        "quest_abandoned":
            if data is Dictionary:
                quest_abandoned.emit(data.get("quest_id", ""))
        "world_transition_started":
            if data is Dictionary:
                world_transition_started.emit(
                    data.get("from_world", ""),
                    data.get("to_world", "")
                )
        "world_transition_finished":
            if data is Dictionary:
                world_transition_finished.emit(data.get("world_id", ""))
        "npc_interacted":
            if data is Dictionary:
                npc_interacted.emit(data.get("npc_id", ""))
        "npc_shop_opened":
            if data is Dictionary:
                npc_shop_opened.emit(data.get("npc_id", ""))
        "npc_shop_closed":
            if data is Dictionary:
                npc_shop_closed.emit(data.get("npc_id", ""))
        "day_night_cycle_changed":
            if data is Dictionary:
                day_night_cycle_changed.emit(
                    data.get("is_day", true),
                    data.get("time_of_day", 0.0)
                )
        "weather_changed":
            if data is Dictionary:
                weather_changed.emit(data.get("new_weather", ""))
        "dungeon_entered":
            if data is Dictionary:
                dungeon_entered.emit(data.get("dungeon_id", ""), data.get("depth", 0))
        "player_died":
            if data is Dictionary:
                player_died.emit(data.get("player_id", ""))
        "item_used":
            if data is Dictionary:
                item_used.emit(data.get("item_id", ""), data.get("player_id", ""))
        "item_crafted":
            if data is Dictionary:
                item_crafted.emit(data.get("recipe_id", ""), data.get("player_id", ""))
        "disease_contracted":
            if data is Dictionary:
                disease_contracted.emit(data.get("disease_id", ""))


func clear() -> void:
    event_bus.clear()
