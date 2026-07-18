extends Control

func _on_iniciar_aventura_pressed() -> void:
    get_tree().change_scene_to_file("res://Escenas/SelectorDePersonajes.tscn")


func _on_configuracion_pressed() -> void:
    pass # Replace with function body.


func _on_salir_del_juego_pressed() -> void:
    get_tree().quit()
