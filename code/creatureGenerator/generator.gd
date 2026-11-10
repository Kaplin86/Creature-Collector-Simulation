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
@export var spineThickness := 0.2


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


func getPartsWithHighestStat(stat) -> Array[BodyPart]: 
	var partsReturned : Array[BodyPart]= []
	for I in parts:
		var valid := true
		for S in Stats:
			if I.get(S) > I.get(stat):
				valid = false
				break
		if valid: partsReturned.append(I)
	return partsReturned

func generate():
	seed(seedVal)
	for I in get_children(): I.queue_free()
	var spinePoints = createSpinePoints()
	renderSpineFromPoints(spinePoints)
	#print(generateRingOfPointsAroundPoint(Vector3.ZERO,10,3,Vector3(0,-1,-1).normalized()))

## This returns the spine layout for the creature. Imagine this as a 2D image from the side, with each point referring to a seperate spine point
func createSpinePoints() -> PackedVector2Array:
	
	var points : PackedVector2Array = []
	
	var noise = FastNoiseLite.new()
	noise.seed = seedVal
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.56
	
	@warning_ignore("integer_division")
	var length = randi_range(2,int(getAllStatTotal() / statTotalPerSpineSegment))
	var direction : float = deg_to_rad(randf_range(-185,-175))
	if getPartsWithHighestStat("SP").size() <= 2:
		print(getPartsWithHighestStat("SP"))
		direction =  deg_to_rad(randf_range(-95,-85))
	var currentPosition = Vector2.ZERO
	points.append(currentPosition)
	
	for I in length:
		direction += noise.get_noise_2dv(currentPosition) * PI * 0.8
		currentPosition += Vector2.from_angle(direction) * spineDistPerSegment
		points.append(currentPosition)
	
	return points

## Creates a handful of meshes to fill in for the spine
func renderSpineFromPoints(spine : PackedVector2Array) -> void:
	var newMesh = MeshInstance3D.new()
	var actualMesh = SurfaceTool.new()
	
	var subCount = 3
	
	var points : Array[Vector3] = []
	for I in spine:
		var next = spine.get(spine.find(I) + 1)
		var currentPos = Vector3(0,-I.y,I.x) + (Vector3(sin(I.x),cos(I.x),cos(I.y)) * 0.1)
		points.append(currentPos)
		if next:
			next = Vector3(0,-next.y,next.x)
			for C in range(subCount):
				points.append(lerp(currentPos,next,(C + 1) / float(subCount + 1)))

	
	
	var rings :Array[Array] = []
	var lastDir = Vector3(0,0,-1)
	for I in points.size():
		var pos = points[I]
		var nextPos = points.get(I + 1)
		if nextPos:
			var nextDir = pos.direction_to(nextPos)

			rings.append(generateRingOfPointsAroundPoint(pos,10,spineThickness,nextDir.normalized()))
			lastDir = nextDir
		else:
			rings.append(generateRingOfPointsAroundPoint(pos,10,spineThickness,lastDir.normalized()))
	
	actualMesh.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
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
