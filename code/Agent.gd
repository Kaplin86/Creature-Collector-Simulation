extends Node2D
class_name Agent

# NOTES FOR L8R: A bst of 300 and lower is considered small. For pokemon context, 300 bst is roughly most starter mons.

var energy = 1.0
@export var parts : Array[BodyPart] = []

func calculateFinalStat(stat : String):
	var sum = 0
	for I in parts:
		sum += I.get(stat)
	return sum

func calculateBST():
	var sum = 0
	for I in parts:
		for X in I.stats:
			sum += I.get(X)
	return sum

func _ready():
	_bstHash = calculateBST()

var _bstHash = 0.0


var age = 0.0
func _process(delta):
	if _bstHash == 0.0: _bstHash = calculateBST()
	age += delta
	energy -= (delta / GlobalVars.TimeForSmallCreatureToDieOfStarvation) * (_bstHash/300.0)
	
	if energy <= 0:
		queue_free()
	
	if GlobalVars.AgeToReproducePerStat * _bstHash < age:
		if GlobalVars.reproductionType == 0:
			if energy >= 0.75:
				energy -= 0.5
				soloReproduction()

func soloReproduction():
	var newAgent = Agent.new()
	get_parent().add_child(newAgent)
	newAgent.parts = parts.duplicate(true)
	for I : BodyPart in newAgent.parts:
		I.mutateRandomly()
