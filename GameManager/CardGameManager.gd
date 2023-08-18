extends Node

signal deck_updated

enum decks {
	BASE_GAME
}

enum effect {
	SECOND_CHANCE,
	SKIP,
	EXCHANGE,
	GIFT
}

var deck_map := {}

# Called when the node enters the scene tree for the first time.
func _ready():
	deck_map = {
		decks.BASE_GAME: load("res://CardList/Decks/base_game.tres").duplicate(true)
	}
	deck_updated.emit()
