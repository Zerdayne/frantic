extends Node

func make_p2p_handshake():
	print("Sending P2P handshake to the lobby")
	
	_send_p2p_packet(0, {"message": "handshake", "from": Global.STEAM_ID})

func _send_p2p_packet(target: int, packet_data: Dictionary):
	# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0
	
	# Create a data array to send the data through
	var data: PackedByteArray
	data.append_array(var_to_bytes(packet_data))
	
	# If sending a packet to everyone
	if target == 0:
		# If there is more than one user, send packets
		if Global.LOBBY_MEMBERS.size() > 1:
			# Loop through all members that aren't you
			for member in Global.LOBBY_MEMBERS:
				if member['steam_id'] != Global.STEAM_ID:
					Steam.sendP2PPacket(member['steam_id'], data, send_type, channel)
	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(target, data, send_type, channel)
