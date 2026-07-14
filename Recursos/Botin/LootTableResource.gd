class_name LootTableResource
extends Resource

## Tabla de drops para enemigos y cofres

@export var id: String
@export var display_name: String
@export var entries: Array[Dictionary] = []
# Cada entry: { "item_id": String, "chance": float (0-1), "min_qty": int, "max_qty": int }

func roll() -> Array[Dictionary]:
    var drops: Array[Dictionary] = []
    for entry in entries:
        var roll = randf()
        if roll <= entry.get("chance", 0.0):
            var qty = randi_range(
                entry.get("min_qty", 1),
                entry.get("max_qty", 1)
            )
            drops.append({
                "item_id": entry.get("item_id", ""),
                "quantity": qty
            })
    return drops

func has_drops() -> bool:
    return entries.size() > 0