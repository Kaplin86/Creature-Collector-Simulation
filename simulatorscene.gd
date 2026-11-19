extends Node

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

@export var topGround : FastNoiseLite
@export var secondaryGroundNoise : FastNoiseLite
@export var BiomeNoiseTemperature : FastNoiseLite
@export var BiomeNoiseHumidity : FastNoiseLite

@export var biomeTypingRanges : Dictionary[GlobalVars.Typings,Vector2]

func _ready():
	
	if !ChangeOnValues:
		return 
	
	simMinX = sizeX / -2
	simMaxX = sizeX / 2
	
	simMinY = sizeY / -2
	simMaxY = sizeY / 2
	
	
	#@await get_tree().process_frame
	$StaticBody3D/MeshInstance3D.mesh.size = Vector2(sizeX,sizeY)
	
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
	
	
	
	
	for I in range(startingTreeCount):
		var newTree = FruitSpawningTree.new()
		add_child(newTree)
		newTree.global_position = Vector3(randf_range(simMinX,simMaxX),0,randf_range(simMinY,simMaxY))
		for C in range(7):
			newTree.spawnFruit()
	
	#spawnCreatures()
	
	makeGroundMesh()
	
	for I in range(6):
		while get_tree().get_nodes_in_group("creature").size() != 1:
			await get_tree().process_frame
		spawnCreatures()
	
	

func spawnCreatures():
	
	var move = Move.new()
	for I in range(startingSpeciesCount):
		var randomPosition = Vector3(randf_range(simMinX,simMaxX),0,randf_range(simMinY,simMaxY))
		var newAgent = Agent.new()
		for C in startingGenes: newAgent.genes.append(C.duplicate(true))
		var part1 = basicBodyPart.duplicate(true)
		newAgent.parts.append(part1)
		newAgent.moveSet.append(move.duplicate(true))
		for C in range(mutationLevel):
			newAgent.mutateAgent(newAgent)
		#newAgent.global_position = randomPosition
		newAgent.species = %SpeciesHandler.checkChildIfNewSpecies(newAgent,-5)
		#newAgent.modulate = %SpeciesHandler.Species[newAgent.species].color
		for C in range(countPerGroup):
			var dupe = newAgent.duplicate()
			dupe.level = randi_range(minStartingLevel,maxStartingLevel)
			dupe.age = dupe.level * 20
			add_child(dupe)
			dupe.global_position = randomPosition
			
		var newNest = Nest.new()
		newNest.species = newAgent.species
		add_child(newNest)
		newNest.global_position = randomPosition
	

func _process(delta):
	#print(%SpatialGrid.getCell(get_global_mouse_position()))
	#print(delta)
	pass


func _on_button_2_pressed():
	Engine.time_scale = 1
	Transition.transition(load("res://startMenu.tscn").instantiate())

func makeGroundMesh():
	
	
	var subdivisionCount = 20.0
	#var normal = Vector3(1,0,0)
	var actualMesh = SurfaceTool.new()
	actualMesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for Xval in range(int(sizeX / subdivisionCount)):
		for Yval in range(int(sizeY / subdivisionCount)):
			var realX = Xval * subdivisionCount
			var realY = Yval * subdivisionCount
			var otherRealY = (Yval + 1) * subdivisionCount
			var otherRealX = (Xval + 1) * subdivisionCount
			
			var chosenColor = Color.WHITE
			var biome = getBiomeAtPoint(Vector2(realX,realY))
			if biome == GlobalVars.Typings.Fire:
				chosenColor = Color.RED
			elif biome == GlobalVars.Typings.Water:
				chosenColor = Color.BLUE
			elif biome == GlobalVars.Typings.Green:
				chosenColor = Color.GREEN
			elif biome == GlobalVars.Typings.Robot:
				chosenColor = Color.BLACK 
			print(biome)
			
			
			actualMesh.set_color(chosenColor)
			actualMesh.add_vertex(Vector3(realX,getGroundValueAtPoint(realX,otherRealY),otherRealY))
			actualMesh.set_color(chosenColor)
			actualMesh.add_vertex(Vector3(realX, getGroundValueAtPoint(realX,realY),realY))
			actualMesh.set_color(chosenColor)
			actualMesh.add_vertex(Vector3(otherRealX,getGroundValueAtPoint(otherRealX,realY),realY))
			
			actualMesh.set_color(chosenColor)
			actualMesh.add_vertex(Vector3(otherRealX,getGroundValueAtPoint(otherRealX,otherRealY),otherRealY))
			actualMesh.set_color(chosenColor)
			actualMesh.add_vertex(Vector3(realX,getGroundValueAtPoint(realX,otherRealY),otherRealY))
			actualMesh.set_color(chosenColor)
			actualMesh.add_vertex(Vector3(otherRealX,getGroundValueAtPoint(otherRealX,realY),realY))
	actualMesh.generate_normals()
	$StaticBody3D/MeshInstance3D.mesh = actualMesh.commit()

func getGroundValueAtPoint(x,y):
	var groundMult = 60.0
	var secondVal = (secondaryGroundNoise.get_noise_2d(x,y) * 2)
	if abs(secondVal) < 1.0:
		secondVal *= 1.2
	return groundMult*(topGround.get_noise_2d(x,y) * 1.0)*secondVal

var numStore = {}
func getBiomeAtPoint(val : Vector2):
	var temperature = BiomeNoiseTemperature.get_noise_2dv(val)
	var humidity = BiomeNoiseHumidity.get_noise_2dv(val)
	var searchVector = Vector2(temperature,humidity)
	
	var closestBiome = null
	var dist = 99999
	for I in biomeTypingRanges:
		if biomeTypingRanges[I].distance_squared_to(searchVector) < dist:
			dist = biomeTypingRanges[I].distance_squared_to(searchVector)
			closestBiome = I
	print(dist)
	if dist > 1.2:
		return null
	return closestBiome
