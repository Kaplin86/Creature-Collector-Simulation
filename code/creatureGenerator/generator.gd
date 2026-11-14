@tool
extends Node3D
class_name CreatureGeneratorNode

## BODY TYPE PLANNING -----------------------------------
## This is a small tree to show how exactly i will code the body renderer,
## starting with figuring out the "body type". You know what they say, Good plan = good code.
##
## Step 1: Fallback
##
##                                    / Steel Or Poison -> FallBack 3
##                          --> Typing                      "Gathering Shape"
##                      / No          \ 
##     Fallback        /                Water -> Fallback 4
##    "RoundShape" --> Has Tail?                "Fish Shape"
##                     \                  /
##                      \ Yes         / Water type?
##                         FallBack2   
##                         "SerpentineShape"
##
## Shapes remaining "Legs shape","Insect shape","four legged shape","upright torso shape", "two leg and tail shape", "human shape", "two wing shape", "arms shape"

## Step 2: Legs
##                         / --> Four --> "Four legged shape"
##                        /
##                       / --> Two --> "Legs Shape"
##  PreviousShape       /
##  Step 1 shape    --> Leg Count
##                     \
##                      \ --> Six / Eight --> "Insectoid shape"
##
## Shapes remaining ,"upright torso shape", "two leg and tail shape", "human shape", "two wing shape", "arm shape"

## Step 3: Arms
##
## Any Step 1 Shape -> more than 1 arm -> Stat Spread -> Physical stats "Arms shape"
##                                             \ Special stats "Upright torso shape" 
##
## Legs shape -> has two arms -> "human shape"
## 
## Shapes remaining , "two leg and tail shape", "two wing shape"
##

## Step 4: Tails and wings
##
## "Human shape" -> Has tail -> "two leg and tail shape"
##
## Step 1 shape and legs shape -> Has two wings -> "two wing shape"

## A body type, each having unique generation.
enum BodyTypes { 
	Round, ## A creature thats exclusively a head. Pokemon examples: Voltorb, Nacli, Solosis
	Serpentine, ## A creature that is a head, base / torso, and a leg. Pokemon Examples: Dratini, Ekans, Dreepy (I think dreepy is an important example due to how defined the head is)
	Fish, ## Need I explain this one? This can be interpreted as an offbranch of Round and Serpentine. Pokemon Examples: Magikarp, Tatsugiri, Luvdisc
	Gathering, ## This is the hardest body type to clearly define, as its multiple Round creatures bunched up. Pokemon Examples: Dugtrio, Tandemaus, Klink
	UprightTorso, ## Creatures that have a torso and a head. Pokemon Examples: Vanillite, Diglett, Morelull
	FourLegged, ## Four legged animal, typically has a neck and tail. Pokemon Examples: Eevee, Dialga, Boltund
	Insectoid, ## Wingless bug with a lot of legs. Pokemon Examples: Paras, Sewaddle, Blipbug, Galvantula
	Legs, ## Take Round or Serpentine and slap on legs. Pokemon Example: Seedot, Oddish, Toedscool
	Arms, ## Take Round or Serpentine and slap on arms. Pokemon Example: Geodude, Yamask, Reuniclus
	Human, ## A creature with two legs, two arms, a torso and a head. Pokemon Example: Mr. Mime, Lurantis, Regirock
	TailedHuman, ## Human with a tail. Pokemon Example: Charmander, Lucario, Archaludon technically
	WingedShape, ## Creatures without arms but have wings. Pokemon Example: Pidgey, Natu, Altaria
	}

## The different types a limb can be
enum BodyPartTypes {
	Torso, ## Typically only one. Favors HP and Defensive Stats.
	Arm, ## Favors Attack and Special Attack.
	Leg, ## Favors Speed
	Tail, ## Well Rounded Part
	Wings, ## Favors Speed and Attack Stats
	Other, ## Leftover pieces.
}


var Stats = ["HP","ATK","DEF","SpA","SpD","SP"]

@export_tool_button("Run Action") var run_action_btn = generate
@export var seedVal := 1
@export var  parts : Array[BodyPart] = []
@export var typings : Array[GlobalVars.Typings] = []
@export_group("Config")
@export var specializationThreshold = 0.5
@export var statTotalPerSpineSegment := 50
@export var spineDistPerSegment := 0.25
@export var spineMaxThickness := 0.2
@export var spineMinThickness := 0.1
@export_range(0.00000001,0.005,0.00000001) var spineMinMaxOffsetPerStat = 0.005
@export_subgroup("Serpentine")
@export var S_Curve : Curve = preload("res://code/creatureGenerator/curves/serpentineCurve.tres")
@export_subgroup("Fish")
@export var F_Curve : Curve

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

func getTotalStatOnPart(part : BodyPart) -> int:
	var sum = 0
	for C in Stats:
		sum += part.get(C)
	return sum

func getHighestStatValueOnPart(part : BodyPart) -> int:
	var val = 0
	for C in Stats:
		if part.get(C) > val:
			val = part.get(C)
	return val

func getPartsWithHighestStat(stat, startingArray = null) -> Array[BodyPart]: 
	var partsReturned : Array[BodyPart]= []
	var using = parts
	if startingArray != null: 
		using = startingArray
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

	for I in get_children(): I.queue_free()
	
	var definePartsAsLimbs := defineLimbs()
	var bodyTypeUsing := defineBodyType(definePartsAsLimbs)
	print("starting up ", seedVal )
	print( BodyTypes.keys()[bodyTypeUsing] )
	for I in definePartsAsLimbs.values():
		print(BodyPartTypes.keys()[I])
	#print(BodyPartTypes.keys()[definePartsAsLimbs.values()[0]])
	
	if bodyTypeUsing == BodyTypes.Round:
		generateRoundBody(definePartsAsLimbs)
	elif bodyTypeUsing == BodyTypes.Serpentine:
		generateSerpentineBody(definePartsAsLimbs)
	elif bodyTypeUsing == BodyTypes.Fish:
		generateFishBody(definePartsAsLimbs)
	elif bodyTypeUsing == BodyTypes.Gathering:
		generateGatheringBody(definePartsAsLimbs)

func generateGatheringBody(limbDefinitions : Dictionary[BodyPart,BodyPartTypes]):
	var properSpinePoints : Array[Vector3] = []
	var headCount = getAllStatTotal()/125
	var startingHead = Vector3(0,0,0)
	properSpinePoints.append(startingHead)
	var angle
	
	var doneDUO = false
	var dist = 1.0
	for I in range(headCount):
		if doneDUO == true:
			angle = (Vector3.ZERO - angle).normalized()
		else:
			angle = Vector3(
			randf_range(0.0, TAU),
			randf_range(0.0, TAU),
			randf_range(0.0, TAU)
			).normalized()
			
			var fine = true
			for C in properSpinePoints:
				if C.distance_squared_to(dist * angle) < 2:
					fine = false
					break
			var count = 0
			while !fine and count < 200:
				count += 1
				print(count)
				fine = true
				angle = Vector3(randf_range(0.0, TAU),randf_range(0.0, TAU),randf_range(0.0, TAU)).normalized()
				for C in properSpinePoints:
					if C.distance_squared_to(dist * angle) < 0.65:
						fine = false
						break
			
		properSpinePoints.append(dist * angle)
		doneDUO = !doneDUO
	
	for I in properSpinePoints:
		createHead(I)
	
	var partsList = limbDefinitions.keys()
	partsList.erase(limbDefinitions.find_key(BodyPartTypes.Torso))
	
	var limbAssignment := randomlyAssignLimbs(properSpinePoints,partsList)
	print(limbAssignment)
	renderLimbsWithRandomRotation(properSpinePoints,limbAssignment,limbDefinitions)

func generateFishBody(limbDefinitions : Dictionary[BodyPart,BodyPartTypes]):
	var spinePoints := createSpinePoints(getAllStatTotal() / statTotalPerSpineSegment * 1,180,0)
	var properSpinePoints := sanitizeSpinePoints(spinePoints)
	var partsList = limbDefinitions.keys()
	partsList.erase(limbDefinitions.find_key(BodyPartTypes.Torso))
	partsList.erase(limbDefinitions.find_key(BodyPartTypes.Tail))
	var limbAssignment := randomlyAssignLimbs(properSpinePoints,partsList)
	addSpineThickness(properSpinePoints,limbAssignment,2,0.0,F_Curve)
	renderSpineFromPoints(properSpinePoints)
	
	createHead(properSpinePoints[-1])
	renderLimbsWithRandomRotation(properSpinePoints,limbAssignment,limbDefinitions)

func generateSerpentineBody(limbDefinitions : Dictionary[BodyPart,BodyPartTypes]):
	var spinePoints := createSpinePoints(getAllStatTotal() / statTotalPerSpineSegment * 1.5,180,0,S_Curve)
	var properSpinePoints := sanitizeSpinePoints(spinePoints)
	var partsList = limbDefinitions.keys()
	partsList.erase(limbDefinitions.find_key(BodyPartTypes.Torso))
	partsList.erase(limbDefinitions.find_key(BodyPartTypes.Tail))
	var limbAssignment := randomlyAssignLimbs(properSpinePoints,partsList)
	addSpineThickness(properSpinePoints,limbAssignment,0.6,0.7)
	renderSpineFromPoints(properSpinePoints)
	
	createHead(properSpinePoints[-1])
	renderLimbsWithRandomRotation(properSpinePoints,limbAssignment,limbDefinitions)

## The generation function for [enum BodyTypes.Round]
func generateRoundBody(limbDefinitions : Dictionary[BodyPart,BodyPartTypes] ):
	
	var spinePoints := createSpinePoints(1,-90,0)
	var properSpinePoints := sanitizeSpinePoints(spinePoints)
	var limbAssignment := randomlyAssignLimbs(properSpinePoints)
	
	addSpineThickness(properSpinePoints,limbAssignment,0.5)
	renderSpineFromPoints(properSpinePoints)
	
	createHead(properSpinePoints[-1])
	renderLimbsWithRandomRotation(properSpinePoints,limbAssignment,limbDefinitions)

func oldGenerationCodeDeprecatedDontUseDeleteLater():
	var spinePoints := createSpinePoints(1,1,1)
	var properSpinePoints := sanitizeSpinePoints(spinePoints)
	var limbAssignment := assignLimbs(properSpinePoints)
	
	addSpineThickness(properSpinePoints,limbAssignment)
	renderSpineFromPoints(properSpinePoints)

	var headPos = (properSpinePoints[-1])
	var firstPos = (properSpinePoints[0])
	createHead(headPos)
	#renderLimbs(properSpinePoints,limbAssignment)


func defineLimbs() -> Dictionary[BodyPart,BodyPartTypes]:
	var limbDefs : Dictionary[BodyPart,BodyPartTypes] = {}
	
	var remainingLimbs = parts.duplicate(true)
	var torsoScore = 30
	var torso = null
	for I in remainingLimbs:
		var score = I.get("HP") * 1.5 + I.get("DEF") + I.get("SpD")
		if score > torsoScore:
			torsoScore = score
			torso = I
	
	remainingLimbs.erase(torso)
	if torso: limbDefs[torso] = BodyPartTypes.Torso
	
	var legs = []
	for I in getPartsWithHighestStat("SP",remainingLimbs):
		var proportion = float(I.get("SP")) / float(getTotalStatOnPart(I) )
		if proportion > specializationThreshold:
			legs.append(I) # Only speed specialized part are legs
	
	for I in legs:
		remainingLimbs.erase(I)
		limbDefs[I] = BodyPartTypes.Leg
	
	var armCandidates = getPartsWithHighestStat("ATK",remainingLimbs)
	armCandidates.append_array(getPartsWithHighestStat("SpA"))
	var arms = []
	for I in armCandidates:
		var proportion = float(I.get("ATK") + I.get("SpA")) / float(getTotalStatOnPart(I) )
		if proportion > specializationThreshold:
			arms.append(I) # Only offense specialized parts get to be arms
	
	
	for I in arms:
		remainingLimbs.erase(I)
		limbDefs[I] = BodyPartTypes.Arm
	
	
	var tail
	var lowestPercent = INF
	for I in remainingLimbs:
		var avg = getTotalStatOnPart(I) / 6.0
		var percent = 1 - (avg / float(getHighestStatValueOnPart(I)))
		if percent < lowestPercent:
			lowestPercent = percent
			tail = I
	
	if lowestPercent < 0.2:
		limbDefs[tail] = BodyPartTypes.Tail
		remainingLimbs.erase(tail)
	
	var wingCandidates = getPartsWithHighestStat("ATK",remainingLimbs)
	wingCandidates.append_array(getPartsWithHighestStat("SpA",remainingLimbs))
	wingCandidates.append_array(getPartsWithHighestStat("SP",remainingLimbs))
	var wings = []
	for I in wingCandidates:
		var proportion = float(I.get("ATK") + I.get("SpA") + I.get("SP")) / float(getTotalStatOnPart(I) )
		if proportion > specializationThreshold:
			wings.append(I) # Only offense and speed specialized parts get to be wings
	
	for I in wings:
		remainingLimbs.erase(I)
		limbDefs[I] = BodyPartTypes.Wings
	
	for I in remainingLimbs:
		limbDefs[I] = BodyPartTypes.Other
	
	return limbDefs

func defineBodyType(limbDef : Dictionary[BodyPart,BodyPartTypes]) -> BodyTypes:
	var body = BodyTypes.Round
	var bodyTypeArray : Array[BodyPartTypes] = limbDef.values()
	
	# Step 1
	if bodyTypeArray.has(BodyPartTypes.Torso):
		if bodyTypeArray.has(BodyPartTypes.Tail):
			body = BodyTypes.Serpentine
		else:
			body = BodyTypes.UprightTorso
	
	if typings.has(GlobalVars.Typings.Robot):
		var val = randi_range(0,2)
		if val == 1:
			body = BodyTypes.Gathering
	
	if typings.has(GlobalVars.Typings.Water):
		var val = randi_range(0,2)
		if val == 1:
			body = BodyTypes.Fish
	
	# Step 2
	var legCount = bodyTypeArray.count(BodyPartTypes.Leg)
	if legCount == 2:
		body = BodyTypes.Legs
	elif legCount == 4:
		body = BodyTypes.FourLegged
	elif legCount in [6,8]:
		body = BodyTypes.Insectoid
	
	# Step 3
	var armCount = bodyTypeArray.count(BodyPartTypes.Arm)
	
	if legCount == 2 and armCount == 2:
		body = BodyTypes.Human
	elif armCount == 2 and body in [BodyTypes.Round,BodyTypes.Serpentine]:
		body = BodyTypes.Arms
	
	# Step 4
	
	if bodyTypeArray.has(BodyPartTypes.Tail) and body == BodyTypes.Human:
		body = BodyTypes.TailedHuman
	
	if bodyTypeArray.count(BodyPartTypes.Wings) >= 2 and armCount < 1:
		body = BodyTypes.WingedShape
	
	return body

## This returns the spine layout for the creature. Imagine this as a 2D image from the side, with each point referring to a seperate spine point
func createSpinePoints(length, startingDir, curveMult, forceCurve : Curve = null) -> PackedVector2Array:
	
	var points : PackedVector2Array = []
	
	var noise = FastNoiseLite.new()
	noise.seed = seedVal
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.56
	
	@warning_ignore("integer_division")
	var direction : float = deg_to_rad(startingDir)
	var currentPosition = Vector2.ZERO
	points.append(currentPosition)
	
	
	for I in length:
		direction += (noise.get_noise_2dv(currentPosition) * PI * 0.8) * curveMult
		if forceCurve:
			direction += forceCurve.sample(I/length)
		currentPosition += Vector2.from_angle(direction) * spineDistPerSegment
		points.append(currentPosition)
	
	return points

## Converts spine points into physical vector 3s
func sanitizeSpinePoints(spine : PackedVector2Array) -> Array[Vector3]:
	var points : Array[Vector3] = []
	var subCount = 1
	for I in spine:
		var next = spine.get(spine.find(I) + 1)
		var currentPos = spinePosTo3D(I) + (Vector3(sin(I.x),cos(I.x),cos(I.y)) * 0.1)
		points.append(currentPos) 
		if next:
			next = spinePosTo3D(next) + (Vector3(sin(next.x),cos(next.x),cos(next.y)) * 0.1)
			for C in range(subCount):
				points.append(lerp(currentPos,next,(C + 1) / float(subCount + 1)))
	
	
	
	return points

## Adds thickness values for each point
func addSpineThickness(points,body, mult = 1.0,smoothness = 1.0, offsetCurve : Curve = null):
	spineThicknessChart = {}
	var offset = getAllStatTotal() * spineMinMaxOffsetPerStat * mult
	for I in range(points.size()):
		var usingOffset = offset
		if offsetCurve:
			usingOffset = offset * offsetCurve.sample(I/float(points.size()))
		spineThicknessChart[I] = (smoothness * randf_range(spineMinThickness ,spineMaxThickness)) + (usingOffset) + body.get(I,[]).size()*0.2
	spineThicknessChart[points.size() - 2] = offset * 0.2
	spineThicknessChart[points.size() - 1] = offset * 0.2
	
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
	var lastDir = Vector3(0,-1,-1)
	for I in points.size():
		var pos = points[I]
		var nextPos = points.get(I + 1)
		if nextPos:
			var nextDir = pos.direction_to(nextPos)

			rings.append(generateRingOfPointsAroundPoint(pos,15,spineThicknessChart[I],nextDir.normalized()))
			lastDir = nextDir
		else:
			rings.append(generateRingOfPointsAroundPoint(pos,15,spineThicknessChart[I],lastDir.normalized()))
	
	actualMesh.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	# ending
	for I in range(rings[0].size() + 1):
		var ring = rings[0]
		actualMesh.set_normal(Vector3(1,0,0))
		actualMesh.add_vertex(ring[wrap(I,0,ring.size() - 1)])
		actualMesh.add_vertex(ring[wrap(I + 1,0,ring.size() - 1)])
		actualMesh.add_vertex(points[0])
	
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

## Makes rings
func generateRingOfPointsAroundPoint(center : Vector3,pointCount : int, thickness : float, up : Vector3):
	var ringPoints : Array[Vector3] = []
	var dirOffset = 0.0
	var normal = up.normalized()
	var reference = Vector3(-1,0,0)
	if abs(normal.dot(reference)) > 0.99:
		reference = Vector3.FORWARD

	
	for I in pointCount:
		dirOffset += TAU / pointCount
		var crossed = normal.cross(reference).normalized() 
		
		#var newMesh = MeshInstance3D.new()
		#newMesh.mesh = BoxMesh.new()
		
		#add_child(newMesh)
		#newMesh.position = crossed.rotated(up.normalized() ,dirOffset) * thickness + center
		#newMesh.scale = Vector3(0.1,0.1,0.1)
		
		ringPoints.append(crossed.rotated(up.normalized() ,dirOffset) * thickness + center)
	
	return ringPoints

## Converts vector 2 to vector 3
func spinePosTo3D(pos : Vector2):
	return Vector3(0,-pos.y,pos.x)

## Creates a head at position
func createHead(pos : Vector3):
	var newMesh = MeshInstance3D.new()
	add_child(newMesh)
	newMesh.position = pos
	newMesh.mesh = SphereMesh.new()
	var newFace = Sprite3D.new()
	newFace.texture = load("res://art/cuteface.png")
	add_child(newFace)
	newFace.position = pos + Vector3(0,0,-0.5)
	

func randomlyAssignLimbs(spinePoints : Array[Vector3], partsList : Array[BodyPart] = [null]) -> Dictionary[int,Array]:
	var limbsRemaining : Array[BodyPart] = parts.duplicate()
	if partsList != [null]:
		limbsRemaining = partsList.duplicate(true)
	var jointToLimb : Dictionary[int,Array] = {}
	while limbsRemaining:
		var new = limbsRemaining.pop_front()
		var thinking = randf_range(0,spinePoints.size() - 1)
		jointToLimb.get_or_add(thinking,[]).append(new)
	return jointToLimb

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

func renderLimbsWithRandomRotation(spinePoints : Array[Vector3], assignment : Dictionary[int,Array], def : Dictionary[BodyPart,BodyPartTypes]):
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
			if def[C] in [BodyPartTypes.Arm,BodyPartTypes.Leg]:
				newModel = %PlaceholderLimbArmLeg.duplicate()
			elif def[C] in [BodyPartTypes.Other]:
				newModel = %PlaceholderLimbDefense.duplicate()
			add_child(newModel)
			newModel.position = actualPos + Vector3(percentage * spineThicknessChart.get(I,0.35),0,0)
			newModel.global_rotation_degrees = Vector3(randf_range(0,180),90,0)
			
		print(actualPos,placingParts)


## Place limbs at assigned spots.
func renderLimbs(spinePoints : Array[Vector3], assignment : Dictionary[int,Array], def : Dictionary[BodyPart,BodyPartTypes]):
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
			if def[C] in [BodyPartTypes.Arm,BodyPartTypes.Leg]:
				newModel = %PlaceholderLimbArmLeg.duplicate()
			elif def[C] in [BodyPartTypes.Other]:
				newModel = %PlaceholderLimbDefense.duplicate()
			add_child(newModel)
			newModel.position = actualPos + Vector3(percentage * spineThicknessChart[I],0,0)
			if def[C]  in [BodyPartTypes.Arm,BodyPartTypes.Wings]:
				newModel.global_rotation_degrees = Vector3(percentage*-45,90,0)
			if def[C] == BodyPartTypes.Leg:
				newModel.position += Vector3(0,0,spineThicknessChart[I])
			if def[C] == BodyPartTypes.Other:
				newModel.position -= Vector3(0,0,spineThicknessChart[I])
			
		print(actualPos,placingParts)

func _ready():
	generate()
