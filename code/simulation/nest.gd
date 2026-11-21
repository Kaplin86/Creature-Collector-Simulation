extends Node3D
class_name Nest

## A nest object. Belongs to a specific species

## The species this nest belongs too.
@export var species : int

@onready var _spatialGrid : SpatialGrid = get_parent().get_node("SpatialGrid")

var _texture = preload("res://art/nest.png")

func _ready():
	_spatialGrid.addEntity(self)
	var newMesh = MeshInstance3D.new()
	add_child(newMesh)
	var actualmesh := SphereMesh.new()
	newMesh.mesh = actualmesh
	actualmesh.radius = 3
	print("john nesty at",global_position)

func _process(delta):
	_spatialGrid.updateEntity(self,global_position)

func _exit_tree():
	_spatialGrid.removeEntity(self)
