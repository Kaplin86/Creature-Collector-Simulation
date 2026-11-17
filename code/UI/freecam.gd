extends Camera3D

var sensitivity = 2

var target : Node3D = null

func _unhandled_input(event):
	if !target:
		if event is InputEventMouseMotion:
			if event.button_mask == 4:
				global_position.x -= event.relative.x * (global_position.y/30)
				global_position.z -= event.relative.y * (global_position.y/30)
		
	if event is InputEventMouseButton:
		if event.button_index == 4:
			global_position.y *= 1.1
		elif event.button_index == 5:
			global_position.y /= 1.1


func _process(delta: float) -> void:
	var realDelta = delta / Engine.time_scale
	if target:
		global_position = lerp(global_position,target.global_position,realDelta * 4)
		#zoom = lerp(zoom,Vector2.ONE * 2, realDelta * 4)
	
	var cellThings = %SpatialGrid.getEntitiesUsingDist(global_position,100)
	for I in cellThings:
		if is_instance_valid(I):
			if I is Agent:
				if !I._hasGenerated:
					I.doVisual()
