extends Node

class_name State

var state_machine:
    get:
        return get_parent()


var entity:
    get:
        var sm = state_machine
        if sm and sm.has_method("get_parent"):
            var p = sm.get_parent()
            if p:
                return p
        return null


var fsm:
    get:
        return state_machine

var playback:
    get:
        var anim_tree = _get_animation_tree()
        if anim_tree and anim_tree.has_method("get"):
            return anim_tree.get("parameters/playback")
        var anim_player = _get_animation_player()
        if anim_player:
            return AnimationPlayerPlaybackProxy.new(anim_player)
        return null


class AnimationPlayerPlaybackProxy:
    var anim_player: AnimationPlayer
    func _init(player: AnimationPlayer):
        anim_player = player
    func travel(anim_name: String) -> void:
        if anim_player.has_animation(anim_name):
            anim_player.play(anim_name)
        elif anim_name == "attack_1" and anim_player.has_animation("attack"):
            anim_player.play("attack")


func enter(_prev_state = "") -> void:
    pass


func exit() -> void:
    pass


func update(_delta: float) -> void:
    pass


func physics_update(_delta: float) -> void:
    pass


func handle_input(_event: InputEvent) -> void:
    pass


func _get_animation_tree():
    if entity:
        return entity.get_node_or_null("AnimationTree")
    return null


func _get_animation_player():
    if entity:
        return entity.get_node_or_null("AnimationPlayer")
    return null
