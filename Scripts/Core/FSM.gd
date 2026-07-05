extends Node

class_name FSM

var entity:
    get:
        return get_parent()

var states: Dictionary = {}
var current_state
var current_state_name: String = ""
var previous_state_name: String = ""

signal state_changed(state_name: String)


func _ready() -> void:
    await get_tree().process_frame
    _collect_states()


func _collect_states() -> void:
    for child in get_children():
        if child.get_script() and child.has_method("enter"):
            var state_name = child.name.to_lower().trim_suffix("state")
            states[state_name] = child

    # Inicializar estado inicial automáticamente
    if states.size() > 0 and current_state_name == "":
        var initial_state = "idle" if states.has("idle") else states.keys()[0]
        current_state_name = initial_state
        current_state = states[initial_state]
        current_state.enter("")


func change_state(state_name: String) -> void:
    var lower_name = state_name.to_lower()
    if not states.has(lower_name):
        push_warning("Estado '%s' no encontrado" % state_name)
        return
    if current_state_name == lower_name:
        return

    if current_state:
        current_state.exit()

    previous_state_name = current_state_name
    current_state_name = lower_name
    current_state = states[lower_name]
    current_state.enter(previous_state_name)
    state_changed.emit(lower_name)


func is_in_state(state_name: String) -> bool:
    return current_state_name == state_name.to_lower()


func transition_to(state_name: String) -> void:
    change_state(state_name)


func _process(delta: float) -> void:
    update(delta)


func _physics_process(delta: float) -> void:
    physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
    handle_input(event)


func update(delta: float) -> void:
    if current_state:
        current_state.update(delta)


func physics_update(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)


func handle_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)
