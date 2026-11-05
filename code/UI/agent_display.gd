extends Control

var displayingAgent : Agent


var lastDisplayedAgent : Agent

var scriptToGeneLabel = {}
var scriptToGeneBar = {}

func _process(delta: float) -> void:
	if is_instance_valid(displayingAgent):
		if lastDisplayedAgent != displayingAgent:
			onNew()
			lastDisplayedAgent = displayingAgent
		
		
		%Age.text = "Age - " + str(int(floor(displayingAgent.age))) + " SECONDS"
		%Species.text = "Species #" + str(displayingAgent.species)
		%Energy.text = "Energy - " + str(String.num(displayingAgent.energy,4))
		%HP.text = "HP - " + str(int(displayingAgent.HP))
		
		for I in displayingAgent.lastValueCheckResults:
			var text : Label = scriptToGeneLabel[I]
			text.add_theme_color_override("font_color",Color.WHITE)
			var bar : ProgressBar= scriptToGeneBar[I]
			bar.min_value = displayingAgent._minGeneHash
			bar.max_value = displayingAgent._maxGeneHash
			bar.value = displayingAgent.lastValueCheckResults[I]
			
			if I == displayingAgent.lastPerformedGene:
				text.add_theme_color_override("font_color",Color.RED) 
			

func onNew():
	
	for I in %GeneContainer.get_children(): I.queue_free()
	var genes = []
	genes.append_array(displayingAgent.genes)
	genes.append(displayingAgent.wanderGene)
	for I in genes:
		var script : GDScript = I.get_script()
		var newLabel = Label.new()
		%GeneContainer.add_child(newLabel)
		newLabel.text = script.get_global_name()
		var newBar = ProgressBar.new()
		%GeneContainer.add_child(newBar)
		scriptToGeneBar[script] = newBar
		scriptToGeneLabel[script] = newLabel
		newBar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
