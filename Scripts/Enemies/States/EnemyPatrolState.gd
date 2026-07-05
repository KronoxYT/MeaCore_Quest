extends "res://Scripts/Core/State.gd"

func enter(_prev_state = ""):
    entity.play_animation("walk")

func physics_process(_delta: float):
    if entity.ai:
        match entity.ai.current_state:
            entity.ai.AIState.IDLE:
                fsm.transition_to("idle")
            entity.ai.AIState.CHASE:
                fsm.transition_to("chase")
            entity.ai.AIState.ALERT:
                fsm.transition_to("alert")