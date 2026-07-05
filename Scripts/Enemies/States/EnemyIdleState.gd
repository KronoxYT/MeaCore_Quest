extends "res://Scripts/Core/State.gd"

func enter(_prev_state = ""):
    entity.velocity = Vector2.ZERO
    entity.play_animation("idle")

func physics_process(_delta: float):
    if entity.ai:
        match entity.ai.current_state:
            entity.ai.AIState.PATROL:
                fsm.transition_to("patrol")
            entity.ai.AIState.CHASE:
                fsm.transition_to("chase")