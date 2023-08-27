extends Node3D
class_name Bin

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func add_card(card):
	card.get_parent().remove_child(card)
	add_child(card)
	card.position = Vector3.ZERO
	card.position.z += get_child_count() * 0.002
	card.rotation.x = 0
	card.rotation.y = 0
