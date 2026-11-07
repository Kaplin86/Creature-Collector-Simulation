extends Node2D
class_name Nest

## A nest object. Belongs to a specific species

## The species this nest belongs too.
@export var species : int

@onready var _spatialGrid : SpatialGrid = get_parent().get_node("SpatialGrid")

var _texture = preload("res://art/nest.png")

func _ready():
	_spatialGrid.addEntity(self)
	var newSprite = Sprite2D.new()
	newSprite.scale = Vector2(0.183,0.183)
	newSprite.texture = _texture
	add_child(newSprite)

func _process(delta):
	_spatialGrid.updateEntity(self,global_position)

func _exit_tree():
	_spatialGrid.removeEntity(self)

func _draw():
	draw_string(ThemeDB.fallback_font,Vector2.ZERO - Vector2(100,0),str(species),HORIZONTAL_ALIGNMENT_CENTER,200)
