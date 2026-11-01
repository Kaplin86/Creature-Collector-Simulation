extends Node2D
class_name Agent

## A simulation agent. Has [member HP], [member ENERGY], and [member parts]. 

var HP : float = 60 ## If HP is below 0, the agent is deleted (only outside of battle)

## The energy of the creature, from 0.0 to 1.0
var energy : float = 1.0

## A timer that dictates if a creature can give birth again. [br] If it is below 0, they can. It gets set to stat-total * simulator-value on reproduction. Reduced by delta every frame.
var birthtimer = 0

## The parts on the creature. Used to dictate its stats
@export var parts : Array[BodyPart] = []

## The position of last seen fruit. Functionally a [Vector2], however it remains untyped
var memoryFoodPosition

## The species number of the agent [br]
## See [SpeciesHandler]
@export var species = 1

## A somewhat useless value to keep track on how many 'generations' down this agent is. Increased when born and passed down.
var generation = 0

## Dictates if the creature can move
var inBattle = false

## The three types of diets an agent can have
enum Diets {
	Herbivore, ## Only eats plants
	Carnivore, ## Will attempt to hunt other creatures, initiating a [method battle]
	Omnivore ## Eats plants and other creatures. Initiates a [method battle] when hunting another creature.
	}

## The list of Moves a creature has. At max, it can have 4
@export var moveSet : Array[Move] = []

@onready var _spatialGrid : SpatialGrid = get_parent().get_node("SpatialGrid")
@onready var _speciesHandler : SpeciesHandler = get_parent().get_node("SpeciesHandler")

var lookingForMate = false

#Behavior Vals
@export var dietType : Diets = Diets.Herbivore
@export var battleRiskyness : float = 0.5 #refers to the level of hp a predator needs to be to go hunting. By default, below 50% hp will cause them to not fight.

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
	
	_spatialGrid.addEntity(self)
	
	targetLocation = global_position + Vector2(randf_range(-50,50),randf_range(-50,50))

func _exit_tree():
	_spatialGrid.removeEntity(self)

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
	if !inBattle:
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
		lookingForMate = false
		
		wanderCode()
		var result = lookForFood()
		if result:
			memoryFoodPosition = result.global_position
	elif currentAction == ActionTypes.Hunt:
		lookingForMate = false
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
	elif currentAction == ActionTypes.LookForMate:
		lookingForMate = true
		var result = lookForMate()
		if result and result is Agent:
			targetLocation = result.global_position
			if global_position.distance_squared_to(targetLocation) <= 10:
				var ChildBearer : Agent = result
				var Other : Agent = self
				if result.energy < energy:
					ChildBearer = self
					Other = result
				
				ChildBearer.duoReproduction(ChildBearer,Other)
				ChildBearer.energy -= 0.25
				
		else:
			wanderCode()
	
	
	if !inBattle:
		var oldPos = global_position
		global_position += global_position.direction_to(targetLocation) * min(_SPHash * GlobalVars.SpeedPerSpeed,global_position.distance_to(targetLocation))
		
		_spatialGrid.updateEntity(self,oldPos)
		
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
	
	
	mutateAgent(newAgent)

	get_parent().add_child(newAgent)
	newAgent.modulate = modulate
	
	newAgent.species = _speciesHandler.checkChildIfNewSpecies(newAgent,species)
	
	
	newAgent.modulate = _speciesHandler.Species[newAgent.species].color
	
	birthtimer = _bstHash * GlobalVars.bstPerBirthTimer

func mutateAgent(agent : Agent):
	if randf() <= GlobalVars.newLimbChance:
		var NewPart = BodyPart.new()
		NewPart.mutateRandomly()
		NewPart.mutateRandomly()
		NewPart.mutateRandomly()
		agent.parts.append(NewPart)
	
	if randf() <= GlobalVars.MutateLimbDebuffChance:
		agent.parts.pick_random().MutateDebuff()
	
	for I : BodyPart in agent.parts:
		I.mutateRandomly()
	
	if randf() <= GlobalVars.changedDietChance:
		agent.dietType = Diets.values().pick_random()
		if agent.dietType != dietType:
			for Q in range(4):
				for C : BodyPart in agent.parts:
					C.mutateRandomly()

func duoReproduction(parent1 : Agent, parent2 : Agent):
	var newAgent = Agent.new()
	newAgent.dietType = dietType
	var pool = parent1.parts.duplicate(true)
	var i = -1
	for part2 in parent2.parts:
		i += 1
		var part1 : BodyPart = pool.get(i)
		if part1:
			part1.averageWith(part2)
	
	
	newAgent.parts = pool
	
	var movePool = parent1.moveSet.duplicate(true)
	movePool.append_array(parent2.moveSet.duplicate(true))
	
	var usingMoves : Array[Move] = []
	while usingMoves.size() < 4 and movePool.size() != 0:
		var new = movePool.pick_random()
		movePool.erase(new)
		usingMoves.append(new)
	
	
	newAgent.moveSet = usingMoves
	newAgent.global_position = global_position
	newAgent.targetLocation = global_position
	newAgent.energy = 0.5
	newAgent.generation = generation + 1
	newAgent.battleRiskyness = clamp(((parent1.battleRiskyness + parent2.battleRiskyness) / 2),0,1) + randf_range(-0.05,0.05)
	
	mutateAgent(newAgent)

	get_parent().add_child(newAgent)
	newAgent.modulate = modulate
	
	newAgent.species = _speciesHandler.checkChildIfNewSpecies(newAgent,species)
	
	
	newAgent.modulate = _speciesHandler.Species[newAgent.species].color
	
	birthtimer = _bstHash * GlobalVars.bstPerBirthTimer

func lookInVision() -> Array[Node2D]:
	
	var VisionDistance = _SpDHash * GlobalVars.PixelVisionPerSPD
	var foundNodes : Array[Node2D] = []
	var nodes = _spatialGrid.getEntitiesUsingDist(global_position,VisionDistance)
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
			if inverse_lerp(0,_HPHash,HP) >= battleRiskyness:
				if I is Agent:
					if !I.inBattle:
						if I.species != species:
							return I
	
	return null

func lookForMate() -> Node2D:
	var results = lookInVision()
	for I in results:
		if I is Agent:
			if I.species == species:
				if I.lookingForMate and !I.inBattle:
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
			rando.pick_random().HP = -9999
		
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
		print("battle won", name)
	else:
		energy -= 0.3
		HP = 1
		print("battle lose", name)
		if target.dietType in [Diets.Carnivore,Diets.Omnivore]:
			target.energy = 1
