extends BasicBehaviorGene
class_name DropOffAtNestGene

## The creature will attempt to drop off held items at the nest

## See [method BasicBehaviorGene.evaluate]
func evaluate(agent : Agent) -> float:
	if agent.holdingObject != null and agent.has_meta("nest"):
		return sanitizeOutput(agent.energy * multiplier)
	return sanitizeOutput(-9999)

## Called when the agent chooses a specific action.[br]
func act(agent : Agent) -> void:
	geneDebug = {}
	geneDebug["current tick "] = Time.get_ticks_usec()
	if agent.has_meta("lastNestPos"):
		agent.targetLocation = agent.get_meta("lastNestPos")
		
		geneDebug["target set"] = "yes"
		
		geneDebug["distance in axis"] = agent.global_position - agent.get_meta("lastNestPos")
		if agent.global_position.distance_to(agent.get_meta("lastNestPos")) <= agent.getVisionDist():
			geneDebug["checking if new nest still exists"] = attemptToFindNest(agent)
			
		if agent.has_meta("lastNestPos"):
			if agent.global_position.distance_squared_to(agent.get_meta("lastNestPos")) <= 20:
				geneDebug["close enough"] = "yes"
				agent.drop()
			else:
				geneDebug["distance "] = String.num(agent.global_position.distance_squared_to(agent.get_meta("lastNestPos")),2)
	else:
		geneDebug["lacks nest"] = "yes"
		geneDebug["wandering? "] = "yes"
		agent.setWanderTarget()
	
func attemptToFindNest(agent : Agent):
	for I : Node3D in agent.lookInVision(["nest"]):
		if I is Nest:
			if I.species == agent.species:
				agent.set_meta("nest",I)
				agent.set_meta("lastNestPos",I.global_position)
				return true
	agent.set_meta("nest",null)
	agent.set_meta("lastNestPos",null)
	return false
