extends Button

func _on_pressed():
	$FileDialog.visible = true


func _on_file_dialog_file_selected(path):
	var error = SimulationRecorder.saveToFile(path)
	if error:
		text = "Failed..."
	else:
		text = "Saved!"
	
	await get_tree().create_timer(2).timeout
	text = "Save Simulation History To File"
