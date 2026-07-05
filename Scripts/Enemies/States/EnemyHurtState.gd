extends "res://Scripts/Core/State.gd"

const HURT_DURATION = 0.2
var hurt_timer: float = 0.0

func enter(_prev_state = ""):
    hurt_timer = HURT_DURATION
    entity.play_animation("hurt")
    entity.velocity = Vector2.ZERO

func process(delta: float):
    hurt_timer -= delta
    if hurt_timer <= 0:
        if entity.ai:
            match entity.ai.current_state:
                entity.ai.AIState.CHASE:
                    fsm.transition_to("chase")
                entity.ai.AIState.FLEE:
                    fsm.transition_to("flee")
                _:
                    fsm.transition_to("idle")