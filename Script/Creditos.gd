extends Control

# Arrastra tu escena del Menú Principal aquí en el Inspector de Godot
@export var escena_menu: PackedScene

# Velocidad de subida (píxeles por segundo)
@export var velocidad_scroll: float = 50.0

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var boton_regresar: Button = $Regresar

var posicion_scroll: float = 0.0

func _ready() -> void:
    # 1. Intentar desconectar cualquier señal vieja para evitar que Godot tire errores
    if boton_regresar.pressed.is_connected(_on_regresar_pressed):
        boton_regresar.pressed.disconnect(_on_regresar_pressed)
        
    # 2. Forzar la conexión del botón de forma segura mediante código
    boton_regresar.pressed.connect(_on_regresar_pressed)
    
    # Forzar a que el scroll empiece desde arriba del todo
    scroll_container.scroll_vertical = 0
    posicion_scroll = 0.0

func _process(delta: float) -> void:
    # Mover el scroll vertical de forma suave usando el tiempo delta
    posicion_scroll += velocidad_scroll * delta
    scroll_container.scroll_vertical = int(posicion_scroll)
    
    # Detectar si el usuario llegó al final de la lista de créditos
    var v_bar = scroll_container.get_v_scroll_bar()
    if scroll_container.scroll_vertical >= (v_bar.max_value - scroll_container.size.y):
        set_process(false)
        boton_regresar.visible = true

func _on_regresar_pressed() -> void:
    if escena_menu:
        get_tree().change_scene_to_packed(escena_menu)
    else:
        print("Nota: No has asignado la escena del menú principal en el Inspector.")
