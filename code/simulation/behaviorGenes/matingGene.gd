extends BasicBehaviorGene
class_name BasicMateGene

## A gene where the creature will attempt to walk to another creature for matings. Functions as a wander if no mate is found.

## See [method BasicBehaviorGene.evaluate]
func evaluate(agent : Agent) -> float:
	if max(GlobalVars.AgeToReproducePerStat * agent._bstHash,30) < agent.age and agent.birthtimer < 0.01:
		return sanitizeOutput(agent.energy * multiplier)
	
	return -999

## Called when the agent chooses a specific action.[br]
##If an action needs to keep memory of something, it should be saved on the gene and be limited.
func act(agent : Agent) -> void:
	if GlobalVars.reproductionType == GlobalVars.SimulationReproductionType.Duplication:
		agent.soloReproduction()
		agent.energy -= 0.3
		return
	
	agent.lookingForMate = true
	var result = agent.lookForMate()
	if result and result is Agent:
		agent.targetLocation = result.global_position
		if agent.global_position.distance_squared_to(result.global_position) <= 10:
			var ChildBearer : Agent = result
			var Other : Agent = agent
			if result.energy < agent.energy:
				ChildBearer = agent
				Other = result
			
			ChildBearer.duoReproduction(ChildBearer,Other)
			ChildBearer.energy -= 0.25
	else:
		agent.setWanderTarget()
