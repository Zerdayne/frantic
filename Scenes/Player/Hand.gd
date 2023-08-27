extends Node3D
class_name Hand

@export_node_path var camera_path
@onready var camera := get_node(camera_path)

@onready var bin := get_tree().get_first_node_in_group("bin")

@export var spread_curve: Curve
@export var height_curve: Curve
@export var rotation_curve: Curve

@export var width_array: Array[float]

@export var is_player := false

const CARD = preload("res://card.tscn")


func sort_hand():
	var max_width 
	if get_child_count() >= width_array.size():
		max_width = width_array.back()
	else:
		max_width = width_array[get_child_count()]
	
	for card in get_children():
		var destination := self.transform
		
		var hand_ratio = 0.5
		if get_child_count() > 1:
			hand_ratio = float(card.get_index()) / float(get_child_count() - 1)
		
		destination.origin.x += spread_curve.sample(hand_ratio) * max_width
		card.target_transform.origin.x = destination.origin.x
		card.target_transform.origin += camera.basis * Vector3.FORWARD * 0.001
		card.target_transform.basis = camera.basis


func draw(card):
	if not is_player:
		return
	
	add_card(card)

func add_card(card):
	card.get_parent().remove_child(card)
	add_child(card)
	if is_player:
		card.connect("play_card", self._on_play_card)
	card.position = Vector3.ZERO
	card.is_player = is_player
	sort_hand()


func _on_play_card(card):
	bin.add_card(card)
	CardGameManager.card_played(card)
	sort_hand()
