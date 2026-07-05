extends "res://Scripts/Core/State.gd"

var attack_executed: bool = false

func enter(_prev_state = ""):
    attack_executed = false
    entity.play_animation("attack")
    entity.velocity = Vector2.ZERO
    
    # Activar hitbox
    var hitbox = entity.get_node_or_null("HitboxComponent")
    if hitbox:
        hitbox.activate()
    
    # Esperar a que termine la animación
    if entity.animation_player:
        entity.animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String) -> void:
    if anim_name == "attack":
        attack_executed = true
        var hitbox = entity.get_node_or_null("HitboxComponent")
        if hitbox:
            hitbox.deactivate()
        
        if entity.animation_player:
            entity.animation_player.animation_finished.disconnect(_on_animation_finished)
        
        fsm.transition_to("chase")