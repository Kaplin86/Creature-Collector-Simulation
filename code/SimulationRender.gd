extends Control

@export var simulationHistory : SimulationHistory

var historyArray : Array
var RelevantSpecies : Array[int] = []
var RelevantSpeciesToData : Dictionary[int,SpeciesDatastore] = {}

var speciesToCheckboxNode : Dictionary[int,HBoxContainer] = {}
var speciesToGraphNode : Dictionary[int,Control] = {}

var StatTocolor = {"ATK":Color.GOLD,"DEF":Color.ORANGE,"HP":Color.GREEN,"SpA":Color.TURQUOISE,"SpD":Color.DARK_BLUE,"SP":Color.PURPLE}


var CountRemovingThreshHold = 5 #if a species' count never goes higher than this number, the species is considered 'irrelevant'

func _ready():
	historyArray = simulationHistory.cachedHistory
	RelevantSpeciesToData = {}
	RelevantSpecies = []
	
	var seenLastNode = false
	for I in %MainBox.get_children():
		if seenLastNode: I.queue_free()
		if I == %LastNode:
			seenLastNode = true
	
	for I in historyArray:
		for C in I.keys(): 
			if not C in RelevantSpecies:
				RelevantSpecies.append(C)
				RelevantSpeciesToData[C] = I[C].get("specieData",null)
	
	await get_tree().process_frame
	
	pruneSpecies()
	
	for I in %FullCount.get_children(): I.queue_free()
	for I in %FullStatTotal.get_children(): I.queue_free()
	renderLineOnControl(CountAsPercentage(RelevantSpecies),%FullCount)
	renderLineOnControl(AverageStatTotalAsPercentage(RelevantSpecies),%FullStatTotal, true)
	showColorCodes(%ColorCode)
	
	makeStatCheckbox(%GlobalStatHbox,updateGlobalSpecie,["HP","ATK","DEF","SpA","SpD","SP"], 0)
	
	
	for I in RelevantSpecies:
		var newLabel = Label.new()
		newLabel.add_theme_font_size_override("font_size",25)
		%MainBox.add_child(newLabel)
		newLabel.text = "Species Data For Species '" + str(I) + "'"
		newLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		if RelevantSpeciesToData[I] != null:
			var speciesData = Label.new()
			var data : SpeciesDatastore = RelevantSpeciesToData[I]
			
			var typingText = GlobalVars.Typings.find_key(data.typings[0]) 
			
			if data.typings.size() != 1:
				typingText += ", " +  GlobalVars.Typings.find_key(data.typings[1]) 
			
			speciesData.text = "Typings - " + str(typingText) + ". Diet Type - " + str(Agent.Diets.find_key(data.diet)) + "."
			speciesData.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			%MainBox.add_child(speciesData)
		
		var newHoriz = HBoxContainer.new()
		newHoriz.alignment = BoxContainer.ALIGNMENT_CENTER
		%MainBox.add_child(newHoriz)
		
		makeStatCheckbox(newHoriz,UpdateSingleSpecie.bind(I),["COUNT","HP","ATK","DEF","SpA","SpD","SP"], I)
		
			
			
		speciesToCheckboxNode[I] = newHoriz
		var newGraphNode = Panel.new()
		var newMargin = MarginContainer.new()
		%MainBox.add_child(newMargin)
		newMargin.add_child(newGraphNode)
		speciesToGraphNode[I] = newGraphNode
		newMargin.custom_minimum_size = Vector2(0,250)
	await get_tree().process_frame
	for I in RelevantSpecies: UpdateSingleSpecie(I)

func makeStatCheckbox(target : Control,function : Callable,stats : Array, SpeciesNumber : int):
	for I in target.get_children(): I.queue_free()
	var STATS = stats
	for S in STATS:
		var NewCheckbox = CheckBox.new()
		target.add_child(NewCheckbox)
		NewCheckbox.text = S
		NewCheckbox.pressed.connect(function)
		if S == "COUNT":
			NewCheckbox.button_pressed = true
		
		
		
		var newColor = ColorRect.new()
		target.add_child(newColor)
		if S == "COUNT":
			newColor.color = Color.from_hsv(inverse_lerp(0,RelevantSpecies.max(),SpeciesNumber),1,1,1)
		newColor.custom_minimum_size = Vector2(31,31)
		
		if S != "COUNT":
			newColor.color = StatTocolor[S]
	

func UpdateSingleSpecie(specie):
	
	for I in speciesToGraphNode[specie].get_children(): I.queue_free()
	
	var StatsAssociated = []
	for I : Control in speciesToCheckboxNode[specie].get_children(): if I is CheckBox: if I.button_pressed: StatsAssociated.append(I.text)
	
	if "COUNT" in StatsAssociated:
		renderLineOnControl(CountAsPercentage([specie]),speciesToGraphNode[specie])
		StatsAssociated.erase("COUNT")
	
	for I in StatsAssociated:
		renderLineOnControl(StatAsPercentage([specie],I),speciesToGraphNode[specie],true,StatTocolor[I])

func updateGlobalSpecie():
	for I in %GlobalStat.get_children(): I.queue_free()
	
	var StatsAssociated = []
	for I : Control in %GlobalStatHbox.get_children(): if I is CheckBox: if I.button_pressed: StatsAssociated.append(I.text)
	print(StatsAssociated)
	for I in StatsAssociated:
		var statPercentage = StatAsPercentage(RelevantSpecies,I)
		var trueAverages = AllSpeciesAveragePercentageFromPercentage(statPercentage)
		renderLineOnControl(trueAverages,%GlobalStat,true,StatTocolor[I])

func AllSpeciesAveragePercentageFromPercentage(data : Array[Dictionary]):
	var newData : Array[Dictionary] = []
	for I : Dictionary in data:
		var Total = 0
		for E in I.values():
			Total += E
		Total /= I.size()
		newData.append({0:Total})
	return newData

func showColorCodes(displayNode : Control):
	for I in displayNode.get_children():I.queue_free()
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

func pruneSpecies():
	var speciesToTop = {}
	for I in historyArray:
		for Specie in I.keys():
			if !speciesToTop.has(Specie): speciesToTop[Specie] = 0 
			
			if speciesToTop[Specie] < I[Specie]["count"]:
				speciesToTop[Specie] = I[Specie]["count"]
	
	for I in speciesToTop:
		if speciesToTop[I] < CountRemovingThreshHold:
			RelevantSpecies.erase(I)
	

func StatAsPercentage(species : Array[int],Stat : String):
	var HighestStat = 0
	var LowestStat = 99999
	for I in historyArray: 
		for Specie in I.keys():
			if Specie in species:
				var Part : BodyPart = I[Specie]["averagePart"]
				if Part.get(Stat) > HighestStat:
					HighestStat = Part.get(Stat)
				if Part.get(Stat) < LowestStat:
					LowestStat = Part.get(Stat)
	
	var newArray : Array[Dictionary] = []
	for I in historyArray: 
		var report = {}
		for Specie in species:
			if I.has(Specie):
				var Part : BodyPart = I[Specie]["averagePart"]
				report[Specie] = inverse_lerp(LowestStat,HighestStat,Part.get(Stat))
		newArray.append(report)
	
	return newArray

func renderLineOnControl(data : Array[Dictionary],control : Control, ignore0 = false, forcecolor : Color = Color.TRANSPARENT):
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
		if forcecolor == Color.TRANSPARENT:
			line2D.default_color  = Color.from_hsv(inverse_lerp(0,RelevantSpecies.max(),specie),1,1,1)
		else:
			line2D.default_color = forcecolor
		control.add_child(line2D)


func _on_spin_box_value_changed(value):
	CountRemovingThreshHold = value
	_ready()
	


func _on_main_menu_pressed():
	Transition.transition(load("res://startMenu.tscn").instantiate())
