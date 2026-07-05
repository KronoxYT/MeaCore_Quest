extends "res://Scripts/Core/State.gd"

class_name HurtState

var hurt_timer: float = 0.0
const HURT_DURATION: float = 0.3


func enter(_prev_state = ""):
    hurt_timer = HURT_DURATION
    if playback:
        playback.travel("hurt")


func physics_update(delta: float) -> void:
    hurt_timer -= delta
    var p = entity
    if not p:
        return
    p.velocity = p.velocity.move_toward(Vector2.ZERO, p.friction * delta)
    if hurt_timer <= 0.0:
        if p.input_direction.length() > 0.1:
            state_machine.change_state("Walk")
        else:
            state_machine.change_state("Idle")


func update(_delta: float) -> void:
    var p = entity
    if not p:
        return
    if hurt_timer <= 0.0:
        if p.input_direction.length() > 0.1:
            state_machine.change_state("Walk")
        else:
            state_machine.change_state("Idle")
