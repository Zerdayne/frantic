extends Node3D

signal play_card(card)

const ANIM_SPEED := 12.0

@onready var target_transform := global_transform

var outlineVisible := false
var is_player := true

var color: CardGameManager.color
var value: CardGameManager.value

func setup(res: Resource):
	if not is_inside_tree():
		await ready
	
	get_node("Cube").set_surface_override_material(1, res.front)
	color = res.color
	value = res.label
	

func _process(delta):
	if is_in_hand() and outlineVisible and is_player:
		var view_spot = target_transform
		view_spot.origin += view_spot.basis.y * 0.2
		transform = transform.interpolate_with(view_spot, ANIM_SPEED * delta)
	elif is_in_hand():
		transform = transform.interpolate_with(target_transform, ANIM_SPEED * delta)


func _on_area_3d_mouse_entered():
	outlineVisible = true


func _on_area_3d_mouse_exited():
	outlineVisible = false


func find_camera_pos() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var unprojected = camera.unproject_position(target_transform.origin)
	# I fiddled with the y coordinate and distance here so the full card is visible
	return camera.project_position(Vector2(unprojected.x, 750), -2.0)


func is_in_hand() -> bool:
	return get_parent() is Hand


func _on_area_3d_input_event(camera, event, _position, _normal, _shape_idx):
	if is_player:
		if event.is_action_pressed("left_click") and is_in_hand() and CardGameManager.is_card_playable(self):
			play_card.emit(self)
