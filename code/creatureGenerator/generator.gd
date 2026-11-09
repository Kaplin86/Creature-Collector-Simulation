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
	var direction : float = deg_to_rad(randf_range(-95,-85))
	var currentPosition = Vector2.ZERO
	points.append(currentPosition)
	
	for I in length:
		direction += noise.get_noise_2dv(currentPosition) * PI * 0.8
		currentPosition += Vector2.from_angle(direction) * spineDistPerSegment
		points.append(currentPosition)
	
	return points

## Creates a handful of meshes to fill in for the spine
func renderSpineFromPoints(spine : PackedVector2Array) -> void:
	for I in spine:
		var newMesh = MeshInstance3D.new()
		newMesh.mesh = SphereMesh.new()
		add_child(newMesh)
		newMesh.global_position = Vector3(0,-I.y,I.x)
