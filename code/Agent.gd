extends Node2D
class_name Agent

# NOTES FOR L8R: A bst of 300 and lower is considered small. For pokemon context, 300 bst is roughly most starter mons.

var HP = 60

var energy = 1.0
var birthtimer = 0
@export var parts : Array[BodyPart] = []

var memoryFoodPosition # a position that refers to the last seen fruit

@export var species = 1
var generation = 0

var inBattle = false

enum Diets {Herbivore, Carnivore, Omnivore}

@export var dietType : Diets = Diets.Herbivore

@export var moveSet : Array[Move] = []

@onready var spatialGrid : SpatialGrid = get_parent().get_node("SpatialGrid")
@onready var speciesHandler : SpeciesHandler = get_parent().get_node("SpeciesHandler")

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

var texture = preload("res://art/50.png")

func _ready():
	_bstHash = max(calculateBST(),5)
	_SpDHash = max(5,calculateFinalStat("SpD"))
	_SPHash = max(5,calculateFinalStat("SP"))
	_HPHash = max(5,calculateFinalStat("HP"))
	
	add_to_group("creature")
	
	var newSprite = Sprite2D.new()
	newSprite.texture = texture
	add_child(newSprite)
	
	HP = _HPHash
	
	spatialGrid.addEntity(self)
	
	targetLocation = global_position + Vector2(randf_range(-50,50),randf_range(-50,50))

func _exit_tree():
	spatialGrid.removeEntity(self)

func getTyping():
	return GlobalVars.Typings.Fire

var _bstHash = 0.0
var _SpDHash = 0.0
var _SPHash = 0.0
var _HPHash = 0.0

enum ActionTypes {Wander,Hunt,LookForMate}

var targetLocation : Vector2

var age = 0.0
func _process(delta):
	if _bstHash == 0.0: _bstHash = calculateBST()
	age += delta
	energy -= (delta / GlobalVars.TimeForSmallCreatureToDieOfStarvation) * ( 200/float(_bstHash))
	if HP > 0:
		HP = min(HP + delta, _HPHash)
	
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
				if result is Agent:
					battle(result)
		else:
			if memoryFoodPosition:
				targetLocation = memoryFoodPosition
				if global_position.distance_to(memoryFoodPosition) < _SpDHash * GlobalVars.PixelVisionPerSPD:
					memoryFoodPosition = null
			else:
				wanderCode()
			
			
	
	if !inBattle:
		var oldPos = global_position
		global_position += global_position.direction_to(targetLocation) * min(_SPHash * GlobalVars.SpeedPerSpeed,global_position.distance_to(targetLocation))
		
		spatialGrid.updateEntity(self,oldPos)
		
		if HP <= 0:
			queue_free()

func wanderCode():
	if randi_range(0,20) == 0:
			targetLocation = global_position + Vector2(randf_range(-_SPHash * 2,_SPHash * 2),randf_range(-_SPHash * 2,_SPHash * 2))

func soloReproduction():
	var newAgent = Agent.new()

	newAgent.dietType = dietType

	newAgent.parts = parts.duplicate(true)
	newAgent.moveSet = moveSet.duplicate(true)
	newAgent.global_position = global_position
	newAgent.targetLocation = global_position
	newAgent.energy = 0.5
	newAgent.generation = generation + 1
	
	
	if randf() <= GlobalVars.newLimbChance:
		var NewPart = BodyPart.new()
		NewPart.mutateRandomly()
		NewPart.mutateRandomly()
		NewPart.mutateRandomly()
		newAgent.parts.append(NewPart)
	
	if randf() <= GlobalVars.MutateLimbDebuffChance:
		newAgent.parts.pick_random().MutateDebuff()
	
	for I : BodyPart in newAgent.parts:
		I.mutateRandomly()
	
	if randf() <= GlobalVars.changedDietChance:
		newAgent.dietType = Diets.values().pick_random()
		if newAgent.dietType != dietType:
			for Q in range(4):
				for C : BodyPart in newAgent.parts:
					C.mutateRandomly()
		

	get_parent().add_child(newAgent)
	newAgent.modulate = modulate
	
	newAgent.species = speciesHandler.checkChildIfNewSpecies(newAgent,species)
	
	
	newAgent.modulate = speciesHandler.Species[newAgent.species].color
	
	birthtimer = _bstHash * GlobalVars.bstPerBirthTimer

func lookInVision() -> Array[Node2D]:
	
	var VisionDistance = _SpDHash * GlobalVars.PixelVisionPerSPD
	var foundNodes : Array[Node2D] = []
	var nodes = spatialGrid.getEntitiesUsingDist(global_position,VisionDistance)
	for I in nodes:
		if I == self:
			continue
		
		if !is_instance_valid(I):
			continue
		
		if global_position.distance_squared_to(I.global_position) < VisionDistance * VisionDistance:
			foundNodes.append(I)
	
	foundNodes.sort_custom(byDistance)
	
	return foundNodes

func byDistance(a : Node2D,b : Node2D):
	return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position)

func lookForFood() -> Node2D:
	var results = lookInVision()
	for I in results:
		if dietType in [Diets.Herbivore,Diets.Omnivore]:
			if I is Fruit:
				return I
		elif dietType in [Diets.Carnivore,Diets.Omnivore]:
			if I is Agent:
				if !I.inBattle:
					if I.species != species:
						return I
	
	return null

func battle(target : Agent):
	inBattle = true
	target.inBattle = true
	
	var turn = 0
	while (target.HP > 0) and (HP > 0):
		turn += 1
		
		if turn > 300:
			var rando = [target,self]
			rando.pick_random().hp = -9999
		
		var order = []
		if target.calculateFinalStat("SP") > _SPHash:
			order.append(target)
			order.append(self)
		else:
			order.append(self)
			order.append(target)
		
		
		for Attacker : Agent in order:
			var Defender = order[order.find(Attacker) - 1] #Gets the agent that goes before the attacker, which in the context of 2 means the other character. Will need to be changed in 2v2
			
			var move : Move = Attacker.moveSet.pick_random()
			
			var damageToDeal = max(GlobalVars.calculateDamage(move, Attacker, Defender),1)
			
			
			Defender.HP -= damageToDeal
			
			
			if !((target.HP > 0) and (HP > 0)):
				break
	
	inBattle = false
	target.inBattle = false
	
	if target.HP <= 0:
		energy = 1
	else:
		queue_free()
		if target.dietType in [Diets.Carnivore,Diets.Omnivore]:
			target.energy = 1
	
