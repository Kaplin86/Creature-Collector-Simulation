extends HSlider



func _on_value_changed(value):
	Engine.time_scale = value
	$"../Label".text = "SPEED - " + str(snapped(value,0.5))
var dt = 0.0
func _process(delta):
	dt += delta
	$"../ElapsedTime".text ="Elapsed Time: " + String.num(dt,3)
	$"../../PanelContainer/HBoxContainer/Species".text = "Species Count: " + str(%SpeciesHandler.Species.size())
	$"../../PanelContainer/HBoxContainer/CreatureCount".text = "Creature Count: " + str(get_tree().get_node_count_in_group("creature"))
