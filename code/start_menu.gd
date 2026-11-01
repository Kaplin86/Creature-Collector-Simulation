extends Control



func _on_button_pressed(): #Open Big Sim
	var NewScene = load("res://simulation_scene_big.tscn").instantiate()
	NewScene.sizeX = %XSize.value
	NewScene.sizeY = %YSize.value
	NewScene.startingSpeciesCount = %SpeciesCount.value
	NewScene.startingTreeCount = %TreeCount.value
	NewScene.mutationLevel = %MutationCount.value
	NewScene.countPerGroup = %CountPerGroup.value
	GlobalVars.reproductionType = %ReproductionType.selected
	get_tree().change_scene_to_node(NewScene)
