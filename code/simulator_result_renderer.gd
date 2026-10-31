extends Node2D

@export var data : SimulationHistory

var maxX = 300

func _ready() -> void:
	_render()

func _render():
	
	var speciesTotal = []
	for I in data.cachedHistory:
		for C in I.keys():
			if not C in speciesTotal: speciesTotal.append(C)
	
	
	renderProperty("count",speciesTotal[0],$Species1COUNT)
	renderProperty("averageBST",speciesTotal[0],$Species1STAT)
	
	renderProperty("count",speciesTotal[1],$Species2count)
	renderProperty("averageBST",speciesTotal[1],$Species2STAT)

func renderProperty(property,specie, line):
	var num = -1
	for I in data.cachedHistory:
		num += 1
		if I.has(specie):
			line.add_point(Vector2(num * maxX/data.cachedHistory.size(),-I[specie][property]))
		else:
			pass
			#$Line2D2.add_point(Vector2(num * maxX/data.cachedHistory.size(),-I["averageBST"]))
