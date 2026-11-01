extends Node2D

func _ready():
	Engine.time_scale = 16

func _process(delta):
	#print(%SpatialGrid.getCell(get_global_mouse_position()))
	print(delta)
