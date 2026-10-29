extends Node2D

@export var data : SimulationHistory

var maxX = 300

func _ready() -> void:
	_render()

func _render():
	var num = -1
	for I in data.cachedHistory:
		num += 1
		$Line2D.add_point(Vector2(num * maxX/data.cachedHistory.size(),-I["count"] * 2))
	
	num = -1
	for I in data.cachedHistory:
		num += 1
		$Line2D2.add_point(Vector2(num * maxX/data.cachedHistory.size(),-I["averageBST"]))
