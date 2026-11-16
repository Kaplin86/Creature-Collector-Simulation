extends Node3D

func _ready():
	var num = 0
	for I in %TypingContainer.get_children():
		if I is OptionButton:
			for C in GlobalVars.Typings:
				I.add_item(C)
				I.item_selected.emit(newTypingSelected.bind(num))
			I.select(%generator.typings[num])
			num +=1
	
	%generator.generate()

func renderParts(def : Dictionary):
	
	var unaccountedforparts = %generator.parts.duplicate()
	for I in %MainVbox.get_children():
		if I is BodypartPreviewer:
			if not I.partHash in %generator.parts:
				I.queue_free()
			else:
				I.displayPart(I.partHash)
				if %generator.BodyPartTypes.find_key(def[I.partHash]):
					I.setName(%generator.BodyPartTypes.find_key(def[I.partHash]))
				unaccountedforparts.erase(I.partHash)
	
	
	for I in unaccountedforparts:
		var newGuy : BodypartPreviewer = load("res://scenes/creatureGenerator/bodypartUIpreviewer.tscn").instantiate()
		%MainVbox.add_child(newGuy)
		newGuy.displayPart(I)
		newGuy.updated.connect(func():
			%generator.generate()
			)
		newGuy.delete.connect(func():
			%generator.parts.erase(newGuy.partHash)
			%generator.generate()
			)
		newGuy.setName(%generator.BodyPartTypes.find_key(def[I]))
	
	%MainVbox.move_child(%NewPart,-1)
	

func newTypingSelected(optionindex,indexintypearray):
	%generator.typings[indexintypearray] = optionindex
	%generator.generate()

func _on_species_spinny_value_changed(value):
	%generator.seedVal = int(value)
	%generator.generate()


func _on_right_turn_pressed():
	%generator.global_rotation.y += 0.1


func _on_left_turn_pressed():
	%generator.global_rotation.y -= 0.1

func _unhandled_input(event):
	
	if event is InputEventMouseButton:
		if !get_viewport().gui_get_hovered_control():
			if event.button_index == 4:
				%generator.global_rotation.y += 0.1
			if event.button_index == 5:
				%generator.global_rotation.y -= 0.1


func _on_generator_generation_complete(bodyType, def : Dictionary):
	%CurrentBodyType.text = "CURRENT BODY TYPE: " + str(%generator.BodyTypes.find_key(bodyType))
	renderParts(def)


func _on_new_part_pressed():
	%generator.parts.append(BodyPart.new())
	%generator.generate()
	
