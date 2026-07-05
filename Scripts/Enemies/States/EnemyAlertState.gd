extends "res://Scripts/Core/State.gd"

func enter(_prev_state = ""):
    entity.velocity = Vector2.ZERO
    entity.play_animation("alert")

func physics_process(_delta: float):
    if entity.ai and entity.ai.current_state != entity.ai.AIState.ALERT:
        pass
