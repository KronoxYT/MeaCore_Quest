extends Node2D

func _ready():
	var spawn = $PlayerSpawn
	if spawn:
		var player = $Player
		if player:
			player.global_position = spawn.position

	var portal = $ReturnPortal
	if portal:
		portal.body_entered.connect(_on_return_portal_entered)

	GameManager.add_chat_msg("[Sistema]", "Has entrado a una zona segura.", Color(0.3, 0.8, 1.0))

func _on_return_portal_entered(body):
	if body.is_in_group("player"):
		GameManager.add_chat_msg("[Portal]", "Regresas al mundo principal.", Color(0.3, 0.8, 1.0))
		get_tree().change_scene_to_file("res://Scenes/MainGame.tscn")
