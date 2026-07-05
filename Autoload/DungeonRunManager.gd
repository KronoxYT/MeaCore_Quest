extends Node

signal run_started(depth: int)
signal run_ended(success: bool)
signal temp_item_added(item_id: String, qty: int)

var is_in_dungeon: bool = false
var current_depth: int = 1
var temp_inventory: Dictionary = {}
var temp_gold: int = 0

var _player_main_inventory_backup: Dictionary = {}

func _ready():
    var EM = get_node("/root/EventManager")
    if EM:
        EM.player_died.connect(_on_player_died)
        EM.item_picked_up.connect(_on_item_picked_up)
        EM.dungeon_entered.connect(_on_dungeon_entered)

func start_run(depth: int = 1) -> void:
    is_in_dungeon = true
    current_depth = depth
    temp_inventory.clear()
    temp_gold = 0
    var player = GameManager.player
    if player and player.inventory_comp:
        _player_main_inventory_backup = player.inventory_comp.slots.duplicate(true)
    run_started.emit(depth)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.notification_shown.emit("Incursión iniciada. Cuidado, el loot es temporal.", "danger")

func end_run(success: bool) -> void:
    is_in_dungeon = false
    if success:
        var player = GameManager.player
        if player and player.inventory_comp:
            for item_id in temp_inventory:
                player.inventory_comp.add_item(item_id, temp_inventory[item_id])
            player.gold += temp_gold
        var EM = get_node("/root/EventManager")
        if EM:
            EM.notification_shown.emit("¡Escapaste con el botín!", "success")
    else:
        var EM = get_node("/root/EventManager")
        if EM:
            EM.notification_shown.emit("Has muerto. Perdiste el botín de la mazmorra.", "danger")
    temp_inventory.clear()
    temp_gold = 0
    run_ended.emit(success)

func _on_dungeon_entered(dungeon_id: String, depth: int) -> void:
    start_run(depth)

func _on_player_died(player_id: String) -> void:
    if is_in_dungeon and player_id == _get_player_id():
        end_run(false)

func _on_item_picked_up(item_id: String, player_id: String) -> void:
    if not is_in_dungeon or player_id != _get_player_id():
        return
    if item_id.begins_with("dungeon_"):
        if item_id in temp_inventory:
            temp_inventory[item_id] += 1
        else:
            temp_inventory[item_id] = 1
        temp_item_added.emit(item_id, 1)
        var player = GameManager.player
        if player and player.inventory_comp:
            pass

func _get_player_id() -> String:
    var GM = get_node("/root/GameManager")
    if GM and GM.player and GM.player.has_method("_setup_player_id"):
        return GM.player.player_id
    return ""
