extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	if not is_inside_tree():
		await ready
	
	CardGameManager.spawn_players(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
