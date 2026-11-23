extends Control



func _on_button_pressed(): #Open Big Sim
	var NewScene = load("res://scenes/sim/3dSim.tscn").instantiate()
	NewScene.sizeX = %XSize.value
	NewScene.sizeY = %YSize.value
	NewScene.startingSpeciesCount = %SpeciesCount.value
	NewScene.startingTreeCount = %TreeCount.value
	NewScene.mutationLevel = %MutationCount.value
	NewScene.countPerGroup = %CountPerGroup.value
	GlobalVars.reproductionType = %ReproductionType.selected
	Transition.transition(NewScene)


func _on_CREATRERENDERERbutton_pressed():
	Transition.transition(load("res://scenes/creatureGenerator/generatorPreviewer.tscn").instantiate())
