extends CharacterBody2D

# NPC configuration
@export var npc_id: String = "elder" # elder, merchant

var npc_name: String = ""
var is_player_near: bool = false
var player_ref: Node = null

# Animation spritesheet coordinates
var char_x_offset: int = 0
var char_y_offset: int = 128 # NPCs are on Row 3 and 4 (cy = 1)
var current_dir: int = 0 # 0: Down, 1: Up, 2: Left, 3: Right

# UI components
@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel
@onready var quest_marker: Label = $QuestMarker

func _ready():
	add_to_group("npc")
	input_pickable = true
	
	# Connect mouse interaction
	input_pickable = true
	
	setup_npc_graphics()
	
	# Connect to GameManager signals to update quest markers when anything changes
	GameManager.quest_log_changed.connect(update_quest_marker)
	GameManager.player_stats_changed.connect(update_quest_marker)
	update_quest_marker()

func setup_npc_graphics():
	if npc_id == "elder":
		npc_name = "Elder Sabio"
		# Elder is at cx = 0, cy = 1 (x: 0, y: 128)
		char_x_offset = 0
	elif npc_id == "merchant":
		npc_name = "Comerciante Silas"
		# Merchant is at cx = 1, cy = 1 (x: 96, y: 128)
		char_x_offset = 96
		
	name_label.text = npc_name
	update_sprite_rect()

func _physics_process(delta):
	# Redraw target circle if selected
	queue_redraw()
	
	# Check if player is near
	if player_ref == null:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
			
	if player_ref != null:
		var dist = global_position.distance_to(player_ref.global_position)
		var was_near = is_player_near
		is_player_near = dist < 45.0
		
		# Auto-interact help message
		if is_player_near and not was_near:
			GameManager.add_chat_msg("[Elder]", "Salomón te saluda. Haz click en mí para hablar.", Color(0.9, 0.9, 0.4))
			
		# Turn to face player if near
		if is_player_near:
			var dir_vec = (player_ref.global_position - global_position).normalized()
			if abs(dir_vec.x) > abs(dir_vec.y):
				current_dir = 3 if dir_vec.x > 0 else 2
			else:
				current_dir = 0 if dir_vec.y > 0 else 1
			update_sprite_rect()
		elif was_near:
			# Reset facing down
			current_dir = 0
			update_sprite_rect()

func update_sprite_rect():
	# Frame 0 is Idle (NPCs don't walk)
	var frame_x = char_x_offset + 0 * 32
	var frame_y = char_y_offset + current_dir * 32
	sprite.region_rect = Rect2(frame_x, frame_y, 32, 32)

func update_quest_marker():
	# Determine quest marker based on player quest state
	# Yellow '!' = Quest available
	# Gray '?' = Quest active but not complete
	# Yellow '?' = Quest complete and ready to hand in
	
	var marker_text = ""
	var marker_color = Color(1.0, 0.9, 0.1) # Yellow-gold
	
	if npc_id == "elder":
		# Elder quests: quest_slime -> quest_goblin -> quest_boss
		if not GameManager.active_quests.has("quest_slime") and not GameManager.completed_quests.has("quest_slime"):
			marker_text = "!"
		elif GameManager.active_quests.has("quest_slime"):
			if GameManager.can_complete_quest("quest_slime"):
				marker_text = "?"
			else:
				marker_text = "?"
				marker_color = Color(0.6, 0.6, 0.6) # Gray active
		elif not GameManager.active_quests.has("quest_goblin") and not GameManager.completed_quests.has("quest_goblin"):
			marker_text = "!"
		elif GameManager.active_quests.has("quest_goblin"):
			if GameManager.can_complete_quest("quest_goblin"):
				marker_text = "?"
			else:
				marker_text = "?"
				marker_color = Color(0.6, 0.6, 0.6)
		elif not GameManager.active_quests.has("quest_boss") and not GameManager.completed_quests.has("quest_boss"):
			marker_text = "!"
		elif GameManager.active_quests.has("quest_boss"):
			if GameManager.can_complete_quest("quest_boss"):
				marker_text = "?"
			else:
				marker_text = "?"
				marker_color = Color(0.6, 0.6, 0.6)
				
	elif npc_id == "merchant":
		# Merchant quests: quest_skeleton
		if not GameManager.active_quests.has("quest_skeleton") and not GameManager.completed_quests.has("quest_skeleton"):
			marker_text = "!"
		elif GameManager.active_quests.has("quest_skeleton"):
			if GameManager.can_complete_quest("quest_skeleton"):
				marker_text = "?"
			else:
				marker_text = "?"
				marker_color = Color(0.6, 0.6, 0.6)
				
	quest_marker.text = marker_text
	quest_marker.add_theme_color_override("font_color", marker_color)
	quest_marker.visible = marker_text != ""

# Interaction trigger on click
func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GameManager.target = self
		if is_player_near:
			interact()
		else:
			GameManager.add_chat_msg("[Sistema]", "¡Estás demasiado lejos para hablar con " + npc_name + "!", Color(1.0, 0.6, 0.3))
		get_viewport().set_input_as_handled()

func interact():
	# Trigger HUD dialogs
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		if npc_id == "elder":
			hud.open_elder_dialog()
		elif npc_id == "merchant":
			hud.open_merchant_shop()

# Draw target circle if selected
func _draw():
	if GameManager and GameManager.target == self:
		draw_arc(Vector2(0, 4), 16.0, 0, PI * 2, 16, Color(0.2, 0.8, 1.0), 1.5)
