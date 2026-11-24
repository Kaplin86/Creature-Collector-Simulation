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

var inBattle = false

signal turnOver #emit when the enemy is supposed to act

func _ready():
	$Battle.visible = false

func createAgentViewport(agent : Agent, rotating = false, forcerotation = Vector3.ZERO, position = Vector3.INF) -> SubViewport:
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
	
	if forcerotation != Vector3.ZERO:
		newAgent.rotation = forcerotation
	
	if position != Vector3.INF:
		newAgent.position = position
	
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
		var pick : Agent = get_tree().get_nodes_in_group("creature").pick_random().duplicate(Node.DUPLICATE_DEFAULT | Node.DUPLICATE_INTERNAL_STATE)
		#pick.duplicate()
		pick.remove_from_group("creature")
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
				I.level = 5
				%PlayerCharacter.addToParty(I)
				render(%PlayerCharacter)
				#doBattle(%PlayerCharacter, get_tree().get_nodes_in_group("creature").pick_random())
		)

var currentAlly : Agent # the current ally in battle
var currentEnemy : Agent
func doBattle(player : Player, enemy : Agent):
	
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	inBattle = true
	currentAlly = player.party[0]
	currentEnemy = enemy
	$Battle.visible = true
	var allyviewport = createAgentViewport(currentAlly,false,Vector3(0,deg_to_rad(-60),0),Vector3(0,-1,-5))
	add_child(allyviewport)
	var enemyviewport = createAgentViewport(enemy,false,Vector3(0,deg_to_rad(170),0),Vector3(0,-1,-5))
	add_child(enemyviewport)
	$Battle/Ally.texture = allyviewport.get_texture()
	$Battle/Foe.texture = enemyviewport.get_texture()
	$Battle/AllyDisplay.render(currentAlly)
	$Battle/EnemyDisplay.render(enemy)
	
	while inBattle:
		await turnOver
		print("enemy tur")
		$Battle/AllyDisplay.render(currentAlly)
		print(currentAlly.HP)
		$Battle/EnemyDisplay.render(enemy)
		if enemy.HP < 0:
			inBattle = false
		if inBattle:
			var move : Move = enemy.moveSet.pick_random()
			var damageToDeal = max(GlobalVars.calculateDamage(move, enemy , currentAlly),1)
			currentAlly.HP -= damageToDeal
			doNumberFloatEffect(-damageToDeal,$Battle/Ally.global_position + $Battle/Ally.size / 2)
		await get_tree().create_timer(1).timeout
		$Battle/BasicButtons.visible = true
	
	$Battle.visible = false
	inBattle = false
	get_tree().paused = false

var dt = 0.0
func _process(delta):
	dt += delta
	$Battle/Ally.offset_transform_position.y = sin(dt * 3) * 3
	$Battle/Foe.offset_transform_position.y = cos(dt * 3) * 3


func _flee_battle_press():
	$Battle.visible = false
	inBattle = false
	get_tree().paused = false

func doNumberFloatEffect(number, pos):
	var newNumber = Label.new()
	newNumber.global_position = pos
	newNumber.text = str(number)
	if float(number) < 0:
		newNumber.add_theme_color_override("font_color",Color.RED)
	else:
		newNumber.text = "+" + str(number)
		newNumber.add_theme_color_override("font_color",Color.GREEN)
	newNumber.add_theme_font_size_override("font_size",32)
	newNumber.add_theme_constant_override("outline_size",3)
	add_child(newNumber)
	var newtween = create_tween()
	newtween.parallel()
	
	newtween.tween_property(newNumber,"position",pos - Vector2(0,30),1)
	newtween.tween_property(newNumber,"modulate",Color.TRANSPARENT,1)


func _attack_battle_press():
	$Battle/Moves.visible = true
	$Battle/BasicButtons.visible = false
	
	for I in $Battle/Moves.get_children(): I.queue_free()
	
	
	
	for I in currentAlly.moveSet:
		var newButton = Button.new()
		$Battle/Moves.add_child(newButton)
		newButton.text = I.name
		newButton.pressed.connect(
			func():
				var move : Move = I
				var damageToDeal = max(GlobalVars.calculateDamage(move, currentAlly , currentEnemy),1)
				currentEnemy.HP -= damageToDeal
				doNumberFloatEffect(-damageToDeal,$Battle/Foe.global_position + $Battle/Foe.size / 2)
				$Battle/Moves.visible = false
				await get_tree().create_timer(1).timeout
				turnOver.emit()
		)
	
	
	var newButton = Button.new()
	$Battle/Moves.add_child(newButton)
	newButton.text = "back"
	newButton.pressed.connect(
		func():
			$Battle/Moves.visible = false
			$Battle/BasicButtons.visible = true
	)
	
	#turnOver.emit()
