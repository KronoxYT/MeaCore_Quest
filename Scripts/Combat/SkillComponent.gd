extends "res://Scripts/Core/BaseComponent.gd"

class_name SkillComponent

signal skill_used(skill_id: String)
signal cooldown_started(skill_id: String, duration: float)

var known_skills: Array = []
var active_cooldowns: Dictionary = {}
var stats_comp = null

func _on_entity_ready():
    if not entity:
        return
    stats_comp = entity.get_node_or_null("StatsComponent")

func _process(delta: float):
    var skills_to_remove = []
    for skill_id in active_cooldowns:
        active_cooldowns[skill_id] -= delta
        if active_cooldowns[skill_id] <= 0:
            skills_to_remove.append(skill_id)
    for skill_id in skills_to_remove:
        active_cooldowns.erase(skill_id)

func add_skill(skill) -> void:
    if skill not in known_skills:
        known_skills.append(skill)

func can_use_skill(skill) -> bool:
    if not skill:
        return false
    if active_cooldowns.has(skill.id):
        return false
    if stats_comp:
        if stats_comp.get_stat("mp") < skill.mana_cost:
            return false
        if stats_comp.get_stat("stamina") < skill.stamina_cost:
            return false
    return true

func use_skill(skill, target: Node = null) -> bool:
    if not can_use_skill(skill):
        return false
    if stats_comp:
        if skill.mana_cost > 0:
            stats_comp._set_stat_value("mp", stats_comp.get_stat("mp") - skill.mana_cost)
        if skill.stamina_cost > 0:
            stats_comp._set_stat_value("stamina", stats_comp.get_stat("stamina") - skill.stamina_cost)
    active_cooldowns[skill.id] = skill.cooldown
    cooldown_started.emit(skill.id, skill.cooldown)
    _execute_skill(skill, target)
    skill_used.emit(skill.id)
    return true

func _execute_skill(skill, target: Node) -> void:
    if entity.has_method("play_animation") and skill.animation_name != "":
        entity.play_animation(skill.animation_name)
    if target and target.has_method("take_damage") and skill.base_damage > 0:
        var stat_value = stats_comp.get_stat(skill.damage_scaling_stat) if stats_comp else 0
        var final_damage = skill.base_damage + int(stat_value * 0.5)
        target.take_damage(final_damage, entity)
    if skill.vfx_scene:
        var vfx = skill.vfx_scene.instantiate()
        vfx.global_position = entity.global_position
        entity.get_tree().current_scene.add_child(vfx)

func get_cooldown_percent(skill_id: String) -> float:
    if not active_cooldowns.has(skill_id):
        return 0.0
    var skill = _get_skill_by_id(skill_id)
    if not skill:
        return 0.0
    return active_cooldowns[skill_id] / skill.cooldown

func _get_skill_by_id(skill_id: String):
    for skill in known_skills:
        if skill.id == skill_id:
            return skill
    return null
