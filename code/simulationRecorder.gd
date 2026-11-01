extends Node

var TimeSpanCreatureInfo

var SampleSpan = 120
var timer : Timer

var generationByGenerationInfo = []

func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = SampleSpan
	timer.timeout.connect(check)
	timer.start()

func check():
	var totalReport = {}
	var specieType = []
	for I : Agent in get_tree().get_nodes_in_group("creature"):
		if not I.species in specieType:
			specieType.append(I.species)
	
	for C in specieType:
		var report = {}
		var count = 0
		
		var averageStatTotals = BodyPart.new()
		var stats = ["HP","ATK","DEF","SpA","SpD","SP"]
		for I in stats: averageStatTotals.set(I,0)
		var averageBST = 0
		for I : Agent in get_tree().get_nodes_in_group("creature"):
			if I.species == C:
				count += 1
				if count == 1 or count == 2:
					var packed_scene = PackedScene.new()
					packed_scene.pack(I)
					report["example" + str(count)] = packed_scene
				averageBST += I.calculateBST()
				for E in stats:
					averageStatTotals.set(E,I.calculateFinalStat(E) + averageStatTotals.get(E))
		
		for I in stats: averageStatTotals.set(I,averageStatTotals.get(I) / count)
		averageBST /= count
		report["averagePart"] = averageStatTotals
		report["averageBST"] = averageBST
		report["count"] = count
		
		totalReport[C] = report
	
	generationByGenerationInfo.append(totalReport)
	

func _process(delta):
	if Input.is_action_just_pressed("saveSim"):
		var resource = SimulationHistory.new()
		resource.cachedHistory = generationByGenerationInfo
		resource.timePerSample = SampleSpan
		ResourceSaver.save(resource,"res://savedSimulationResults/"+Time.get_datetime_string_from_system().replace(":","-")+".tres")
		print("Saved!")
