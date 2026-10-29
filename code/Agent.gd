extends Node2D
class_name Agent

# NOTES FOR L8R: A bst of 300 and lower is considered small. For pokemon context, 300 bst is roughly most starter mons.

var energy = 1.0
var birthtimer = 0
@export var parts : Array[BodyPart] = []

var memoryFoodPosition # a position that refers to the last seen fruit

@export var species = 1

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

func _init():
	var newSprite = Sprite2D.new()
	newSprite.texture = load("res://art/thebrainguyfromtheoldoldnosmonprojectmeandmyfriendsdidofwhomiwillbeusingasaplaceholderforthetimebeing.png")
	add_child(newSprite)

func _ready():
	_bstHash = max(calculateBST(),5)
	_SpDHash = max(5,calculateFinalStat("SpD"))
	_SPHash = max(5,calculateFinalStat("SP"))

var _bstHash = 0.0
var _SpDHash = 0.0
var _SPHash = 0.0

enum ActionTypes {Wander,Hunt,LookForMate}

var targetLocation : Vector2

var age = 0.0
func _process(delta):
	if _bstHash == 0.0: _bstHash = calculateBST()
	age += delta
	energy -= (delta / GlobalVars.TimeForSmallCreatureToDieOfStarvation) * (_bstHash/300.0)
	
	if energy <= 0:
		queue_free()
	
	var currentAction : ActionTypes = ActionTypes.Wander
	birthtimer -= delta
	if max(GlobalVars.AgeToReproducePerStat * _bstHash,30) < age and birthtimer < 0.01:
		if energy >= 0.75:
			if GlobalVars.reproductionType == 0:
				energy -= 0.7
				soloReproduction()
			elif GlobalVars.reproductionType == 1:
				currentAction = ActionTypes.LookForMate
	
	
	if energy <= 0.75:
		currentAction = ActionTypes.Hunt
	
	if currentAction == ActionTypes.Wander:
		wanderCode()
		var result = lookForFood()
		if result:
			memoryFoodPosition = result.global_position
	elif currentAction == ActionTypes.Hunt:
		var result = lookForFood()
		if result:
			targetLocation = result.global_position
			if global_position.distance_to(result.global_position) < 5:
				if result is Fruit:
					energy += result.NutritionalValue
					result.queue_free()
		else:
			if memoryFoodPosition:
				targetLocation = memoryFoodPosition
				if global_position.distance_to(memoryFoodPosition) < _SpDHash * GlobalVars.PixelVisionPerSPD:
					memoryFoodPosition = null
			else:
				wanderCode()
			
			
	
	
	global_position += global_position.direction_to(targetLocation) * min(_SPHash,global_position.distance_to(targetLocation))

func wanderCode():
	if randi_range(0,20) == 0:
			targetLocation = global_position + Vector2(randf_range(-50,50),randf_range(-50,50))

func soloReproduction():
	var newAgent = Agent.new()

	newAgent.parts = parts.duplicate(true)
	newAgent.global_position = global_position
	newAgent.targetLocation = global_position
	newAgent.energy = 0.5
	newAgent.species = species
	for I : BodyPart in newAgent.parts:
		I.mutateRandomly()
	
	get_parent().add_child(newAgent)
	newAgent.modulate = modulate
	birthtimer = _bstHash * GlobalVars.bstPerBirthTimer

func lookInVision() -> Array[Node2D]:
	
	var VisionDistance = _SpDHash * GlobalVars.PixelVisionPerSPD
	var foundNodes : Array[Node2D] = []
	var nodes = get_parent().get_children()
	for I in nodes:
		if I is Node2D: if global_position.distance_to(I.global_position) < VisionDistance:
			foundNodes.append(I)
	
	var sortedByDistance = foundNodes.duplicate()
	sortedByDistance.sort_custom(byDistance)
	
	return sortedByDistance

func byDistance(a : Node2D,b : Node2D):
	return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position)

func lookForFood() -> Node2D:
	var results = lookInVision()
	for I in results:
		if I is Fruit:
			return I
	
	return null
