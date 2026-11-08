extends Node


var SampleSpan = 240
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
		var averageLevel = 0
		for I : Agent in get_tree().get_nodes_in_group("creature"):
			if I.species == C:
				count += 1
				if count == 1:
					if I.species in range(I._speciesHandler.Species.size()):
						report["specieData"] = I._speciesHandler.Species[I.species].duplicate(true)
				averageBST += I.calculateBST()
				averageLevel += I.level
				for E in stats:
					averageStatTotals.set(E,I.calculateBaseStat(E) + averageStatTotals.get(E))
		
		for I in stats: averageStatTotals.set(I,averageStatTotals.get(I) / count)
		averageBST /= count
		averageLevel /= count
		report["averagePart"] = averageStatTotals
		report["averageBST"] = averageBST
		report["count"] = count
		report["averageLevel"] = averageLevel
		
		
		totalReport[C] = report
	
	if specieType != []:
		generationByGenerationInfo.append(totalReport)

func saveToFile(file : String):
	var resource = SimulationHistory.new()
	resource.cachedHistory = generationByGenerationInfo
	resource.timePerSample = SampleSpan
	return ResourceSaver.save(resource,file)
