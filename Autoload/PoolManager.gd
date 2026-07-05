extends Node

const ObjectPool = preload("res://Scripts/Core/ObjectPool.gd")
var _pools: Dictionary = {}

func _ready():
    _register_default_pools()

func _register_default_pools():
    register_pool("damage_number", preload("res://Scenes/Effects/DamageNumber.tscn"), 10, 30)
    var item_drop_scene = load("res://Scenes/Items/ItemDrop.tscn") if ResourceLoader.exists("res://Scenes/Items/ItemDrop.tscn") else null
    if item_drop_scene:
        register_pool("item_drop", item_drop_scene, 5, 20)
    var hit_effect_scene = load("res://Scenes/Effects/HitEffect.tscn") if ResourceLoader.exists("res://Scenes/Effects/HitEffect.tscn") else null
    if hit_effect_scene:
        register_pool("hit_effect", hit_effect_scene, 5, 20)
    register_pool("projectile_arrow", null, 0, 0)
    register_pool("projectile_fireball", null, 0, 0)

func register_pool(pool_name: String, scene: PackedScene, initial_size: int = 5, max_size: int = 50):
    if _pools.has(pool_name):
        return
    var pool = ObjectPool.new()
    pool.name = pool_name
    add_child(pool)
    if scene:
        pool.setup(pool_name, scene, initial_size, max_size)
    _pools[pool_name] = pool

func get_pool(pool_name: String) -> ObjectPool:
    return _pools.get(pool_name, null)

func acquire(pool_name: String) -> Node:
    var pool = _pools.get(pool_name)
    if pool:
        return pool.acquire()
    return null

func release(pool_name: String, item: Node):
    var pool = _pools.get(pool_name)
    if pool:
        pool.release(item)

func release_all(pool_name: String):
    var pool = _pools.get(pool_name)
    if pool:
        pool.release_all()

func release_all_pools():
    for pool_name in _pools:
        _pools[pool_name].release_all()

func spawn_damage_number(position: Vector2, amount: int, color: Color = Color(1, 1, 1)):
    var dmg = acquire("damage_number")
    if dmg:
        dmg.global_position = position
        dmg.show_damage(amount, color)
    return dmg

func spawn_hit_effect(position: Vector2):
    var effect = acquire("hit_effect")
    if effect:
        effect.global_position = position
    return effect
