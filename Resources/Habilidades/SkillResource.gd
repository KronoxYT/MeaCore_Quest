class_name SkillResource
extends Resource

enum SkillType { ACTIVE, PASSIVE, AURA, ULTIMATE }
enum DamageType { PHYSICAL, MAGICAL, TRUE }
enum TargetType { SELF, SINGLE_ENEMY, AOE_CIRCLE, AOE_CONE }

@export var id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var skill_type: SkillType = SkillType.ACTIVE

@export_group("Requirements")
@export var class_requirement: String = ""
@export var level_requirement: int = 1

@export_group("Costs & Cooldown")
@export var mana_cost: int = 0
@export var stamina_cost: int = 0
@export var cooldown: float = 5.0
@export var cast_time: float = 0.0

@export_group("Combat")
@export var base_damage: int = 0
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var range: float = 50.0
@export var radius: float = 0.0
@export var damage_scaling_stat: String = "attack"

@export_group("Visuals")
@export var animation_name: String = ""
@export var vfx_scene: PackedScene = null
@export var sfx_stream: AudioStream = null
