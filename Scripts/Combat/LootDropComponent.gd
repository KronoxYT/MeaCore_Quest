class_name LootDropComponent
extends Node

## Componente que genera drops de enemigos y cofres

signal loot_dropped(items: Array)

@export var loot_tables: Array = []
@export var drop_radius: float = 30.0
@export var auto_pickup: bool = false

var item_drop_scene: PackedScene = null

func _ready():
    item_drop_scene = preload("res://Scenes/Items/ItemDrop.tscn")

func drop_loot(enemy_resource) -> void:
    var all_drops: Array[Dictionary] = []
    
    # Drops de las tablas de loot
    for table in loot_tables:
        if table:
            all_drops.append_array(table.roll())
    
    # Drops garantizados
    for item_id in enemy_resource.guaranteed_drops:
        all_drops.append({"item_id": item_id, "quantity": 1})
    
    # Oro
    var gold_amount = randi_range(enemy_resource.gold_min, enemy_resource.gold_max)
    if gold_amount > 0:
        all_drops.append({"item_id": "gold", "quantity": gold_amount})
    
    # Crear items en el mundo
    _spawn_drops(all_drops)
    loot_dropped.emit(all_drops)

func _spawn_drops(drops: Array[Dictionary]) -> void:
    if not item_drop_scene:
        return
    
    var parent = get_parent()
    var base_position = parent.global_position if parent else Vector2.ZERO
    
    for i in drops.size():
        var drop_data = drops[i]
        var drop = item_drop_scene.instantiate()
        
        # Posición aleatoria alrededor del punto de muerte
        var angle = randf() * TAU
        var distance = randf() * drop_radius
        var offset = Vector2(cos(angle), sin(angle)) * distance
        
        drop.setup(drop_data["item_id"], drop_data["quantity"])
        drop.global_position = base_position + offset
        
        # Añadir a la escena actual
        get_tree().current_scene.add_child(drop)