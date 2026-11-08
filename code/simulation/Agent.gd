extends CharacterBody2D
class_name Agent

## A simulation agent. Has [member HP], [member energy], [member parts], and a lot more. 

# Note For l8r: Look into rendering using MultiMeshInstance2D


var HP : float = 60 ## If HP is below 0, the agent is deleted (only outside of battle)

## The age of the creature, in seconds.
var age :float = 0.0


## The energy of the creature, from 0.0 to 1.0
var energy : float = 1.0

## the creature's level
var level : int = 1

## the creature's exp
var expPoints : float = 1

## A timer that dictates if a creature can give birth again. [br] If it is below 0, they can. It gets set to stat-total * simulator-value on reproduction. Reduced by delta every frame.
var birthtimer : float = 0

## The parts on the creature. Used to dictate its stats
@export var parts : Array[BodyPart] = []

## The behavior genes on the creature. Used to dictate how it acts
@export var genes : Array[BasicBehaviorGene] = []

## The position of last seen fruit. Functionally a [Vector2], however it remains untyped
var memoryFoodPosition

## The species number of the agent [br]
## See [SpeciesHandler]
@export var species := 1

## A somewhat useless value to keep track on how many 'generations' down this agent is. Increased when born and passed down.
var generation := 0

## Dictates if the creature can move
var inBattle := false

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

## A boolean to signify if the agent is looking for a mate.
var lookingForMate := false

var _bstHash = 0.0
var _SpDHash = 0.0
var _SPHash = 0.0
var _HPHash = 0.0
var _lastHashLevel : int = -99

var _minGeneHash = 0.0 # the lowest value the lowest gene can be
var _maxGeneHash = 0.0 # the highest value the highest gene can be

## A dictionary with the last checked gene values, indexed by script.
var lastValueCheckResults : Dictionary[GDScript,float]= {}

## Last performed gene, in script form
var lastPerformedGene : GDScript

#Behavior Vals -----------------
## The diet type the agent has
@export var dietType : Diets = Diets.Herbivore
## The percentage of [member HP] that a predator needs to be to go hunting. If their [member HP] / MaxHP is less than this, they will abstain and instead do Wander movement until fully healed.
@export var battleRiskyness : float = 0.5
## The percentage distance a predator (any carnivore, or carnivore of higher base stat if this agent is already a carnivore) needs to be before this agent goes into run state
@export var fleeDist : float = 0.5


## The current location the agent is walking to.
var targetLocation : Vector2

## Object that the creature is holding.
var holdingObject : Node = null 

## A function that retrieves the sum of all [member parts] in a specific stat, accounting for levels. [br]
## [param stat] needs to be an actual stat string ("HP", "ATK", etc.) to work
func calculateFinalStat(stat : String) -> int:
	var sum = 0
	for I in parts:
		sum += I.get(stat)
	
	if stat == "HP":
		return (((2 * sum) * level) / 100) + 10 + level
	else:
		return (((2 * sum) * level) / 100) + 5
	

## A function that retrieves the sum of all [member parts] in a specific stat, ignoring levels [br]
## [param stat] needs to be an actual stat string ("HP", "ATK", etc.) to work
func calculateBaseStat(stat : String) -> int:
	var sum = 0
	for I in parts:
		sum += I.get(stat)
	return sum

## Adds up all stats on all [member parts]
func calculateBST() -> int:
	var sum = 0
	for I in parts:
		for X in I.stats:
			sum += I.get(X)
	return sum

## Picks up a object
func pickup(node : Node2D) -> bool:
	if holdingObject == null:
		var new = node.duplicate()
		holdingObject = new
		node.queue_free()
		return true
	return false

## Drops an object
func drop() -> bool:
	if holdingObject:
		holdingObject.global_position = global_position
		add_sibling(holdingObject)
		holdingObject = null
		return true
	return false


var _texture = preload("res://art/50.png")

@onready var ForwardRaycast : RayCast2D = RayCast2D.new()

func _ready():
	updateLevelHashes()
	
	add_to_group("creature")
	
	var newSprite = Sprite2D.new()
	newSprite.texture = _texture
	add_child(newSprite)
	
	HP = _HPHash
	
	_spatialGrid.addEntity(self)
	
	targetLocation = global_position + Vector2(randf_range(-50,50),randf_range(-50,50))
	
	ForwardRaycast.collision_mask = 2
	add_child(ForwardRaycast)
	
	var newHitbox = CollisionShape2D.new()
	add_child(newHitbox)
	var circle = CircleShape2D.new()
	circle.radius = 10
	newHitbox.shape = circle
	collision_mask = 2
	
	if genes == []:
		genes.append(BasicHuntingGene.new())
		genes.append(BasicMateGene.new())


## To save on resources, passively needed values (such as BST, HP, Special Defense and Speed) are
## stored as hash variables rather than being recalculated every frame.[br]
## This function updates those hashes.
func updateLevelHashes():
	_bstHash = max(calculateBST(),5)
	_SpDHash = max(5,calculateFinalStat("SpD"))
	_SPHash = max(5,calculateFinalStat("SP"))
	_HPHash = max(5,calculateFinalStat("HP"))
	_lastHashLevel = level

func _exit_tree():
	_spatialGrid.removeEntity(self)

## Returns the typing of the first two moves. Will return only one if there is one move, or both moves share a type.
## For some reason the docs on this are consistently getting bugged. It returns a typing from the [enum GlobalVars.Typings]
func getTyping() -> Array[GlobalVars.Typings]:
	var types : Array[GlobalVars.Typings] = []
	if moveSet.get(0):
		types.append(moveSet.get(0).typing)
	
	if moveSet.size() != 1:
		if moveSet.get(1):
			types.append(moveSet.get(1).typing)
	return types

## Returns the pixel vision distance the creature can look
func getVisionDist() -> float:
	return _SpDHash * GlobalVars.PixelVisionPerSPD

## Runs at the start of the frame-by-frame loop. Increases [member age], [member HP], and decreases [member energy] and [member birthtimer]. The creature is killed here if it lacks energy.
func ageAndEnergyTick(delta) -> void:
	age += delta
	energy -= delta * GlobalVars.HungerRate / (_bstHash / 300.0) ** 0.33
	birthtimer -= delta
	
	expPoints += delta
	
	checkLevel()
	
	if !inBattle:
		if HP > 0:
			HP = min(HP + delta, _HPHash)
		
	if energy <= 0 or HP < 0:
		
		if holdingObject:
			drop()
		
		queue_free()

var wanderGene = WanderGene.new()

## Based on various values.
func determineCurrentAction() -> BasicBehaviorGene:
	var currentAction = wanderGene
	var highestTier = 0.65
	
	_minGeneHash = 999
	_maxGeneHash = -999
	
	lastValueCheckResults[currentAction.get_script()] = highestTier
	
	var currentAgeRatio = getAgeMetric()
	
	for I in genes:
		var val = I.evaluate(self)
		
		lastValueCheckResults[I.get_script()] = val
		
		if val > highestTier:
			if currentAgeRatio >= I.ageRestriction:
				currentAction = I
				highestTier = val
			
		_maxGeneHash = max(_maxGeneHash,I.maximum)
		_minGeneHash = min(_minGeneHash,I.minimum)
	
	lastPerformedGene = currentAction.get_script()
	
	return currentAction


## Runs every frame, if the determined [enum ActionTypes] is [enum ActionTypes.Wander]
func wander() -> void:
	lookingForMate = false
	
	setWanderTarget()
	var result = lookForFood()
	if result:
		memoryFoodPosition = result.global_position

var fleeDirOffset = 0.0

func flee() -> void:
	var result = lookForPredator()
	if !result:
		return
	
	var awayDirection = (global_position - result.global_position).normalized()
	
	var possibleAngles = [0,30,-30,60,-60,90,-90,135,-135,180]
	var bestDirection = awayDirection
	var foundPath = false
	
	for angle in possibleAngles:
		var testDirection = awayDirection.rotated(deg_to_rad(angle))
		
		ForwardRaycast.target_position = testDirection * 40
		ForwardRaycast.force_raycast_update()
		
		if !ForwardRaycast.is_colliding():
			bestDirection = testDirection
			foundPath = true
			break
	
	if !foundPath:
		bestDirection = Vector2.from_angle(randf()*TAU)
	
	targetLocation = global_position + bestDirection * 100
	
	
func _process(delta):
	if _bstHash == 0.0: _bstHash = calculateBST()
	
	
	ageAndEnergyTick(delta)
	
	
	var currentAction : BasicBehaviorGene = determineCurrentAction()
	currentAction.act(self)
	
	var result = lookForFood()
	if result:
		memoryFoodPosition = result.global_position
	
	if !inBattle:
		var oldPos = global_position
		
		var offset = targetLocation - global_position
		var dist = offset.length()
		var speed = _SPHash * GlobalVars.SpeedPerSpeed 
		
		if dist > 0.0 and delta > 0.0:
			var travelDist = min(speed * delta,dist)
			var motion = offset.normalized() * travelDist
			
			move_and_collide(motion)
			
			if global_position.distance_to(targetLocation) < 0.01:
				global_position = targetLocation
				velocity = Vector2.ZERO
			
		else:
			velocity = Vector2.ZERO
		
		_spatialGrid.updateEntity(self,oldPos)
		

## Checks the current EXP, and detects if the creature leveled up.
func checkLevel() -> void:
	var expNeededVal = expNeeded()
	if expPoints >= expNeededVal:
		expPoints -= expNeededVal
		level += 1
	if level != _lastHashLevel:
		updateLevelHashes()

## Returns the exp needed for next level, based on current level.
func expNeeded() -> float:
	return level ** 3

## Age as adulthood metric (from 0.0 to 1.0+, with 1.0 exactly being when the creature is old enough to reproduce)
func getAgeMetric() -> float:
	return inverse_lerp(0,max(GlobalVars.AgeToReproducePerStat * _bstHash,30),age)

## sets [member targetLocation] to a nearby location, based on Speed.[br]
## Most gene behaviors will call this if they fail.
func setWanderTarget() -> void:
	if randi_range(0,20) == 0:
		var awayDirection = (global_position - global_position + Vector2(randf_range(-_SPHash * 2,_SPHash * 2),randf_range(-_SPHash * 2,_SPHash * 2))).normalized()
	
		var possibleAngles = [0,30,-30,60,-60,90,-90,135,-135,180]
		var bestDirection = awayDirection
		var foundPath = false
		
		for angle in possibleAngles:
			var testDirection = awayDirection.rotated(deg_to_rad(angle))
			
			ForwardRaycast.target_position = testDirection * 40
			ForwardRaycast.force_raycast_update()
			
			if !ForwardRaycast.is_colliding():
				bestDirection = testDirection
				foundPath = true
				break
		
		if !foundPath:
			bestDirection = Vector2.from_angle(randf()*TAU)
		
		targetLocation = global_position + bestDirection * 100
		
		
		

## The agent creates a new agent at this location, which inherits everything and gets mutated.[br]
## See [method mutateAgent]
func soloReproduction() -> Agent:
	var newAgent = Agent.new()
	newAgent.dietType = dietType
	
	for I in parts: newAgent.parts.append(I.duplicate(true))
	for I in genes: newAgent.genes.append(I.duplicate(true))

	newAgent.moveSet = moveSet.duplicate(true)
	newAgent.global_position = global_position
	newAgent.targetLocation = global_position
	newAgent.energy = 0.7
	newAgent.generation = generation + 1
	
	
	mutateAgent(newAgent)

	get_parent().add_child(newAgent)
	newAgent.modulate = modulate
	
	newAgent.updateSpecies()
	
	birthtimer = _bstHash * GlobalVars.bstPerBirthTimer
	return newAgent

## Checks with [SpeciesHandler] to determine what class this creature is, and updates modulate accordingly.
func updateSpecies():
	species = _speciesHandler.checkChildIfNewSpecies(self,species)
	modulate = _speciesHandler.Species[species].color

## Mutates the inputted agent.
func mutateAgent(agent : Agent) -> void:
	if randf() <= GlobalVars.newLimbChance:
		var NewPart = BodyPart.new()
		NewPart.mutateRandomly()
		NewPart.mutateRandomly()
		NewPart.mutateRandomly()
		agent.parts.append(NewPart)
	
	if randf() <= GlobalVars.MutateLimbDebuffChance:
		agent.parts.pick_random().MutateDebuff()
	
	for I : BodyPart in agent.parts:
		I.mutateRandomly() #Alters stats a tiny bit
	
	for I in agent.moveSet:
		I.mutate() # Chance to alter the moveset
	
	
	
	if randf() <= GlobalVars.changeBehaviorGenesChance:
		if randi_range(0,1) == 0:
			genes.erase(genes.pick_random())
		else:
			var thinkingGene = GlobalVars.genePool.pick_random()
			var hasIt = false
			for I : BasicBehaviorGene in agent.genes: 
				if I.get_script() == thinkingGene:
					hasIt = true
					break
			
			if !hasIt:
				agent.genes.append(thinkingGene.new())
	
	for I in agent.genes:
		I.mutate()
	
	
	if randf() <= GlobalVars.changedDietChance:
		agent.dietType = Diets.values().pick_random()
		if agent.dietType != dietType:
			for Q in range(4):
				for C : BodyPart in agent.parts:
					C.mutateRandomly()


## The agent creates a new agent at this location, which has the averaged stats of both input agents. It is then mutated.[br]
## See [method mutateAgent]
func duoReproduction(parent1 : Agent, parent2 : Agent) -> Agent:
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
	
	var typeToGene = {}
	for I : BasicBehaviorGene in parent1.genes:
		typeToGene[I.get_script()] = I.duplicate(true)
	for I : BasicBehaviorGene in parent2.genes:
		if typeToGene.has(I.get_script()):
			if randi_range(0,1) == 0:
				typeToGene[I.get_script()] = I.duplicate(true)
		else:
			typeToGene[I.get_script()] = I.duplicate(true)
	
	for I in typeToGene.values(): newAgent.genes.append(I.duplicate(true))
	
	newAgent.moveSet = usingMoves.duplicate(true)
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
	
	return newAgent

## Looks in the vision, calling [SpatialGrid], and returns all of the found nodes.
func lookInVision() -> Array[Node2D]:
	
	var VisionDistance = getVisionDist()
	var foundNodes : Array[Node2D] = []
	var nodes = _spatialGrid.getEntitiesUsingDist(global_position,VisionDistance)
	
	for I in nodes:
		if I == self:
			continue
		
		if !is_instance_valid(I):
			continue
		
		
		if global_position.distance_squared_to(I.global_position) < VisionDistance * VisionDistance:
			ForwardRaycast.global_position = global_position
			ForwardRaycast.target_position = I.global_position - global_position
			ForwardRaycast.force_raycast_update()
			
			if !ForwardRaycast.is_colliding():
				foundNodes.append(I)
	
	foundNodes.sort_custom(_byDistance)
	
	return foundNodes


func _byDistance(a : Node2D,b : Node2D):
	return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position)

## Looks for food in vision, and returns the nearest one. This can either return a [Fruit], or another [Agent]
func lookForFood() -> Node2D:
	var results = lookInVision()
	for I in results:
		if dietType in [Diets.Herbivore,Diets.Omnivore]:
			if I is Fruit:
				return I
		elif dietType in [Diets.Carnivore,Diets.Omnivore]:
			if I is Agent:
				if inverse_lerp(0,_HPHash,HP) >= battleRiskyness:
					if !I.inBattle:
						if I.species != species:
							return I
	
	return null

## The same as [member lookForFood], except it returns all food options
func lookForFoods() -> Array[Node2D]:
	var results = lookInVision()
	var final : Array[Node2D] = []
	for I in results:
		if dietType in [Diets.Herbivore,Diets.Omnivore]:
			if I is Fruit:
				final.append(I)
				continue
		elif dietType in [Diets.Carnivore,Diets.Omnivore]:
			if I is Agent:
				if inverse_lerp(0,_HPHash,HP) >= battleRiskyness:
					if !I.inBattle:
						if I.species != species:
							final.append(I)
							continue
	
	return final


## Looks for predators in vision, and returns the nearest one.
func lookForPredator() -> Node2D:
	var results = lookInVision()
	for I in results:
		if I is Agent:
			if I.species != species:
				if I.energy <= 0.75:
					if I.dietType in [Diets.Omnivore,Diets.Carnivore]:
						if dietType == Diets.Herbivore: # herbivores flee fear all omnivores and carnivores
							return I
						else:
							if I._bstHash >= _bstHash:
								return I
	
	return null

## Looks for a valid mate in vision, and returns the nearest one.
func lookForMate() -> Agent:
	var results = lookInVision()
	for I in results:
		if I is Agent:
			if I.species == species:
				if I.lookingForMate and !I.inBattle:
					return I
	
	return null

## Initiates a battle against the target. It loops until the [member HP] on either creature is reduced to 0. [br]
##If the battle is won, the intiator kills the target. If it is lost, the intiator leaves at 1 hp and reduced energy.
func battle(target : Agent) -> void:
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
		expPoints += target.level/7.0
	else:
		energy -= 0.3
		HP = 1
		#print("battle lose", name)
		
		target.expPoints += level/7.0
		if target.dietType in [Diets.Carnivore,Diets.Omnivore]:
			target.energy = 1
			
