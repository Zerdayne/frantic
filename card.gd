extends Node3D

signal play_card(card)

const ANIM_SPEED := 12.0

@onready var target_transform := global_transform

var target_rotation := 0.0
var outlineVisible := false
var is_player := true
var is_inspecting := false

var original_position

# Called when the node enters the scene tree for the first time.
func _ready():
	scale = Vector3.ONE * 0.1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#if is_in_hand() and outlineVisible and is_player and !is_inspecting:
		# card hovered
		#rotation.z = lerp(rotation.z, 0.0, ANIM_SPEED * delta)
		#var view_spot = target_transform
		#view_spot.origin.y += 4.5
		#transform = transform.interpolate_with(view_spot, ANIM_SPEED * delta)
	if is_in_hand():
		#transform = transform.interpolate_with(target_transform, ANIM_SPEED * delta)
		rotation.z = lerp(rotation.z, target_rotation, ANIM_SPEED * delta)


func _on_area_3d_mouse_entered():
	outlineVisible = true


func _on_area_3d_mouse_exited():
	outlineVisible = false


func find_camera_pos() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var unprojected = camera.unproject_position(target_transform.origin)
	# I fiddled with the y coordinate and distance here so the full card is visible
	return camera.project_position(Vector2(unprojected.x, 750), 2.0)


func is_in_hand() -> bool:
	return get_parent() is Hand


func _on_area_3d_input_event(camera, event, _position, _normal, _shape_idx):
	if event.is_action_pressed("left_click") and is_in_hand():
		play_card.emit(self)
	elif event.is_action_pressed("inspect"):
		inspect(camera)


func inspect(camera):
	if is_inspecting:
		target_transform = original_position
	else:
		original_position = target_transform
		var camera_position = find_camera_pos()
		var view_spot = camera_position
		view_spot.z -= 8
		target_transform.origin = view_spot
	
	is_inspecting = !is_inspecting
