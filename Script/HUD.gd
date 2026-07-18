extends CanvasLayer

@onready var vida_bar: ProgressBar = $MainContainer/TopRow/BarsColumn/VidaBar
@onready var mana_bar: ProgressBar = $MainContainer/TopRow/BarsColumn/ManaBar
@onready var exp_bar: ProgressBar = $MainContainer/TopRow/BarsColumn/EXPBar
@onready var stamina_bar: ProgressBar = $MainContainer/TopRow/BarsColumn/StaminaBar
@onready var moneda_label: Label = $Monedas/MonedaCount
@onready var calavera_texture: TextureRect = $MainContainer/TopRow/Calavera/CalaveraTexture

func _ready() -> void:
    moneda_label.text = str(Stats.monedas)

func actualizar_vida(actual: int, maximo: int) -> void:
    vida_bar.max_value = maximo
    vida_bar.value = actual

func actualizar_mana(actual: int, maximo: int) -> void:
    mana_bar.max_value = maximo
    mana_bar.value = actual

func actualizar_exp(actual: int, maximo: int) -> void:
    exp_bar.max_value = maximo
    exp_bar.value = actual

func actualizar_stamina(actual: int, maximo: int) -> void:
    stamina_bar.max_value = maximo
    stamina_bar.value = actual

    var porcentaje := actual / float(maximo)
    var color: Color

    if porcentaje > 0.6:
        color = Color(0.1, 0.7, 0.2)
    elif porcentaje > 0.3:
        color = Color(0.9, 0.6, 0.05)
    else:
        color = Color(0.8, 0.1, 0.1)

    var estilo := StyleBoxFlat.new()
    estilo.bg_color = color
    estilo.corner_radius_top_left = 2
    estilo.corner_radius_top_right = 2
    estilo.corner_radius_bottom_right = 2
    estilo.corner_radius_bottom_left = 2
    stamina_bar.add_theme_stylebox_override("fill", estilo)

func actualizar_monedas(cantidad: int) -> void:
    moneda_label.text = str(cantidad)

func mostrar_calavera(textura: Texture2D) -> void:
    calavera_texture.texture = textura
