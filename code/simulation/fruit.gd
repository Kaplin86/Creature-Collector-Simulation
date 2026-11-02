extends Sprite2D
class_name Fruit

## A edible, fruit object.

## The amount of energy recoveredwhen a carnivore eats this
@export var NutritionalValue = 0.25

@onready var _spatialGrid : SpatialGrid = get_parent().get_node("SpatialGrid")


func _ready():
	await get_tree().process_frame
	_spatialGrid.addEntity(self)

func _exit_tree():
	_spatialGrid.removeEntity(self)
