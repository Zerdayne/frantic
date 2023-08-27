extends Node

# Steam Variables
var IS_ON_STEAM: bool = false
var IS_ON_STEAM_DECK: bool = false
var IS_ONLINE: bool = false
var IS_OWNED: bool = false
var STEAM_ID: int = 0
var STEAM_USERNAME: String = "No one"

#Lobby Variables
var DATA
var LOBBY_ID = 0
var LOBBY_MEMBERS = []
var LOBBY_INVITE_FLAG = false

func _ready():
	_initialize_steam()
	
	if IS_ON_STEAM_DECK:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN

func _process(_delta: float):
	if IS_ON_STEAM:
		Steam.run_callbacks()

func _initialize_steam():
	if Engine.has_singleton("Steam"):
		var INIT: Dictionary = Steam.steamInit(false)
		
		if INIT['status'] != 1:
			print("[STEAM] Failed to initialize: " + str(INIT['verbal']) + " Shutting down...")
			get_tree().quit()
		
		IS_ON_STEAM = true
		IS_ON_STEAM_DECK = Steam.isSteamRunningOnSteamDeck()
		
		IS_ONLINE = Steam.loggedOn()
		IS_OWNED = Steam.isSubscribed()
		STEAM_ID = Steam.getSteamID()
		STEAM_USERNAME = Steam.getPersonaName()

func _set_rich_presence(token: String) -> void:
	var SETTING_PRESENCE = Steam.setRichPresence("steam_display", token)
	print("Setting rich presence to " + str(token) + ": " + str(SETTING_PRESENCE))
