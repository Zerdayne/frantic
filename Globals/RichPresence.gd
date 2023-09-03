extends Node

func _ready():
	discord_sdk.app_id = 1147867150170738759
	print("[RICH_PRESENCE][DISCORD] Working: " + str(discord_sdk.get_is_discord_working()))
	discord_sdk.large_image = "icon"
	discord_sdk.refresh()

func main_menu() -> void:
	_set_steam_rich_presence('#MainMenu')
	_set_discord_rich_presence("Main Menu")

func _set_steam_rich_presence(token: String) -> void:
	var SETTING_PRESENCE = Steam.setRichPresence("steam_display", token)
	print("[RICH_PRESENCE][STEAM] Setting rich presence to " + str(token) + ": " + str(SETTING_PRESENCE))

func _set_discord_rich_presence(details: String) -> void:
	discord_sdk.details = details
	discord_sdk.refresh()
