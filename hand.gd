extends Node3D
class_name Hand

@export_node_path var camera_path
@onready var camera := get_node(camera_path)

@export_node_path var bin_path
@onready var bin := get_node(bin_path)

@export var spread_curve: Curve
@export var height_curve: Curve
@export var rotation_curve: Curve

@export var width_array: Array[float]

@export var is_player := true

const CARD = preload("res://card.tscn")


func sort_hand():
	var max_width 
	if get_child_count() >= width_array.size():
		max_width = width_array.back()
	else:
		max_width = width_array[get_child_count()]
	
	for card in get_children():
		var destination := global_transform
		
		var hand_ratio = 0.5
		if get_child_count() > 1:
			hand_ratio = float(card.get_index()) / float(get_child_count() - 1)
		
		if is_player:
			destination.basis = camera.global_transform.basis
			destination.origin.x += spread_curve.sample(hand_ratio) * max_width
			card.target_rotation = rotation_curve.sample(hand_ratio) * 0.3
			destination.origin += camera.basis * Vector3.UP * height_curve.sample(hand_ratio) * 0.5
			destination.origin += camera.basis * Vector3.FORWARD * hand_ratio * 2
			
		else:
			# enemy hand orientation
			destination.basis = global_transform.basis
			destination.origin.x += spread_curve.sample(hand_ratio) * 6.0
			destination.origin += global_transform.basis * Vector3.UP * height_curve.sample(hand_ratio) * 0.5

	
		card.target_transform.origin = destination.origin
		card.target_transform.basis = destination.basis


func _on_deck_draw(card):
	card.get_parent().remove_child(card)
	add_child(card)
	card.connect("play_card", self._on_play_card)
	card.position = Vector3.ZERO
	sort_hand()


func _on_play_card(card):
	bin.add_card(card)
