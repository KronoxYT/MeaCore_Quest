extends CanvasLayer

# Class Selection Screen
@onready var class_select_panel = $ClassSelectPanel
@onready var game_ui_container = $GameUI

# Player Info
@onready var hp_anim = $GameUI/PlayerFrame/AnimatedSprite2D
@onready var mp_bar = $GameUI/PlayerFrame/MPBar
@onready var mp_label = $GameUI/PlayerFrame/MPBar/Label
@onready var lvl_label = $GameUI/PlayerFrame/LvlLabel
@onready var name_label = $GameUI/PlayerFrame/NameLabel
@onready var xp_bar = $GameUI/PlayerFrame/XPBar
@onready var gold_label = $GameUI/PlayerFrame/GoldLabel

# Target Info
@onready var target_frame = $GameUI/TargetFrame
@onready var target_name = $GameUI/TargetFrame/TargetName
@onready var target_hp = $GameUI/TargetFrame/TargetHP
@onready var target_lvl = $GameUI/TargetFrame/TargetLvl

# Hotbar Skills and Items
@onready var skill_slot_1_cd = $GameUI/Hotbar/Skill1/CDOverlay
@onready var skill_slot_1_lbl = $GameUI/Hotbar/Skill1/CDLabel
@onready var skill_slot_2_cd = $GameUI/Hotbar/Skill2/CDOverlay
@onready var skill_slot_2_lbl = $GameUI/Hotbar/Skill2/CDLabel
@onready var skill_slot_3_cd = $GameUI/Hotbar/Skill3/CDOverlay
@onready var skill_slot_3_lbl = $GameUI/Hotbar/Skill3/CDLabel

@onready var skill1_name_lbl = $GameUI/Hotbar/Skill1/NameLabel
@onready var skill2_name_lbl = $GameUI/Hotbar/Skill2/NameLabel
@onready var skill3_name_lbl = $GameUI/Hotbar/Skill3/NameLabel

@onready var hp_pot_count = $GameUI/Hotbar/ItemHP/CountLabel
@onready var mp_pot_count = $GameUI/Hotbar/ItemMP/CountLabel

# Chat Box
@onready var chat_text = $GameUI/ChatBox/ScrollContainer/RichTextLabel
@onready var chat_scroll = $GameUI/ChatBox/ScrollContainer

# Quest Tracker
@onready var quest_tracker_label = $GameUI/QuestTracker/ScrollContainer/QuestListLabel

# Popups
@onready var inventory_panel = $GameUI/InventoryPanel
@onready var inventory_grid = $GameUI/InventoryPanel/ScrollContainer/GridContainer
@onready var character_panel = $GameUI/CharacterPanel
@onready var elder_dialog_panel = $GameUI/ElderDialogPanel
@onready var elder_text = $GameUI/ElderDialogPanel/DialogueText
@onready var elder_buttons_container = $GameUI/ElderDialogPanel/ScrollContainer/VBoxContainer
@onready var shop_panel = $GameUI/ShopPanel
@onready var shop_buy_container = $GameUI/ShopPanel/BuyContainer/VBoxContainer
@onready var shop_sell_container = $GameUI/ShopPanel/SellContainer/VBoxContainer

# Character Stats Labels
@onready var char_class_lbl = $GameUI/CharacterPanel/StatsBox/ClassVal
@onready var char_lvl_lbl = $GameUI/CharacterPanel/StatsBox/LvlVal
@onready var char_atk_lbl = $GameUI/CharacterPanel/StatsBox/AtkVal
@onready var char_def_lbl = $GameUI/CharacterPanel/StatsBox/DefVal
@onready var char_gold_lbl = $GameUI/CharacterPanel/StatsBox/GoldVal

# Equipped items
@onready var eq_weapon_btn = $GameUI/CharacterPanel/EquipmentBox/WeaponSlot
@onready var eq_armor_btn = $GameUI/CharacterPanel/EquipmentBox/ArmorSlot
@onready var eq_shield_btn = $GameUI/CharacterPanel/EquipmentBox/ShieldSlot

# Item Tooltip
@onready var tooltip_lbl = $GameUI/TooltipPanel/Label
@onready var tooltip_panel = $GameUI/TooltipPanel

# Victory
@onready var victory_panel = $VictoryPanel

# Combo display
var combo_label: Label

static func get_playthrough_count() -> int:
    var cfg := ConfigFile.new()
    cfg.load("user://playthrough.cfg")
    return cfg.get_value("meta", "playthrough_count", 0)

static func increment_playthrough() -> void:
    var cfg := ConfigFile.new()
    cfg.load("user://playthrough.cfg")
    var count = cfg.get_value("meta", "playthrough_count", 0) + 1
    cfg.set_value("meta", "playthrough_count", count)
    cfg.save("user://playthrough.cfg")

func _ready():
    add_to_group("hud")
    
    # Connect GameManager signals
    GameManager.player_stats_changed.connect(update_player_hud)
    GameManager.inventory_changed.connect(update_inventory_ui)
    GameManager.quest_log_changed.connect(update_quest_tracker)
    GameManager.target_changed.connect(update_target_hud)
    GameManager.chat_received.connect(on_chat_received)
    GameManager.game_victory.connect(on_victory)
    GameManager.combo_changed.connect(_on_combo_changed)
    
    # Create combo display label
    combo_label = Label.new()
    combo_label.name = "ComboLabel"
    combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    combo_label.add_theme_font_size_override("font_size", 32)
    combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.1))
    combo_label.add_theme_color_override("font_outline_color", Color.BLACK)
    combo_label.add_theme_constant_override("outline_size", 4)
    combo_label.position = Vector2(540, 200)
    combo_label.size = Vector2(200, 60)
    combo_label.visible = false
    add_child(combo_label)
    
    # Initial visibility setup
    class_select_panel.visible = true
    game_ui_container.visible = false
    target_frame.visible = false
    inventory_panel.visible = false
    character_panel.visible = false
    elder_dialog_panel.visible = false
    shop_panel.visible = false
    victory_panel.visible = false
    tooltip_panel.visible = false
    
    var name_input = $ClassSelectPanel/VBoxContainer/NameInput
    $ClassSelectPanel/VBoxContainer/WarriorBtn.pressed.connect(func(): select_class("Warrior", name_input.text.strip_edges()))
    $ClassSelectPanel/VBoxContainer/MageBtn.pressed.connect(func(): select_class("Mage", name_input.text.strip_edges()))
    $ClassSelectPanel/VBoxContainer/ArcherBtn.pressed.connect(func(): select_class("Archer", name_input.text.strip_edges()))
    
    # Connect Panel close buttons
    $GameUI/InventoryPanel/CloseBtn.pressed.connect(func(): inventory_panel.visible = false)
    $GameUI/CharacterPanel/CloseBtn.pressed.connect(func(): character_panel.visible = false)
    $GameUI/ElderDialogPanel/CloseBtn.pressed.connect(func(): elder_dialog_panel.visible = false)
    $GameUI/ShopPanel/CloseBtn.pressed.connect(func(): shop_panel.visible = false)
    $VictoryPanel/RestartBtn.pressed.connect(func(): get_tree().reload_current_scene())
    
    # Connect Toggle HUD buttons
    $GameUI/MenuButtons/BagBtn.pressed.connect(toggle_inventory)
    $GameUI/MenuButtons/CharBtn.pressed.connect(toggle_character)

    # Add volume toggle to MenuButtons
    var vol_btn = Button.new()
    vol_btn.text = "🔊"
    vol_btn.flat = true
    vol_btn.add_theme_font_size_override("font_size", 14)
    vol_btn.mouse_entered.connect(func(): tooltip_panel.visible = false)
    var muted = false
    vol_btn.pressed.connect(func():
        muted = not muted
        SoundManager.set_volume(0.0 if muted else 1.0)
        vol_btn.text = "🔇" if muted else "🔊"
    )
    $GameUI/MenuButtons.add_child(vol_btn)
    
    # Connect Hotbar potion buttons click
    $GameUI/Hotbar/ItemHP.pressed.connect(func(): use_potion_by_id("hp_potion"))
    $GameUI/Hotbar/ItemMP.pressed.connect(func(): use_potion_by_id("mp_potion"))

func _process(delta):
    if not game_ui_container.visible:
        return
        
    # Ticks cooldown overlays in real-time
    _update_cooldowns_display()
    
    # Sync target HP if target exists
    if GameManager.target != null and is_instance_valid(GameManager.target):
        if "hp" in GameManager.target:
            target_hp.value = GameManager.target.hp
            if GameManager.target.hp <= 0:
                target_frame.visible = false
        else:
            target_hp.value = target_hp.max_value

    # Potion and UI hotkeys
    if Input.is_action_just_pressed("use_hp_potion"):
        use_potion_by_id("hp_potion")
    if Input.is_action_just_pressed("use_mp_potion"):
        use_potion_by_id("mp_potion")
    if Input.is_action_just_pressed("toggle_inventory"):
        toggle_inventory()

func select_class(cls: String, player_name_str: String = "HeroePixel"):
    if player_name_str == "":
        player_name_str = "HeroePixel"
    GameManager.select_class(cls, player_name_str)
    class_select_panel.visible = false
    game_ui_container.visible = true

    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.set_physics_process(true)

    skill1_name_lbl.text = "1: " + GameManager.skills[0]["name"]
    skill2_name_lbl.text = "2: " + GameManager.skills[1]["name"]
    if GameManager.skills.size() > 2:
        skill3_name_lbl.text = "3: " + GameManager.skills[2]["name"]
    else:
        skill3_name_lbl.text = "3: Bloqueado"

func toggle_inventory():
    inventory_panel.visible = not inventory_panel.visible
    if inventory_panel.visible:
        update_inventory_ui()

func toggle_character():
    character_panel.visible = not character_panel.visible
    if character_panel.visible:
        update_character_ui()

func use_potion_by_id(item_id: String):
    for i in range(GameManager.inventory.size()):
        if GameManager.inventory[i]["id"] == item_id:
            GameManager.use_item(i)
            return
    GameManager.add_chat_msg("[Sistema]", "No te quedan pociones de ese tipo.", Color(1.0, 0.4, 0.4))

# Update Main HUD values
func update_player_hud():
    if not game_ui_container.visible: return
    
    var hp_ratio = float(GameManager.hp) / float(max(GameManager.max_hp, 1))
    var frame_idx = clamp(7 - int(hp_ratio * 7), 0, 7)
    hp_anim.frame = frame_idx
    
    mp_bar.max_value = GameManager.max_mp
    mp_bar.value = GameManager.mp
    mp_label.text = str(int(GameManager.mp)) + " / " + str(int(GameManager.max_mp))
    
    lvl_label.text = "Nivel " + str(GameManager.level) + "  Pts:" + str(GameManager.stat_points)
    name_label.text = GameManager.player_name + " (" + GameManager.player_class + ")"
    
    xp_bar.max_value = GameManager.xp_needed
    xp_bar.value = GameManager.xp
    
    gold_label.text = str(GameManager.gold) + " Oro"
    
    # Update potion counts in hotbar
    hp_pot_count.text = "x" + str(GameManager.get_item_count("hp_potion"))
    mp_pot_count.text = "x" + str(GameManager.get_item_count("mp_potion"))
    
    # Update skill 3 unlock status
    if GameManager.skills.size() > 2:
        skill3_name_lbl.text = "3: " + GameManager.skills[2]["name"]
    else:
        skill3_name_lbl.text = "3: Bloqueado (Lvl 3)"
        
    if character_panel.visible:
        update_character_ui()

func update_target_hud(new_target: Node):
    if new_target == null or not is_instance_valid(new_target) or not new_target.is_in_group("enemy") or new_target.is_dead:
        target_frame.visible = false
        return
        
    target_frame.visible = true
    target_name.text = new_target.monster_name
    target_hp.max_value = new_target.max_hp
    target_hp.value = new_target.hp
    target_lvl.text = "Lvl " + str(new_target.level)

func _update_cooldowns_display():
    # Skill 1 CD
    var cd1 = GameManager.skills[0]["current_cooldown"]
    skill_slot_1_cd.visible = cd1 > 0.0
    skill_slot_1_lbl.text = "%.1f" % cd1 if cd1 > 0.0 else ""
    
    # Skill 2 CD
    var cd2 = GameManager.skills[1]["current_cooldown"]
    skill_slot_2_cd.visible = cd2 > 0.0
    skill_slot_2_lbl.text = "%.1f" % cd2 if cd2 > 0.0 else ""
    
    # Skill 3 CD
    if GameManager.skills.size() > 2:
        var cd3 = GameManager.skills[2]["current_cooldown"]
        skill_slot_3_cd.visible = cd3 > 0.0
        skill_slot_3_lbl.text = "%.1f" % cd3 if cd3 > 0.0 else ""
    else:
        skill_slot_3_cd.visible = true
        skill_slot_3_lbl.text = ""

# Chat handling
func on_chat_received(sender: String, message: String, color: Color):
    chat_text.append_text("\n[color=#" + color.to_html(false) + "]" + sender + ":[/color] " + message)
    # Wait for layout updates, then scroll
    await get_tree().process_frame
    chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value

# Inventory Panel Rendering
func update_inventory_ui():
    # Clear grid
    for child in inventory_grid.get_children():
        child.queue_free()
        
    # Populate slots
    for i in range(GameManager.MAX_INVENTORY_SIZE):
        var slot_btn = Button.new()
        slot_btn.custom_minimum_size = Vector2(36, 36)
        slot_btn.add_theme_stylebox_override("normal", load_stylebox(Color(0.2, 0.2, 0.2, 0.8)))
        slot_btn.add_theme_stylebox_override("hover", load_stylebox(Color(0.3, 0.3, 0.3, 0.8)))
        
        if i < GameManager.inventory.size():
            var item = GameManager.inventory[i]
            # Draw icon using atlas texture
            var texture_rect = TextureRect.new()
            texture_rect.texture = load("res://Assets/Sprites/icons.png")
            texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
            # Define region mapping in atlas (icons are 32x32)
            var coord = item["icon_coord"]
            texture_rect.texture = AtlasTexture.new()
            texture_rect.texture.atlas = load("res://Assets/Sprites/icons.png")
            texture_rect.texture.region = Rect2(coord.x * 32, coord.y * 32, 32, 32)
            
            texture_rect.size = Vector2(28, 28)
            texture_rect.position = Vector2(4, 4)
            slot_btn.add_child(texture_rect)
            
            # Quantity label
            if item["quantity"] > 1:
                var q_label = Label.new()
                q_label.text = str(item["quantity"])
                q_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
                q_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
                q_label.add_theme_font_size_override("font_size", 8)
                q_label.add_theme_color_override("font_outline_color", Color.BLACK)
                q_label.add_theme_constant_override("outline_size", 2)
                q_label.size = Vector2(32, 32)
                q_label.position = Vector2(2, 2)
                slot_btn.add_child(q_label)
                
            # Rarity borders
            var rarity_color = get_rarity_color(item["rarity"])
            slot_btn.add_theme_stylebox_override("normal", load_stylebox(Color(0.15, 0.15, 0.15, 0.9), rarity_color))
            
            # Connect actions
            var idx = i
            slot_btn.pressed.connect(func(): GameManager.use_item(idx))
            slot_btn.mouse_entered.connect(func(): show_tooltip(item, slot_btn.global_position))
            slot_btn.mouse_exited.connect(hide_tooltip)
            
        inventory_grid.add_child(slot_btn)

func update_character_ui():
    char_class_lbl.text = GameManager.player_class
    char_lvl_lbl.text = str(GameManager.level)
    char_atk_lbl.text = str(GameManager.atk)
    char_def_lbl.text = str(GameManager.def)
    char_gold_lbl.text = str(GameManager.gold) + "g"

    setup_equipped_button(eq_weapon_btn, "weapon")
    setup_equipped_button(eq_armor_btn, "armor")
    setup_equipped_button(eq_shield_btn, "shield")

    _build_stat_alloc_ui()

func _build_stat_alloc_ui():
    var stats_box = $GameUI/CharacterPanel/StatsBox
    for child in stats_box.get_children():
        if child.has_meta("stat_row"):
            child.queue_free()

    var stats = [
        {"key": "str", "label": "FUE", "val": GameManager.str, "color": Color(1.0, 0.4, 0.4)},
        {"key": "dex", "label": "DES", "val": GameManager.dex, "color": Color(0.4, 1.0, 0.4)},
        {"key": "intel", "label": "INT", "val": GameManager.intel, "color": Color(0.4, 0.6, 1.0)},
        {"key": "vit", "label": "VIT", "val": GameManager.vit, "color": Color(1.0, 0.8, 0.4)},
    ]

    var points_label = stats_box.get_node("PointsLabel")
    points_label.text = "Puntos Disponibles: " + str(GameManager.stat_points)

    var y_off = 180
    for s in stats:
        var lbl = Label.new()
        lbl.set_meta("stat_row", true)
        lbl.text = s["label"] + ": " + str(s["val"])
        lbl.add_theme_color_override("font_color", s["color"])
        lbl.add_theme_font_size_override("font_size", 10)
        lbl.position = Vector2(10, y_off)
        lbl.size = Vector2(80, 20)
        stats_box.add_child(lbl)

        var plus_btn = Button.new()
        plus_btn.set_meta("stat_row", true)
        plus_btn.text = "+"
        plus_btn.add_theme_font_size_override("font_size", 12)
        plus_btn.custom_minimum_size = Vector2(24, 20)
        plus_btn.position = Vector2(100, y_off)
        plus_btn.size = Vector2(24, 20)
        var stat_key = s["key"]
        plus_btn.pressed.connect(func():
            GameManager.allocate_stat(stat_key)
            update_character_ui()
        )
        plus_btn.disabled = GameManager.stat_points <= 0
        stats_box.add_child(plus_btn)

        y_off += 24

func setup_equipped_button(btn: Button, slot: String):
    # Clear old children
    for child in btn.get_children():
        if child is TextureRect:
            child.queue_free()
            
    var item = GameManager.equipped[slot]
    btn.text = slot.capitalize()
    btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
    btn.add_theme_stylebox_override("normal", load_stylebox(Color(0.15, 0.15, 0.15, 0.8)))
    
    # Clear old connections safely
    if btn.is_connected("pressed", unequip_slot.bind(slot)):
        btn.pressed.disconnect(unequip_slot.bind(slot))
        
    # Disconnect any other hover events
    for conn in btn.mouse_entered.get_connections():
        btn.mouse_entered.disconnect(conn["callable"])
    for conn in btn.mouse_exited.get_connections():
        btn.mouse_exited.disconnect(conn["callable"])
        
    if item != null:
        btn.text = ""
        var texture_rect = TextureRect.new()
        texture_rect.texture = AtlasTexture.new()
        texture_rect.texture.atlas = load("res://Assets/Sprites/icons.png")
        var coord = item["icon_coord"]
        texture_rect.texture.region = Rect2(coord.x * 32, coord.y * 32, 32, 32)
        texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
        texture_rect.size = Vector2(28, 28)
        texture_rect.position = Vector2(4, 4)
        btn.add_child(texture_rect)
        
        # Rarity border
        var rc = get_rarity_color(item["rarity"])
        btn.add_theme_stylebox_override("normal", load_stylebox(Color(0.15, 0.15, 0.15, 0.9), rc))
        
        btn.pressed.connect(unequip_slot.bind(slot))
        btn.mouse_entered.connect(func(): show_tooltip(item, btn.global_position))
        btn.mouse_exited.connect(hide_tooltip)

func unequip_slot(slot: String):
    GameManager.unequip_item(slot)
    update_character_ui()

# Quest Tracker HUD rendering
func update_quest_tracker():
    var text = "[color=#ffcd75][b]MISIONES ACTIVAS[/b][/color]\n"
    if GameManager.active_quests.size() == 0:
        text += "\nNinguna misión activa.\nHabla con el Elder."
    else:
        for q_id in GameManager.active_quests:
            var q = GameManager.quests_db[q_id]
            var status = GameManager.active_quests[q_id]
            text += "\n[color=#73eff7]• " + q["title"] + "[/color]\n"
            text += "  " + q["description"] + "\n"
            var current_prog = status["progress"]
            var target_cnt = q["target_count"]
            
            if current_prog >= target_cnt:
                text += "  [color=#38b764]¡Objetivo Completo! (Listo)[/color]\n"
            else:
                var target_name_str = "Kills" if q["target_type"] == "kill" else GameManager.items_db[q["target_id"]]["name"]
                text += "  Progreso: [color=#ff7d57]" + str(current_prog) + "/" + str(target_cnt) + "[/color] " + target_name_str + "\n"
                
    quest_tracker_label.text = text
    
    # Dialogue panel update if currently talking to Elder
    if elder_dialog_panel.visible:
        open_elder_dialog()

# Tooltip helpers
func show_tooltip(item: Dictionary, pos: Vector2):
    tooltip_panel.visible = true
    var screen_size = get_viewport().get_visible_rect().size
    var tip_x = clamp(pos.x - 120, 10, screen_size.x - 250)
    var tip_y = clamp(pos.y - 170, 10, screen_size.y - 170)
    tooltip_panel.global_position = Vector2(tip_x, tip_y)
    
    var r_name = item["rarity"].capitalize()
    var r_color = get_rarity_color(item["rarity"]).to_html(false)
    var text = "[color=#" + r_color + "][b]" + item["name"] + " (" + r_name + ")[/b][/color]\n"
    text += "[color=#94b0c2]" + item["description"] + "[/color]\n"
    
    if "stat_bonus" in item:
        text += "\n[color=#a7f070]Estadísticas:[/color]"
        for stat in item["stat_bonus"]:
            text += "\n  +" + str(item["stat_bonus"][stat]) + " " + stat.to_upper()
            
    if "class_req" in item:
        text += "\nClase: " + item["class_req"]
        
    text += "\n[color=#ffcd75]Valor: " + str(item["value"]) + " Oro[/color]"
    tooltip_lbl.text = text

func hide_tooltip():
    tooltip_panel.visible = false

# NPC Interaction Panels
func open_elder_dialog():
    elder_dialog_panel.visible = true
    
    # Clear dialogue buttons
    for child in elder_buttons_container.get_children():
        child.queue_free()
        
    # Check Elder quest progression sequence: quest_slime -> quest_goblin -> quest_boss
    # Select text based on quest state
    var main_dialogue = "Saludos, joven viajero de clase " + GameManager.player_class + ". "
    
    var available_quest = ""
    
    if not GameManager.active_quests.has("quest_slime") and not GameManager.completed_quests.has("quest_slime"):
        main_dialogue += "Nuestra aldea está siendo atacada por Slimes pegajosos. ¿Nos ayudarías a exterminar 3 slimes en las afueras?"
        available_quest = "quest_slime"
    elif GameManager.active_quests.has("quest_slime"):
        if GameManager.can_complete_quest("quest_slime"):
            main_dialogue += "¡Increíble! Has derrotado a los slimes. Aquí tienes tu recompensa: tu nueva arma especializada de Hierro."
            add_quest_action_button("Completar Misión: Plaga de Slimes", func(): GameManager.complete_quest("quest_slime"))
        else:
            main_dialogue += "Aún veo slimes rondando las praderas del Sur. Vuelve cuando hayas derrotado a 3. (Progreso: " + str(GameManager.active_quests["quest_slime"]["progress"]) + "/3)"
    elif not GameManager.active_quests.has("quest_goblin") and not GameManager.completed_quests.has("quest_goblin"):
        main_dialogue += "¡Gracias por salvar las praderas! Pero ahora un peligro mayor acecha. Los Goblins del bosque están asaltando a los mercaderes. Tráeme 3 Garras de Goblin como prueba de su derrota."
        available_quest = "quest_goblin"
    elif GameManager.active_quests.has("quest_goblin"):
        if GameManager.can_complete_quest("quest_goblin"):
            main_dialogue += "¡Excelente trabajo! Has asustado a los goblins. Te otorgo esta armadura especializada."
            add_quest_action_button("Completar Misión: Garras Goblin", func(): GameManager.complete_quest("quest_goblin"))
        else:
            main_dialogue += "Necesito 3 Garras de Goblin para comprobar la seguridad del bosque. Búscalos en el área boscosa del Este. (Progreso: " + str(GameManager.active_quests["quest_goblin"]["progress"]) + "/3)"
    elif not GameManager.active_quests.has("quest_boss") and not GameManager.completed_quests.has("quest_boss"):
        main_dialogue += "Viajero, te has vuelto muy fuerte. El Señor Oscuro (Demon Boss) ha despertado en el Norte de las ruinas. Entra a su arena a través del portal y destruye su Corazón de Demonio para salvarnos a todos de la destrucción."
        available_quest = "quest_boss"
    elif GameManager.active_quests.has("quest_boss"):
        if GameManager.can_complete_quest("quest_boss"):
            main_dialogue += "¡POR DIOSES DEL PIXEL! ¡Has derrotado al Señor Oscuro y recuperado su Corazón palpitante! ¡Eres el héroe legendario que salvó nuestro mundo!"
            add_quest_action_button("¡Entregar Corazón de Demonio!", func(): GameManager.complete_quest("quest_boss"))
        else:
            main_dialogue += "La maldad del Señor Oscuro se expande. Cruza el portal en la zona norte, derrótalo y arrebata su Corazón de Demonio."
    else:
        main_dialogue += "¡Has salvado al mundo del Señor Oscuro! Eres una leyenda viviente. Puedes seguir explorando y cazando monstruos libremente."
        
    elder_text.text = main_dialogue
    
    if available_quest != "":
        var q_id = available_quest
        add_quest_action_button("Aceptar Misión: " + GameManager.quests_db[q_id]["title"], func():
            GameManager.accept_quest(q_id)
            open_elder_dialog()
        )
        
    # Always add a goodbye button
    var bye_btn = Button.new()
    bye_btn.text = "Adiós"
    bye_btn.pressed.connect(func(): elder_dialog_panel.visible = false)
    elder_buttons_container.add_child(bye_btn)

func add_quest_action_button(text: String, action_callable: Callable):
    var btn = Button.new()
    btn.text = text
    btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
    btn.pressed.connect(action_callable)
    elder_buttons_container.add_child(btn)

# Merchant Shop Panel Rendering
func open_merchant_shop():
    shop_panel.visible = true
    update_shop_ui()

func update_shop_ui():
    # Clear lists
    for child in shop_buy_container.get_children():
        child.queue_free()
    for child in shop_sell_container.get_children():
        child.queue_free()
        
    # Populate Buy Catalogue
    var buy_items = ["hp_potion", "mp_potion"]
    # Add class weapon/armor/shield
    if GameManager.player_class == "Warrior":
        buy_items.append("iron_sword")
        buy_items.append("plate_armor")
        buy_items.append("steel_shield")
    elif GameManager.player_class == "Mage":
        buy_items.append("fire_staff")
        buy_items.append("sage_robe")
    elif GameManager.player_class == "Archer":
        buy_items.append("hunter_bow")
        buy_items.append("ranger_tunic")
        
    # Merchant also offers quest_skeleton!
    var merchant_dialogue = "¡Hola viajero! Compro lo que no sirva y vendo excelentes consumibles y equipamiento militar. ¿Qué deseas?"
    
    # Add quest offer to merchant buy block if not completed/active
    if not GameManager.active_quests.has("quest_skeleton") and not GameManager.completed_quests.has("quest_skeleton"):
        var q_btn = Button.new()
        q_btn.text = "[Misión] Limpieza del Cementerio"
        q_btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
        q_btn.pressed.connect(func():
            GameManager.accept_quest("quest_skeleton")
            update_shop_ui()
        )
        shop_buy_container.add_child(q_btn)
    elif GameManager.active_quests.has("quest_skeleton"):
        var q_btn = Button.new()
        if GameManager.can_complete_quest("quest_skeleton"):
            q_btn.text = "[Misión] ¡Entregar Misión Cementerio!"
            q_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
            q_btn.pressed.connect(func():
                GameManager.complete_quest("quest_skeleton")
                update_shop_ui()
            )
        else:
            q_btn.text = "[Misión] Cementerio (%d/5 Esqueletos)" % GameManager.active_quests["quest_skeleton"]["progress"]
            q_btn.disabled = true
        shop_buy_container.add_child(q_btn)

    for item_id in buy_items:
        var item = GameManager.items_db[item_id]
        var buy_btn = Button.new()
        buy_btn.custom_minimum_size = Vector2(0, 28)
        buy_btn.size_flags_horizontal = Control.SIZE_FILL
        buy_btn.add_theme_font_size_override("font_size", 9)
        buy_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

        var icon_rect = TextureRect.new()
        icon_rect.texture = AtlasTexture.new()
        icon_rect.texture.atlas = load("res://Assets/Sprites/icons.png")
        var coord = item["icon_coord"]
        icon_rect.texture.region = Rect2(coord.x * 32, coord.y * 32, 32, 32)
        icon_rect.custom_minimum_size = Vector2(24, 24)
        icon_rect.position = Vector2(4, 2)
        buy_btn.add_child(icon_rect)

        var name_lbl = Label.new()
        name_lbl.text = item["name"]
        name_lbl.add_theme_font_size_override("font_size", 9)
        name_lbl.position = Vector2(32, 4)
        buy_btn.add_child(name_lbl)

        var price_lbl = Label.new()
        price_lbl.text = str(item["value"]) + "g"
        price_lbl.add_theme_font_size_override("font_size", 8)
        price_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
        price_lbl.position = Vector2(140, 4)
        buy_btn.add_child(price_lbl)

        buy_btn.pressed.connect(func():
            if GameManager.gold >= item["value"]:
                var ok = GameManager.add_item_to_inventory(item_id)
                if ok:
                    GameManager.gold -= item["value"]
                    SoundManager.play_sfx("equip")
                    GameManager.player_stats_changed.emit()
                    update_shop_ui()
            else:
                GameManager.add_chat_msg("[Mercader]", "¡No tienes suficiente oro!", Color(1.0, 0.4, 0.4))
        )
        shop_buy_container.add_child(buy_btn)
        
    # Populate SELL items (from current inventory)
    if GameManager.inventory.size() == 0:
        var lbl = Label.new()
        lbl.text = "Inventario vacío."
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.add_theme_font_size_override("font_size", 10)
        shop_sell_container.add_child(lbl)
    else:
        for i in range(GameManager.inventory.size()):
            var item = GameManager.inventory[i]
            var sell_val = int(item["value"] * 0.6)

            var sell_btn = Button.new()
            sell_btn.custom_minimum_size = Vector2(0, 28)
            sell_btn.size_flags_horizontal = Control.SIZE_FILL
            sell_btn.add_theme_font_size_override("font_size", 9)
            sell_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

            var icon_rect = TextureRect.new()
            icon_rect.texture = AtlasTexture.new()
            icon_rect.texture.atlas = load("res://Assets/Sprites/icons.png")
            var coord = item["icon_coord"]
            icon_rect.texture.region = Rect2(coord.x * 32, coord.y * 32, 32, 32)
            icon_rect.custom_minimum_size = Vector2(24, 24)
            icon_rect.position = Vector2(4, 2)
            sell_btn.add_child(icon_rect)

            var name_lbl = Label.new()
            var qty_str = " x%d" % item["quantity"] if item["quantity"] > 1 else ""
            name_lbl.text = item["name"] + qty_str
            name_lbl.add_theme_font_size_override("font_size", 9)
            name_lbl.position = Vector2(32, 4)
            sell_btn.add_child(name_lbl)

            var price_lbl = Label.new()
            price_lbl.text = "+" + str(sell_val) + "g"
            price_lbl.add_theme_font_size_override("font_size", 8)
            price_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
            price_lbl.position = Vector2(140, 4)
            sell_btn.add_child(price_lbl)

            var idx = i
            sell_btn.pressed.connect(func():
                GameManager.gold += sell_val
                GameManager.remove_item_from_inventory(item["id"], 1)
                SoundManager.play_sfx("equip")
                GameManager.player_stats_changed.emit()
                update_shop_ui()
            )
            shop_sell_container.add_child(sell_btn)

# Styling Helpers
func load_stylebox(bg_color: Color, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
    var style = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.corner_radius_top_left = 3
    style.corner_radius_top_right = 3
    style.corner_radius_bottom_right = 3
    style.corner_radius_bottom_left = 3
    if border_color != Color.TRANSPARENT:
        style.border_width_left = 1
        style.border_width_top = 1
        style.border_width_right = 1
        style.border_width_bottom = 1
        style.border_color = border_color
    return style

func get_rarity_color(rarity: String) -> Color:
    match rarity:
        "common": return Color(0.6, 0.6, 0.6) # Gray
        "rare": return Color(0.2, 0.5, 1.0) # Blue
        "epic": return Color(0.6, 0.2, 0.9) # Purple
        "legendary": return Color(1.0, 0.6, 0.0) # Orange/Gold
        _: return Color.WHITE

func _on_combo_changed(count: int):
    if count == 0:
        combo_label.visible = false
        return

    combo_label.visible = true
    var text = ""
    match count:
        1: text = "HIT x1"
        2: text = "COMBO x2!"
        3: text = "COMBO x3!!"
    combo_label.text = text

    var tween = create_tween()
    tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.08)
    tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.12)

func on_victory():
    victory_panel.visible = true
    SoundManager.play_sfx("quest_complete")
