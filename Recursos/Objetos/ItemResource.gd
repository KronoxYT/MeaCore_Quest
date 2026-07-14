class_name ItemResource
extends Resource

enum ItemType { WEAPON, ARMOR, ACCESSORY, CONSUMABLE, MATERIAL, QUEST, CURRENCY }
enum EquipSlot { NONE, MAIN_HAND, OFF_HAND, HEAD, CHEST, HANDS, LEGS, RING_1, RING_2, AMULET, CAPE, PET }
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC, DIVINE }

@export var id: String
@export var display_name: String
@export var description: String
@export var item_type: ItemType
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var icon: Texture2D

@export_group("Stacking & Economy")
@export var stackable: bool = false
@export var max_stack: int = 1
@export var weight: float = 1.0
@export var sell_price: int = 0
@export var buy_price: int = 0

@export_group("Equipment")
@export var equip_slot: EquipSlot = EquipSlot.NONE
@export var level_requirement: int = 1
@export var class_restriction: Array[String] = []
@export var stats_bonus: Dictionary = {}
@export var special_effect: String = ""
@export var set_id: String = ""

@export_group("Consumable")
@export var heal_amount: int = 0
@export var mana_amount: int = 0
@export var buff_id: String = ""
@export var buff_duration: float = 0.0
@export var cooldown: float = 0.0

func get_rarity_color() -> Color:
    match rarity:
        ItemRarity.COMMON: return Color("#9E9E9E")
        ItemRarity.UNCOMMON: return Color("#4CAF50")
        ItemRarity.RARE: return Color("#2196F3")
        ItemRarity.EPIC: return Color("#9C27B0")
        ItemRarity.LEGENDARY: return Color("#FF9800")
        ItemRarity.MYTHIC: return Color("#F44336")
        ItemRarity.DIVINE: return Color("#FFD700")
        _: return Color.WHITE

func is_equippable() -> bool:
    return equip_slot != EquipSlot.NONE

func is_consumable() -> bool:
    return item_type == ItemType.CONSUMABLE
