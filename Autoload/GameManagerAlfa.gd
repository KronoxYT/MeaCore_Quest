extends Node

# Signals
signal player_stats_changed
signal inventory_changed
signal quest_log_changed
signal target_changed(new_target)
signal chat_received(sender, message, channel_color)
signal show_damage_number(position, text, color)
signal play_effect(effect_name, position)
signal game_victory
signal combo_changed(count)

# Constants
const MAX_INVENTORY_SIZE = 24

# Player Data
var player_name: String = "HeroePixel"
var player_class: String = "" # Warrior, Mage, Archer
var level: int = 1
var xp: int = 0
var xp_needed: int = 100
var hp: float = 50.0
var max_hp: float = 50.0
var mp: float = 20.0
var max_mp: float = 20.0
var gold: int = 50
var base_atk: int = 5
var base_def: int = 2
var atk: int = 5
var def: int = 2
var atk_speed: float = 1.0
var current_combo: int = 0

# Stat Allocation
var stat_points: int = 0
var str: int = 5
var dex: int = 5
var intel: int = 5
var vit: int = 5

# Target System
var _target: Node = null
var target: Node = null :
	get(): return _target
	set(val):
		_target = val
		target_changed.emit(_target)

# Skills List
var skills: Array = []

# Inventory and Equipment
var inventory: Array = [] # Array of item dictionaries
var equipped: Dictionary = {
	"weapon": null,
	"armor": null,
	"shield": null
}

# Quests Data
# active_quests: { "quest_id": { "stage": 0, "progress": 0 } }
var active_quests: Dictionary = {}
var completed_quests: Dictionary = {}

# Items Database
var items_db = {
	"hp_potion": {
		"id": "hp_potion",
		"name": "Poción de Vida",
		"icon_coord": Vector2i(0, 0),
		"type": "consumable",
		"rarity": "common",
		"value": 10,
		"effect": "heal_hp",
		"power": 35.0,
		"description": "Restaura 35 Puntos de Vida."
	},
	"mp_potion": {
		"id": "mp_potion",
		"name": "Poción de Maná",
		"icon_coord": Vector2i(1, 0),
		"type": "consumable",
		"rarity": "common",
		"value": 10,
		"effect": "heal_mp",
		"power": 20.0,
		"description": "Restaura 20 Puntos de Maná."
	},
	"rusty_sword": {
		"id": "rusty_sword",
		"name": "Espada Oxidada",
		"icon_coord": Vector2i(3, 0),
		"type": "weapon",
		"rarity": "common",
		"value": 15,
		"stat_bonus": {"atk": 4},
		"class_req": "Warrior",
		"description": "Una espada vieja. Mejor que usar los puños."
	},
	"app_staff": {
		"id": "app_staff",
		"name": "Báculo de Aprendiz",
		"icon_coord": Vector2i(0, 1),
		"type": "weapon",
		"rarity": "common",
		"value": 15,
		"stat_bonus": {"atk": 4},
		"class_req": "Mage",
		"description": "Un báculo de madera con una gema pequeña."
	},
	"short_bow": {
		"id": "short_bow",
		"name": "Arco Simple",
		"icon_coord": Vector2i(1, 1),
		"type": "weapon",
		"rarity": "common",
		"value": 15,
		"stat_bonus": {"atk": 4},
		"class_req": "Archer",
		"description": "Arco de madera tallada, ligero y básico."
	},
	"iron_sword": {
		"id": "iron_sword",
		"name": "Espada de Hierro",
		"icon_coord": Vector2i(2, 1),
		"type": "weapon",
		"rarity": "rare",
		"value": 120,
		"stat_bonus": {"atk": 12},
		"class_req": "Warrior",
		"description": "Espada de acero forjado bastante robusta."
	},
	"fire_staff": {
		"id": "fire_staff",
		"name": "Báculo de Fuego",
		"icon_coord": Vector2i(3, 1),
		"type": "weapon",
		"rarity": "rare",
		"value": 120,
		"stat_bonus": {"atk": 12},
		"class_req": "Mage",
		"description": "Báculo de madera de fresno que irradia calor."
	},
	"hunter_bow": {
		"id": "hunter_bow",
		"name": "Arco de Cazador",
		"icon_coord": Vector2i(0, 2),
		"type": "weapon",
		"rarity": "rare",
		"value": 120,
		"stat_bonus": {"atk": 12},
		"class_req": "Archer",
		"description": "Arco curvo reforzado con garras de bestia."
	},
	"plate_armor": {
		"id": "plate_armor",
		"name": "Armadura de Placas",
		"icon_coord": Vector2i(1, 2),
		"type": "armor",
		"rarity": "rare",
		"value": 180,
		"stat_bonus": {"def": 8, "max_hp": 30},
		"class_req": "Warrior",
		"description": "Protección de metal templado pesada pero segura."
	},
	"sage_robe": {
		"id": "sage_robe",
		"name": "Toga de Sabio",
		"icon_coord": Vector2i(2, 2),
		"type": "armor",
		"rarity": "rare",
		"value": 180,
		"stat_bonus": {"def": 3, "max_mp": 40},
		"class_req": "Mage",
		"description": "Túnica bendecida que amplifica la capacidad mágica."
	},
	"ranger_tunic": {
		"id": "ranger_tunic",
		"name": "Túnica de Explorador",
		"icon_coord": Vector2i(3, 2),
		"type": "armor",
		"rarity": "rare",
		"value": 180,
		"stat_bonus": {"def": 5, "max_hp": 15, "max_mp": 15},
		"class_req": "Archer",
		"description": "Túnica ligera de cuero tintado verde bosque."
	},
	"steel_shield": {
		"id": "steel_shield",
		"name": "Escudo de Acero",
		"icon_coord": Vector2i(3, 3),
		"type": "shield",
		"rarity": "rare",
		"value": 90,
		"stat_bonus": {"def": 6, "max_hp": 15},
		"class_req": "Warrior",
		"description": "Un escudo de acero con emblemas grabados."
	},
	"slime_core": {
		"id": "slime_core",
		"name": "Núcleo de Slime",
		"icon_coord": Vector2i(0, 3),
		"type": "quest",
		"rarity": "common",
		"value": 5,
		"description": "Gema viscosa y translúcida extraída de un Slime."
	},
	"wolf_claw": {
		"id": "wolf_claw",
		"name": "Garra de Lobo",
		"icon_coord": Vector2i(1, 3),
		"type": "quest",
		"rarity": "common",
		"value": 8,
		"description": "Garra afilada obtenida de los Goblins."
	},
	"demon_heart": {
		"id": "demon_heart",
		"name": "Corazón de Demonio",
		"icon_coord": Vector2i(2, 3),
		"type": "quest",
		"rarity": "legendary",
		"value": 1000,
		"description": "El ardiente corazón del Rey Demonio. ¡Poder puro!"
	}
}

# Quests Database
var quests_db = {
	"quest_slime": {
		"id": "quest_slime",
		"title": "Misión: Plaga de Slimes",
		"description": "Derrota a 3 Slimes en la pradera para ayudar a la aldea.",
		"target_type": "kill",
		"target_id": "slime",
		"target_count": 3,
		"gold_reward": 50,
		"xp_reward": 80,
		"item_reward": "iron_sword", # Will adapt based on class: iron_sword, fire_staff, hunter_bow
		"reward_description": "Arma Especializada de Hierro (Tier 2)"
	},
	"quest_goblin": {
		"id": "quest_goblin",
		"title": "Misión: Garras Goblin",
		"description": "Recolecta 3 Garras de Goblin de la zona boscosa.",
		"target_type": "collect",
		"target_id": "wolf_claw",
		"target_count": 3,
		"gold_reward": 100,
		"xp_reward": 150,
		"item_reward": "plate_armor", # Will adapt: plate_armor, sage_robe, ranger_tunic
		"reward_description": "Armadura Especializada (Tier 2)"
	},
	"quest_skeleton": {
		"id": "quest_skeleton",
		"title": "Misión: Limpieza de Cementerio",
		"description": "Elimina a 5 Esqueletos que merodean el norte del mapa.",
		"target_type": "kill",
		"target_id": "skeleton",
		"target_count": 5,
		"gold_reward": 200,
		"xp_reward": 300,
		"item_reward": "steel_shield", # Warrior shield or hp/mp potions for others
		"reward_description": "Escudo de Acero (o Pociones)"
	},
	"quest_boss": {
		"id": "quest_boss",
		"title": "Misión Final: El Señor Oscuro",
		"description": "Entra a la Arena del Demon Boss en el portal del Norte, derrótalo y consigue su corazón.",
		"target_type": "collect",
		"target_id": "demon_heart",
		"target_count": 1,
		"gold_reward": 1000,
		"xp_reward": 1000,
		"item_reward": "",
		"reward_description": "¡Salva el Mundo Pixelado!"
	}
}

# Chat Simulation Variables
var chat_timer: Timer
var chat_names = [
	"GamerPro99", "xX_Legolas_Xx", "ShadowNinja", "Kira_RP", "SlayerGod", 
	"ManaWaster", "Pikachu_Lover", "NoobMaster69", "LootGoblin", "GandalfThePink",
	"PixelWarrior", "TornadoSwordsman", "BowString", "ChurroMaster", "TacoRico"
]
var chat_phrases = [
	"¿Alguien para farmear slimes en la entrada?",
	"Vendo [Gel de Slime] a 3g la unidad. PM me!",
	"¡El Boss de nivel 5 me mató de un solo golpe! T_T",
	"Oigan, ¿cómo se equipan las armas? Ah, doble click.",
	"¡Acabo de subir a lvl 3! ¡Síiii!",
	"Busco grupo para Esqueletos en el norte.",
	"Alguien sabe dónde está el Elder de las misiones?",
	"¡Este juego está genial! El PixelArt está chulísimo.",
	"¡¡Aviso!! El Demon Lord está activo en el portal del Norte.",
	"¿El mago tiene curación o solo daño?",
	"¡Compro pociones baratas! Estoy seco de oro.",
	"Lag? O es mi conexión?",
	"¡Qué buena música! /dance",
	"Se busca healer para mazmorra!! Ah espera, es single player xd",
	"Ocupen la habilidad 2, hace un montón de daño crítico."
]

func _ready():
	chat_timer = Timer.new()
	chat_timer.wait_time = randf_range(8.0, 20.0)
	chat_timer.one_shot = false
	chat_timer.autostart = true
	chat_timer.timeout.connect(_on_chat_timer_timeout)
	add_child(chat_timer)

	set_process(true)

	call_deferred("add_chat_msg", "[Sistema]", "¡Bienvenido a Pixel MMORPG Simulator (MVP 1.0)! Habla con el Elder en la plaza para tu primera misión.", Color(1.0, 0.8, 0.2))

var _regen_timer: float = 0.0

func _process(delta):
	if player_class == "" or hp <= 0:
		return
	_regen_timer += delta
	if _regen_timer >= 5.0:
		_regen_timer = 0.0
		if hp < max_hp:
			hp = min(hp + 5.0, max_hp)
			player_stats_changed.emit()
		if mp < max_mp:
			mp = min(mp + 3.0, max_mp)
			player_stats_changed.emit()

func select_class(selected: String, player_name_str: String = "HeroePixel"):
	player_name = player_name_str
	player_class = selected
	stat_points = 3
	inventory.clear()
	equipped = {"weapon": null, "armor": null, "shield": null}

	if player_class == "Warrior":
		max_hp = 65.0
		hp = 65.0
		max_mp = 15.0
		mp = 15.0
		base_atk = 6
		base_def = 4
		atk_speed = 1.1
		str = 8; dex = 4; intel = 3; vit = 7
		add_item_to_inventory("rusty_sword")
		add_item_to_inventory("hp_potion", 3)
		add_item_to_inventory("mp_potion", 1)
		skills = [
			{"name": "Ataque Básico", "mp_cost": 0, "cooldown": 1.0, "current_cooldown": 0.0, "multiplier": 1.0, "effect": "atk_melee"},
			{"name": "Golpe Heroico", "mp_cost": 4, "cooldown": 4.0, "current_cooldown": 0.0, "multiplier": 1.8, "effect": "atk_slash"}
		]
	elif player_class == "Mage":
		max_hp = 40.0
		hp = 40.0
		max_mp = 40.0
		mp = 40.0
		base_atk = 8
		base_def = 1
		atk_speed = 1.3
		str = 3; dex = 4; intel = 9; vit = 4
		add_item_to_inventory("app_staff")
		add_item_to_inventory("hp_potion", 2)
		add_item_to_inventory("mp_potion", 3)
		skills = [
			{"name": "Disparo Mágico", "mp_cost": 0, "cooldown": 1.2, "current_cooldown": 0.0, "multiplier": 0.8, "effect": "atk_spell"},
			{"name": "Bola de Fuego", "mp_cost": 8, "cooldown": 5.0, "current_cooldown": 0.0, "multiplier": 2.2, "effect": "atk_fireball"}
		]
	elif player_class == "Archer":
		max_hp = 50.0
		hp = 50.0
		max_mp = 20.0
		mp = 20.0
		base_atk = 7
		base_def = 2
		atk_speed = 0.9
		str = 4; dex = 9; intel = 3; vit = 5
		add_item_to_inventory("short_bow")
		add_item_to_inventory("hp_potion", 2)
		add_item_to_inventory("mp_potion", 2)
		skills = [
			{"name": "Disparo Rápido", "mp_cost": 0, "cooldown": 0.8, "current_cooldown": 0.0, "multiplier": 0.9, "effect": "atk_bow"},
			{"name": "Flecha Tóxica", "mp_cost": 5, "cooldown": 5.0, "current_cooldown": 0.0, "multiplier": 1.4, "effect": "atk_poison"}
		]

	for i in range(inventory.size()):
		if inventory[i]["type"] == "weapon":
			equip_item(i)
			break

	recalculate_stats()
	player_stats_changed.emit()
	inventory_changed.emit()

	add_chat_msg("[Sistema]", "Bienvenido, " + player_name + ". Has entrado como " + player_class + ". ¡Mucha suerte!", Color(0.2, 1.0, 0.4))

func allocate_stat(stat: String):
	if stat_points <= 0:
		return
	match stat:
		"str": str += 1
		"dex": dex += 1
		"intel": intel += 1
		"vit": vit += 1
		_: return
	stat_points -= 1
	recalculate_stats()
	player_stats_changed.emit()

# Recalculate stats based on level and equipment
func recalculate_stats():
	var lvl_bonus = level - 1

	var base_max_hp = 50.0 + vit * 5.0 + lvl_bonus * 5.0
	var base_max_mp = 20.0 + intel * 3.0 + lvl_bonus * 2.0
	var total_atk = base_atk + str * 1 + lvl_bonus * 1
	var total_def = base_def + vit * 1 + lvl_bonus * 1

	atk_speed = max(0.5, 1.0 - dex * 0.01)

	for slot in equipped:
		var eq_item = equipped[slot]
		if eq_item != null and "stat_bonus" in eq_item:
			for stat in eq_item["stat_bonus"]:
				var val = eq_item["stat_bonus"][stat]
				if stat == "atk": total_atk += val
				elif stat == "def": total_def += val
				elif stat == "max_hp": base_max_hp += val
				elif stat == "max_mp": base_max_mp += val

	var hp_ratio = hp / max_hp if max_hp > 0 else 1.0
	var mp_ratio = mp / max_mp if max_mp > 0 else 1.0

	atk = total_atk
	def = total_def
	max_hp = base_max_hp
	max_mp = base_max_mp

	hp = max(1.0, hp_ratio * max_hp) if hp > 0 else 0.0
	mp = min(mp_ratio * max_mp, max_mp)

	player_stats_changed.emit()

func add_xp(amount: int):
	xp += amount
	add_chat_msg("[Sistema]", "¡Obtienes +" + str(amount) + " XP!", Color(0.8, 0.8, 1.0))
	if xp >= xp_needed:
		level_up()
	player_stats_changed.emit()

func level_up():
	xp -= xp_needed
	level += 1
	xp_needed = int(xp_needed * 1.5)
	stat_points += 3
	
	# Level up unlocks skills
	if level == 3:
		if player_class == "Warrior":
			skills.append({"name": "Torbellino", "mp_cost": 8, "cooldown": 7.0, "current_cooldown": 0.0, "multiplier": 1.3, "effect": "atk_spin"})
			add_chat_msg("[Sistema]", "¡Has aprendido la habilidad: Torbellino!", Color(1.0, 0.8, 0.0))
		elif player_class == "Mage":
			skills.append({"name": "Furia de Hielo", "mp_cost": 10, "cooldown": 6.0, "current_cooldown": 0.0, "multiplier": 1.4, "effect": "atk_ice"})
			add_chat_msg("[Sistema]", "¡Has aprendido la habilidad: Furia de Hielo!", Color(1.0, 0.8, 0.0))
		elif player_class == "Archer":
			skills.append({"name": "Flechas Lluvia", "mp_cost": 8, "cooldown": 8.0, "current_cooldown": 0.0, "multiplier": 1.3, "effect": "atk_rain"})
			add_chat_msg("[Sistema]", "¡Has aprendido la habilidad: Flechas Lluvia!", Color(1.0, 0.8, 0.0))
			
	recalculate_stats()
	# Heal completely on level up
	hp = max_hp
	mp = max_mp
	
	add_chat_msg("[Sistema]", "¡¡HAS SUBIDO AL NIVEL " + str(level) + "!!", Color(1.0, 0.8, 0.0))
	play_effect.emit("level_up", Vector2.ZERO) # Placed on player in world script
	SoundManager.play_sfx("level_up")

func heal_player(amount: float):
	hp = min(hp + amount, max_hp)
	player_stats_changed.emit()
	SoundManager.play_sfx("heal")

func restore_mana(amount: float):
	mp = min(mp + amount, max_mp)
	player_stats_changed.emit()
	SoundManager.play_sfx("mana")

# Inventory management
func add_item_to_inventory(item_id: String, quantity: int = 1) -> bool:
	if not items_db.has(item_id):
		return false
		
	var db_item = items_db[item_id]
	
	# Check stackable
	if db_item["type"] == "consumable" or db_item["type"] == "quest":
		# Check if we already have it to increase stack
		for i in range(inventory.size()):
			if inventory[i]["id"] == item_id:
				inventory[i]["quantity"] += quantity
				inventory_changed.emit()
				# Check quests for collection
				check_collection_quests(item_id)
				return true
				
	# Check inventory limit
	if inventory.size() >= MAX_INVENTORY_SIZE:
		add_chat_msg("[Sistema]", "¡Tu inventario está lleno!", Color(1.0, 0.3, 0.3))
		return false
		
	var item_inst = db_item.duplicate(true)
	item_inst["quantity"] = quantity
	inventory.append(item_inst)
	inventory_changed.emit()
	
	# Check quests
	check_collection_quests(item_id)
	return true

func remove_item_from_inventory(item_id: String, quantity: int = 1) -> bool:
	for i in range(inventory.size()):
		if inventory[i]["id"] == item_id:
			if inventory[i]["quantity"] > quantity:
				inventory[i]["quantity"] -= quantity
				inventory_changed.emit()
				return true
			elif inventory[i]["quantity"] == quantity:
				inventory.remove_at(i)
				inventory_changed.emit()
				return true
	return false

func get_item_count(item_id: String) -> int:
	var count = 0
	for item in inventory:
		if item["id"] == item_id:
			count += item["quantity"]
	return count

# Equip Item
func equip_item(index: int):
	if index < 0 or index >= inventory.size():
		return

	var item = inventory[index]
	if not item.has("type") or item["type"] == "consumable" or item["type"] == "quest":
		return

	if item.has("class_req") and item["class_req"] != player_class:
		add_chat_msg("[Sistema]", "Esta clase no puede equipar este objeto.", Color(1.0, 0.3, 0.3))
		return

	var slot = item["type"]

	if equipped[slot] != null:
		var old_item = equipped[slot]
		equipped[slot] = item
		inventory[index] = old_item
	else:
		equipped[slot] = item
		inventory.remove_at(index)

	recalculate_stats()
	inventory_changed.emit()
	SoundManager.play_sfx("equip")
	add_chat_msg("[Sistema]", "Equipado: " + item["name"], Color(0.6, 0.8, 1.0))

func unequip_item(slot: String):
	if not equipped.has(slot) or equipped[slot] == null:
		return
		
	if inventory.size() >= MAX_INVENTORY_SIZE:
		add_chat_msg("[Sistema]", "Inventario lleno. No puedes desequipar.", Color(1.0, 0.3, 0.3))
		return
		
	var item = equipped[slot]
	equipped[slot] = null
	inventory.append(item)
	
	recalculate_stats()
	inventory_changed.emit()
	SoundManager.play_sfx("equip")
	add_chat_msg("[Sistema]", "Desequipado: " + item["name"], Color(0.6, 0.8, 1.0))

# Use Item
func use_item(index: int):
	if index < 0 or index >= inventory.size():
		return
		
	var item = inventory[index]
	if item["type"] == "consumable":
		var heal_pos = Vector2.ZERO
		var player = get_tree().get_first_node_in_group("player")
		if player: heal_pos = player.global_position
		if item["effect"] == "heal_hp":
			if hp >= max_hp: return
			heal_player(item["power"])
			show_damage_number.emit(heal_pos, "+" + str(item["power"]) + " HP", Color(0.2, 0.9, 0.2))
		elif item["effect"] == "heal_mp":
			if mp >= max_mp: return
			restore_mana(item["power"])
			show_damage_number.emit(heal_pos, "+" + str(item["power"]) + " MP", Color(0.2, 0.5, 0.9))
			
		remove_item_from_inventory(item["id"], 1)
		
	elif item["type"] in ["weapon", "armor", "shield"]:
		equip_item(index)

# Quests System
func accept_quest(quest_id: String):
	if active_quests.has(quest_id) or completed_quests.has(quest_id):
		return
		
	if not quests_db.has(quest_id):
		return
		
	active_quests[quest_id] = {
		"progress": 0,
		"completed": false
	}
	
	var q = quests_db[quest_id]
	add_chat_msg("[Misión]", "Nueva Misión Aceptada: " + q["title"], Color(1.0, 0.9, 0.3))
	
	# If collection quest, check starting progress
	if q["target_type"] == "collect":
		check_collection_quests(q["target_id"])
		
	quest_log_changed.emit()

func check_collection_quests(item_id: String):
	for q_id in active_quests:
		var q = quests_db[q_id]
		if q["target_type"] == "collect" and q["target_id"] == item_id:
			var current_count = get_item_count(item_id)
			active_quests[q_id]["progress"] = min(current_count, q["target_count"])
			quest_log_changed.emit()

func track_kill(monster_id: String):
	for q_id in active_quests:
		var q = quests_db[q_id]
		if q["target_type"] == "kill" and q["target_id"] == monster_id:
			if active_quests[q_id]["progress"] < q["target_count"]:
				active_quests[q_id]["progress"] += 1
				add_chat_msg("[Misión]", q["title"] + " Progress: " + str(active_quests[q_id]["progress"]) + "/" + str(q["target_count"]), Color(1.0, 0.9, 0.5))
				quest_log_changed.emit()

func can_complete_quest(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	var q = quests_db[quest_id]
	return active_quests[quest_id]["progress"] >= q["target_count"]

func complete_quest(quest_id: String):
	if not can_complete_quest(quest_id):
		return
		
	var q = quests_db[quest_id]
	
	# Remove items if it was a collection quest
	if q["target_type"] == "collect":
		remove_item_from_inventory(q["target_id"], q["target_count"])
		
	# Award rewards
	gold += q["gold_reward"]
	add_xp(q["xp_reward"])
	
	# Item reward scaling with class
	var rew_item = q["item_reward"]
	if rew_item != "":
		# Adapt reward to class
		if quest_id == "quest_slime":
			if player_class == "Warrior": rew_item = "iron_sword"
			elif player_class == "Mage": rew_item = "fire_staff"
			elif player_class == "Archer": rew_item = "hunter_bow"
		elif quest_id == "quest_goblin":
			if player_class == "Warrior": rew_item = "plate_armor"
			elif player_class == "Mage": rew_item = "sage_robe"
			elif player_class == "Archer": rew_item = "ranger_tunic"
		elif quest_id == "quest_skeleton":
			if player_class == "Warrior": rew_item = "steel_shield"
			else: rew_item = "hp_potion" # Consumables if not warrior
			
		if rew_item != "hp_potion":
			add_item_to_inventory(rew_item)
			add_chat_msg("[Sistema]", "Obtienes objeto: " + items_db[rew_item]["name"], Color(0.6, 0.8, 1.0))
		else:
			add_item_to_inventory("hp_potion", 3)
			add_item_to_inventory("mp_potion", 3)
			add_chat_msg("[Sistema]", "Obtienes Pociones x3", Color(0.6, 0.8, 1.0))
			
	# Mark completed
	active_quests.erase(quest_id)
	completed_quests[quest_id] = true
	
	add_chat_msg("[Misión]", "Misión Completada: " + q["title"] + " (+" + str(q["gold_reward"]) + " Oro)", Color(0.4, 1.0, 0.4))
	SoundManager.play_sfx("quest_complete")
	quest_log_changed.emit()
	player_stats_changed.emit()
	
	# Trigger Victory check
	if quest_id == "quest_boss":
		game_victory.emit()

# Chat Helpers
func add_chat_msg(sender: String, message: String, color: Color = Color.WHITE):
	chat_received.emit(sender, message, color)

func _on_chat_timer_timeout():
	var sender = chat_names[randi() % chat_names.size()]
	var msg = chat_phrases[randi() % chat_phrases.size()]
	var color = Color.from_hsv(randf(), 0.5, 0.95)
	add_chat_msg(sender, msg, color)
	chat_timer.wait_time = randf_range(8.0, 20.0)
