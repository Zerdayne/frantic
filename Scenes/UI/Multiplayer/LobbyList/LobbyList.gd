extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	SteamLobby.lobby_list.connect(_on_lobby_list)
	refresh()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func refresh():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

func _on_lobby_list(lobbies: Array):
	for lobby_id in lobbies:
		$ItemList.add_item(str(lobby_id))

func _on_create_pressed():
	if SteamLobby.in_lobby():
		SteamLobby.leave_lobby()
	
	SteamLobby.create_lobby(Steam.LOBBY_TYPE_PUBLIC, 8)
	SceneManager.open_lobby()


func _on_item_list_item_selected(index):
	SteamLobby.join_lobby(int($ItemList.get_item_text(index)))
	SceneManager.open_lobby()
