extends Button


func _on_pressed():
	$FileDialog.visible = true


func _on_file_dialog_file_selected(path):
	var SimHistory = load(path)
	print(SimHistory)
	var Viewer = load("res://PROPERsimulationRenderer.tscn").instantiate()
	Viewer.simulationHistory = SimHistory
	print(SimHistory)
	Transition.transition(Viewer)
