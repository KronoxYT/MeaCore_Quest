extends Control

func _on_iniciar_aventura_pressed() -> void:
    get_tree().change_scene_to_file("res://Scenes/MainGame.tscn")


func _on_configuracion_pressed() -> void:
    get_tree().change_scene_to_file("res://Scenes/Configuracion.tscn")


func _on_salir_del_juego_pressed() -> void:
    get_tree().quit()
