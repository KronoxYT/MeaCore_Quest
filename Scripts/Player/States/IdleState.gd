extends "res://Scripts/Core/State.gd"

class_name IdleState


func enter(_prev_state = ""):
    if playback:
        playback.travel("idle")


func update(_delta: float) -> void:
    var p = entity
    if not p:
        return
    if p.input_direction.length() > 0.1:
        state_machine.change_state("Walk")
    if p.is_attacking:
        state_machine.change_state("Attack")
    if p.is_dodging:
        state_machine.change_state("Dodge")
    if p.is_blocking:
        state_machine.change_state("Block")


func physics_update(delta: float) -> void:
    var p = entity
    if not p:
        return
    # Aplicar fricción para detener el movimiento gradualmente
    p.velocity = p.velocity.move_toward(Vector2.ZERO, p.friction * delta)
    p.move_and_slide()


func handle_input(event: InputEvent) -> void:
    var p = entity
    if not p:
        return
    if event.is_action_pressed("player_dodge"):
        p.is_dodging = true
    elif event.is_action_pressed("player_attack"):
        p.is_attacking = true
    elif event.is_action_pressed("player_block"):
        p.is_blocking = true
