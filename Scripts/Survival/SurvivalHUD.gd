extends Control

@onready var hunger_bar: ProgressBar = $MarginContainer/VBox/HungerBar
@onready var thirst_bar: ProgressBar = $MarginContainer/VBox/ThirstBar
@onready var temp_bar: ProgressBar = $MarginContainer/VBox/TempBar
@onready var temp_label: Label = $MarginContainer/VBox/TempBar/TempLabel


func _ready():
    var survival = get_node_or_null("/root/SurvivalManager")
    if survival:
        survival.hunger_changed.connect(_on_hunger_changed)
        survival.thirst_changed.connect(_on_thirst_changed)
        survival.temperature_changed.connect(_on_temperature_changed)


func _on_hunger_changed(value: float) -> void:
    hunger_bar.value = value
    hunger_bar.modulate = _get_warning_color(value)


func _on_thirst_changed(value: float) -> void:
    thirst_bar.value = value
    thirst_bar.modulate = _get_warning_color(value)


func _on_temperature_changed(value: float) -> void:
    var normalized = clampf((value - 20.0) / 25.0, 0, 1) * 100
    temp_bar.value = normalized
    temp_label.text = "%.1f°C" % value
    if value < 35.0 or value > 39.0:
        temp_bar.modulate = Color.RED
    else:
        temp_bar.modulate = Color.WHITE


func _get_warning_color(value: float) -> Color:
    if value < 20:
        return Color.RED
    elif value < 40:
        return Color.YELLOW
    return Color.GREEN
