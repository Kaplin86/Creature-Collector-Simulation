extends Control

@export var simulationHistory : SimulationHistory

var historyArray : Array
var RelevantSpecies : Array[int] = []

func _ready():
	historyArray = simulationHistory.cachedHistory
	for I in historyArray: for C in I.keys(): if not C in RelevantSpecies: RelevantSpecies.append(C)
	
	await get_tree().process_frame
	
	renderLineOnControl(CountAsPercentage(RelevantSpecies),%FullCount)
	showColorCodes(%ColorCode)

func showColorCodes(displayNode : Control):
	for I in RelevantSpecies:
		var newLabel = Label.new()
		displayNode.add_child(newLabel)
		var newColor = ColorRect.new()
		displayNode.add_child(newColor)
		newLabel.text = str(I) + ": "
		newColor.color = Color.from_hsv(inverse_lerp(0,RelevantSpecies.max(),I),1,1,1)
		newColor.custom_minimum_size = Vector2(23,23)

func CountAsPercentage(species : Array[int]):
	var HighestCount = 0
	for I in historyArray: 
		for Specie in I.keys():
			if Specie in species:
				if I[Specie].get("count",0) > HighestCount:
					HighestCount = I[Specie].get("count",0)
	
	var newArray : Array[Dictionary] = []
	for I in historyArray: 
		var report = {}
		for Specie in species:
			report[Specie] = inverse_lerp(0,HighestCount,I.get(Specie,{}).get("count",0))
		newArray.append(report)
	
	return newArray

func renderLineOnControl(data : Array[Dictionary],control : Control):
	var renderingSpecies = []
	for I in data: for C in I.keys(): if not C in renderingSpecies: renderingSpecies.append(C)
	
	for specie in renderingSpecies:
		var line2D = Line2D.new()
		var count = -1
		for I in data:
			count += 1
			var pos = Vector2(inverse_lerp(0.0,data.size() - 1,count),1 - I[specie])
			line2D.add_point(pos * Vector2(control.size))
		
		line2D.default_color = Color.from_hsv(inverse_lerp(0,RelevantSpecies.max(),specie),1,1,1)
		control.add_child(line2D)
