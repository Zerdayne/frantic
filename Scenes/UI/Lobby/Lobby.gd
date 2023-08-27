extends Control

enum search_distance {
	Close,
	Default,
	Far,
	Worldwide
}

@onready var steam_name = $SteamName
@onready var lobby_set_name = $Create/LobbyName
@onready var lobby_get_name = $Chat/Name
@onready var lobby_output = $Chat/RichTextLabel
@onready var lobby_popup = $LobbyPopup
@onready var lobby_list = $LobbyPopup/Panel/ScrollContainer/VBoxContainer
@onready var player_count = $Players/Label
@onready var player_list = $Players/RichTextLabel
@onready var chat_input = $Message/TextEdit

func _ready():
	steam_name.text = Global.STEAM_USERNAME
	
	# Steamwork Connections
	Steam.connect("lobby_created", _on_lobby_created)
	Steam.connect("lobby_match_list", _on_lobby_match_list)
	Steam.connect("lobby_joined", _on_lobby_joined)
	Steam.connect("lobby_chat_update", _on_lobby_chat_update)
	Steam.connect("lobby_message", _on_lobby_message)
	Steam.connect("lobby_data_update", _on_lobby_data_update)
	Steam.connect("join_requested", _on_lobby_join_requested)
	
	# Check for command line arguments
	check_command_line()

func create_lobby():
	# Check no other lobby is running
	if Global.LOBBY_ID == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 8)

func join_lobby(lobby_id):
	lobby_popup.hide()
	var name = Steam.getLobbyData(lobby_id, "name")
	display_message("Joining lobby " + str(name) + "...")
	
	# Clear previous lobby members list
	Global.LOBBY_MEMBERS.clear()
	
	# Steam join request
	Steam.joinLobby(lobby_id)

func get_lobby_members():
	# Clear previous lobby members list
	Global.LOBBY_MEMBERS.clear()
	
	# Get number of members in lobby
	var member_count = Steam.getNumLobbyMembers(Global.LOBBY_ID)
	# Update player list count
	player_count.set_text("Players (" + str(member_count) + ")")
	
	# Get members data
	for member in range(0, member_count):
		# Members Steam ID
		var member_steam_id = Steam.getLobbyMemberByIndex(Global.LOBBY_ID, member)
		# Members Steam Name
		var member_steam_name = Steam.getFriendPersonaName(member_steam_id)
		# Add member to list
		add_player_list(member_steam_id, member_steam_name)

func add_player_list(steam_id, steam_name):
	# Add player to list
	Global.LOBBY_MEMBERS.append({"steam_id": steam_id, "steam_name": steam_name})
	# Ensure list is cleared
	player_list.clear()
	# Populate player list
	for member in Global.LOBBY_MEMBERS:
		player_list.add_text(str(member['steam_name']) + "\n")

func send_chat_message():
	# Get chat input
	var message = chat_input.text
	# Pass message to steam
	var sent = Steam.sendLobbyChatMsg(Global.LOBBY_ID, message)
	# Check message sent
	if not sent:
		display_message("ERROR: Chat message failed to send.")
	# Clear chat input
	chat_input.text = ""

func leave_lobby():
	if Global.LOBBY_ID == 0:
		return
	
	display_message("Leaving lobby...")
	# Send leave request
	Steam.leaveLobby(Global.LOBBY_ID)
	# Wipe lobby id
	Global.LOBBY_ID = 0
	
	lobby_get_name.text = "Lobby Name"
	player_count.text = "Players (0)"
	player_list.clear()
	
	# Close session with all users
	for member in Global.LOBBY_MEMBERS:
		Steam.closeP2PSessionWithUser(member['steam_id'])
	
	# Clear lobby list
	Global.LOBBY_MEMBERS.clear()

func display_message(message):
	lobby_output.add_text("\n" + str(message))

###########################
### Steamwork Callbacks ###
###########################

func _on_lobby_created(connect, lobby_id):
	if connect == 1:
		# Set lobby id
		Global.LOBBY_ID = lobby_id
		display_message("Created Lobby: " + lobby_set_name.text)
		
		# Set lobby data
		Steam.setLobbyData(lobby_id, "name", lobby_set_name.text)
		var name = Steam.getLobbyData(lobby_id, "name")
		lobby_get_name.text = str(name)

func _on_lobby_match_list(lobbies):
	for lobby in lobbies:
		# Grab desired lobby data
		var lobby_name = Steam.getLobbyData(lobby, "name")
		
		# Get the current number of members
		var lobby_members = Steam.getNumLobbyMembers(lobby)
		
		# Create button for each lobby
		var lobby_button = Button.new()
		lobby_button.set_text("Lobby " + str(lobby) + ": " + str(lobby_name) + " - [" + str(lobby_members) + "] Player(s)")
		lobby_button.set_size(Vector2(1620, 50))
		lobby_button.set_name("lobby_" + str(lobby))
		lobby_button.pressed.connect(join_lobby.bind(lobby))
		
		# Add lobby to the list
		lobby_list.add_child(lobby_button)

func _on_lobby_joined(lobby_id, permissions, locked, response):
	# Set lobby id
	Global.LOBBY_ID = lobby_id
	
	# Get the lobby name
	var name = Steam.getLobbyData(lobby_id, "name")
	lobby_get_name.text = str(name)
	
	# Get lobby members
	get_lobby_members()
	
	SteamNetwork.make_p2p_handshake()

func _on_lobby_chat_update(lobby_id, changed_id, making_change_id, chat_state):
	# User who made lobby change
	var changer = Steam.getFriendPersonaName(making_change_id)
	
	# chat_state change made
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		display_message(str(changer) + " has joined the lobby.")
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		display_message(str(changer) + " has left the lobby.")
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
		display_message(str(changer) + " disconnected from the lobby.")
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		display_message(str(changer) + " has been kicked from the lobby.")
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		display_message(str(changer) + " has been banned the lobby.")
	else:
		display_message(str(changer) + " did... something.")
	
	# Update lobby
	get_lobby_members()

func _on_lobby_message(result, user, message, type):
	# Sender and their message
	var sender = Steam.getFriendPersonaName(user)
	display_message(str(sender) + ": " + str(message))

func _on_lobby_data_update(success, lobby_id, member_id, key):
	print("Success: " + str(success) + ", Lobby ID: " + str(lobby_id) + ", Member ID: " + str(member_id) + ", Key: " + str(key))

func _on_lobby_join_requested(lobby_id, friend_id):
	# Get lobby owners name
	var OWNER_NAME = Steam.getFriendPersonaName(friend_id)
	display_message("Joining " + str(OWNER_NAME) + " lobby...")
	
	# Join lobby
	join_lobby(lobby_id)

###############################
### Button Signal Functions ###
###############################

func _on_create_pressed():
	create_lobby()

func _on_join_pressed():
	lobby_popup.popup()
	
	# Set server search distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	display_message("Searching for lobbies...")
	
	Steam.requestLobbyList()

func _on_start_pressed():
	pass # Replace with function body.

func _on_leave_pressed():
	leave_lobby()

func _on_message_pressed():
	send_chat_message()

func _on_close_pressed():
	lobby_popup.hide()

##############################
### Command Line Arguments ###
##############################

func check_command_line():
	var ARGUMENTS = OS.get_cmdline_args()
	
	# Check if detected arguments
	if ARGUMENTS.size() > 0:
		for argument in ARGUMENTS:
			# Invite argument passed
			if Global.LOBBY_INVITE_FLAG:
				join_lobby(int(argument))
			
			# Steam connection argument
			if argument == "+connect_lobby":
				Global.LOBBY_INVITE_FLAG = true
