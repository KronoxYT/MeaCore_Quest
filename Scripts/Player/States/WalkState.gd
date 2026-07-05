extends "res://Scripts/Core/State.gd"

class_name WalkState


func enter(_prev_state = ""):
    if playback:
        playback.travel("walk")


func update(_delta: float) -> void:
    var p = entity
    if not p:
        return
    if p.input_direction.length() < 0.1:
        state_machine.change_state("Idle")
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
    p.velocity = p.velocity.move_toward(p.input_direction * p.move_speed, p.acceleration * delta)
    p.move_and_slide()
    # Voltear el sprite según la dirección horizontal sin rotar el nodo completo
    if p.input_direction.x != 0:
        var sprite = p.get_node_or_null("Sprite2D")
        if sprite:
            sprite.flip_h = p.input_direction.x < 0


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
