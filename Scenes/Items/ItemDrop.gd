class_name ItemDrop
extends Area2D

## Objeto que cae al suelo y puede ser recogido

signal picked_up(player: Node)

@export var item_id: String = ""
@export var quantity: int = 1
@export var pickup_delay: float = 0.5  # Tiempo antes de poder recoger
@export var lifetime: float = 300.0  # 5 minutos antes de desaparecer
@export var magnet_radius: float = 50.0  # Radio para auto-recoger

var can_pickup: bool = false
var lifetime_timer: float = 0.0
var magnet_target: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
    add_to_group("item_drops")
    body_entered.connect(_on_body_entered)
    
    # Timer de vida
    lifetime_timer = lifetime
    can_pickup = false
    
    # Delay antes de poder recoger
    await get_tree().create_timer(pickup_delay).timeout
    can_pickup = true

func setup(item: String, qty: int = 1) -> void:
    item_id = item
    quantity = qty
    _update_visual()

func _update_visual() -> void:
    # Aquí se cargaría el icono del item
    # Por ahora, un placeholder
    if sprite:
        sprite.modulate = _get_rarity_color()
    
    # Animación de aparición
    var tween = create_tween()
    scale = Vector2(0.1, 0.1)
    tween.tween_property(self, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
    lifetime_timer -= delta
    
    # Parpadear cuando está por desaparecer
    if lifetime_timer < 10.0:
        var blink = sin(lifetime_timer * 10) > 0
        visible = blink
    
    if lifetime_timer <= 0:
        queue_free()
        return
    
    # Efecto magnético hacia el jugador
    if magnet_target and is_instance_valid(magnet_target):
        var direction = (magnet_target.global_position - global_position).normalized()
        global_position += direction * 200 * delta
        
        if global_position.distance_to(magnet_target.global_position) < 20:
            _pickup(magnet_target)

func _on_body_entered(body: Node) -> void:
    if not can_pickup:
        return
    
    if body.is_in_group("players"):
        _pickup(body)
    elif body.is_in_group("enemies"):
        pass  # Los enemigos no recogen items

func _pickup(player: Node) -> void:
    if player.has_method("pickup_item"):
        player.pickup_item(item_id, quantity)
    
    picked_up.emit(player)
    
    # Efecto visual de recoger
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.2)
    tween.tween_callback(queue_free)

func _get_rarity_color() -> Color:
    # Colores según rareza del item (placeholder)
    return Color.WHITE

func activate_magnet(target: Node) -> void:
    magnet_target = target