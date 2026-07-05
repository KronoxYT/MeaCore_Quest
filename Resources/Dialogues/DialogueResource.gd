class_name DialogueResource
extends Resource

enum NodeType { DIALOGUE, CHOICE, ACTION, QUEST_START, QUEST_END, END }

@export var id: String
@export var npc_id: String
@export var npc_display_name: String
@export var portrait: Texture2D

@export_group("Content")
@export var text: String
@export var node_type: NodeType = NodeType.DIALOGUE

@export_group("Options (solo para nodo tipo CHOICE)")
@export var options: Array[Dictionary] = []

@export_group("Quest Integration")
@export var quest_to_start: String = ""
@export var quest_to_complete: String = ""

@export_group("Actions")
@export var give_items: Array[Dictionary] = []
@export var take_gold: int = 0
@export var reputation_effects: Dictionary = {}
