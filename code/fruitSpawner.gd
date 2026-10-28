extends Node2D

var dt = 0.0
func _process(delta):
	dt += delta
	if dt >= 90:
		var newFruit = Fruit.new()
		add_sibling(newFruit)
		newFruit.global_position = global_position + Vector2(randi_range(-100,100),randi_range(-100,100))
		newFruit.texture = load("res://icon.svg")
		newFruit.scale = Vector2(0.183,0.183)
		dt = 0.0
