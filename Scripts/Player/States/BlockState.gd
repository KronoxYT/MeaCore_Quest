extends "res://Scripts/Core/State.gd"

class_name BlockState


func enter(_prev_state = ""):
    var p = entity
    if not p:
        return
    p.is_blocking = true
    if playback:
        playback.travel("block")


func exit() -> void:
    var p = entity
    if p:
        p.is_blocking = false


func update(_delta: float) -> void:
    var p = entity
    if not p:
        return
    if not p.is_blocking:
        if p.input_direction.length() > 0.1:
            state_machine.change_state("Walk")
        else:
            state_machine.change_state("Idle")


func physics_update(delta: float) -> void:
    var p = entity
    if not p:
        return
    p.velocity = p.velocity.move_toward(Vector2.ZERO, p.friction * delta * 2.0)


func handle_input(event: InputEvent) -> void:
    var p = entity
    if not p:
        return
    if event.is_action_released("player_block"):
        p.is_blocking = false
