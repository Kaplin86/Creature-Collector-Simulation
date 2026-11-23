extends Node

@export var simMinX = 0
@export var simMaxX = 0
@export var simMinY = 0
@export var simMaxY = 0

@export var startingSpeciesCount = 10
@export var startingTreeCount = 10
@export var basicBodyPart : Array[BodyPart] = []
@export var startingGenes : Array[BasicBehaviorGene] = []

@export var sizeX = 10000
@export var sizeY = 10000

@export var mutationLevel = 5

@export var countPerGroup = 5

@export var ChangeOnValues = true

@export var minStartingLevel = 5
@export var maxStartingLevel = 15

@export var bumpiness = 1.0
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

	makeGroundMesh()
	
	$Floor/RightWall.shape.size.x = sizeX
	$Floor/ForwardWall.shape.size.z = sizeY
	$Floor/RightWall.global_position = Vector3(0.0,0.0,(sizeX / 2) )
	$Floor/LeftWall.global_position = Vector3(0.0,0.0,-(sizeX / 2) )
	$Floor/ForwardWall.global_position = Vector3(-(sizeY / 2) ,0.0,0.0)
	$Floor/BackwardsWall.global_position = Vector3((sizeY / 2) ,0.0,0.0)
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var treeRaycast = RayCast3D.new()
	treeRaycast.collision_mask = 3
	add_child(treeRaycast)
	for I in range(startingTreeCount):
		var newTree = FruitSpawningTree.new()
		treeRaycast.position = Vector3(randf_range(simMinX,simMaxX),30,randf_range(simMinY,simMaxY))
		treeRaycast.target_position = treeRaycast.position - Vector3(0,90,0)
		treeRaycast.force_raycast_update()
		add_child(newTree)
		newTree.global_position = treeRaycast.get_collision_point()
		for C in range(1):
			newTree.spawnFruit()
			
	
	print("spawning...")
	
	spawnCreatures()
	
	$Floor/RightWall.disabled = false
	$Floor/LeftWall.disabled = false
	$Floor/ForwardWall.disabled = false
	$Floor/BackwardsWall.disabled = false
	var lastCount =  get_tree().get_nodes_in_group("creature").size()
	for I in range(6):
		
		while lastCount != 0:
			if get_tree():
				await get_tree().process_frame
			if get_tree():
				lastCount =  get_tree().get_nodes_in_group("creature").size()
			else:
				lastCount= 0
		if get_tree(): spawnCreatures()
	
	

func spawnCreatures():
	var creatureRaycast = RayCast3D.new()
	creatureRaycast.collision_mask = 3
	add_child(creatureRaycast)
	var move = Move.new()
	for I in range(startingSpeciesCount):
		var randomPosition = Vector3(randf_range(simMinX,simMaxX),150,randf_range(simMinY,simMaxY))
		creatureRaycast.global_position = randomPosition
		creatureRaycast.target_position = randomPosition - Vector3(0,9999,0)
		creatureRaycast.force_raycast_update()
		if creatureRaycast.is_colliding():
			randomPosition = creatureRaycast.get_collision_point()
			randomPosition += Vector3(0,0.5,0)
			
		
		var newAgent = Agent.new()
		for C in startingGenes: newAgent.genes.append(C.duplicate(true))
		for C in basicBodyPart: newAgent.parts.append(C.duplicate(true))
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
			dupe.global_position = randomPosition
			add_child(dupe)
			dupe.global_position = randomPosition
			
		var newNest = Nest.new()
		newNest.species = newAgent.species
		add_child(newNest)
		newNest.global_position = randomPosition
	

var frame = []
var dt = 0.0
func _process(delta):
	#print(%SpatialGrid.getCell(get_global_mouse_position()))
	dt += delta
	if dt > 60:
		GlobalVars._agentsMadeThisMinute = 0
		dt = 0.0
		frame.append("frame count " + str(Engine.get_frames_per_second()) + " - "+  str(get_tree().get_node_count_in_group("creature")))
		for I in range(%CreatureRunningSectioner.groups.size()):
			
			print("group ", I, " has a average tick time of ", get_average(%CreatureRunningSectioner.processingTimePerGroup[I]))
		for I in GlobalVars.geneProcessingSamples:
			print(I," (evaluation) - ", get_average(GlobalVars.geneProcessingSamples[I]))
		for I in GlobalVars.geneUsingSamples:
			print(I," (using) - ", get_average(GlobalVars.geneUsingSamples[I]))
		for I in GlobalVars.matingGeneSamples:
			print("SOLO REPRODUCTION STUFF : ",I,"  - ", get_average(GlobalVars.matingGeneSamples[I]))
		print("solo reproduction sample count ", GlobalVars.matingGeneSamples.get("instantiating",[]).size() )
		print("mating gene count", GlobalVars.geneUsingSamples.get(BasicMateGene.new().get_script(),[]).size())
		
		for I in GlobalVars.readySamples:
			print("READY STUFF : ",I,"  - ", get_average(GlobalVars.readySamples[I]))
		
		print("species count ", %SpeciesHandler.Species.size())
		print(frame)
	
	var cellThings = %SpatialGrid.getEntitiesUsingDist(get_viewport().get_camera_3d().global_position,25)
	for I in cellThings:
		if is_instance_valid(I):
			if I is Agent:
				if !I._hasGenerated:
					I.doVisual()
	
func get_average(numbers: Array) -> float:
	if numbers.is_empty():
		return 0.0
	
	var sum := 0.0
	for n in numbers:
		sum += n
	
	return sum / numbers.size()


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
	$Floor/MeshInstance3D.global_position = -Vector3(sizeX/2,0,sizeY/2)
	$Floor/CollisionShape3D.global_position = -Vector3(sizeX/2,0,sizeY/2)
	var arrmesh := actualMesh.commit()
	$Floor/CollisionShape3D.shape = arrmesh.create_trimesh_shape()
	$Floor/MeshInstance3D.mesh = arrmesh

func getGroundValueAtPoint(x,y):
	var groundMult = 60.0
	var secondVal = (secondaryGroundNoise.get_noise_2d(x,y) * 2)
	if abs(secondVal) < 1.0:
		secondVal *= 1.2
	return -6 + (groundMult*(topGround.get_noise_2d(x,y) * 1.0)*secondVal * bumpiness)

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
	
	if dist > 1.2:
		return null
	return closestBiome
