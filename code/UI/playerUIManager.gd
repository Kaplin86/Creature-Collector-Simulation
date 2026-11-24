extends CanvasLayer

func render(player : Player):
	for C in %PartyArea.get_children(): C.queue_free()
	for creature : Agent in player.party:
		var container = SubViewportContainer.new()
		container.stretch = true
		container.custom_minimum_size = Vector2(0,%PartyArea.size.x)
		var newViewport = createAgentViewport(creature,true)
		container.add_child(newViewport)
		%PartyArea.add_child(container)
		



func createAgentViewport(agent : Agent, rotating = false) -> SubViewport:
	var newViewport = SubViewport.new()
	newViewport.own_world_3d = true
	newViewport.transparent_bg = true
	newViewport.add_child($"../WorldEnvironment".duplicate())
	var cam = Camera3D.new()
	newViewport.add_child(cam)
	
	var newAgent = agent.duplicate()
	newAgent._doReady = false
	newAgent.process_mode = Node.PROCESS_MODE_DISABLED
	newViewport.add_child(newAgent)
	newAgent.visualGenerator = CreatureGeneratorNode.new()
	newAgent.visualGenerator.surfaceMaterial.albedo_color = %SpeciesHandler.Species[newAgent.species].color
	newAgent.doVisual()
	newAgent.position = Vector3(0,-1,-5)
	
	if rotating:
		var spin = Node3D.new()
		spin.position = newAgent.position
		newViewport.add_child(spin)
		newAgent.reparent(spin)
		spin.set_script(load("res://code/UI/selfRotate.gd"))
	
	return newViewport

func doStarterPrompt():
	var choices : Array[Agent] = []
	var typingGroup = [GlobalVars.Typings.Fire,GlobalVars.Typings.Green,GlobalVars.Typings.Water]
	var index = 0
	var attempts = 0
	$Starters.visible = true
	while choices.size() <= 2:
		var pick : Agent = get_tree().get_nodes_in_group("creature").pick_random()
		attempts += 1
		
		var valid = false
		var dupeSpecies = false
		if pick.getTyping() == [typingGroup[index]]:
			valid = true
		
		for I in choices:
			print("my species and temp species is ", I.species , " vs ", pick.species, " with the equal being ", I.species == pick.species)
			if I.species == pick.species:
				valid = false
				dupeSpecies = true
		
		if valid:
			choices.append(pick)
			index += 1
			attempts = 0
		if attempts > 20:
			if dupeSpecies:
				if attempts > 50:
					choices.append(pick)
					index += 1
			else:
				choices.append(pick)
				index += 1
	for I in %StartersArea.get_children(): I.queue_free()
	for I in choices:
		var newButton = Button.new()
		var properTypingSegment = ""
		for C in I.getTyping():
			properTypingSegment += ","
			properTypingSegment += str(GlobalVars.Typings.find_key(C))
		properTypingSegment = properTypingSegment.erase(0,1)
		newButton.text = "starter choice #" + str(choices.find(I)) + "\nSpecies #" + str(I.species) + "\nTypings: " + properTypingSegment
		newButton.expand_icon = true
		newButton.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		newButton.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		newButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		newButton.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var viewport = createAgentViewport(I,true)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		newButton.add_child(viewport)
		var texture = viewport.get_texture()
		
		newButton.icon = texture
		%StartersArea.add_child(newButton)
		newButton.pressed.connect(
			func():
				$Starters.visible = false
				%PlayerCharacter.party.append(I)
				render(%PlayerCharacter)
		)
