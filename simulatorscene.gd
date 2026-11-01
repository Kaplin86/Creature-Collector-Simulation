extends Node2D

@export var simMinX = 0
@export var simMaxX = 0
@export var simMinY = 0
@export var simMaxY = 0

func _ready():
	Engine.time_scale = 16
	
	#%SpeciesHandler.AddSpecies($Node2D10,0)
	#%SpeciesHandler.AddSpecies($Node2D37,0)

func _process(delta):
	#print(%SpatialGrid.getCell(get_global_mouse_position()))
	#print(delta)
	pass
