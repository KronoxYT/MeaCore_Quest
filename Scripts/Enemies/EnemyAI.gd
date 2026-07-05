class_name EnemyAI
extends Node

## Controlador de IA para enemigos
## Maneja detección, persecución y toma de decisiones

signal state_changed(new_state: String)
signal target_acquired(target: Node)
signal target_lost()

enum AIState { IDLE, PATROL, ALERT, CHASE, ATTACK, FLEE, RETURN }

@export var detection_radius: float = 150.0
@export var attack_radius: float = 40.0
@export var chase_radius: float = 250.0
@export var patrol_radius: float = 100.0
@export var flee_hp_percent: float = 0.2
@export var alert_duration: float = 1.0
@export var attack_cooldown: float = 1.5

var current_state: AIState = AIState.IDLE
var target: Node = null
var enemy = null
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var alert_timer: float = 0.0
var attack_timer: float = 0.0
var home_position: Vector2 = Vector2.ZERO

func _ready():
    enemy = get_parent()
    if enemy:
        home_position = enemy.home_position
        _generate_patrol_points()
    
    # Cargar configuración del resource si existe
    if enemy and enemy.enemy_resource:
        detection_radius = enemy.enemy_resource.detection_radius
        attack_radius = enemy.enemy_resource.attack_radius
        chase_radius = enemy.enemy_resource.chase_radius
        patrol_radius = enemy.enemy_resource.patrol_radius
        attack_cooldown = enemy.enemy_resource.attack_cooldown
        flee_hp_percent = enemy.enemy_resource.flee_hp_percent

func _generate_patrol_points() -> void:
    # Generar 3-4 puntos de patrullaje alrededor de la posición inicial
    var num_points = randi_range(3, 4)
    for i in num_points:
        var angle = randf() * TAU
        var distance = randf_range(patrol_radius * 0.5, patrol_radius)
        var point = home_position + Vector2(cos(angle), sin(angle)) * distance
        patrol_points.append(point)

func _physics_process(delta: float) -> void:
    if not enemy or not enemy.health:
        return
    
    # Verificar si debe huir
    if enemy.health.get_health_percent() < flee_hp_percent:
        if current_state != AIState.FLEE:
            _change_state(AIState.FLEE)
        return
    
    attack_timer = max(0, attack_timer - delta)
    
    match current_state:
        AIState.IDLE:
            _process_idle(delta)
        AIState.PATROL:
            _process_patrol(delta)
        AIState.ALERT:
            _process_alert(delta)
        AIState.CHASE:
            _process_chase(delta)
        AIState.ATTACK:
            _process_attack(delta)
        AIState.FLEE:
            _process_flee(delta)
        AIState.RETURN:
            _process_return(delta)

func _process_idle(_delta: float) -> void:
    if _detect_target():
        _change_state(AIState.ALERT)
        return
    
    # Si tiene puntos de patrullaje, ir a patrullar
    if patrol_points.size() > 0:
        await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
        if current_state == AIState.IDLE:
            _change_state(AIState.PATROL)

func _process_patrol(_delta: float) -> void:
    if _detect_target():
        _change_state(AIState.ALERT)
        return
    
    if patrol_points.is_empty():
        _change_state(AIState.IDLE)
        return
    
    var target_point = patrol_points[current_patrol_index]
    var distance = enemy.global_position.distance_to(target_point)
    
    if distance < 10:
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
        # Pausa antes de ir al siguiente punto
        _change_state(AIState.IDLE)
    else:
        _move_towards(target_point)

func _process_alert(delta: float) -> void:
    alert_timer -= delta
    
    if not target or not is_instance_valid(target):
        _change_state(AIState.IDLE)
        return
    
    # Mirar al objetivo
    var direction = (target.global_position - enemy.global_position).normalized()
    enemy.face_direction(direction)
    
    if alert_timer <= 0:
        if _is_target_in_range(detection_radius):
            _change_state(AIState.CHASE)
            # Alertar aliados
            if enemy.enemy_resource and enemy.enemy_resource.aggro_group:
                _alert_nearby_allies()
        else:
            _change_state(AIState.IDLE)

func _process_chase(_delta: float) -> void:
    if not target or not is_instance_valid(target):
        _change_state(AIState.RETURN)
        return
    
    var distance = enemy.global_position.distance_to(target.global_position)
    
    if distance > chase_radius:
        target = null
        target_lost.emit()
        _change_state(AIState.RETURN)
    elif distance <= attack_radius:
        _change_state(AIState.ATTACK)
    else:
        _move_towards(target.global_position)
        enemy.face_direction((target.global_position - enemy.global_position).normalized())

func _process_attack(_delta: float) -> void:
    if not target or not is_instance_valid(target):
        _change_state(AIState.IDLE)
        return
    
    var distance = enemy.global_position.distance_to(target.global_position)
    
    if distance > attack_radius * 1.5:
        _change_state(AIState.CHASE)
        return
    
    enemy.face_direction((target.global_position - enemy.global_position).normalized())
    
    if attack_timer <= 0:
        _perform_attack()
        attack_timer = attack_cooldown

func _process_flee(_delta: float) -> void:
    if not target or not is_instance_valid(target):
        _change_state(AIState.IDLE)
        return
    
    var flee_direction = (enemy.global_position - target.global_position).normalized()
    var flee_target = enemy.global_position + flee_direction * 150
    _move_towards(flee_target)
    
    # Si recupera suficiente HP, volver a pelear
    if enemy.health.get_health_percent() > flee_hp_percent + 0.15:
        _change_state(AIState.CHASE)

func _process_return(_delta: float) -> void:
    var distance = enemy.global_position.distance_to(home_position)
    
    if distance < 20:
        target = null
        _change_state(AIState.IDLE)
        # Curar al volver a casa
        if enemy.health:
            enemy.health.heal(enemy.health.max_health)
    else:
        _move_towards(home_position)

func _detect_target() -> bool:
    var players = get_tree().get_nodes_in_group("players")
    var closest_player: Node = null
    var closest_distance: float = detection_radius
    
    for player in players:
        if not is_instance_valid(player):
            continue
        var distance = enemy.global_position.distance_to(player.global_position)
        if distance < closest_distance:
            closest_distance = distance
            closest_player = player
    
    if closest_player:
        target = closest_player
        target_acquired.emit(closest_player)
        return true
    
    return false

func _is_target_in_range(radius: float) -> bool:
    if not target or not is_instance_valid(target):
        return false
    return enemy.global_position.distance_to(target.global_position) <= radius

func _alert_nearby_allies() -> void:
    var enemies = get_tree().get_nodes_in_group("enemies")
    for other_enemy in enemies:
        if other_enemy == enemy:
            continue
        if other_enemy.ai and other_enemy.ai.current_state in [AIState.IDLE, AIState.PATROL]:
            var distance = enemy.global_position.distance_to(other_enemy.global_position)
            if distance < detection_radius * 1.5:
                other_enemy.ai.target = target
                other_enemy.ai._change_state(AIState.CHASE)

func _move_towards(target_pos: Vector2) -> void:
    var direction = (target_pos - enemy.global_position).normalized()
    var speed = enemy.stats.get_stat("speed") if enemy.stats else 80.0
    enemy.velocity = direction * speed
    enemy.move_and_slide()
    
    # Animación de caminar
    if enemy.fsm and not enemy.fsm.is_in_state("walk"):
        enemy.play_animation("walk")

func _perform_attack() -> void:
    if not enemy.fsm:
        return
    enemy.fsm.transition_to("attack")

func _change_state(new_state: AIState) -> void:
    current_state = new_state
    state_changed.emit(_get_state_name(new_state))
    
    match new_state:
        AIState.IDLE:
            enemy.play_animation("idle")
        AIState.PATROL:
            enemy.play_animation("walk")
        AIState.ALERT:
            alert_timer = alert_duration
            enemy.play_animation("alert")
        AIState.CHASE:
            enemy.play_animation("run")
        AIState.RETURN:
            enemy.play_animation("walk")

func _get_state_name(state: AIState) -> String:
    match state:
        AIState.IDLE: return "idle"
        AIState.PATROL: return "patrol"
        AIState.ALERT: return "alert"
        AIState.CHASE: return "chase"
        AIState.ATTACK: return "attack"
        AIState.FLEE: return "flee"
        AIState.RETURN: return "return"
        _: return "unknown"