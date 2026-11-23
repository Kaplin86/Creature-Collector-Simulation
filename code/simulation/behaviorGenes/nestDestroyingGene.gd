extends BasicBehaviorGene
class_name NestDestroyingGene

## The creature will destroy nests of a differing species

func evaluate(agent : Agent) -> float:
	return sanitizeOutput(agent.energy * multiplier)

func act(agent : Agent) -> void:
	var result = getEnemyNestInVision(agent)
	if result:
		agent.targetLocation = result.global_position
		attemptToBreak(result, agent)
	else:
		agent.setWanderTarget()

func getEnemyNestInVision(agent : Agent) -> Nest:
	for I in agent.lookInVision(["nest"]):
		if I.species != agent.species:
			return I
	return null

func attemptToBreak(nest : Nest, agent : Agent):
	if agent.global_position.distance_to(nest.global_position) < 15:
		nest.queue_free()
		agent.energy += 0.05
