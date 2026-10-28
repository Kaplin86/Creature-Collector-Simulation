extends Node2D
class_name Agent

# NOTES FOR L8R: A bst of 300 and lower is considered small. For pokemon context, 300 bst is roughly most starter mons.

var energy = 1.0
@export var parts : Array[BodyPart] = []

var memoryFoodPosition # a position that refers to the last seen fruit

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
	_bstHash = calculateBST()
	_SpDHash = calculateFinalStat("SpD")

var _bstHash = 0.0
var _SpDHash = 0.0

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
	if GlobalVars.AgeToReproducePerStat * _bstHash < age:
		if energy >= 0.75:
			if GlobalVars.reproductionType == 0:
				energy -= 0.5
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
			if targetLocation.distance_to(result.global_position) < 10:
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
			
			
	
	
	global_position = lerp(global_position,targetLocation,delta)

func wanderCode():
	if randi_range(0,20) == 0:
			targetLocation = global_position + Vector2(randf_range(-50,50),randf_range(-50,50))

func soloReproduction():
	var newAgent = Agent.new()

	newAgent.parts = parts.duplicate(true)
	newAgent.global_position = global_position
	newAgent.targetLocation = global_position
	for I : BodyPart in newAgent.parts:
		I.mutateRandomly()
	
	get_parent().add_child(newAgent)

func lookInVision() -> Array[Node2D]:
	
	var VisionDistance = _SpDHash * GlobalVars.PixelVisionPerSPD
	var foundNodes : Array[Node2D] = []
	var nodes = get_parent().get_children()
	for I in nodes:
		if I is Node2D: if global_position.distance_to(I.global_position) < VisionDistance:
			foundNodes.append(I)
	
	
	return foundNodes

func lookForFood() -> Node2D:
	var results = lookInVision()
	for I in results:
		if I is Fruit:
			return I
	
	return null
