extends Node3D

var groups : Array[Array] = [[],[],[],[],[],[],[],[]]
var elapsedTime : Array[float] = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
var agentToGroup = {}

var num = 0
var dt = 0.0
func _process(delta):
	dt += delta
	for I in range(groups.size()):
		elapsedTime[I] += delta
	
	num = (num + 1) % groups.size()
	
	var timeUsing = elapsedTime[num]
	elapsedTime[num] = 0.0
	
	for agent: Agent in groups[num].duplicate():
		if is_instance_valid(agent) and !agent.is_queued_for_deletion():
			if agentToGroup.has(agent):
				agent.frame(timeUsing)
	
	#if Engine.get_frames_per_second() < 20 and dt > 50:
	#	dt = 0.0
		#elapsedTime.append(0.0)
		

func addAgent(agent : Agent):
	var smallestGroup = 0
	var groupSize = 99999
	for I in range(groups.size()):
		if groups[I].size() < groupSize:
			smallestGroup = I
			groupSize = groups[I].size()
	agentToGroup[agent] = smallestGroup
	groups[smallestGroup].append(agent)

func removeAgent(agent : Agent):
	var group = agentToGroup[agent]
	groups[group].erase(agent)
	agentToGroup.erase(agent)
