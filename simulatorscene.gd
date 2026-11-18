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

@export var groundNoise : FastNoiseLite

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
	
	spawnCreatures()
	
	makeGroundMesh()
	
	for I in range(6):
		while get_tree().get_nodes_in_group("creature").size() != 0:
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
	
	var sampleMult = 10.0
	
	var vertices = PackedVector3Array()
	var newMesh := ArrayMesh.new()
	var grid : Dictionary[Vector2i,float] = {}
	for X in range(sizeX / sampleMult):
		for Y in range(sizeY / sampleMult):
			grid[Vector2i(X * sampleMult,Y * sampleMult)] = groundNoise.get_noise_2d(X * sampleMult,Y * sampleMult)
	
	print(grid)
	
	for X in range(sizeX / sampleMult):
		for Y in range(sizeY / sampleMult):
			var usingX = int(X * sampleMult)
			var usingY = int(Y * sampleMult)
			var vector : Vector2i = Vector2i(usingX,usingY)
			var points = [Vector3(usingX,grid[vector],usingY)]
			if grid.has(vector + Vector2i(0,1)):
				points.append(Vector3(usingX,grid[vector + Vector2i(0,sampleMult)],usingY + sampleMult))
			if grid.has(vector + Vector2i(1,0)):
				points.append(Vector3(usingX + sampleMult,grid[vector + Vector2i(sampleMult,0)],usingY))
			if points.size() >= 3:
				for I in points:
					vertices.append(I)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	newMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	$StaticBody3D/MeshInstance3D.mesh = newMesh
