extends Node2D

# =========================================================================
# GENERADOR DE MUNDO 2D - MUNDO INFINITO POR CHUNKS
# El mundo ya no tiene tamaño fijo: se generan chunks de TAMANO_CHUNK x
# TAMANO_CHUNK tiles alrededor del jugador a medida que se mueve, y se
# descargan los que quedan muy lejos para no acumular memoria para siempre.
#
# Como el bioma de cada celda depende SOLO de sus coordenadas globales
# (x,y) a través del ruido, dos chunks vecinos generados en momentos
# distintos siempre calzan sin costuras (mismo input -> mismo resultado).
# =========================================================================

@onready var nodo_piso: TileMapLayer = $Piso
@onready var nodo_decoracion: TileMapLayer = $Piso/Decoracion

const ESCENA_HUD := preload("res://Escenas/HUD.tscn")
const TAMANO_TILE_PX := 16

@onready var hud: Node
var jugador: Node2D

@export_group("Chunks")
@export var tamano_chunk: int = 16          # Tiles por lado de cada chunk
@export var radio_carga: int = 3            # Chunks alrededor del jugador que se mantienen generados
@export var radio_descarga: int = 5         # Más allá de este radio, se descargan

@export_group("Ruido - Terreno")
@export var frecuencia_terreno: float = 0.015
@export var octavas_terreno: int = 4
@export var fuerza_warp: float = 40.0

@export_group("Ruido - Decoración")
@export var frecuencia_decoracion: float = 0.35
@export var frecuencia_parches: float = 0.06
@export var umbral_decoracion: float = 0.2

var ruido_terreno: FastNoiseLite
var ruido_humedad: FastNoiseLite
var ruido_warp_x: FastNoiseLite
var ruido_warp_y: FastNoiseLite
var ruido_decoracion: FastNoiseLite
var ruido_parches: FastNoiseLite

const FUENTE_ID = 0

enum Bioma { MORADO, VERDE, SECO, OTONAL, VERDE_OSCURO, PASTO_AZULADO }

const TERRAIN_SET_ID: int = 0
const BIOMA_A_TERRENO := {
    Bioma.VERDE:          0,
    Bioma.OTONAL:         1,
    Bioma.SECO:           2,
    Bioma.MORADO:         3,
    Bioma.VERDE_OSCURO:   4,
    Bioma.PASTO_AZULADO:  5,
}

var paleta_decoracion: Dictionary = {}

# --- Estado de chunks cargados ---
var chunks_cargados: Dictionary = {}   # Vector2i (coord. de chunk) -> true
var chunk_actual: Vector2i = Vector2i(999999, 999999)  # fuerza la primera carga


func _ready() -> void:
    randomize()
    _configurar_ruidos()
    _construir_paleta_decoracion()
    _instanciar_hud()
    _instanciar_personaje()

    # Carga inicial de chunks alrededor del punto de aparición, antes del
    # primer frame, para que el jugador no aparezca sobre un vacío.
    chunk_actual = _posicion_a_chunk(jugador.position)
    _actualizar_chunks_cercanos()


func _process(_delta: float) -> void:
    if jugador == null:
        return
    var nuevo_chunk = _posicion_a_chunk(jugador.position)
    if nuevo_chunk != chunk_actual:
        chunk_actual = nuevo_chunk
        _actualizar_chunks_cercanos()


func _posicion_a_chunk(pos: Vector2) -> Vector2i:
    var tam_px = float(tamano_chunk * TAMANO_TILE_PX)
    return Vector2i(int(floor(pos.x / tam_px)), int(floor(pos.y / tam_px)))


func _actualizar_chunks_cercanos() -> void:
    var necesarios := {}

    for dx in range(-radio_carga, radio_carga + 1):
        for dy in range(-radio_carga, radio_carga + 1):
            var c = chunk_actual + Vector2i(dx, dy)
            necesarios[c] = true
            if not chunks_cargados.has(c):
                _generar_chunk(c)
                chunks_cargados[c] = true

    # Descargamos chunks que quedaron demasiado lejos, para que la memoria
    # no crezca para siempre en una sesión larga de "mundo infinito".
    for c in chunks_cargados.keys():
        if not necesarios.has(c) and Vector2(c - chunk_actual).length() > radio_descarga:
            _descargar_chunk(c)
            chunks_cargados.erase(c)


func _instanciar_hud() -> void:
    hud = ESCENA_HUD.instantiate()
    add_child(hud)


func _instanciar_personaje() -> void:
    var ruta = DatosDelJugador.CLASES.get(DatosDelJugador.clase_seleccionada)
    if ruta == null:
        push_error("Clase no encontrada: " + DatosDelJugador.clase_seleccionada)
        return
    var escena = load(ruta) as PackedScene
    if escena == null:
        push_error("No se pudo cargar la escena: " + ruta)
        return
    jugador = escena.instantiate()
    jugador.position = Vector2.ZERO  # El mundo ya no tiene tamaño fijo: se aparece en el origen (chunk 0,0)
    add_child(jugador)

    jugador.vida_cambio.connect(hud.actualizar_vida)
    jugador.mana_cambio.connect(hud.actualizar_mana)
    jugador.exp_cambio.connect(hud.actualizar_exp)
    jugador.stamina_cambio.connect(hud.actualizar_stamina)
    jugador.monedas_cambiaron.connect(hud.actualizar_monedas)
    jugador.vida_cambio.emit(jugador.vida, jugador.vida_max)
    jugador.mana_cambio.emit(jugador.mana, jugador.mana_max)
    jugador.exp_cambio.emit(jugador.exp, jugador.exp_max)
    jugador.stamina_cambio.emit(jugador.stamina, jugador.stamina_max)
    jugador.monedas_cambiaron.emit(Stats.monedas)


func _configurar_ruidos() -> void:
    ruido_terreno = FastNoiseLite.new()
    ruido_terreno.seed = randi()
    ruido_terreno.noise_type = FastNoiseLite.TYPE_PERLIN
    ruido_terreno.frequency = frecuencia_terreno
    ruido_terreno.fractal_type = FastNoiseLite.FRACTAL_FBM
    ruido_terreno.fractal_octaves = octavas_terreno
    ruido_terreno.fractal_lacunarity = 2.0
    ruido_terreno.fractal_gain = 0.5

    ruido_humedad = FastNoiseLite.new()
    ruido_humedad.seed = randi() + 100
    ruido_humedad.noise_type = FastNoiseLite.TYPE_PERLIN
    ruido_humedad.frequency = frecuencia_terreno * 1.3
    ruido_humedad.fractal_type = FastNoiseLite.FRACTAL_FBM
    ruido_humedad.fractal_octaves = 3

    ruido_warp_x = FastNoiseLite.new()
    ruido_warp_x.seed = randi() + 200
    ruido_warp_x.frequency = 0.01

    ruido_warp_y = FastNoiseLite.new()
    ruido_warp_y.seed = randi() + 300
    ruido_warp_y.frequency = 0.01

    ruido_decoracion = FastNoiseLite.new()
    ruido_decoracion.seed = randi() + 10
    ruido_decoracion.noise_type = FastNoiseLite.TYPE_PERLIN
    ruido_decoracion.frequency = frecuencia_decoracion

    ruido_parches = FastNoiseLite.new()
    ruido_parches.seed = randi() + 400
    ruido_parches.frequency = frecuencia_parches


func _rango_atlas(col_ini: int, col_fin: int, row_ini: int, row_fin: int) -> Array[Vector2i]:
    var resultado: Array[Vector2i] = []
    for c in range(col_ini, col_fin + 1):
        for r in range(row_ini, row_fin + 1):
            resultado.append(Vector2i(c, r))
    return resultado


func _construir_paleta_decoracion() -> void:
    paleta_decoracion = {
        Bioma.VERDE:         _rango_atlas(0, 3, 12, 13),
        Bioma.OTONAL:        _rango_atlas(4, 7, 12, 13),
        Bioma.SECO:          _rango_atlas(8, 11, 12, 13) + _rango_atlas(10, 11, 10, 11),
        Bioma.MORADO:        _rango_atlas(12, 15, 10, 13),
        Bioma.VERDE_OSCURO:  _rango_atlas(16, 19, 10, 13),
        Bioma.PASTO_AZULADO: _rango_atlas(20, 24, 10, 13),
    }


# -------------------------------------------------------------------------
# Bioma "crudo" de una celda: función pura de (x,y). Da igual qué chunk lo
# pida, siempre devuelve lo mismo -> por eso los bordes de chunk calzan.
# -------------------------------------------------------------------------
func _bioma_crudo(x: int, y: int) -> int:
    var offset_x = ruido_warp_x.get_noise_2d(x, y) * fuerza_warp
    var offset_y = ruido_warp_y.get_noise_2d(x, y) * fuerza_warp
    var elevacion = ruido_terreno.get_noise_2d(x + offset_x, y + offset_y)
    var humedad = ruido_humedad.get_noise_2d(x + offset_x, y + offset_y)
    return _clasificar_bioma(elevacion, humedad)


# HÚMEDO / SECO en 3 niveles de elevación -> 6 biomas del asset.
func _clasificar_bioma(elevacion: float, humedad: float) -> int:
    var humedo = humedad > 0.0
    if elevacion < -0.25:
        return Bioma.MORADO if humedo else Bioma.PASTO_AZULADO
    elif elevacion < 0.2:
        return Bioma.VERDE if humedo else Bioma.SECO
    else:
        return Bioma.VERDE_OSCURO if humedo else Bioma.OTONAL


# Una pasada de "voto de mayoría" sobre los 8 vecinos crudos. Suficiente
# para limpiar píxeles sueltos y queda self-contained (no depende de si
# los chunks vecinos ya se generaron).
func _bioma_final(x: int, y: int) -> int:
    var conteo := {}
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            var b = _bioma_crudo(x + dx, y + dy)
            conteo[b] = conteo.get(b, 0) + 1

    var mejor_bioma = -1
    var mejor_conteo = -1
    for b in conteo.keys():
        if conteo[b] > mejor_conteo:
            mejor_conteo = conteo[b]
            mejor_bioma = b
    return mejor_bioma


# -------------------------------------------------------------------------
# Generar / descargar un chunk individual
# -------------------------------------------------------------------------
func _generar_chunk(chunk_coord: Vector2i) -> void:
    var origen = chunk_coord * tamano_chunk

    var celdas_por_terreno := {}
    var biomas_del_chunk := {}   # Vector2i local -> bioma (para la decoración)

    for x in range(origen.x, origen.x + tamano_chunk):
        for y in range(origen.y, origen.y + tamano_chunk):
            var bioma = _bioma_final(x, y)
            biomas_del_chunk[Vector2i(x, y)] = bioma

            var id_terreno = BIOMA_A_TERRENO.get(bioma, 0)
            if not celdas_por_terreno.has(id_terreno):
                celdas_por_terreno[id_terreno] = []
            celdas_por_terreno[id_terreno].append(Vector2i(x, y))

    for id_terreno in celdas_por_terreno.keys():
        nodo_piso.set_cells_terrain_connect(celdas_por_terreno[id_terreno], TERRAIN_SET_ID, id_terreno, false)

    _pintar_decoracion_chunk(biomas_del_chunk)


func _pintar_decoracion_chunk(biomas_del_chunk: Dictionary) -> void:
    for celda in biomas_del_chunk.keys():
        var bioma = biomas_del_chunk[celda]
        var variantes: Array = paleta_decoracion.get(bioma, [])
        if variantes.is_empty():
            continue

        var v_decoracion = ruido_decoracion.get_noise_2d(celda.x, celda.y)
        var v_parche = ruido_parches.get_noise_2d(celda.x, celda.y)

        if v_parche > 0.1 and v_decoracion > umbral_decoracion:
            var variante = variantes[randi() % variantes.size()]
            nodo_decoracion.set_cell(celda, FUENTE_ID, variante)


func _descargar_chunk(chunk_coord: Vector2i) -> void:
    var origen = chunk_coord * tamano_chunk
    for x in range(origen.x, origen.x + tamano_chunk):
        for y in range(origen.y, origen.y + tamano_chunk):
            var celda = Vector2i(x, y)
            nodo_piso.erase_cell(celda)
            nodo_decoracion.erase_cell(celda)
