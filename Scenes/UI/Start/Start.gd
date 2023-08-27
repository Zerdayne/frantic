extends Control

@export var game_scene : PackedScene
@export var lobby_scene : PackedScene

func _ready():
	Global._set_rich_presence("#MainMenu")

func _on_play_pressed():
	CardGameManager.start_game(game_scene)

func _on_multiplayer_pressed():
	get_tree().change_scene_to_packed(lobby_scene)
