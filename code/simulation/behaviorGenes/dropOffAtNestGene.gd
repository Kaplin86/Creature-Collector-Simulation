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
	if agent.has_meta("lastNestPos"):
		agent.targetLocation = agent.get_meta("lastNestPos")
		if agent.global_position.distance_squared_to(agent.get_meta("lastNestPos")) <= 20:
			agent.drop()
	else:
		agent.setWanderTarget()
	
