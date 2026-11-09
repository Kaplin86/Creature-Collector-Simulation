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
	var actualMesh = ArrayMesh.new()
	
	var points : Array[Vector3] = []
	for I in spine: points.append(Vector3(0,-I.y,I.x))
	
	var vertices = PackedVector3Array()
	
	
	var startTopLeft = points[0] + Vector3(-1,0,-1)* spineThickness
	var startTopRight = points[0] + Vector3(1,0,-1)* spineThickness
	var startBottomRight = points[0] + Vector3(1,0,1)* spineThickness
	var startBottomLeft = points[0] + Vector3(-1,0,1)* spineThickness
	vertices.push_back(startTopRight)
	vertices.push_back(startTopLeft)
	vertices.push_back(startBottomRight)
	
	vertices.push_back(startBottomRight)
	vertices.push_back(startTopLeft)
	vertices.push_back(startBottomLeft)
	
	for C in range(points.size() - 1):
		var I = points[C]
		var nextI = points[C + 1]
		if !nextI:
			break
		
		# variable names viewed from above
		var topLeft = I + Vector3(-1,0,-1) * spineThickness
		var topRight = I + Vector3(1,0,-1) * spineThickness
		var bottomRight = I + Vector3(1,0,1) * spineThickness
		var bottomLeft = I + Vector3(-1,0,1) * spineThickness
		
		var NtopLeft = nextI + Vector3(-1,0,-1) * spineThickness
		var NtopRight = nextI + Vector3(1,0,-1) * spineThickness
		var NbottomRight = nextI + Vector3(1,0,1) * spineThickness
		var NbottomLeft = nextI + Vector3(-1,0,1) * spineThickness
		
		# Front Faces
		vertices.push_back(NtopLeft)
		vertices.push_back(topLeft)
		vertices.push_back(topRight)
		
		vertices.push_back(NtopRight)
		vertices.push_back(NtopLeft)
		vertices.push_back(topRight)
		
		# Back Faces
		vertices.push_back(NbottomLeft)
		vertices.push_back(bottomRight)
		vertices.push_back(bottomLeft)
		
		vertices.push_back(bottomRight)
		vertices.push_back(NbottomLeft)
		vertices.push_back(NbottomRight)
		
		# Left Faces
		vertices.push_back(NbottomLeft)
		vertices.push_back(bottomLeft)
		vertices.push_back(topLeft)
		
		vertices.push_back(NtopLeft)
		vertices.push_back(NbottomLeft)
		vertices.push_back(topLeft)
		
		# Right Faces
		vertices.push_back(bottomRight)
		vertices.push_back(NbottomRight)
		vertices.push_back(topRight)
		
		vertices.push_back(NbottomRight)
		vertices.push_back(NtopRight)
		vertices.push_back(topRight)
	
	var endTopLeft = points[-1] + Vector3(-1,0,-1) * spineThickness
	var endTopRight = points[-1] + Vector3(1,0,-1) * spineThickness
	var endBottomRight = points[-1] + Vector3(1,0,1) * spineThickness
	var endBottomLeft = points[-1] + Vector3(-1,0,1) * spineThickness
	vertices.push_back(endTopLeft)
	vertices.push_back(endTopRight)
	vertices.push_back(endBottomRight)
	
	vertices.push_back(endTopLeft)
	vertices.push_back(endBottomRight)
	vertices.push_back(endBottomLeft)
	
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	actualMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	newMesh.mesh = actualMesh
	add_child(newMesh)
