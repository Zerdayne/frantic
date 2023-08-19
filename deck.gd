extends Node3D

signal draw()

const CARD = preload("res://card.tscn")

var deck = []

# Called when the node enters the scene tree for the first time.
func _ready():
	deck = CardGameManager.deck_map[CardGameManager.decks.BASE_GAME].deck
	randomize()
	deck.shuffle()
	for res in deck:
		var card = CARD.instantiate()
		card.setup(res)
		add_child(card)
		var count = get_children().filter(filterDeckNodes).size()
		card.position.z = count * -0.002
	$Area3D/CollisionShape3D.shape.size.z = get_children().filter(filterDeckNodes).back().position.z * -1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_3d_input_event(camera, event, position, normal, shape_idx):
	if event.is_action_pressed("left_click"):
		draw.emit(get_children().filter(filterDeckNodes).back())


func filterDeckNodes(node: Node):
	return node.is_in_group("card")
