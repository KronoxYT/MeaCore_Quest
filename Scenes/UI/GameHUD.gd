class_name GameHUD
extends CanvasLayer

## HUD principal del juego con barras de HP, Stamina y información

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPBar/HPLabel
@onready var stamina_bar: ProgressBar = $MarginContainer/VBoxContainer/StaminaBar
@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelLabel
@onready var gold_label: Label = $MarginContainer/VBoxContainer/GoldLabel
@onready var xp_bar: ProgressBar = $MarginContainer/VBoxContainer/XPBar
@onready var notification_label: Label = $NotificationContainer/NotificationLabel

var player = null
var notification_timer: float = 0.0

func _ready():
    player = GameManager.player
    if player:
        _connect_signals()
    _update_all()

func _connect_signals() -> void:
    if player.health:
        player.health.health_changed.connect(_on_health_changed)
    if player.stats:
        player.stats.stat_changed.connect(_on_stat_changed)
    EventManager.notification_shown.connect(_on_notification)
    EventManager.player_level_up.connect(_on_level_up)

func _process(delta: float) -> void:
    if player and player.stats:
        var stamina = player.stats.get_stat("stamina")
        var max_stamina = 100  # Ajustar según el sistema
        stamina_bar.value = stamina
        stamina_bar.max_value = max_stamina
    
    # Timer de notificación
    if notification_timer > 0:
        notification_timer -= delta
        if notification_timer <= 0 and notification_label:
            notification_label.visible = false

func _on_health_changed(new_health: float, _delta: float) -> void:
    if hp_bar and player and player.health:
        hp_bar.value = new_health
        hp_bar.max_value = player.health.max_health
    if hp_label and player and player.health:
        hp_label.text = "%d / %d" % [new_health, player.health.max_health]

func _on_stat_changed(stat_name: String, _old_value: float, _new_value: float) -> void:
    _update_all()

func _on_notification(message: String, type: String) -> void:
    if notification_label:
        notification_label.text = message
        notification_label.visible = true
        notification_timer = 3.0
        
        match type:
            "info":
                notification_label.add_theme_color_override("font_color", Color.WHITE)
            "success":
                notification_label.add_theme_color_override("font_color", Color.GREEN)
            "danger":
                notification_label.add_theme_color_override("font_color", Color.RED)

func _on_level_up(new_level: int) -> void:
    if level_label:
        level_label.text = "Nivel %d" % new_level
    _show_notification("¡Nivel %d alcanzado!" % new_level, "success")

func _show_notification(message: String, type: String = "info") -> void:
    _on_notification(message, type)

func _update_all() -> void:
    if not player:
        return
    
    if player.health:
        _on_health_changed(player.health.current_health, 0.0)
    
    if level_label:
        level_label.text = "Nivel %d" % player.level
    
    if gold_label:
        gold_label.text = "Oro: %d" % player.gold
    
    if xp_bar:
        xp_bar.value = player.xp
        xp_bar.max_value = player.xp_to_next_level