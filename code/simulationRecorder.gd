extends Node

var TimeSpanCreatureInfo

var SampleSpan = 60
var timer : Timer

var generationByGenerationInfo = []

func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = SampleSpan
	timer.timeout.connect(check)
	timer.start()

func check():
	var report = {}
	var count = get_tree().get_node_count_in_group("creature")
	report["count"] = count
	var averageStatTotals = BodyPart.new()
	var stats = ["HP","ATK","DEF","SpA","SpD","SP"]
	for I in stats: averageStatTotals.set(I,0)
	var averageBST = 0
	for I : Agent in get_tree().get_nodes_in_group("creature"):
		averageBST += I.calculateBST()
		print(I.calculateFinalStat("HP"))
		for E in stats:
			averageStatTotals.set(E,I.calculateFinalStat(E) + averageStatTotals.get(E))
	
	for I in stats: averageStatTotals.set(I,averageStatTotals.get(I) / count)
	averageBST /= count
	print(averageBST)
	report["averagePart"] = averageStatTotals
	report["averageBST"] = averageBST
	generationByGenerationInfo.append(report)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		var resource = SimulationHistory.new()
		resource.cachedHistory = generationByGenerationInfo
		resource.timePerSample = SampleSpan
		ResourceSaver.save(resource,"res://savedSimulationResults/thing.tres")
