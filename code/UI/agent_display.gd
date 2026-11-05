extends Control

var displayingAgent : Agent

func _process(delta: float) -> void:
	if is_instance_valid(displayingAgent):
		%Age.text = "Age - " + str(int(floor(displayingAgent.age))) + " SECONDS"
		%Species.text = "Species #" + str(displayingAgent.species)
		%Energy.text = "Energy - " + str(String.num(displayingAgent.energy,4))
		%HP.text = "HP - " + str(displayingAgent.HP)
