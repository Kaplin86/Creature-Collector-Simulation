extends Sprite2D
class_name Fruit

@export var NutritionalValue = 0.25

@onready var spatialGrid : SpatialGrid = get_parent().get_node("SpatialGrid")

func _ready():
	await get_tree().process_frame
	spatialGrid.addEntity(self)

func _exit_tree():
	spatialGrid.removeEntity(self)
