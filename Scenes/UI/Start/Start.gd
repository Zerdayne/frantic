extends Control

@export var game_scene : PackedScene
@export var multiplayer_scene : PackedScene

func _ready():
	RichPresence.main_menu()

func _on_play_pressed():
	CardGameManager.start_game(game_scene)

func _on_multiplayer_pressed():
	SceneManager.open_lobby_list()
