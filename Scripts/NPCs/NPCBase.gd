class_name NPCBase
extends CharacterBody2D

signal npc_interacted(npc_id: String)
signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
signal shop_opened(npc_id: String)

@export var npc_resource = null
@export var auto_routine: bool = true

var npc_id: String = ""
var current_routine: String = "idle"
var day_night = null
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var animation_player = null
var sprite = null
var icon_indicator = null
var interaction_area = null
var player_nearby: bool = false
var current_dialogue_active: bool = false


func _ready():
    if npc_resource:
        npc_id = npc_resource.id
    else:
        npc_id = "npc_unknown"
    animation_player = get_node_or_null("AnimationPlayer")
    sprite = get_node_or_null("Sprite2D")
    icon_indicator = get_node_or_null("IconIndicator")
    interaction_area = get_node_or_null("InteractionArea")
    add_to_group("npcs")
    day_night = get_node_or_null("/root/DayNightCycle")
    if day_night and npc_resource and npc_resource.has_routine:
        day_night.time_updated.connect(_on_time_updated)
        _update_routine()
    if interaction_area:
        interaction_area.body_entered.connect(_on_body_entered)
        interaction_area.body_exited.connect(_on_body_exited)
    if npc_resource and sprite and npc_resource.sprite_sheet:
        sprite.texture = npc_resource.sprite_sheet
    await get_tree().process_frame
    _update_quest_indicator()


func _process(delta: float) -> void:
    if not npc_resource or not npc_resource.has_routine:
        return
    if target_position != global_position and not current_dialogue_active:
        var direction = (target_position - global_position).normalized()
        var distance = global_position.distance_to(target_position)
        if distance > 5:
            velocity = direction * 60.0
            move_and_slide()
            _face_direction(direction)
            if animation_player and animation_player.has_animation("walk"):
                animation_player.play("walk")
            is_moving = true
        else:
            velocity = Vector2.ZERO
            if is_moving:
                is_moving = false
                _on_arrived_at_target()


func _on_time_updated(hour: float, _is_day: bool) -> void:
    if npc_resource and npc_resource.has_routine:
        _update_routine()


func _update_routine() -> void:
    if not day_night:
        return
    var hour = day_night.current_hour
    var new_routine: String = "idle"
    if hour >= npc_resource.work_hours.x and hour < npc_resource.work_hours.y:
        new_routine = "work"
        target_position = npc_resource.work_position
    elif hour >= npc_resource.rest_hours.x and hour < npc_resource.rest_hours.y:
        new_routine = "rest"
        target_position = npc_resource.rest_position
    else:
        new_routine = "home"
        target_position = npc_resource.home_position
    if new_routine != current_routine:
        current_routine = new_routine


func _on_arrived_at_target() -> void:
    if animation_player and animation_player.has_animation("idle"):
        animation_player.play("idle")


func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("players"):
        player_nearby = true


func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("players"):
        player_nearby = false


func _unhandled_input(event: InputEvent) -> void:
    if not player_nearby:
        return
    if event.is_action_pressed("interact"):
        _on_interaction_pressed()


func _on_interaction_pressed() -> void:
    if current_dialogue_active:
        return
    npc_interacted.emit(npc_id)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.npc_interacted.emit(npc_id)
    if npc_resource and npc_resource.shop_inventory_id != "":
        if EM:
            EM.npc_shop_opened.emit(npc_id)
        shop_opened.emit(npc_id)
    if npc_resource and npc_resource.starting_dialogue:
        _start_dialogue(npc_resource.starting_dialogue)


func _start_dialogue(dialogue) -> void:
    current_dialogue_active = true
    dialogue_started.emit(npc_id)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.dialogue_started.emit(npc_id)
    var UM = get_node("/root/UIManager")
    if UM:
        UM.open_dialogue(dialogue)


func end_dialogue() -> void:
    current_dialogue_active = false
    dialogue_ended.emit(npc_id)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.dialogue_ended.emit(npc_id)


func _update_quest_indicator() -> void:
    if icon_indicator:
        icon_indicator.visible = false


func _face_direction(direction: Vector2) -> void:
    if sprite and abs(direction.x) > abs(direction.y):
        sprite.flip_h = direction.x < 0
