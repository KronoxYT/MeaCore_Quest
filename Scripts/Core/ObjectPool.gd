extends Node

signal pool_exhausted(pool_name: String)

var _pool: Array[Node] = []
var _scene: PackedScene
var _name: String
var _initial_size: int = 0
var _max_pool_size: int = 50
var _auto_expand: bool = true

func _init() -> void:
    pass

func setup(pool_name: String, scene: PackedScene, initial_size: int = 5, max_size: int = 50, auto_expand: bool = true):
    _name = pool_name
    _scene = scene
    _initial_size = initial_size
    _max_pool_size = max_size
    _auto_expand = auto_expand
    for i in range(initial_size):
        var instance = scene.instantiate()
        instance.visible = false
        instance.set_process(false)
        instance.set_physics_process(false)
        add_child(instance)
        _pool.append(instance)

func acquire() -> Node:
    for item in _pool:
        if not item.visible:
            item.visible = true
            item.set_process(true)
            item.set_physics_process(true)
            return item
    if _auto_expand and _pool.size() < _max_pool_size:
        var instance = _scene.instantiate()
        add_child(instance)
        _pool.append(instance)
        return instance
    pool_exhausted.emit(_name)
    return null

func release(item: Node):
    item.visible = false
    item.set_process(false)
    item.set_physics_process(false)

func release_all():
    for item in _pool:
        release(item)

func get_active_count() -> int:
    var count = 0
    for item in _pool:
        if item.visible:
            count += 1
    return count

func get_pool_size() -> int:
    return _pool.size()
