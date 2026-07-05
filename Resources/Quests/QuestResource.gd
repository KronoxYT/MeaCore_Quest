class_name QuestResource
extends Resource

enum QuestType { MAIN, SIDE, DAILY, WEEKLY, GUILD, EVENT }

@export var id: String
@export var display_name: String
@export var description: String
@export var lore_text: String
@export var quest_type: QuestType = QuestType.SIDE
@export var level_requirement: int = 1
@export var prerequisite_quests: Array[String] = []
@export var faction_requirement: String = ""
@export var min_reputation: int = 0

@export_group("Objectives")
@export var objectives: Array[Dictionary] = []

@export_group("Rewards")
@export var xp_reward: int = 100
@export var gold_reward: int = 50
@export var item_rewards: Array[Dictionary] = []
@export var reputation_rewards: Dictionary = {}
@export var unlocks_quests: Array[String] = []
@export var unlocks_features: Array[String] = []

@export_group("Dialogue Integration")
@export var start_dialogue: DialogueResource = null
@export var completion_dialogue: DialogueResource = null
@export var npc_id_giver: String = ""
@export var npc_id_completer: String = ""

func get_progress_percent() -> float:
    if objectives.size() == 0:
        return 0.0
    var total_required: float = 0.0
    var total_current: float = 0.0
    for objective in objectives:
        total_required += objective.get("required_amount", 1)
        total_current += min(objective.get("current", 0), objective.get("required_amount", 1))
    return (total_current / total_required) if total_required > 0 else 0.0

func is_complete() -> bool:
    for objective in objectives:
        if objective.get("current", 0) < objective.get("required_amount", 1):
            return false
    return true
