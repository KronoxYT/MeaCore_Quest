extends "res://Scripts/Core/State.gd"

func enter(_prev_state = ""):
    entity.play_animation("death")
    entity.velocity = Vector2.ZERO
    entity.set_physics_process(false)
    entity.set_process(false)
    
    # Llamar a die() después de la animación
    if entity.animation_player:
        await entity.animation_player.animation_finished
    
    entity.die()