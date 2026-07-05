extends Node

var _notifier: VisibleOnScreenNotifier2D
var _is_player: bool = false
var _is_boss: bool = false

func _ready():
    _is_player = owner.has_node("PlayerInputSync") or owner.has_node("CombatSync")
    if _is_player:
        set_physics_process(false)
        return
    if owner.has_node("BossComponent"):
        _is_boss = true
        set_physics_process(false)
        return
    _notifier = owner.find_child("VisibleOnScreenNotifier2D")
    if not _notifier:
        _notifier = VisibleOnScreenNotifier2D.new()
        _notifier.name = "EntityCullingNotifier"
        owner.add_child(_notifier)
    _notifier.screen_entered.connect(_on_screen_entered)
    _notifier.screen_exited.connect(_on_screen_exited)

func _on_screen_entered():
    owner.set_process(true)
    owner.set_physics_process(true)

func _on_screen_exited():
    owner.set_process(false)
    owner.set_physics_process(false)
