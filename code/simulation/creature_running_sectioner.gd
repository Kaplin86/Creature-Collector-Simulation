extends Node3D

var groups : Array[Array] = [[],[],[]]
var agentToGroup = {}

var num = 0
func _process(delta):
	num = wrap(num + 1,0,3)
	for I : Agent in groups[num]:
		if is_instance_valid(I):
			I.frame(delta)

func addAgent(agent : Agent):
	var chosenGroup = randi_range(0,2)
	agentToGroup[agent] = chosenGroup
	groups[chosenGroup].append(agent)

func removeAgent(agent : Agent):
	var group = agentToGroup[agent]
	groups[group].erase(agent)
	agentToGroup.erase(agent)
