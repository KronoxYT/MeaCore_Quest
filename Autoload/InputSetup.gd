extends Node

func _ready():
	_setup_action("dash", KEY_SHIFT)
	_setup_action("cycle_target", KEY_TAB)
	_setup_action("basic_attack", KEY_SPACE)
	# WASD movement
	_setup_action("move_up", KEY_W, KEY_UP)
	_setup_action("move_down", KEY_S, KEY_DOWN)
	_setup_action("move_left", KEY_A, KEY_LEFT)
	_setup_action("move_right", KEY_D, KEY_RIGHT)
	# Skill keys
	_setup_action("skill_1", KEY_1, KEY_KP_1)
	_setup_action("skill_2", KEY_2, KEY_KP_2)
	_setup_action("skill_3", KEY_3, KEY_KP_3)
	# Potion keys
	_setup_action("use_hp_potion", KEY_4, KEY_KP_4)
	_setup_action("use_mp_potion", KEY_5, KEY_KP_5)
	# Interaction and UI
	_setup_action("interact", KEY_E)
	_setup_action("toggle_inventory", KEY_R)

func _setup_action(name: String, key1: Key, key2: Key = KEY_NONE):
	if InputMap.has_action(name):
		InputMap.erase_action(name)
	InputMap.add_action(name)
	
	var event = InputEventKey.new()
	event.physical_keycode = key1
	InputMap.action_add_event(name, event)
	
	if key2 != KEY_NONE:
		var event2 = InputEventKey.new()
		event2.physical_keycode = key2
		InputMap.action_add_event(name, event2)
