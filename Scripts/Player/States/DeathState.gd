extends "res://Scripts/Core/State.gd"

class_name DeathState

var death_timer: float = 2.0


func enter(_prev_state = ""):
    var p = entity
    if not p:
        return
    p.is_alive = false
    p.velocity = Vector2.ZERO
    if playback:
        playback.travel("death")
    EventManager.emit_event("player_died", {"player_id": str(p.get_instance_id())})


func physics_update(delta: float) -> void:
    death_timer -= delta
    var p = entity
    if not p:
        return
    p.velocity = p.velocity.move_toward(Vector2.ZERO, p.friction * delta)
    if death_timer <= 0.0:
        p.queue_free()
        GameManager.change_state(GameManager.GameState.GAME_OVER)
