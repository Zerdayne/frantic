extends Resource

@export var card_list: Array[Resource]
@export var color: CardGameManager.color
@export var back: StandardMaterial3D

var generated := false
var list := []:
	get:
		if not generated:
			generated = true
			return generate_cards()
		return list

func generate_cards() -> Array:
	for res in card_list:
		var card = res.duplicate(true)
		#card.set_local_to_scene(true)
		card.color = color
		card.front = load("res://CardList/Cards/" + CardGameManager.color.keys()[color] + "/" + CardGameManager.value.keys()[card.label] + ".tres").front
		if back != null:
			card.back = back
		list.append(card)
	return list
