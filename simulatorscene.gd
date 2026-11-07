extends Node2D

@export var simMinX = 0
@export var simMaxX = 0
@export var simMinY = 0
@export var simMaxY = 0

@export var startingSpeciesCount = 10
@export var startingTreeCount = 10
@export var basicBodyPart : BodyPart
@export var startingGenes : Array[BasicBehaviorGene] = []

@export var sizeX = 10000
@export var sizeY = 10000

@export var mutationLevel = 5

@export var countPerGroup = 5

@export var ChangeOnValues = true

@export var minStartingLevel = 5
@export var maxStartingLevel = 15

func _ready():
	
	if !ChangeOnValues:
		return 
	
	simMinX = sizeX / -2
	simMaxX = sizeX / 2
	
	simMinY = sizeY / -2
	simMaxY = sizeY / 2
	
	
	#@await get_tree().process_frame
	%BG.global_position = Vector2(simMinX,simMinY)
	%BG.size = Vector2(abs(simMinX - simMaxX),abs(simMinY - simMaxY))
	
	var TopWall = CollisionShape2D.new()
	var BottomWall = CollisionShape2D.new()
	var Hitbox = RectangleShape2D.new()
	Hitbox.size = Vector2(abs(simMinX - simMaxX) + 10,10)
	
	TopWall.global_position = Vector2(0,simMinY)
	BottomWall.global_position = Vector2(0,simMaxY)
	
	TopWall.shape = Hitbox
	BottomWall.shape = Hitbox
	
	%StaticBody2D.add_child(TopWall)
	%StaticBody2D.add_child(BottomWall)
	
	var LeftWall = CollisionShape2D.new()
	var RightWall = CollisionShape2D.new()
	var Hitbox2 = RectangleShape2D.new()
	Hitbox2.size = Vector2(10,abs(simMinY - simMaxY) + 10)
	
	LeftWall.global_position = Vector2(simMinX,  0)
	RightWall.global_position = Vector2(simMaxX, 0)
	
	LeftWall.shape = Hitbox2
	RightWall.shape = Hitbox2
	
	%StaticBody2D.add_child(LeftWall)
	%StaticBody2D.add_child(RightWall)
	
	
	var move = Move.new()
	
	for I in range(startingTreeCount):
		var newTree = FruitSpawningTree.new()
		newTree.global_position = Vector2(randf_range(simMinX,simMaxX),randf_range(simMinY,simMaxY))
		add_child(newTree)
		for C in range(7):
			newTree.spawnFruit()
	
	for I in range(startingSpeciesCount):
		var randomPosition = Vector2(randf_range(simMinX,simMaxX),randf_range(simMinY,simMaxY))
		var newAgent = Agent.new()
		for C in startingGenes: newAgent.genes.append(C.duplicate(true))
		var part1 = basicBodyPart.duplicate(true)
		newAgent.parts.append(part1)
		newAgent.moveSet.append(move.duplicate(true))
		for C in range(mutationLevel):
			newAgent.mutateAgent(newAgent)
		newAgent.global_position = randomPosition
		newAgent.species = %SpeciesHandler.checkChildIfNewSpecies(newAgent,-5)
		newAgent.modulate = %SpeciesHandler.Species[newAgent.species].color
		for C in range(countPerGroup):
			var dupe = newAgent.duplicate()
			dupe.level = randi_range(minStartingLevel,maxStartingLevel)
			dupe.age = dupe.level * 20
			add_child(dupe)
			
		var newNest = Nest.new()
		newNest.species = newAgent.species
		newNest.global_position = randomPosition
		add_child(newNest)
	
	

func _process(delta):
	#print(%SpatialGrid.getCell(get_global_mouse_position()))
	#print(delta)
	pass


func _on_button_2_pressed():
	Engine.time_scale = 1
	Transition.transition(load("res://startMenu.tscn").instantiate())
