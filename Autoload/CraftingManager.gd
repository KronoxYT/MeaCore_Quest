extends Node

signal craft_started(recipe_id: String)
signal craft_completed(recipe_id: String, quality: String)
signal craft_failed(recipe_id: String)
signal skill_leveled_up(skill_name: String, new_level: int)

var recipes_cache: Dictionary = {}
var crafting_skills: Dictionary = {
    "smithing": 1, "tailoring": 1, "alchemy": 1, "cooking": 1,
    "carpentry": 1, "enchanting": 1, "engineering": 1
}


func _ready():
    process_mode = PROCESS_MODE_ALWAYS
    _load_recipes()
    var EM = get_node("/root/EventManager")
    if EM:
        EM.item_crafted.connect(_on_item_crafted)


func _load_recipes() -> void:
    var dir = DirAccess.open("res://Resources/Recipes")
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".tres"):
                var recipe = load("res://Resources/Recipes/" + file_name)
                if recipe and _is_recipe_resource(recipe):
                    recipes_cache[recipe.id] = recipe
            file_name = dir.get_next()


func _is_recipe_resource(res):
    return res.script.resource_path == "res://Resources/Crafting/RecipeResource.gd"


func get_known_recipes() -> Array:
    return recipes_cache.values()


func get_skill_level(skill_name: String) -> int:
    return crafting_skills.get(skill_name, 1)


func can_craft(recipe, player, near_station: String) -> bool:
    if not recipe or not player:
        return false
    if recipe.required_station != "" and near_station != recipe.required_station:
        return false
    var current_level = crafting_skills.get(recipe.crafting_skill, 1)
    if current_level < recipe.required_skill_level:
        return false
    return recipe.validate_ingredients(player.inventory_comp)


func craft_item(recipe, player) -> Dictionary:
    if not can_craft(recipe, player, ""):
        craft_failed.emit(recipe.id)
        return {"success": false, "reason": "requirements_not_met"}
    for ingredient in recipe.ingredients:
        player.inventory_comp.remove_item(ingredient.item_id, ingredient.quantity)
    var quality = _roll_quality(recipe, player)
    var output_quantity = recipe.output_quantity
    if quality == "Master":
        output_quantity += 1
    elif quality == "Exceptional":
        output_quantity = int(output_quantity * 1.2)
    if player.inventory_comp:
        var item_res = _load_item_resource(recipe.output_item_id)
        if item_res:
            player.inventory_comp.add_item(item_res, output_quantity)
    _gain_crafting_xp(recipe.crafting_skill, recipe.xp_reward)
    craft_completed.emit(recipe.id, quality)
    var EM = get_node("/root/EventManager")
    if EM:
        EM.item_crafted.emit(recipe.id, player.player_id)
    return {"success": true, "quality": quality, "output_item_id": recipe.output_item_id, "quantity": output_quantity}


func _load_item_resource(item_id: String):
    var paths = {
        "iron_sword": "res://Resources/Items/Weapons/iron_sword.tres",
        "health_potion_small": "res://Resources/Items/Consumables/health_potion_small.tres",
    }
    var path = paths.get(item_id)
    if path:
        return load(path)
    return null


func _roll_quality(recipe, player) -> String:
    var skill_level = crafting_skills.get(recipe.crafting_skill, 1)
    var skill_modifier = clampf(skill_level / 100.0, 0, 0.5)
    var luck_modifier = 0.0
    if player.stats:
        luck_modifier = player.stats.get_stat("luck") * 0.002
    var curve = recipe.quality_curve.duplicate()
    curve[0] -= skill_modifier * 0.5
    curve[1] += skill_modifier * 0.3
    curve[2] += skill_modifier * 0.15 + luck_modifier * 0.5
    curve[3] += skill_modifier * 0.05 + luck_modifier * 0.5
    var roll = randf()
    var accumulated = 0.0
    var quality_index = 0
    for i in curve.size():
        accumulated += curve[i]
        if roll <= accumulated:
            quality_index = i
            break
    var qualities = ["Normal", "Superior", "Exceptional", "Master"]
    return qualities[quality_index]


func _gain_crafting_xp(skill_name: String, base_xp: int) -> void:
    if skill_name not in crafting_skills:
        return
    if randi_range(0, 99) < base_xp:
        crafting_skills[skill_name] += 1
        skill_leveled_up.emit(skill_name, crafting_skills[skill_name])
        var EM = get_node("/root/EventManager")
        if EM:
            EM.notification_shown.emit("¡%s nivel %d!" % [skill_name.capitalize(), crafting_skills[skill_name]], "success")


func _on_item_crafted(recipe_id: String, player_id: String) -> void:
    var GM = get_node("/root/GameManager")
    if GM and GM.player and player_id == GM.player.player_id:
        var EM = get_node("/root/EventManager")
        if EM:
            EM.notification_shown.emit("Objeto creado exitosamente", "success")
