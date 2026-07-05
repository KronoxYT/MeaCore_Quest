extends "res://Scripts/Core/State.gd"

func enter(_prev_state = ""):
    entity.play_animation("run")

func physics_process(delta: float):
    if not entity.ai:
        return
    var target = entity.ai.target
    if not target:
        fsm.transition_to("idle")
        return
    var flee_dir = (entity.global_position - target.global_position).normalized()
    var speed = entity.stats.get_stat("speed") if entity.stats else 80.0
    entity.velocity = flee_dir * speed
    entity.move_and_slide()
