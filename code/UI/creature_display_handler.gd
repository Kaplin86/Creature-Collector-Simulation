extends Node3D
class_name CreatureDisplayHandler

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			
			
			var camera = get_viewport().get_camera_3d()
			var mouse_pos = get_viewport().get_mouse_position()
			var origin = camera.project_ray_origin(mouse_pos)
			var direction = camera.project_ray_normal(mouse_pos)
			var query = PhysicsRayQueryParameters3D.create(
				origin,
				origin + direction * 50
			)
			var space = get_world_3d().direct_space_state
			var result = space.intersect_ray(query)
			if result.is_empty():
				return
			var mousePos = result.position
			var creatures = %SpatialGrid.getEntitiesUsingDist(mousePos, 200)
			$"../MeshInstance3D".global_position = mousePos

			
			var lowestDist = INF
			var closestCreature : Agent = null
			for I in creatures:
				if is_instance_valid(I):
					if I is Agent:
						var dist = mousePos.distance_squared_to(I.global_position)
						#print(dist)
						if dist < lowestDist:
							lowestDist = dist
							closestCreature = I
			
			#print(lowestDist)
			if lowestDist < 30:
				%Camera3D.target = closestCreature
				#print("hi ", closestCreature)
				$CanvasLayer/Panel2.visible = true
				$CanvasLayer/Panel2.displayingAgent = closestCreature 
			else:
				%Camera3D.target = null
				$CanvasLayer/Panel2.visible = false
				$CanvasLayer/Panel2.displayingAgent = null 

func _process(delta):
	if $CanvasLayer/Panel2.displayingAgent:
		var agent : Agent =  $CanvasLayer/Panel2.displayingAgent
		global_position = agent.global_position
		$VisionRing.mesh.inner_radius = agent.getVisionDist()
		$VisionRing.mesh.outer_radius = agent.getVisionDist() + 0.1
