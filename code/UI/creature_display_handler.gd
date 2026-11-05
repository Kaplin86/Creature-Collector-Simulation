extends Node2D
class_name CreatureDisplayHandler

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:

			var mousePos = get_global_mouse_position()
			var creatures = %SpatialGrid.getEntitiesUsingDist(mousePos,200)
			var lowestDist = INF
			var closestCreature : Agent = null
			#print()
			for I in creatures:
				if is_instance_valid(I):
					if I is Agent:
						var dist = mousePos.distance_squared_to(I.global_position)
						#print(dist)
						if dist < lowestDist:
							lowestDist = dist
							closestCreature = I
			
			#print(lowestDist)
			if lowestDist < 5000:
				%Camera2D.target = closestCreature
				#print("hi ", closestCreature)
				$CanvasLayer/Panel2.visible = true
				$CanvasLayer/Panel2.displayingAgent = closestCreature 
			else:
				%Camera2D.target = null
				$CanvasLayer/Panel2.visible = false
				$CanvasLayer/Panel2.displayingAgent = null 

func _draw() -> void:
	if $CanvasLayer/Panel2.displayingAgent:
		var agent : Agent =  $CanvasLayer/Panel2.displayingAgent
		draw_circle(agent.global_position,agent.getVisionDist(),Color.REBECCA_PURPLE,false,3)

func _process(delta: float) -> void:
	queue_redraw()
