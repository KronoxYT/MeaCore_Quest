extends Node2D

@export var rise_speed: float = 60.0
@export var lifetime: float = 1.0
@export var font_size: int = 16

var damage_amount: int = 0
var is_critical: bool = false
var is_heal: bool = false
var timer: float = 0.0
var initial_position: Vector2 = Vector2.ZERO
var drift_direction: Vector2 = Vector2.ZERO

@onready var label: Label = $Label

func _ready():
    initial_position = position
    drift_direction = Vector2(randf_range(-20, 20), 0)

func show_damage(amount: int, color: Color = Color(1, 1, 1), critical: bool = false, heal: bool = false):
    damage_amount = amount
    is_critical = critical
    is_heal = heal
    timer = lifetime
    initial_position = position
    drift_direction = Vector2(randf_range(-20, 20), 0)
    modulate.a = 1.0
    visible = true
    set_process(true)
    set_physics_process(true)
    if label:
        label.text = str(amount)
        if heal:
            label.text = "+" + str(amount)
        label.add_theme_color_override("font_color", color)

func _process(delta: float):
    timer -= delta
    position.y -= rise_speed * delta
    position.x += drift_direction.x * delta * 0.5
    var alpha = clamp(timer / lifetime, 0, 1)
    modulate.a = alpha
    if timer <= 0:
        visible = false
        set_process(false)
        set_physics_process(false)
