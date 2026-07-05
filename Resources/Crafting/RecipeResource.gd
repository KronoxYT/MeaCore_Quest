class_name RecipeResource
extends Resource

enum CraftingCategory { SMITHING, TAILORING, ALCHEMY, COOKING, CARPENTRY, ENCHANTING, ENGINEERING }

@export var id: String
@export var display_name: String
@export var description: String
@export var category: CraftingCategory
@export var icon: Texture2D
@export var required_station: String = ""
@export var required_skill_level: int = 1
@export var crafting_skill: String = ""
@export var craft_time: float = 2.0
@export var xp_reward: int = 10

@export_group("Ingredients")
@export var ingredients: Array[Dictionary] = []

@export_group("Output")
@export var output_item_id: String = ""
@export var output_quantity: int = 1

@export_group("Quality")
@export var quality_curve: Array[float] = [0.7, 0.2, 0.08, 0.02]

func validate_ingredients(inventory) -> bool:
    for ingredient in ingredients:
        if not inventory.has_item(ingredient.item_id, ingredient.quantity):
            return false
    return true
