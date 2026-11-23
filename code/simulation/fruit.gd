extends Sprite3D
class_name Fruit

## A edible, fruit object.

## The amount of energy recoveredwhen a herbivore eats this
@export var NutritionalValue = 0.2

@onready var _spatialGrid : SpatialGrid = get_parent().get_node("SpatialGrid")


func _ready():
	await get_tree().process_frame
	_spatialGrid.addEntity(self)
	add_to_group("fruit")

func _exit_tree():
	_spatialGrid.removeEntity(self)
