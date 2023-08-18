extends Resource

@export var card_list: Array[Resource]
@export var front: CompressedTexture2D
@export var back: CompressedTexture2D

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
		card.set_local_to_scene(true)
		card.front = front
		if back != null:
			card.back = back
		list.append(card)
	return list
