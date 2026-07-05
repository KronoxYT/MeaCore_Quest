extends "res://Scripts/Core/State.gd"

func enter(_prev_state = ""):
    entity.play_animation("run")

func physics_process(_delta: float):
    if entity.ai:
        match entity.ai.current_state:
            entity.ai.AIState.ATTACK:
                fsm.transition_to("attack")
            entity.ai.AIState.IDLE:
                fsm.transition_to("idle")
            entity.ai.AIState.RETURN:
                fsm.transition_to("return")