extends CanvasLayer

func render(player : Player):
	for C in %PartyArea.get_children(): C.queue_free()
	for creature : Agent in player.party:
		var container = SubViewportContainer.new()
		container.stretch = true
		container.custom_minimum_size = Vector2(0,%PartyArea.size.x)
		var newViewport = SubViewport.new()
		newViewport.own_world_3d = true
		newViewport.transparent_bg = true
		newViewport.add_child($"../WorldEnvironment".duplicate())
		container.add_child(newViewport)
		%PartyArea.add_child(container)
		var cam = Camera3D.new()
		newViewport.add_child(cam)
		
		var newAgent = creature.duplicate()
		newAgent._doReady = false
		newAgent.process_mode = Node.PROCESS_MODE_DISABLED
		newViewport.add_child(newAgent)
		newAgent.visualGenerator.surfaceMaterial.albedo_color = %SpeciesHandler.Species[newAgent.species].color
		newAgent.doVisual()
		newAgent.global_position = Vector3(0,-1,-5)
		

func _process(delta):
	for C in %PartyArea.get_children():
		C.get_child(0).get_child(2).rotation.y += delta
