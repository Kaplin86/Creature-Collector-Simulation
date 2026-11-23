extends Node3D
class_name FruitSpawningTree


var treeModel = preload("res://scenes/sim/tree.tscn")
var fruitModel = preload("res://scenes/sim/fruit.tscn")

var fruits = []

func _ready():
	var newTexture = treeModel.instantiate()
	add_child(newTexture)

var dt = 0.0
func _process(delta):
	dt += delta
	if dt >= 180:
		spawnFruit()
		dt = 0.0

func spawnFruit():
	for I in fruits:
		if !is_instance_valid(I):
			fruits.erase(I)
	
	if fruits.size() <= 5:
		var newFruit = Fruit.new()
		add_sibling(newFruit)
		newFruit.global_position = global_position + Vector3(randf_range(-5,5),0,randf_range(-5,5))
		var newNesh = fruitModel.instantiate()
		newFruit.add_child(newNesh)
		#newFruit.scale = Vector3(0.183,0.138,0.183)
		fruits.append(newFruit)
