extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	if get_tree().root.has_node("Game/Board/Deck"):
		get_tree().root.get_node("Game/Board/Deck").connect("draw", _on_deck_draw)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_deck_draw(card):
	$Hand.draw(card)

func add_card(card):
	$Hand.add_card(card)
