extends Node

var STEAM_ID: int = 0
var IS_ONLINE: bool = 0
var IS_GAME_OWNED: bool = 0

func _ready():
	if not is_steam_enabled():
		return;
	
	var init = Steam.steamInit();
	print("[STEAM] Initialize successful?: " + str(init))
	
	if init['status'] != 1:
		print("[STEAM] Failed to initialize Steam. " + str(init['verbal']) + " Shutting down...")
		get_tree().quit()
		
		STEAM_ID = Steam.getSteamID()
		IS_ONLINE = Steam.loggedOn()
		IS_GAME_OWNED = Steam.isSubscribed()
		
		if IS_GAME_OWNED == false:
			print("User does not own this game")
			get_tree().quit()

func _process(_delta):
	Steam.run_callbacks()

func is_steam_enabled():
	return OS.has_feature("steam") or OS.is_debug_build()

func get_profile_name():
	return Steam.getPersonaName()
