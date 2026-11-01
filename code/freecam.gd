extends Camera2D

var sensitivity = 2

func _input(event):
	if event is InputEventMouseMotion:
		if event.button_mask == 4:
			global_position -= event.relative / zoom
	
	
	if event is InputEventMouseButton:
		if event.button_index == 4:
			zoom *= 1.1
		elif event.button_index == 5:
			zoom /= 1.1
