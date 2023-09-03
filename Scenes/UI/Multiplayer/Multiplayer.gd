extends Control


func _on_host_pressed():
	SceneManager.open_lobby()
	if SteamLobby.in_lobby():
		SteamLobby.leave_lobby()
	
	SteamLobby.create_lobby(Steam.LOBBY_TYPE_PUBLIC, 8)

func _on_join_pressed():
	pass # Replace with function body.
