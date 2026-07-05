extends Node

signal hunger_changed(value: float)
signal thirst_changed(value: float)
signal temperature_changed(value: float)
signal status_effect_applied(effect: String, severity: float)

const MAX_SURVIVAL: float = 100.0
const MIN_CRITICAL: float = 20.0

var hunger: float = MAX_SURVIVAL
var thirst: float = MAX_SURVIVAL
var body_temperature: float = 37.0
var environmental_temperature: float = 20.0

var hunger_decay_rate: float = 0.08
var thirst_decay_rate: float = 0.12


func _ready():
    process_mode = PROCESS_MODE_ALWAYS
    _connect_signals()


func _connect_signals() -> void:
    var EM = get_node("/root/EventManager")
    if EM:
        EM.item_used.connect(_on_item_consumed)
        EM.weather_changed.connect(_on_weather_changed)
        EM.day_night_cycle_changed.connect(_on_day_night_changed)


func _process(delta: float) -> void:
    var GM = get_node("/root/GameManager")
    if not GM or GM.current_state != GameManager.GameState.PLAYING:
        return
    hunger = clampf(hunger - hunger_decay_rate * delta, 0, MAX_SURVIVAL)
    thirst = clampf(thirst - thirst_decay_rate * delta, 0, MAX_SURVIVAL)
    if body_temperature > environmental_temperature:
        body_temperature -= 0.01 * delta
    else:
        body_temperature += 0.01 * delta
    _check_critical_states(delta)
    hunger_changed.emit(hunger)
    thirst_changed.emit(thirst)
    temperature_changed.emit(body_temperature)


func _check_critical_states(delta: float) -> void:
    var player = get_node("/root/GameManager").player if get_node("/root/GameManager") else null
    if not player:
        return
    if hunger <= 0:
        if player.health:
            player.health.take_damage(int(delta * 5))
        status_effect_applied.emit("starving", 1.0)
    if thirst <= 0:
        if player.stats:
            var current = player.stats.get_stat("stamina")
            player.stats.set_base_stat("stamina", max(0, current - delta * 2))
        status_effect_applied.emit("dehydrated", 1.0)
    if body_temperature < 35.0:
        if player.stats:
            player.stats.add_bonus("speed", -2.0)
        status_effect_applied.emit("hypothermia", 35.0 - body_temperature)
    elif body_temperature > 39.0:
        thirst_decay_rate = 0.25
        status_effect_applied.emit("hyperthermia", body_temperature - 39.0)


func consume_item(item_id: String, amount: int = 1) -> bool:
    var item_res = _load_item_resource(item_id)
    if not item_res or not _is_consumable_resource(item_res):
        return false
    var player = get_node("/root/GameManager").player if get_node("/root/GameManager") else null
    if not player or not player.inventory_comp:
        return false
    if not player.inventory_comp.has_item(item_id, amount):
        return false
    player.inventory_comp.remove_item(item_id, amount)
    hunger = clampf(hunger + item_res.hunger_restored, 0, MAX_SURVIVAL)
    thirst = clampf(thirst + item_res.thirst_restored, 0, MAX_SURVIVAL)
    body_temperature = clampf(body_temperature + item_res.temperature_change, 25, 45)
    if item_res.disease_chance > 0 and randf() < item_res.disease_chance:
        var EM = get_node("/root/EventManager")
        if EM:
            EM.disease_contracted.emit(item_res.disease_id)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.item_used.emit(item_id, player.player_id)
    return true


func _is_consumable_resource(res):
    return res.script.resource_path == "res://Resources/Survival/ConsumableResource.gd"


func _load_item_resource(item_id: String):
    var paths = {
        "apple": "res://Resources/Items/Consumables/apple.tres",
        "bread": "res://Resources/Items/Consumables/bread.tres",
        "water_skin": "res://Resources/Items/Consumables/water_skin.tres",
        "health_potion_small": "res://Resources/Items/Consumables/health_potion_small.tres",
    }
    var path = paths.get(item_id)
    if path:
        return load(path)
    return null


func _on_item_consumed(item_id: String, player_id: String) -> void:
    var GM = get_node("/root/GameManager")
    if GM and GM.player and player_id == GM.player.player_id:
        consume_item(item_id, 1)


func _on_weather_changed(new_weather: String) -> void:
    match new_weather:
        "sunny":
            environmental_temperature = 25.0
        "rain":
            environmental_temperature = 15.0
            thirst_decay_rate = 0.08
        "snow":
            environmental_temperature = -5.0
            hunger_decay_rate = 0.12
        "storm":
            environmental_temperature = 10.0
        "heatwave":
            environmental_temperature = 45.0
            thirst_decay_rate = 0.20
        _:
            environmental_temperature = 20.0


func _on_day_night_changed(is_day: bool, _time: float) -> void:
    if not is_day:
        environmental_temperature -= 5.0
    else:
        environmental_temperature += 3.0
