extends Control

@onready var create_btn = $Actions/Create
@onready var leave_btn = $Actions/Leave
@onready var start_btn = $Actions/Start

@onready var player_items = {
	1: $PlayerList/Left/Player1,
	2: $PlayerList/Left/Player2,
	3: $PlayerList/Left/Player3,
	4: $PlayerList/Left/Player4,
	5: $PlayerList/Right/Player5,
	6: $PlayerList/Right/Player6,
	7: $PlayerList/Right/Player7,
	8: $PlayerList/Right/Player8,
}

#############
### Hooks ###
#############

# Called when the node enters the scene tree for the first time.
func _ready():
	# SteamLobby signals
	SteamLobby.lobby_created.connect(_on_lobby_created)
	SteamLobby.lobby_joined.connect(_on_lobby_joined)
	SteamLobby.lobby_owner_changed.connect(_on_lobby_owner_changed)
	SteamLobby.player_joined_lobby.connect(_on_player_joined_lobby)
	SteamLobby.player_left_lobby.connect(_on_player_left_lobby)
	SteamLobby.chat_message_received.connect(_on_chat_message_received)
	
	# GUI Button signals
	create_btn.pressed.connect(_on_create_btn_pressed)
	leave_btn.pressed.connect(_on_leave_btn_pressed)
	for item in player_items.values():
		item.get_node("HBoxContainer/VBoxContainer/Invite").pressed.connect(_on_invite_pressed)
	
	_render_lobby_members()


#########################
### Private functions ###
#########################

func _render_lobby_members():
	_clear_lobby_members()
	var lobby_members = SteamLobby.get_lobby_members()
	var i = 2
	for member in lobby_members:
		if not SteamNetwork.is_peer_connected(member):
			start_btn.disabled = true
		
		if SteamLobby.is_owner(member):
			_render_host(player_items[1], lobby_members[member])
		else:
			_render_lobby_member(player_items[i], lobby_members[member])
			i += 1

func _render_host(item, member):
	item.get_node("HBoxContainer/VBoxContainer/Invite").hide()
	
	var name = item.get_node("HBoxContainer/VBoxContainer/Name")
	name.text = member
	name.show()

func _render_lobby_member(item, member):
	item.get_node("HBoxContainer/VBoxContainer/Invite").hide()
	
	var name = item.get_node("HBoxContainer/VBoxContainer/Name")
	name.text = member
	name.show()
	
	if SteamLobby.is_owner():
		item.get_node("HBoxContainer/VBoxContainer/MakeHost").show()
		item.get_node("HBoxContainer/VBoxContainer/Kick").show()

func _clear_lobby_members():
	for item in player_items.values():
		item.get_node("HBoxContainer/VBoxContainer/MakeHost").hide()
		item.get_node("HBoxContainer/VBoxContainer/Kick").hide()
		item.get_node("HBoxContainer/VBoxContainer/Name").hide()
		item.get_node("HBoxContainer/VBoxContainer/Invite").show()


############################
### SteamLobby Callbacks ###
############################

func _on_lobby_created(lobby_id: int):
	_render_lobby_members()

func _on_lobby_joined(lobby_id: int):
	_render_lobby_members()

func _on_lobby_owner_changed():
	pass # TODO

func _on_player_joined_lobby(steam_id: int):
	_render_lobby_members()

func _on_player_left_lobby(steam_id: int):
	_render_lobby_members()

func _on_chat_message_received():
	pass # TODO


############################
### GUI Button Callbacks ###
############################

func _on_create_btn_pressed():
	if SteamLobby.in_lobby():
		SteamLobby.leave_lobby()
	
	SteamLobby.create_lobby(Steam.LOBBY_TYPE_PUBLIC, 8)
	create_btn.hide()
	leave_btn.show()

func _on_invite_pressed():
	Steam.activateGameOverlayInviteDialog(SteamLobby.get_lobby_id())

func _on_leave_btn_pressed():
	SteamLobby.leave_lobby()
	SceneManager.open_main_menu()
