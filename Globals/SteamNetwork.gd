extends Node

###############
### Signals ###
###############

signal peer_status_updated(steam_id: int)
signal peer_session_failure(steam_id: int, reason: Steam.P2PSessionError)
signal all_peers_connected


#############
### Enums ###
#############

enum PACKET_TYPE {
	HANDSHAKE = 1,
	HANDSHAKE_REPLY = 2,
	PEER_STATE = 3,
	NODE_PATH_UPDATE = 4,
	NODE_PATH_CONFIRM = 5,
	RPC = 6,
	RPC_WITH_NODE_PATH = 7,
	RSET = 8,
	RSET_WITH_NODE_PATH = 9
}

enum PERMISSION {
	SERVER,
	CLIENT_ALL
}


#################
### Variables ###
#################

var _STEAM_ID: int = 0
var _PEERS: Dictionary = {}
var _SERVER_STEAM_ID: int = 0

var _NODE_PATH_CACHE: Dictionary = {}
var _NEXT_PATH_CACHE_INDEX: int = 0
var _PEERS_CONFIRMED_NODE_PATH: Dictionary = {}

var _PERMISSIONS = {}


#############
### Hooks ###
#############

func _ready() -> void:
	SteamLobby.player_joined_lobby.connect(_init_p2p_session)
	SteamLobby.player_left_lobby.connect(_close_p2p_session)
	
	SteamLobby.lobby_created.connect(_init_p2p_host)
	SteamLobby.lobby_owner_changed.connect(_migrate_host)
	
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)
	
	set_steam_id(Steam.getSteamID())

func _process(_delta) -> void:
	var packet_size = Steam.getAvailableP2PPacketSize(0)
	while packet_size > 0:
		_read_p2p_packet(packet_size)
		packet_size = Steam.getAvailableP2PPacketSize(0)


###############
### Getters ###
###############

func get_steam_id() -> int:
	return _STEAM_ID

func get_peers() -> Dictionary:
	return _PEERS

func get_server_steam_id() -> int:
	if _SERVER_STEAM_ID > 0:
		return _SERVER_STEAM_ID
	for peer in get_peers().values():
		if peer.host:
			set_server_steam_id(peer.steam_id)
			return _SERVER_STEAM_ID
	return -1

func get_node_path_cache() -> Dictionary:
	return _NODE_PATH_CACHE

func get_next_path_cache_index() -> int:
	_NEXT_PATH_CACHE_INDEX += 1
	return _NEXT_PATH_CACHE_INDEX


########################
### Spoecial Getters ###
########################

func get_peer(steam_id: int) -> Peer:
	return get_peers()[steam_id]

func has_peer(steam_id: int) -> bool:
	return get_peers().has(steam_id)

func is_server() -> bool:
	var steam_id = get_steam_id()
	if not has_peer(steam_id):
		return false
	return get_peer(steam_id).host

func get_node_path_in_cache(index: int) -> NodePath:
	return _NODE_PATH_CACHE[index]

func get_permission(hash: String) -> PERMISSION:
	return _PERMISSIONS[hash]

func has_permission(hash: String) -> bool:
	return _PERMISSIONS.has(hash)


###############
### Setters ###
###############

func set_steam_id(steam_id: int) -> void:
	_STEAM_ID = steam_id

func set_peers(peers: Dictionary) -> void:
	_PEERS = peers

func set_server_steam_id(steam_id: int) -> void:
	_SERVER_STEAM_ID = steam_id


########################
### Spoecial setters ###
########################

func set_peer(peer: Peer) -> void:
	_PEERS[peer.steam_id] = peer

func erase_peer(steam_id: int) -> void:
	_PEERS.erase(steam_id)

func clear_peers() -> void:
	_PEERS.clear()

func set_node_path_in_cache(index: int, node_path: NodePath) -> void:
	_NODE_PATH_CACHE[index] = node_path

func add_confirmed_node_path(peer_id: int, index: int) -> void:
	_PEERS_CONFIRMED_NODE_PATH[peer_id] = index


########################
### Public Functions ###
########################

func peers_connected() -> bool:
	for peer_id in get_peers().keys():
		if not get_peer(peer_id).connected:
			return false
	
	return true

func is_peer_connected(steam_id: int) -> bool:
	if has_peer(steam_id):
		return _PEERS[steam_id].connected
	else:
		print("[STEAM_NETWORK] Tried to get status of non-existent peer: %s" % steam_id)
		return false


#########################
### Private Functions ###
#########################

### P2P

func _read_p2p_packet(packet_size: int) -> void:
	var packet = Steam.readP2PPacket(packet_size, 0)
	
	if packet.is_empty():
		push_warning("[STEAM_NETWORK] Read an empty packet with non-zero size!")
	
	var sender: int = packet['steam_id_remote']
	var packet_data: PackedByteArray = packet["data"]
	
	_handle_packet(sender, packet_data)

func _handle_packet(sender: int, payload: PackedByteArray) -> void:
	if payload.size() == 0:
		push_error("[STEAM_NETWORK] Can't handle an empty packet payload!")
		return
	
	var packet_type = payload[0]
	var packet_data = null
	if payload.size() > 1:
		packet_data = payload.slice(1, payload.size()-1)
	
	match packet_type:
		PACKET_TYPE.HANDSHAKE:
			_send_p2p_command_packet(sender, PACKET_TYPE.HANDSHAKE_REPLY)
		PACKET_TYPE.HANDSHAKE_REPLY:
			_confirm_peer(sender)
		PACKET_TYPE.PEER_STATE:
			_update_peer_state(packet_data)
		PACKET_TYPE.NODE_PATH_UPDATE:
			_update_node_path_cache(sender, packet_data)
		PACKET_TYPE.NODE_PATH_CONFIRM:
			_server_confirm_peer_node_path(sender, bytes_to_var(packet_data))
		PACKET_TYPE.RPC:
			_handle_rpc_packet(sender, packet_data)
		PACKET_TYPE.RPC_WITH_NODE_PATH:
			_handle_rpc_packet_with_path(sender, packet_data)
		PACKET_TYPE.RSET:
			_handle_rset_packet(sender, packet_data)
		PACKET_TYPE.RSET_WITH_NODE_PATH:
			_handle_rset_packet_with_path(sender, packet_data)

func _send_p2p_command_packet(steam_id: int, packet_type: PACKET_TYPE, arg = null) -> void:
	var payload = PackedByteArray()
	payload.append(packet_type)
	if arg != null:
		payload.append_array(var_to_bytes(arg))
	if not _send_p2p_packet(steam_id, payload):
		push_error("[STEAM_NETWORK] Failed to send command packet %s" % packet_type)

func _broadcast_p2p_packet(data: PackedByteArray, send_type: Steam.P2PSend = Steam.P2P_SEND_RELIABLE, channel: int = 0) -> void:
	for peer_id in get_peers().keys():
		if peer_id != get_steam_id():
			_send_p2p_packet(peer_id, data, send_type, channel)

func _send_p2p_packet(steam_id: int, data: PackedByteArray, send_type: Steam.P2PSend = Steam.P2P_SEND_RELIABLE, channel: int = 0) -> bool:
	return Steam.sendP2PPacket(steam_id, data, send_type, channel)

### Peer State

func _confirm_peer(steam_id: int) -> void:
	if not has_peer(steam_id):
		push_error("[STEAM_NETWORK] Can't confirm peer %s as they do not exist locally!" % steam_id)
		return
	
	print("[STEAM_NETWORK] Peer %s confirmed" % steam_id)
	_PEERS[steam_id].connected = true
	peer_status_updated.emit(steam_id)
	_server_send_peer_state()
	
	if peers_connected():
		all_peers_connected.emit()

func _server_send_peer_state() -> void:
	print("[STEAM_NETWORK] Sending peer state")
	var peers = []
	for peer in get_peers().values():
		peers.append(peer.serialize())
	
	var payload = PackedByteArray()
	payload.append(PACKET_TYPE.PEER_STATE)
	payload.append_array(var_to_bytes(peers))
	
	_broadcast_p2p_packet(payload)

func _update_peer_state(payload: PackedByteArray) -> void:
	if is_server():
		return
	
	print("[STEAM_NETWORK] Updating peer state")
	var serialized_peers = bytes_to_var(payload)
	var new_peers = []
	for serialized_peer in serialized_peers:
		var peer = Peer.new()
		peer.deserialize(serialized_peer)
		prints("[STEAM_NETWORK]", peer.steam_id, peer.connected, peer.host)
		if not has_peer(peer.steam_id) or not peer.eq(get_peer(peer.steam_id)):
			set_peer(peer)
			peer_status_updated.emit(peer.steam_id)
		new_peers.append(peer.steam_id)
	
	for peer_id in get_peers().keys():
		if not peer_id in new_peers:
			erase_peer(peer_id)
			peer_status_updated.emit(peer_id)

### Node Path Cache

func _update_node_path_cache(sender: int, packet_data: PackedByteArray) -> void:
	if sender != get_server_steam_id():
		return
	
	var data = bytes_to_var(packet_data)
	var path_cache_index = data[0]
	var node_path = data[1]
	_add_node_path_cache(node_path, path_cache_index)
	_send_p2p_command_packet(get_server_steam_id(), PACKET_TYPE.NODE_PATH_CONFIRM, path_cache_index)

func _add_node_path_cache(node_path: NodePath, path_cache_index: int = -1) -> int:
	var already_exists_id = _get_path_cache(node_path)
	if already_exists_id != -1 and already_exists_id == path_cache_index:
		return already_exists_id
	
	if path_cache_index == -1:
		path_cache_index = get_next_path_cache_index()
	set_node_path_in_cache(path_cache_index, node_path)
	
	return path_cache_index

func _get_node_path(path_cache_index: int) -> NodePath:
	return get_node_path_in_cache(path_cache_index)

func _get_path_cache(node_path: NodePath) -> int:
	for path_cache_index in get_node_path_cache().keys():
		if get_node_path_in_cache(path_cache_index) == node_path:
			return path_cache_index
	return -1

func _server_update_node_path_cache(peer_id: int, node_path: NodePath) -> void:
	if not is_server():
		return
	
	var path_cache_index = _get_path_cache(node_path)
	if path_cache_index == -1:
		path_cache_index = _add_node_path_cache(node_path)
	var packet = PackedByteArray()
	var payload = var_to_bytes([path_cache_index, node_path])
	packet.append_array(payload)
	_send_p2p_packet(peer_id, packet)

func _server_confirm_peer_node_path(peer_id, path_cache_index: int) -> void:
	if not is_server():
		return
	add_confirmed_node_path(peer_id, path_cache_index)

### RPC

func _handle_rpc_packet(sender: int, payload: PackedByteArray) -> void:
	var peer = get_peer(sender)
	var data = bytes_to_var(payload)
	var path_cache_index = data[0]
	var method = data[1]
	var args = data[2]
	_execute_rpc(peer, path_cache_index, method, args)

func _handle_rpc_packet_with_path(sender: int, payload: PackedByteArray) -> void:
	var peer = get_peer(sender)
	var data = bytes_to_var(payload)
	
	var node_path = data[0]
	var path_cache_index = data[1]
	var method = data[2]
	var args = data[3]
	
	if is_server():
		path_cache_index = _get_path_cache(node_path)
		if path_cache_index == -1:
			path_cache_index = _add_node_path_cache(node_path)
		_server_update_node_path_cache(sender, node_path)
	else:
		_add_node_path_cache(node_path, path_cache_index)
		_send_p2p_command_packet(sender, PACKET_TYPE.NODE_PATH_CONFIRM, path_cache_index)
	_execute_rpc(peer, path_cache_index, method, args)

func _execute_rpc(sender: Peer, path_cache_index: int, method: String, args: Array) -> void:
	var node_path = _get_node_path(path_cache_index)
	if node_path == null:
		prints("[STEAM_NETWORK]", sender, path_cache_index, method, args)
		push_error("[STEAM_NETWORK] NodePath index %s does not exist on this client! Can't call RPC" % path_cache_index)
		return
	
	if not _sender_has_permission(sender.steam_id, node_path, method):
		prints("[STEAM_NETWORK]", sender, node_path, method, args)
		push_error("[STEAM_NETWORK] Sender does not have permission to execute method %s on node %s" % [method, node_path])
		return
	
	var node = get_node_or_null(node_path)
	if node == null:
		push_error("[STEAM_NETWORK] Node %s does not exist on this client! Can't call RPC" % node_path)
		return
	
	if not node.has_method(method):
		push_error("[STEAM_NETWORK] Node %s does not have a method %s" % [node.name, method])
		return
	
	args.push_front(sender.steam_id)
	node.callv(method, args)

### RSET

func _handle_rset_packet(sender: int, payload: PackedByteArray) -> void:
	var peer = get_peer(sender)
	var data = bytes_to_var(payload)
	
	var path_cache_index = data[0]
	var value = data[1]
	
	_execute_rset(peer, path_cache_index, value)

func _handle_rset_packet_with_path(sender: int, payload: PackedByteArray) -> void:
	var peer = get_peer(sender)
	var data = bytes_to_var(payload)
	
	var node_path = data[0]
	var path_cache_index = data[1]
	var value = data[2]
	
	if is_server():
		path_cache_index = _get_path_cache(node_path)
		if path_cache_index == -1:
			path_cache_index = _add_node_path_cache(node_path)
		_server_update_node_path_cache(sender, path_cache_index)
	else:
		_add_node_path_cache(node_path, path_cache_index)
		_send_p2p_command_packet(sender, PACKET_TYPE.NODE_PATH_CONFIRM, path_cache_index)
	
	_execute_rset(peer, path_cache_index, value)

func _execute_rset(peer: Peer, path_cache_index: int, value) -> void:
	var node_path = _get_node_path(path_cache_index)
	if node_path == null:
		push_error("[STEAM_NETWORK] NodePath index %s does not exist on this client! Can't complete RemoteSet" % path_cache_index)
		return
	if not _sender_has_permission(peer.steam_id, node_path):
		push_error("[STEAM_NETWORK] Sender does not have permission to execute remote set %s on node %s" % [value, node_path])
		return
	
	var node = get_node_or_null(node_path)
	if node == null:
		push_error("[STEAM_NETWORK] Node %s does not exist on this client! Can't complete RemoteSet" % node_path)
		return
	
	var property: String = node_path.get_subname(0)
	if property == null or property.is_empty():
		push_error("Node %s could not resolve to a property. Can't complete RemoteSet" % node_path)
		return
	
	node.set(property, value)

### Permissions

func _sender_has_permission(sender: int, node_path: NodePath, method: String = "") -> bool:
	var perm_hash = _get_permission_hash(node_path, method)
	if not has_permission(perm_hash):
		return false
	
	var permission = get_permission(perm_hash)
	match permission:
		PERMISSION.SERVER:
			return sender == get_server_steam_id()
		PERMISSION.CLIENT_ALL:
			return true
	
	return false

func _get_permission_hash(node_path: NodePath, value: String = "") -> String:
	if value.is_empty():
		return str(node_path).md5_text()
	return (str(node_path) + value).md5_text()

### Peers

func _create_peer(steam_id: int) -> Peer:
	var peer = Peer.new()
	peer.steam_id = steam_id
	_PEERS_CONFIRMED_NODE_PATH[steam_id] = []
	return peer

############################
### SteamLobby Callbacks ###
############################

func _init_p2p_session(steam_id: int) -> void:
	if not is_server():
		return
	
	print("[STEAM_NETWORK] Initializing P2P Session with %s" % steam_id)
	_PEERS[steam_id] = _create_peer(steam_id)
	peer_status_updated.emit(steam_id)
	_send_p2p_command_packet(steam_id, PACKET_TYPE.HANDSHAKE)

func _close_p2p_session(steam_id: int) -> void:
	if steam_id == get_steam_id():
		Steam.closeP2PSessionWithUser(get_server_steam_id())
		set_server_steam_id(0)
		clear_peers()
		return
	
	print("[STEAM_NETWORK] Closing p2p session with %s" % steam_id)
	var session_state = Steam.getP2PSessionState(steam_id)
	if session_state.has("connection_active") and session_state["connection_active"]:
		Steam.closeP2PSessionWithUser(steam_id)
	
	if has_peer(steam_id):
		erase_peer(steam_id)
	
	_server_send_peer_state()

func _init_p2p_host(_lobby_id: int) -> void:
	var steam_id = get_steam_id()
	print("[STEAM_NETWORK] Initializing p2p host as %s" % get_steam_id())
	var host_peer = _create_peer(steam_id)
	host_peer.host = true
	host_peer.connected = true
	set_peer(host_peer)
	all_peers_connected.emit()

func _migrate_host(old_host: int, new_host: int) -> void:
	var old_host_peer = get_peer(old_host)
	if old_host_peer != null:
		old_host_peer.host = false
	
	Steam.closeP2PSessionWithUser(old_host)
	
	set_server_steam_id(0)
	
	clear_peers()
	for steam_id in SteamLobby.get_lobby_members():
		var peer = _create_peer(steam_id)
		set_peer(peer)
	
	var new_host_peer = get_peer(new_host)
	if new_host_peer != null:
		new_host_peer.host = true
	else:
		push_error("[STEAM_NETWORK] Error migrating host, no new host was found!")
		return
	
	if is_server():
		for steam_id in get_peers():
			if steam_id != get_steam_id():
				_init_p2p_session(steam_id)
			else:
				_PEERS[steam_id].connected = true


#######################
### Steam Callbacks ###
#######################

func _on_p2p_session_request(remote_steam_id: int) -> void:
	print("[STEAM_NETWORK] Received p2p session request from %s" % remote_steam_id)
	var requestor = Steam.getFriendPersonaName(remote_steam_id)
	
	if SteamLobby.get_lobby_host() == remote_steam_id:
		Steam.acceptP2PSessionWithUser(remote_steam_id)
	else:
		push_warning("[STEAM_NETWORK] Got a rogue p2p session request from %s. Not accepting." % remote_steam_id)

func _on_p2p_session_connect_fail(remote_steam_id: int, session_error: Steam.P2PSessionError) -> void:
	match session_error:
		Steam.P2P_SESSION_ERROR_NONE:
			push_warning("[STEAM_NETWORK] Session failute with " + str(remote_steam_id) + " [no error given].")
		Steam.P2P_SESSION_ERROR_NOT_RUNNING_APP:
			push_warning("[STEAM_NETWORK] Session failute with " + str(remote_steam_id) + " [target user not running the same game].")
		Steam.P2P_SESSION_ERROR_NO_RIGHTS_TO_APP:
			push_warning("[STEAM_NETWORK] Session failute with " + str(remote_steam_id) + " [local user doesn't own app / game].")
		Steam.P2P_SESSION_ERROR_DESTINATION_NOT_LOGGED_ON:
			push_warning("[STEAM_NETWORK] Session failute with " + str(remote_steam_id) + " [target user isn't connected to Steam].")
		Steam.P2P_SESSION_ERROR_TIMEOUT:
			push_warning("[STEAM_NETWORK] Session failute with " + str(remote_steam_id) + " [connection timed out].")
		Steam.P2P_SESSION_ERROR_MAX:
			push_warning("[STEAM_NETWORK] Session failute with " + str(remote_steam_id) + " [unused].")
		_:
			push_warning("[STEAM_NETWORK] Session failute with " + str(remote_steam_id) + " [unknown error " + str(session_error) + "].")
	
	peer_session_failure.emit(remote_steam_id, session_error)
	
	if remote_steam_id in get_peers().keys():
		_PEERS[remote_steam_id].connected = false
		peer_status_updated.emit(remote_steam_id)
		_server_send_peer_state()


##################
### Peer Class ###
##################

class Peer:
	var steam_id: int
	var connected: bool = false
	var host: bool = false
	
	func serialize() -> PackedByteArray:
		var data = [steam_id, connected, host]
		return var_to_bytes(data)
	
	func deserialize(data: PackedByteArray) -> void:
		var unpacked = bytes_to_var(data)
		steam_id = unpacked[0]
		connected = unpacked[1]
		host = unpacked[2]
	
	func eq(peer) -> bool:
		return peer.steam_id == steam_id and peer.connected == connected and peer.host == host
