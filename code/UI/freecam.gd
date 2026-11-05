extends Camera2D

var sensitivity = 2

var target : Node2D = null

func _input(event):
	
	if !target:
		if event is InputEventMouseMotion:
			if event.button_mask == 4:
				global_position -= event.relative / zoom
		
		
	if event is InputEventMouseButton:
		if event.button_index == 4:
			zoom *= 1.1
		elif event.button_index == 5:
			zoom /= 1.1


func _process(delta: float) -> void:
	var realDelta = delta / Engine.time_scale
	if target:
		global_position = lerp(global_position,target.global_position,realDelta * 4)
		#zoom = lerp(zoom,Vector2.ONE * 2, realDelta * 4)
