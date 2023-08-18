@tool
extends Resource

@export var points: int
@export var has_effect: bool:
	set(value):
		has_effect = value
		notify_property_list_changed()

var effect: CardGameManager.effect
var front: Texture
var back: Texture

func _get_property_list() -> Array:
	var property_usage = PROPERTY_USAGE_NO_EDITOR
	
	if has_effect:
		property_usage = PROPERTY_USAGE_DEFAULT
	
	var properties = []
	if has_effect:
		properties.append({
			"name": "effect",
			"type": TYPE_INT,
			"usage": property_usage,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": ",".join(CardGameManager.effect.keys())
		})
	return properties
