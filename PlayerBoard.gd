extends Node3D

@onready var hand := $Hand

# Called when the node enters the scene tree for the first time.
func _ready():
	$Hand.add_cards(5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
