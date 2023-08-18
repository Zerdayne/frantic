extends Resource

@export var card_lists: Array[Resource]

var generated := false
var deck := []:
	get:
		if not generated:
			generated = true
			return generate_cards()
		return deck

func generate_cards() -> Array:
	for res in card_lists:
		for card in res.list:
			deck.append(card)
	return deck
