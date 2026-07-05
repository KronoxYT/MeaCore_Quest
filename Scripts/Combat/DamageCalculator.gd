extends RefCounted

class_name DamageCalculator


static func calculate_damage(base_damage: float, type: int, target_stats) -> float:
    var damage := base_damage
    var defense: float

    match type:
        0, 1, 5, 6:
            defense = target_stats.get("defense") if target_stats else 0.0
        2, 3, 4:
            defense = target_stats.get("magic_defense") if target_stats else 0.0
        _:
            defense = target_stats.get("defense") if target_stats else 0.0

    damage = max(1.0, damage - defense * 0.5)
    damage *= _get_element_multiplier(type)
    return damage


static func _get_element_multiplier(type: int) -> float:
    if type == 3:
        return 1.0
    return 1.0


static func calculate_heal(base_heal: float, source_stats) -> float:
    var heal := base_heal
    if source_stats:
        heal += source_stats.get("magic_power", 0.0) * 0.2
    return max(0.0, heal)


static func calculate_crit_damage(damage: float, attacker_stats) -> float:
    if not attacker_stats:
        return damage
    if randf() < attacker_stats.get("crit_chance", 0.0):
        return damage * attacker_stats.get("crit_multiplier", 1.5)
    return damage


static func should_dodge(target_stats) -> bool:
    if not target_stats:
        return false
    return randf() < target_stats.get("dodge_chance", 0.0)


static func should_block(target_stats) -> bool:
    if not target_stats:
        return false
    return randf() < target_stats.get("block_chance", 0.0)
