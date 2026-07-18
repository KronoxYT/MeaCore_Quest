extends CharacterBody2D

# --- Señales separadas por stat, en vez de una sola señal con 8 argumentos ---
# Así cada elemento del HUD se conecta solo a la que le interesa, sin
# riesgo de "Method expected N argument(s), but called with M".
signal vida_cambio(vida: int, vida_max: int)
signal mana_cambio(mana: int, mana_max: int)
signal exp_cambio(exp: int, exp_max: int)
signal stamina_cambio(stamina: int, stamina_max: int)
signal monedas_cambiaron(cantidad: int)

@export var velocidad: float = 170.0

@export_group("Stats")
@export var vida_max: int = 100
@export var mana_max: int = 50
@export var exp_max: int = 100
@export var stamina_max: int = 100
@export var costo_stamina_ataque: int = 10
@export var tasa_regeneracion_stamina: float = 15.0
@export var retraso_regeneracion_stamina: float = 1.5  # Segundos quieto antes de regenerar

var vida: int = vida_max
var mana: int = mana_max
@warning_ignore("SHADOWED_GLOBAL_IDENTIFIER")
var exp: int = 0
var stamina: int = stamina_max

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var ultima_direccion: String = "Abajo"
var esta_atacando: bool = false
var timer_seguridad_ataque: Timer
var tiempo_sin_moverse: float = 0.0  # Acumula mientras el personaje está quieto y no ataca

func _ready() -> void:
    vida = vida_max
    mana = mana_max
    stamina = stamina_max

    callable_emitir_stats.call_deferred()

    anim.animation_finished.connect(_on_animation_finished)

    if anim.sprite_frames:
        for nombre in anim.sprite_frames.get_animation_names():
            if nombre.begins_with("Ataque"):
                anim.sprite_frames.set_animation_loop(nombre, false)

    timer_seguridad_ataque = Timer.new()
    timer_seguridad_ataque.one_shot = true
    timer_seguridad_ataque.wait_time = 1.0
    timer_seguridad_ataque.timeout.connect(_liberar_ataque)
    add_child(timer_seguridad_ataque)

func _physics_process(delta: float) -> void:
    var direccion = _leer_direccion_input()

    # --- Control de "tiempo quieto" para el retraso de regeneración ---
    # Se reinicia apenas te mueves o atacas; solo cuenta mientras estás
    # parado sin hacer nada.
    if direccion == Vector2.ZERO and not esta_atacando:
        tiempo_sin_moverse += delta
    else:
        tiempo_sin_moverse = 0.0

    if not esta_atacando and stamina < stamina_max and tiempo_sin_moverse >= retraso_regeneracion_stamina:
        _recuperar_stamina(tasa_regeneracion_stamina * delta)

    if esta_atacando:
        velocity = Vector2.ZERO
        move_and_slide()
        return

    # ATAQUE CONTINUO: is_action_pressed (no just_pressed) permite que,
    # mientras mantengas el botón/click, se encadene un ataque tras otro
    # apenas termina el anterior (esta_atacando vuelve a false), siempre
    # que tengas stamina suficiente. Si no hay stamina, NO cortamos el
    # turno con "return": dejamos que el personaje se pueda mover igual.
    if (Input.is_action_pressed("ui_accept") or Input.is_action_pressed("click_ataque")) and stamina >= costo_stamina_ataque:
        var tipo_ataque = "Ataque1_" if randf() > 0.5 else "Ataque2_"
        _gastar_stamina(costo_stamina_ataque)
        _ejecutar_ataque(tipo_ataque)
        return

    if direccion != Vector2.ZERO:
        velocity = direccion * velocidad

        if abs(direccion.x) > abs(direccion.y):
            if direccion.x > 0:
                ultima_direccion = "Derecha"
            else:
                ultima_direccion = "Izquierda"
        else:
            if direccion.y > 0:
                ultima_direccion = "Abajo"
            else:
                ultima_direccion = "Arriba"

        anim.flip_h = false
        anim.play("Correr_" + ultima_direccion)
    else:
        velocity = velocity.move_toward(Vector2.ZERO, velocidad)
        anim.flip_h = false
        anim.play("Reposo_" + ultima_direccion)

    move_and_slide()

func _leer_direccion_input() -> Vector2:
    var direccion = Vector2.ZERO

    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        direccion.x += 1
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        direccion.x -= 1
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        direccion.y += 1
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        direccion.y -= 1

    return direccion.normalized()

func _ejecutar_ataque(nombre_ataque: String) -> void:
    esta_atacando = true
    velocity = Vector2.ZERO
    var nombre_completo = nombre_ataque + ultima_direccion

    if anim.sprite_frames and anim.sprite_frames.has_animation(nombre_completo):
        anim.flip_h = false
        anim.play(nombre_completo)
        timer_seguridad_ataque.start()
    else:
        push_warning("Animación de ataque no encontrada: " + nombre_completo)
        esta_atacando = false

func _on_animation_finished() -> void:
    if anim.animation.begins_with("Ataque"):
        _liberar_ataque()

func _liberar_ataque() -> void:
    esta_atacando = false
    timer_seguridad_ataque.stop()

func _gastar_stamina(cantidad: float) -> void:
    stamina = max(0, stamina - int(cantidad))
    stamina_cambio.emit(int(stamina), stamina_max)

func _recuperar_stamina(cantidad: float) -> void:
    stamina = min(stamina_max, stamina + int(cantidad))
    stamina_cambio.emit(int(stamina), stamina_max)

func callable_emitir_stats() -> void:
    if has_node("/root/Stats"):
        exp = Stats.exp_total
        monedas_cambiaron.emit(Stats.monedas)
    _emitir_stats()

# Emite las 4 señales de una vez (útil al iniciar, o cuando cambian varias juntas)
func _emitir_stats() -> void:
    vida_cambio.emit(vida, vida_max)
    mana_cambio.emit(mana, mana_max)
    exp_cambio.emit(exp, exp_max)
    stamina_cambio.emit(int(stamina), stamina_max)

func recibir_danio(cantidad: int) -> void:
    vida = max(0, vida - cantidad)
    vida_cambio.emit(vida, vida_max)
    if vida <= 0:
        _morir()

func ganar_exp(cantidad: int) -> void:
    exp += cantidad
    if has_node("/root/Stats"):
        Stats.agregar_exp(cantidad)
    exp_cambio.emit(exp, exp_max)

func ganar_monedas(cantidad: int) -> void:
    if has_node("/root/Stats"):
        Stats.agregar_monedas(cantidad)
        monedas_cambiaron.emit(Stats.monedas)

func _morir() -> void:
    set_process(false)
    set_physics_process(false)
    print("El jugador ha muerto.")
