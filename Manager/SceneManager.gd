extends Node

var _main_menu: PackedScene = preload("res://Scenes/UI/Start/Start.tscn")
var _lobby: PackedScene = preload("res://Scenes/UI/Multiplayer/Lobby/Lobby.tscn")

func open_main_menu():
	get_tree().change_scene_to_packed(_main_menu)

func open_lobby():
	get_tree().change_scene_to_packed(_lobby)
