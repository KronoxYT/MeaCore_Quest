extends CanvasLayer

var current_dialogue = null
var current_node_id: String = ""
var is_typing: bool = false
var type_timer: float = 0.0
var type_index: int = 0
var full_text: String = ""

const NODE_TYPE_CHOICE = 1
const NODE_TYPE_END = 5

@onready var panel = $Panel
@onready var portrait: TextureRect = $Panel/HBoxContainer/Portrait
@onready var name_label: Label = $Panel/HBoxContainer/VBoxContainer/NameLabel
@onready var text_label: Label = $Panel/HBoxContainer/VBoxContainer/TextLabel
@onready var options_container: VBoxContainer = $Panel/HBoxContainer/VBoxContainer/OptionsContainer
@onready var continue_hint: Label = $Panel/HBoxContainer/VBoxContainer/ContinueHint


func _ready():
    hide()
    text_label.visible_ratio = 0.0


func open(dialogue_resource) -> void:
    current_dialogue = dialogue_resource
    show()
    _display_node(dialogue_resource)


func _display_node(node) -> void:
    if not node:
        return
    current_node_id = node.id
    if node.portrait and portrait:
        portrait.texture = node.portrait
    if name_label:
        name_label.text = node.npc_display_name
    _show_text(node.text)
    _show_options(node)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.dialogue_line_displayed.emit(node.id)
    if node.node_type == NODE_TYPE_CHOICE:
        if continue_hint:
            continue_hint.visible = false


func _show_text(text: String) -> void:
    full_text = text
    text_label.text = text
    text_label.visible_ratio = 0.0
    is_typing = true
    type_index = 0
    type_timer = 0.0
    if continue_hint:
        continue_hint.visible = false


func _process(delta: float) -> void:
    if not is_typing or not text_label:
        return
    type_timer += delta
    if type_timer >= 0.03:
        type_timer = 0.0
        type_index += 1
        text_label.visible_ratio = float(type_index) / max(float(full_text.length()), 1.0)
        if type_index >= full_text.length():
            is_typing = false
            if continue_hint:
                continue_hint.visible = true


func _show_options(node) -> void:
    if not options_container:
        return
    for child in options_container.get_children():
        child.queue_free()
    if node.node_type == NODE_TYPE_CHOICE and node.options.size() > 0:
        for i in node.options.size():
            var opt = node.options[i]
            var btn = Button.new()
            btn.text = opt.get("text", "Opción %d" % i)
            btn.pressed.connect(_on_option_selected.bind(i, opt))
            options_container.add_child(btn)


func _on_option_selected(index: int, opt: Dictionary) -> void:
    var EM = get_node("/root/EventManager")
    if EM:
        EM.dialogue_choice_made.emit(index)
    close()


func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
        if is_typing:
            text_label.visible_ratio = 1.0
            type_index = full_text.length()
            is_typing = false
            if continue_hint:
                continue_hint.visible = true
            get_viewport().set_input_as_handled()
            return
        if current_dialogue and options_container and options_container.get_child_count() == 0:
            var next_id = _get_next_node_id()
            if next_id == "":
                close()
            else:
                var next_node = _find_node(current_dialogue, next_id)
                if next_node:
                    _display_node(next_node)
                else:
                    close()
            get_viewport().set_input_as_handled()


func _get_next_node_id() -> String:
    var node = current_dialogue
    if node and node.node_type == NODE_TYPE_END:
        return ""
    if node and node.node_type == NODE_TYPE_CHOICE:
        return ""
    return ""


func _find_node(dialogue, node_id: String):
    if dialogue and dialogue.id == node_id:
        return dialogue
    return null


func close() -> void:
    var EM = get_node("/root/EventManager")
    if EM and current_dialogue:
        EM.dialogue_ended.emit(current_dialogue.npc_id)
    queue_free()
