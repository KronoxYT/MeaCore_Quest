extends Node

signal time_updated(hour: float, is_day: bool)

const SECONDS_PER_DAY: float = 720.0

var current_hour: float = 12.0
var is_day: bool = true
var time_scale: float = 1.0


func _ready():
    process_mode = PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
    var hour_increment = (24.0 / SECONDS_PER_DAY) * delta * time_scale
    current_hour = fmod(current_hour + hour_increment, 24.0)
    var was_day = is_day
    is_day = current_hour >= 6.0 and current_hour < 20.0
    if was_day != is_day:
        var EM = get_node("/root/EventManager")
        if EM:
            EM.day_night_cycle_changed.emit(is_day, current_hour)
    time_updated.emit(current_hour, is_day)


func set_hour(new_hour: float) -> void:
    current_hour = fmod(new_hour, 24.0)
    is_day = current_hour >= 6.0 and current_hour < 20.0


func get_formatted_time() -> String:
    var hour_int = int(current_hour)
    var minutes_int = int((current_hour - hour_int) * 60)
    return "%02d:%02d" % [hour_int, minutes_int]
