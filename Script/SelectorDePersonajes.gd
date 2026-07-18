extends Control

# Ruta de la escena de tu mapa procedural (¡Asegúrate de que la mayúscula coincida!)
@export var escena_mundo: String = "res://Escenas/Mundo.tscn"
@export var escena_menu: String = "res://Escenas/MenuPrincipal.tscn"

func _ready() -> void:
    # Por defecto, al entrar a este menú, guardamos que la clase elegida es "Aventurero"
    if has_node("DatosJugador"): 
        # Nota: Esto asume que tienes un Autoload llamado DatosJugador configurado
        DatosDelJugador.clase_seleccionada = "Aventurero"

func _on_atras_pressed() -> void:
    get_tree().change_scene_to_file(escena_menu)

func _on_confirmar_clase_pressed() -> void:
    if ResourceLoader.exists(escena_mundo):
        get_tree().change_scene_to_file(escena_mundo)
    else:
        print("Error: No se encontró el archivo del mapa en: ", escena_mundo)
