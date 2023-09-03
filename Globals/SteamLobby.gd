extends Node

###############
### Signals ###
###############

signal player_joined_lobby(lobby_id)
signal player_left_lobby(steam_id)

signal lobby_created(lobby_id)
signal lobby_joined(lobby_id)
signal lobby_join_requested(lobby_id)
signal lobby_owner_changed(previous_owner, new_owner)
signal lobby_data_updated(steam_id)

signal chat_message_received(sender, message)


#################
### Variables ###
#################

var _STEAM_ID: int = 0
var _LOBBY_ID: int = 0
var _LOBBY_HOST: int = 0
var _LOBBY_MEMBERS: Dictionary = {}

var _IS_CREATING_LOBBY: bool = false


#############
### Hooks ###
#############

func _ready():
	set_steam_id(Steam.getSteamID())
	if get_steam_id() == 0:
		push_warning("[STEAM_LOBBY] Unable to get steam id of user, check steam has been initialized first.")
		return
	
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_message.connect(_on_lobby_message)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.join_requested.connect(_on_lobby_join_requested)
	
	_check_command_line()

func _exit_tree():
	leave_lobby()


###############
### Getters ###
###############

func get_steam_id() -> int:
	return _STEAM_ID

func get_lobby_id() -> int:
	return _LOBBY_ID

func get_lobby_host() -> int:
	return _LOBBY_HOST

func get_lobby_members() -> Dictionary:
	_update_lobby_members()
	return _LOBBY_MEMBERS

func is_creating_lobby() -> bool:
	return _IS_CREATING_LOBBY


########################
### Spoecial Getters ###
########################

func in_lobby() -> bool:
	return not get_lobby_id() == 0

func is_owner(steam_id = -1) -> bool:
	if steam_id > 0:
		return get_lobby_host() == steam_id
	return get_lobby_host() == get_steam_id()

func get_lobby_member(steam_id) -> String:
	return _LOBBY_MEMBERS[steam_id]

func has_lobby_member(steam_id: int) -> bool:
	return _LOBBY_MEMBERS.has(steam_id)


###############
### Setters ###
###############

func set_steam_id(steam_id: int) -> void:
	_STEAM_ID = steam_id

func set_lobby_id(lobby_id: int) -> void:
	_LOBBY_ID = lobby_id

func set_lobby_host(steam_id: int) -> void:
	_LOBBY_HOST = steam_id

func set_is_creating_lobby(is_creating_lobby: bool) -> void:
	_IS_CREATING_LOBBY = is_creating_lobby


########################
### Spoecial Setters ###
########################

func add_lobby_member(steam_id: int, steam_name: String) -> void:
	_LOBBY_MEMBERS[steam_id] = steam_name

func clear_lobby_members() -> void:
	_LOBBY_MEMBERS.clear()


########################
### Public Functions ###
########################

func create_lobby(lobby_type: Steam.LobbyType, max_players: int = 2) -> void:
	if is_creating_lobby():
		return
	set_is_creating_lobby(true)
	
	if not in_lobby():
		print("[STEAM_LOBBY] Trying to create lobby of type %s" % lobby_type)
		Steam.createLobby(lobby_type, max_players)

func join_lobby(lobby_id: int) -> void:
	print("[STEAM_LOBBY] Trying to join lobby %s" % lobby_id)
	if not in_lobby():
		clear_lobby_members()
		Steam.joinLobby(lobby_id)

func leave_lobby():
	if in_lobby():
		var lobby_id = get_lobby_id()
		print("[STEAM_LOBBY] Leaving lobby %s" % lobby_id)
		
		Steam.leaveLobby(lobby_id)
		
		set_lobby_id(0)
		
		var members = get_lobby_members()
		for steam_id in members.keys():
			if steam_id == get_steam_id():
				continue
			
			var session_state = Steam.getP2PSessionState(steam_id)
			if session_state.has("connection_active") and session_state["connection_active"]:
				Steam.closeP2PSessionWithUser(steam_id)
		
		clear_lobby_members()
		player_left_lobby.emit(get_steam_id())


#########################
### Private Functions ###
#########################

func _update_lobby_members() -> void:
	var lobby_id = get_lobby_id()
	
	clear_lobby_members()
	set_lobby_host(Steam.getLobbyOwner(get_lobby_id()))
	
	var members_count: int = Steam.getNumLobbyMembers(lobby_id)
	for member_index in range(0, members_count):
		var member_steam_id = Steam.getLobbyMemberByIndex(lobby_id, member_index)
		var member_steam_name = Steam.getFriendPersonaName(member_steam_id)
		add_lobby_member(member_steam_id, member_steam_name)

func _owner_changed(from: int, to: int) -> void:
	lobby_owner_changed.emit(from, to)


#######################
### Steam Callbacks ###
#######################

func _on_lobby_created(connect: int, lobby_id: int) -> void:
	print("[STEAM_LOBBY] Lobby created called")
	set_is_creating_lobby(false)
	if connect == 1:
		set_lobby_id(lobby_id)
		print("[STEAM_LOBBY] Created Steam lobby with id: %s" % lobby_id)
		
		var relay = Steam.allowP2PPacketRelay(true)
		print("[STEAM_LOBBY] Relay configuration response: %s" % relay)
		
		lobby_created.emit(get_lobby_id())
	else:
		push_error("[STEAM_LOBBY] Failed to create lobby: %s" % connect)

func _on_lobby_match_list() -> void:
	pass

func _on_lobby_joined(lobby_id: int, permission: int, locked: bool, response: int) -> void:
	print("[STEAM_LOBBY] Lobby joined!")
	set_lobby_id(lobby_id)
	_update_lobby_members()
	lobby_joined.emit(get_lobby_id())

func _on_lobby_chat_update(lobby_id: int, changed_user: int, user_made_change: int, chat_state: int) -> void:
	match chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			print("[STEAM_LOBBY] Player %s joined lobby %s" % [changed_user, lobby_id])
			player_joined_lobby.emit(changed_user)
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
			print("[STEAM_LOBBY] Player %s left the lobby %s" % [changed_user, lobby_id])
			player_left_lobby.emit(changed_user)
		Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
			print("[STEAM_LOBBY] Player %s was kicked by %s" % [changed_user, user_made_change])
			player_left_lobby.emit(changed_user)
		Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
			print("[STEAM_LOBBY] Player %s was banned by %s" % [changed_user, user_made_change])
			player_left_lobby.emit(changed_user)
		Steam.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
			print("[STEAM_LOBBY] Player %s disconnected" % changed_user)
			player_left_lobby.emit(changed_user)

func _on_lobby_message(lobby_id: int, sender: int, message: String, chat_type: int) -> void:
	match chat_type:
		Steam.CHAT_ENTRY_TYPE_CHAT_MSG:
			if not has_lobby_member(sender):
				push_error("[STEAM_LOBBY] Received a message from a user we dont have locally!")
			var name = get_lobby_member(sender);
			chat_message_received.emit(sender, name, message)
		_:
			push_warning("[STEAM_LOBBY] Unhandled chat message type received: %s" % chat_type)

func _on_lobby_data_update(success, lobby_id: int, member_id: int) -> void:
	if success:
		# Check for host change
		var host = Steam.getLobbyOwner(get_lobby_id())
		if host > 0 and not is_owner(host):
			_owner_changed(get_lobby_host(), host)
			set_lobby_host(host)
		lobby_data_updated.emit(member_id)

func _on_lobby_invite(inviter: int, lobby_id: int, member_id: int) -> void:
	pass

func _on_lobby_join_requested(lobby_id: int, friend_id: int) -> void:
	print("[STEAM_LOBBY] Attempting to join lobby %s from request" % lobby_id)
	lobby_join_requested.emit(lobby_id)
	# join_lobby(lobby_id)


##############################
### Command Line Arguments ###
##############################

func _check_command_line():
	var args = OS.get_cmdline_args()
	
	# Check if arguments exists to process
	if args.size() > 0:
		var lobby_invite_arg := false
		for arg in args:
			print("[STEAM_LOBBY] Command line: " + str(arg))
			
			# An invite argument was passed
			if lobby_invite_arg:
				lobby_join_requested.emit(int(arg))
				# join_lobby(int(arg))
			
			if arg == "+connect_lobby":
				lobby_invite_arg = true
