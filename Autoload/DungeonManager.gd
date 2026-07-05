extends Node

signal dungeon_entered(dungeon_id: String)
signal dungeon_exited
signal dungeon_completed(dungeon_id: String)
signal boss_defeated(boss_id: String)
signal raid_started(raid_id: String)
signal raid_wave_spawned(wave: int)
signal raid_completed(raid_id: String)

var current_dungeon_id: String = ""
var current_raid_id: String = ""
var in_dungeon: bool = false
var in_raid: bool = false
var dungeon_wave: int = 0
var dungeon_enemies_alive: int = 0
var raid_enemies_alive: int = 0
var raid_wave: int = 0
var raid_total_waves: int = 0
var raid_enemies_per_wave: int = 0

var dungeons_db = {
	"slime_cave": {
		"id": "slime_cave",
		"name": "Cueva de Slimes",
		"description": "Una cueva oscura llena de slimes gigantes.",
		"min_level": 2,
		"enemies": ["slime", "slime", "slime", "slime_king"],
		"boss": "slime_king",
		"gold_reward": 200,
		"xp_reward": 300,
		"item_reward": "",
		"unlock_quest": "quest_story_goblin",
		"unlock_pet": "mini_golem"
	},
	"skeleton_crypt": {
		"id": "skeleton_crypt",
		"name": "Cripta de los Esqueletos",
		"description": "Una cripta antigua donde los muertos no descansan.",
		"min_level": 3,
		"enemies": ["skeleton", "skeleton", "skeleton", "skeleton", "skeleton_lord"],
		"boss": "skeleton_lord",
		"gold_reward": 500,
		"xp_reward": 600,
		"item_reward": "spirit_ring",
		"unlock_quest": "quest_dungeon_slime"
	}
}

var raids_db = {
	"goblin_camp": {
		"id": "goblin_camp",
		"name": "Campamento Goblin",
		"description": "Asalta el campamento goblin en una batalla por oleadas.",
		"min_level": 3,
		"waves": 5,
		"enemies_per_wave": 4,
		"boss": "goblin_chief",
		"gold_reward": 800,
		"xp_reward": 1000,
		"item_reward": "bone_armor_cosmetic",
		"unlock_quest": "quest_raid_goblin"
	}
}

func _ready():
	add_to_group("dungeon_manager")

func enter_dungeon(dungeon_id: String) -> bool:
	if not dungeons_db.has(dungeon_id):
		return false
	var dd = dungeons_db[dungeon_id]
	if GameManager.level < dd["min_level"]:
		GameManager.add_chat_msg("[Sistema]", "Necesitas nivel " + str(dd["min_level"]) + " para entrar a " + dd["name"], Color(1.0, 0.3, 0.3))
		return false
	current_dungeon_id = dungeon_id
	in_dungeon = true
	dungeon_wave = 0
	dungeon_enemies_alive = 0
	dungeon_entered.emit(dungeon_id)
	# GameManager.dungeon_entered.emit(dungeon_id)
	_spawn_dungeon_wave()
	return true

func exit_dungeon():
	current_dungeon_id = ""
	in_dungeon = false
	dungeon_wave = 0
	dungeon_exited.emit()

func _spawn_dungeon_wave():
	if not in_dungeon or current_dungeon_id == "":
		return
	var dd = dungeons_db[current_dungeon_id]
	var enemies_arr = dd["enemies"]
	_clear_dungeon_enemies()
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var enemy_scene = load("res://Scenes/entities/Enemy.tscn")
	dungeon_enemies_alive = 0
	for i in range(enemies_arr.size()):
		var eid = enemies_arr[i]
		var enemy = enemy_scene.instantiate()
		enemy.monster_id = eid
		var offset = Vector2(randf_range(-80, 80), randf_range(-60, 60))
		enemy.global_position = player.global_position + Vector2(200 + i * 60, 0) + offset
		get_tree().current_scene.add_child(enemy)
		dungeon_enemies_alive += 1
	dungeon_wave += 1

func _clear_dungeon_enemies():
	# Use queue_free directly — calling die() can freeze if Engine.time_scale=0
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e) and not e.is_dead:
			e.is_dead = true
			e.collision_shape.set_deferred("disabled", true)
			e.queue_free()

func on_enemy_killed(monster_id: String):
	if not in_dungeon:
		return
	dungeon_enemies_alive -= 1
	var dd = dungeons_db.get(current_dungeon_id, {})
	if dd.has("boss") and monster_id == dd["boss"]:
		boss_defeated.emit(monster_id)
		call_deferred("_on_dungeon_boss_defeated")
	if dungeon_enemies_alive <= 0:
		if dungeon_wave >= len(dd.get("enemies", [])):
			call_deferred("_on_dungeon_completed")

func _on_dungeon_boss_defeated():
	var dd = dungeons_db.get(current_dungeon_id, {})
	GameManager.add_chat_msg("[Mazmorra]", "¡Has derrotado al jefe de " + dd.get("name", "") + "!", Color(1.0, 0.8, 0.0))
	_on_dungeon_completed()

func _on_dungeon_completed():
	var dd = dungeons_db.get(current_dungeon_id, {})
	GameManager.gold += dd.get("gold_reward", 0)
	GameManager.add_xp(dd.get("xp_reward", 0))
	var reward = dd.get("item_reward", "")
	if reward != "" and GameManager.items_db.has(reward):
		GameManager.add_item_to_inventory(reward)
	var unlock_pet = dd.get("unlock_pet", "")
	if unlock_pet != "":
		GameManager.add_chat_msg("[Sistema]", "¡Mascota desbloqueada: " + unlock_pet + "!", Color(0.4, 1.0, 0.8))
	GameManager.add_chat_msg("[Mazmorra]", "¡Mazmorra completada! Recompensa: +" + str(dd.get("gold_reward", 0)) + " Oro, +" + str(dd.get("xp_reward", 0)) + " XP", Color(0.4, 1.0, 0.4))
	dungeon_completed.emit(current_dungeon_id)
	# GameManager.dungeon_completed.emit(current_dungeon_id)
	exit_dungeon()

func start_raid(raid_id: String) -> bool:
	if not raids_db.has(raid_id):
		return false
	var rd = raids_db[raid_id]
	if GameManager.level < rd["min_level"]:
		GameManager.add_chat_msg("[Sistema]", "Necesitas nivel " + str(rd["min_level"]) + " para la incursión " + rd["name"], Color(1.0, 0.3, 0.3))
		return false
	current_raid_id = raid_id
	in_raid = true
	raid_wave = 0
	raid_total_waves = rd["waves"]
	raid_enemies_per_wave = rd["enemies_per_wave"]
	raid_started.emit(raid_id)
	# GameManager.raid_started.emit(raid_id)
	_spawn_raid_wave()
	return true

func _spawn_raid_wave():
	if not in_raid or current_raid_id == "":
		return
	var rd = raids_db[current_raid_id]
	_clear_dungeon_enemies()
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var enemy_scene = load("res://Scenes/entities/Enemy.tscn")
	var enemy_types = rd.get("enemy_types", ["slime", "goblin", "skeleton"])
	raid_enemies_alive = 0
	for i in range(rd["enemies_per_wave"]):
		var etype = enemy_types[randi() % enemy_types.size()]
		var enemy = enemy_scene.instantiate()
		enemy.monster_id = etype
		var offset = Vector2(randf_range(-100, 100), randf_range(-80, 80))
		enemy.global_position = player.global_position + Vector2(250, 0) + offset
		get_tree().current_scene.add_child(enemy)
		raid_enemies_alive += 1
	raid_wave += 1
	raid_wave_spawned.emit(raid_wave)
	GameManager.add_chat_msg("[Invasión]", "¡Oleada " + str(raid_wave) + "/" + str(raid_total_waves) + "!", Color(1.0, 0.6, 0.0))

func on_raid_enemy_killed():
	if not in_raid:
		return
	raid_enemies_alive -= 1
	if raid_enemies_alive <= 0:
		if raid_wave >= raid_total_waves:
			call_deferred("_spawn_raid_boss")
		else:
			call_deferred("_spawn_raid_wave")

func _spawn_raid_boss():
	var rd = raids_db.get(current_raid_id, {})
	if rd.is_empty():
		return
	var enemy_scene = load("res://Scenes/entities/Enemy.tscn")
	var boss = enemy_scene.instantiate()
	boss.monster_id = rd.get("boss", "goblin")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		boss.global_position = player.global_position + Vector2(250, 0)
		get_tree().current_scene.add_child(boss)
		raid_enemies_alive = 1
		GameManager.add_chat_msg("[Invasión]", "¡Aparece el Jefe " + rd.get("boss", "?") + "!", Color(1.0, 0.2, 0.2))

func on_raid_boss_killed(boss_id: String):
	if not in_raid:
		return
	var rd = raids_db.get(current_raid_id, {})
	GameManager.gold += rd.get("gold_reward", 0)
	GameManager.add_xp(rd.get("xp_reward", 0))
	var reward = rd.get("item_reward", "")
	if reward != "":
		if reward == "bone_armor_cosmetic":
			GameManager.add_chat_msg("[Sistema]", "¡Cosmético desbloqueado: Armadura de Hueso!", Color(0.8, 0.4, 1.0))
	GameManager.add_chat_msg("[Invasión]", "¡Incursión completada! Recompensa: +" + str(rd.get("gold_reward", 0)) + " Oro, +" + str(rd.get("xp_reward", 0)) + " XP", Color(0.4, 1.0, 0.4))
	raid_completed.emit(current_raid_id)
	current_raid_id = ""
	in_raid = false
