extends "res://Scripts/Core/State.gd"

class_name DodgeState

var dodge_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO


func enter(_prev_state = ""):
    var p = entity
    if not p:
        return
    dodge_timer = p.dodge_duration
    dodge_direction = p.input_direction if p.input_direction.length() > 0.1 else Vector2.RIGHT * (1.0 if p.transform.x.x >= 0 else -1.0)
    p.is_dodging = true
    if playback:
        playback.travel("dodge")


func exit() -> void:
    var p = entity
    if p:
        p.is_dodging = false


func physics_update(delta: float) -> void:
    dodge_timer -= delta
    var p = entity
    if not p:
        return
    p.velocity = dodge_direction * p.dodge_speed
    if dodge_timer <= 0.0:
        if p.input_direction.length() > 0.1:
            state_machine.change_state("Walk")
        else:
            state_machine.change_state("Idle")


func update(_delta: float) -> void:
    var p = entity
    if not p:
        return
    if dodge_timer <= 0.0:
        p.is_dodging = false
        if p.input_direction.length() > 0.1:
            state_machine.change_state("Walk")
        else:
            state_machine.change_state("Idle")
