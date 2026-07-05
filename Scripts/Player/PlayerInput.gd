extends Node

class_name PlayerInput

var player: PlayerBase:
    get:
        if is_inside_tree():
            var p := get_parent()
            if p is PlayerBase:
                return p
        return null

var move_direction: Vector2 = Vector2.ZERO
var attack_pressed: bool = false
var block_held: bool = false
var dodge_pressed: bool = false


func _input(event: InputEvent) -> void:
    if not player:
        return

    if event.is_action_pressed("player_attack"):
        attack_pressed = true
    elif event.is_action_released("player_attack"):
        attack_pressed = false

    if event.is_action_pressed("player_block"):
        block_held = true
    elif event.is_action_released("player_block"):
        block_held = false

    if event.is_action_pressed("player_dodge"):
        dodge_pressed = true
    elif event.is_action_released("player_dodge"):
        dodge_pressed = false


func _physics_process(_delta: float) -> void:
    var dir := Vector2.ZERO
    dir.x = Input.get_axis("move_left", "move_right")
    dir.y = Input.get_axis("move_up", "move_down")
    move_direction = dir.normalized()
