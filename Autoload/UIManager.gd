extends Node

signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)

var ui_stack: Array = []
var ui_scenes: Dictionary = {
    "inventory": preload("res://Scenes/UI/InventoryUI.tscn"),
    "dialogue": preload("res://Scenes/UI/DialogueUI.tscn"),
}

var active_dialogue_ui = null
var _overlay = null


func _ready() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    _overlay = CanvasLayer.new()
    _overlay.name = "UIManagerOverlay"
    _overlay.layer = 128
    add_child(_overlay)


func open_ui(ui_name: String, data: Dictionary = {}) -> void:
    if ui_name not in ui_scenes:
        push_warning("UI no encontrada: %s" % ui_name)
        return
    var ui_scene: PackedScene = ui_scenes[ui_name]
    var ui_instance: Node = ui_scene.instantiate()
    if ui_instance.has_method("setup"):
        ui_instance.setup(data)
    _overlay.add_child(ui_instance)
    ui_stack.append(ui_instance)
    var GM = get_node("/root/GameManager")
    if GM:
        GM.change_state(GameManager.GameState.INVENTORY)
    ui_opened.emit(ui_name)


func open_dialogue(dialogue_resource) -> void:
    if active_dialogue_ui:
        active_dialogue_ui.queue_free()
    if not ui_scenes.has("dialogue"):
        push_warning("Escena de diálogo no registrada")
        return
    var dialogue_ui: Node = ui_scenes["dialogue"].instantiate()
    _overlay.add_child(dialogue_ui)
    dialogue_ui.open(dialogue_resource)
    active_dialogue_ui = dialogue_ui
    ui_stack.append(dialogue_ui)
    var GM = get_node("/root/GameManager")
    if GM:
        GM.change_state(GameManager.GameState.DIALOGUE)


func close_ui() -> void:
    if ui_stack.size() > 0:
        var last = ui_stack.pop_back()
        if is_instance_valid(last):
            last.queue_free()
        if ui_stack.is_empty():
            if active_dialogue_ui and not is_instance_valid(active_dialogue_ui):
                active_dialogue_ui = null
            var GM = get_node("/root/GameManager")
            if GM and GM.current_state == GameManager.GameState.INVENTORY:
                GM.change_state(GameManager.GameState.PLAYING)
    if ui_stack.is_empty() and active_dialogue_ui and not is_instance_valid(active_dialogue_ui):
        active_dialogue_ui = null


func is_ui_open(ui_name: String) -> bool:
    for ui in ui_stack:
        if ui.name == ui_name:
            return true
    return false


func register_ui(ui_name: String, scene: PackedScene) -> void:
    ui_scenes[ui_name] = scene
