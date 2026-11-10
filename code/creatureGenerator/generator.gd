@tool
extends Node3D
class_name CreatureGeneratorNode

var Stats = ["HP","ATK","DEF","SpA","SpD","SP"]

@export_tool_button("Run Action") var run_action_btn = generate
@export var seedVal := 1
@export var parts : Array[BodyPart] = []
@export_group("Config")
@export var statTotalPerSpineSegment := 50
@export var spineDistPerSegment := 5
@export var spineMaxThickness := 0.2
@export var spineMinThickness := 0.1
@export_range(0.00000001,0.005,0.00000001) var spineMinMaxOffsetPerStat = 0.005

var spineThicknessChart : Dictionary[int,float] = {}

func getStatTotal(stat) -> int:
	var sum = 0
	for I in parts:
		sum += I.get(stat)
	return sum

func getAllStatTotal() -> int:
	var sum = 0
	for I in parts:
		for C in Stats:
			sum += I.get(C)
	return sum


func getPartsWithHighestStat(stat, startingArray = null) -> Array[BodyPart]: 
	var partsReturned : Array[BodyPart]= []
	var using = parts
	if startingArray: using = startingArray
	for I in using:
		var valid := true
		for S in Stats:
			if I.get(S) > I.get(stat):
				valid = false
				break
		if valid: partsReturned.append(I)
	return partsReturned


func generate():
	seed(seedVal)
	
	for I in Stats:
		print(I, " : ",getStatTotal(I))
	print(getAllStatTotal())
	
	for I in get_children(): I.queue_free()
	var spinePoints := createSpinePoints()
	var properSpinePoints := sanitizeSpinePoints(spinePoints)
	var limbAssignment := assignLimbs(properSpinePoints)
	
	addSpineThickness(properSpinePoints,limbAssignment)
	renderSpineFromPoints(properSpinePoints)

	var headPos = (properSpinePoints[-1])
	var firstPos = (properSpinePoints[0])
	createHead(headPos)
	renderLimbs(properSpinePoints,limbAssignment)
	#print(generateRingOfPointsAroundPoint(Vector3.ZERO,10,3,Vector3(0,-1,-1).normalized()))

## This returns the spine layout for the creature. Imagine this as a 2D image from the side, with each point referring to a seperate spine point
func createSpinePoints() -> PackedVector2Array:
	
	var points : PackedVector2Array = []
	
	var noise = FastNoiseLite.new()
	noise.seed = seedVal
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.56
	
	@warning_ignore("integer_division")
	var length = randi_range(2,min(int(getAllStatTotal() / statTotalPerSpineSegment),5))
	var direction : float = deg_to_rad(randf_range(-185,-175))
	var curveMult = 0.5
	if getPartsWithHighestStat("SP").size() <= 2:
		#print(getPartsWithHighestStat("SP"))
		direction =  deg_to_rad(randf_range(-95,-85))
		curveMult = 0.25
	var currentPosition = Vector2.ZERO
	points.append(currentPosition)
	
	
	for I in length:
		direction += noise.get_noise_2dv(currentPosition) * PI * 0.8 * curveMult
		currentPosition += Vector2.from_angle(direction) * spineDistPerSegment
		points.append(currentPosition)
	
	return points

func sanitizeSpinePoints(spine : PackedVector2Array) -> Array[Vector3]:
	var points : Array[Vector3] = []
	var subCount = 3
	for I in spine:
		var next = spine.get(spine.find(I) + 1)
		var currentPos = spinePosTo3D(I) + (Vector3(sin(I.x),cos(I.x),cos(I.y)) * 0.1)
		points.append(currentPos) 
		if next:
			next = spinePosTo3D(next)
			for C in range(subCount):
				points.append(lerp(currentPos,next,(C + 1) / float(subCount + 1)))
	
	
	
	return points

func addSpineThickness(points,body):
	var offset = getAllStatTotal() * spineMinMaxOffsetPerStat
	for I in range(points.size()):
		spineThicknessChart[I] = randf_range(spineMinThickness + offset ,spineMaxThickness + offset) + body.get(I,[]).size()*0.2
	spineThicknessChart[points.size() - 2] = 0.5
	spineThicknessChart[points.size() - 1] = 0.5
	
	var newSpineThickness : Dictionary[int,float]= {}
	for I in spineThicknessChart:
		var basicVal = spineThicknessChart.get(I) 
		newSpineThickness[I] = (basicVal + spineThicknessChart.get(I - 1,basicVal) + spineThicknessChart.get(I + 1, basicVal)) / 3
	spineThicknessChart = newSpineThickness
	

## Creates a handful of meshes to fill in for the spine
func renderSpineFromPoints(points : Array[Vector3]) -> void:
	var newMesh = MeshInstance3D.new()
	var actualMesh = SurfaceTool.new()
	

	
	
	var rings :Array[Array] = []
	var lastDir = Vector3(0,0,-1)
	for I in points.size():
		var pos = points[I]
		var nextPos = points.get(I + 1)
		if nextPos:
			var nextDir = pos.direction_to(nextPos)

			rings.append(generateRingOfPointsAroundPoint(pos,10,spineThicknessChart[I],nextDir.normalized()))
			lastDir = nextDir
		else:
			rings.append(generateRingOfPointsAroundPoint(pos,10,spineThicknessChart[I],lastDir.normalized()))
	
	actualMesh.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	# ending
	for I in range(rings[0].size() + 1):
		var ring = rings[0]
		actualMesh.set_normal(Vector3(1,0,0))
		actualMesh.add_vertex(ring[wrap(I,0,ring.size() - 1)])
		actualMesh.set_normal(Vector3(1,0,0))
		actualMesh.add_vertex(ring.get(wrap(I - 5,0,ring.size() - 1)))
	
	for I in range(rings.size() - 1):
		var ringA = rings[I]
		var ringB = rings[I + 1]
		
		for stitch in range(ringA.size() + 1):
			var pairIndex = stitch % ringA.size()
			
			actualMesh.set_normal(Vector3(1,0,0))
			actualMesh.add_vertex(ringA[pairIndex])
			
			actualMesh.set_normal(Vector3(1,0,0))
			actualMesh.add_vertex(ringB[pairIndex])
		
	
	newMesh.mesh = actualMesh.commit()
	add_child(newMesh)

func generateRingOfPointsAroundPoint(center : Vector3,pointCount : int, thickness : float, up : Vector3):
	var ringPoints : Array[Vector3] = []
	var dirOffset = 0.0
	for I in pointCount:
		dirOffset += TAU / pointCount
		var crossed = up.normalized().cross(Vector3(-1,0,0)).normalized() 
		#var newMesh = MeshInstance3D.new()
		#newMesh.mesh = BoxMesh.new()
		#add_child(newMesh)
		#newMesh.global_position = crossed.rotated(up,dirOffset) + center
		ringPoints.append(crossed.rotated(up.normalized() ,dirOffset) * thickness + center)
	
	return ringPoints


func spinePosTo3D(pos : Vector2):
	return Vector3(0,-pos.y,pos.x)

func createHead(pos : Vector3):
	var newMesh = MeshInstance3D.new()
	add_child(newMesh)
	newMesh.global_position = pos
	newMesh.mesh = SphereMesh.new()
	var newFace = Sprite3D.new()
	newFace.texture = load("res://art/cuteface.png")
	add_child(newFace)
	newFace.global_position = pos + Vector3(0,0,-0.5)
	



## A very, VERY basic function for determining where each limb will be placed along the spine.
func assignLimbs(spinePoints : Array[Vector3]) -> Dictionary[int,Array]:
	var limbsRemaining : Array[BodyPart] = parts.duplicate()
	
	var jointToLimb : Dictionary[int,Array] = {}
	
	# legs first
	var legEquivilent = getPartsWithHighestStat("SP",limbsRemaining)
	
	var humanoid = false
	
	if legEquivilent.size() > 2: #more than bipedal
		pass
	else:
		humanoid = true
		jointToLimb[0] = legEquivilent
		for I in legEquivilent: 
			I.set_meta("context","leg")
			limbsRemaining.erase(I)
	
	var armEquivilent = getPartsWithHighestStat("ATK",limbsRemaining)
	for I in getPartsWithHighestStat("SpA",limbsRemaining): if !armEquivilent.has(I): armEquivilent.append(I)
	
	var ArmPairs : Array[Array]= [ [] ]
	for I in armEquivilent:
		if ArmPairs[-1].size() != 2:
			ArmPairs[-1].append(I)
		else:
			ArmPairs.append([I])
	
	
	
	if !humanoid:
		pass
	elif humanoid:
		var offset = 0.1
		for I in ArmPairs:
			offset += 0.1
			var point = int(spinePoints.size() * 0.75 + offset)
			jointToLimb[point] = I
			for C in I: 
				C.set_meta("context","arm")
				limbsRemaining.erase(C)
	
	var armorEquivilent = getPartsWithHighestStat("DEF",limbsRemaining)
	for I in getPartsWithHighestStat("SpD",limbsRemaining): if !armorEquivilent.has(I): armorEquivilent.append(I)
	
	for I in armorEquivilent: I.set_meta("context","back")
	for I in getPartsWithHighestStat("HP",limbsRemaining): if !armorEquivilent.has(I): I.set_meta("context","front");armorEquivilent.append(I)
	
	
	while armorEquivilent.size() > 0:
		var chosen = armorEquivilent.pop_front()
		var posOptions = range(spinePoints.size() - 5)
		for I in jointToLimb.keys(): posOptions.erase(I)
		var pos = posOptions.pick_random()
		jointToLimb[pos] = [chosen]
		limbsRemaining.erase(chosen)
		

	
	return jointToLimb

func renderLimbs(spinePoints : Array[Vector3], assignment : Dictionary[int,Array]):
	for I in assignment:
		var actualPos = spinePoints[I]
		var placingParts = assignment[I]
		
		var index = 0
		for C in placingParts:
			index += 1
			
			var percentage = lerp(-1,1,index / placingParts.size())
			if placingParts.size() == 1:
				percentage = 0
			
			var newModel
			if C.get_meta("context","") in ["arm","leg"]:
				newModel = %PlaceholderLimbArmLeg.duplicate()
			elif C.get_meta("context","") in ["back","front"]:
				newModel = %PlaceholderLimbDefense.duplicate()
			add_child(newModel)
			newModel.global_position = actualPos + Vector3(percentage * spineThicknessChart[I],0,0)
			if C.get_meta("context","") == "arm":
				newModel.global_rotation_degrees = Vector3(percentage*-45,90,0)
			if C.get_meta("context","") == "front":
				newModel.global_position += Vector3(0,0,spineThicknessChart[I])
			if C.get_meta("context","") == "back":
				newModel.global_position -= Vector3(0,0,spineThicknessChart[I])
			
		print(actualPos,placingParts)
