extends "res://Scripts/Core/State.gd"

class_name AttackState

var attack_timer: float = 0.0


func enter(_prev_state = ""):
    var p = entity
    if not p:
        return
    attack_timer = p.attack_duration
    if playback:
        playback.travel("attack_1")
    p.is_attacking = true


func exit() -> void:
    var p = entity
    if p:
        p.is_attacking = false


func update(delta: float) -> void:
    attack_timer -= delta
    if attack_timer <= 0.0:
        var p = entity
        if not p:
            return
        if p.input_direction.length() > 0.1:
            state_machine.change_state("Walk")
        else:
            state_machine.change_state("Idle")


func physics_update(delta: float) -> void:
    var p = entity
    if not p:
        return
    var dir = p.input_direction
    if dir.length() > 0.1:
        p.velocity = p.velocity.move_toward(dir * p.move_speed * 0.3, p.acceleration * delta)
    else:
        p.velocity = p.velocity.move_toward(Vector2.ZERO, p.friction * delta)
