extends Node

signal deck_updated
signal players_spawned

enum decks {
	BASE_GAME
}

enum effect {
	SECOND_CHANCE,
	SKIP,
	EXCHANGE,
	GIFT
}

enum color {
	BLUE,
	GREEN,
	RED,
	VIOLET,
	YELLOW
}

enum value {
	Ⅰ,
	Ⅱ,
	Ⅲ,
	Ⅳ,
	Ⅴ,
	Ⅵ,
	Ⅶ,
	Ⅷ,
	Ⅸ,
	Ⅹ
}

var deck_map := {}
var player_scene = preload("res://Scenes/Player/Player.tscn")
var players_node

var last_played_card

# Called when the node enters the scene tree for the first time.
func _ready():
	deck_map = {
		decks.BASE_GAME: load("res://CardList/Decks/base_game.tres").duplicate(true)
	}
	deck_updated.emit()
	connect("players_spawned", _on_players_spawned)

func start_game(game_scene):
	await get_tree().change_scene_to_packed(game_scene)

func spawn_players(node):
	players_node = node
	var count = 8
	
	for i in range(0, count):
		var player = player_scene.instantiate()
		players_node.add_child(player)
		var degree = (360 / count) * i
		player.rotate_y(deg_to_rad(degree))
	
	var player = players_node.get_child(0)
	player.get_node("Camera").set_current(true)
	player.get_node("Hand").is_player = true
	
	players_spawned.emit()

func _on_players_spawned():
	var players = players_node.get_children()
	var deck = get_tree().root.get_node("/root/Game/Board/Deck")
	
	for i in range(0, 7):
		for player in players:
			var card = deck.get_children().filter(deck.filterDeckNodes).back()
			player.add_card(card)
	
	play_first_card(deck.get_children().filter(deck.filterDeckNodes).back())
	
func play_first_card(card):
	last_played_card = card
	get_tree().get_first_node_in_group("bin").add_card(card)

func is_card_playable(card) -> bool:
	var same_color = last_played_card.color == card.color
	var same_value = last_played_card.value == card.value
	return same_color or same_value

func card_played(card):
	last_played_card = card
