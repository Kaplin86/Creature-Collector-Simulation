extends Control

@export var simulationHistory : SimulationHistory

var historyArray : Array
var RelevantSpecies : Array[int] = []

func _ready():
	historyArray = simulationHistory.cachedHistory
	for I in historyArray: for C in I.keys(): if not C in RelevantSpecies: RelevantSpecies.append(C)
	
	await get_tree().process_frame
	
	renderLineOnControl(CountAsPercentage(RelevantSpecies),%FullCount)
	renderLineOnControl(AverageStatTotalAsPercentage(RelevantSpecies),%FullStatTotal, true)
	showColorCodes(%ColorCode)
	
	for I in RelevantSpecies:
		%MainBox.add_spacer(true)
		var newLabel = Label.new()
		newLabel.add_theme_font_size_override("font_size",25)
		%MainBox.add_child(newLabel)
		newLabel.text = "Species Data For Species '" + str(I) + "'"
		newLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var newHoriz = HBoxContainer.new()
		%MainBox.add_child(newHoriz)
		
		var STATS = ["COUNT","HP","ATK","DEF","SPA","SPD","SP"]
		for S in STATS:
			var NewCheckbox = CheckBox.new()
			newHoriz.add_child(NewCheckbox)
			NewCheckbox.text = S

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

func AverageStatTotalAsPercentage(species : Array[int]):
	var HighestStatTotal = 0
	var LowestStatTotal = 9999
	for I in historyArray: 
		for Specie in I.keys():
			if Specie in species:
				if I[Specie].get("averageBST",0) > HighestStatTotal:
					HighestStatTotal = I[Specie].get("averageBST",0)
				if I[Specie].get("averageBST",9999) < LowestStatTotal:
					LowestStatTotal = I[Specie].get("averageBST",0)
	
	var newArray : Array[Dictionary] = []
	for I in historyArray: 
		var report = {}
		for Specie in species:
			if I.get(Specie,{}).get("averageBST",-999) != -999:
				report[Specie] = inverse_lerp(LowestStatTotal,HighestStatTotal,I.get(Specie,{}).get("averageBST",-999))
		newArray.append(report)
	
	return newArray

func renderLineOnControl(data : Array[Dictionary],control : Control, ignore0 = false):
	var renderingSpecies = []
	for I in data: for C in I.keys(): if not C in renderingSpecies: renderingSpecies.append(C)
	
	for specie in renderingSpecies:
		var line2D = Line2D.new()
		var count = -1
		for I in data:
			count += 1
			if I.has(specie):
				var pos = Vector2(inverse_lerp(0.0,data.size() - 1,count),1 - I[specie])
				if !(I[specie] == 0.0 and ignore0):
					line2D.add_point(pos * Vector2(control.size))
		
		line2D.default_color = Color.from_hsv(inverse_lerp(0,RelevantSpecies.max(),specie),1,1,1)
		control.add_child(line2D)
