extends VBoxContainer

class_name QuestTracker


func _ready():
    var qm = get_node_or_null("/root/QuestManager")
    if qm:
        qm.active_quests_updated.connect(_refresh_ui)
    _refresh_ui()


func _refresh_ui() -> void:
    for child in get_children():
        child.queue_free()
    var qm = get_node_or_null("/root/QuestManager")
    if not qm:
        return
    for quest in qm.active_quests:
        _create_quest_entry(quest)


func _create_quest_entry(quest) -> void:
    var entry_panel = VBoxContainer.new()
    add_child(entry_panel)
    var name_lbl = Label.new()
    name_lbl.text = quest.display_name
    name_lbl.add_theme_color_override("font_color", Color("#FFD700"))
    name_lbl.add_theme_font_size_override("font_size", 16)
    entry_panel.add_child(name_lbl)
    for objective in quest.objectives:
        var obj_lbl = Label.new()
        var desc = objective.get("description", "")
        var current = objective.get("current", 0)
        var required = objective.get("required_amount", 1)
        obj_lbl.text = "  . %s [%d/%d]" % [desc, current, required]
        if current >= required:
            obj_lbl.add_theme_color_override("font_color", Color.GREEN)
            obj_lbl.text += " V"
        else:
            obj_lbl.add_theme_color_override("font_color", Color.WHITE)
        entry_panel.add_child(obj_lbl)
    var sep = HSeparator.new()
    entry_panel.add_child(sep)
