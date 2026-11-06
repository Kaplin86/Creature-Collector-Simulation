extends Control

var displayingAgent : Agent


var lastDisplayedAgent : Agent

var scriptToGeneLabel = {}
var scriptToGeneBar = {}

var newgeneIndexToResource = {}

func _ready() -> void:
	for I in GlobalVars.genePool:
		%NewGeneOption.add_item(I.new().get_script().get_global_name() )
		var index = %NewGeneOption.item_count - 1
		newgeneIndexToResource[index] = I.new().get_script()
	print(newgeneIndexToResource)

func _process(delta: float) -> void:
	if is_instance_valid(displayingAgent):
		if lastDisplayedAgent != displayingAgent:
			onNew()
			lastDisplayedAgent = displayingAgent
		
		%Name.text = displayingAgent.name
		%DietType.selected = displayingAgent.dietType
		%Age.text = "Age - " + str(int(floor(displayingAgent.age))) + " SECONDS"
		%Species.text = "Species #" + str(displayingAgent.species)
		%Energy.text = "Energy - " + str(String.num(displayingAgent.energy,4))
		%HP.text = "HP - " + str(int(displayingAgent.HP))
		
		if displayingAgent.dietType == displayingAgent.Diets.Herbivore:
			%Risk.visible = false
			%CurrentRatio.visible = false
		else:
			%Risk.visible = true
			%CurrentRatio.visible = true
		
		%Risk.text = "Riskyness - " + str(displayingAgent.battleRiskyness) 
		%CurrentRatio.text = "Risk Ratio - " + str( inverse_lerp(0,displayingAgent._HPHash,displayingAgent.HP) )
		var cell =  %SpatialGrid.getCell(displayingAgent.global_position)
		%Cell.text = "Spatial Cell - " + str(cell)
		%InCell.text = "Bugged Cell? - " + str(not displayingAgent in  %SpatialGrid.grid.get(cell,[]))
		for I in displayingAgent.lastValueCheckResults:
			if scriptToGeneLabel.has(I):
				var text : Label = scriptToGeneLabel[I]
				text.add_theme_color_override("font_color",Color.WHITE)
				var bar : ProgressBar= scriptToGeneBar[I]
				bar.min_value = displayingAgent._minGeneHash
				bar.max_value = displayingAgent._maxGeneHash
				bar.value = displayingAgent.lastValueCheckResults[I]
				
				if I == displayingAgent.lastPerformedGene:
					text.add_theme_color_override("font_color",Color.RED) 
			

func onNew():
	scriptToGeneLabel = {}
	scriptToGeneBar = {}
	for I in %GeneContainer.get_children(): I.queue_free()
	var genes = []
	genes.append_array(displayingAgent.genes)
	genes.append(displayingAgent.wanderGene)
	var notDisabled = newgeneIndexToResource.keys()
	notDisabled.append(-1)
	for I in genes:
		var script : GDScript = I.get_script()
		var newButton = Button.new()
		if I is WanderGene: newButton.disabled = true
		newButton.text = "X"
		newButton.pressed.connect(func():
			if is_instance_valid(displayingAgent):
				displayingAgent.genes.erase(I)
				onNew()
			)
		%GeneContainer.add_child(newButton)
		var newLabel = Label.new()
		%GeneContainer.add_child(newLabel)
		newLabel.text = script.get_global_name()
		var newBar = ProgressBar.new()
		%GeneContainer.add_child(newBar)
		scriptToGeneBar[script] = newBar
		scriptToGeneLabel[script] = newLabel
		newBar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var index = newgeneIndexToResource.find_key(script)
		if index != null:
			notDisabled.erase(index)
			%NewGeneOption.set_item_disabled(index,true)
	%NewGeneOption.selected = notDisabled[0]
	
	
	for I in %PartsGrid.get_children(): I.queue_free()
	var maxVals : Dictionary[int,int] = {}
	for I in StatGraphDisplay.StatTypes: 
		print(StatGraphDisplay.StatTypes[I])
		maxVals[StatGraphDisplay.StatTypes[I]] = displayingAgent.calculateBaseStat(I)
	print(maxVals)
	for I : BodyPart in displayingAgent.parts:
		var NewDisplay = StatGraphDisplay.new()
		NewDisplay.setCurrentBlockFromPart(I)
		NewDisplay.CurrentStatblockMAX = maxVals
		%PartsGrid.add_child(NewDisplay)
		
	
	

func _on_diet_type_item_selected(index: int) -> void:
	displayingAgent.dietType = index
	displayingAgent.updateSpecies()
	print("new selected")


func _on_add_new_gene_pressed() -> void:
	if %NewGeneOption.selected != -1:
		if is_instance_valid(displayingAgent):
			displayingAgent.genes.append(newgeneIndexToResource[%NewGeneOption.selected].new())
			onNew()
