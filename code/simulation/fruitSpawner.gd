extends Node2D
class_name FruitSpawningTree

var fruitTexture = preload("res://art/fruit.png")
var treeTexture = preload("res://art/tree.png")

var fruits = []

func _ready():
	var newTexture = Sprite2D.new()
	newTexture.texture = treeTexture
	newTexture.scale =  Vector2(0.183,0.183)
	add_child(newTexture)

var dt = 0.0
func _process(delta):
	dt += delta
	if dt >= 90:
		spawnFruit()
		dt = 0.0

func spawnFruit():
	for I in fruits:
		if !is_instance_valid(I):
			fruits.erase(I)
	
	if fruits.size() <= 10:
		var newFruit = Fruit.new()
		add_sibling(newFruit)
		newFruit.global_position = global_position + Vector2(randi_range(-200,200),randi_range(-200,200))
		newFruit.texture = fruitTexture
		newFruit.scale = Vector2(0.183,0.183)
		fruits.append(newFruit)
