extends BasicBehaviorGene
class_name NestDestroyingGene

## The creature will destroy nests of a differing species

func evaluate(agent : Agent) -> float:
	return sanitizeOutput(agent.energy * multiplier)

func act(agent : Agent) -> void:
	geneDebug = {}
	var result = getEnemyNestInVision(agent)
	geneDebug["result"] = result
	if is_instance_valid(result):
		agent.targetLocation = result.global_position
		geneDebug["set target"] = "yes"
		attemptToBreak(result, agent)
	else:
		geneDebug["ended in wander "] = "yes"
		agent.setWanderTarget()

func getEnemyNestInVision(agent : Agent) -> Nest:
	for I in agent.lookInVision(["nest"]):
		if I.species != agent.species:
			return I
	return null

func attemptToBreak(nest : Nest, agent : Agent):
	if agent.global_position.distance_to(nest.global_position) < 15:
		geneDebug["close enough to break? "] = "yes"
		nest.queue_free()
		agent.energy += 0.05
	else:
		geneDebug["close enough to break? "] = "no"
		geneDebug["distance  "] =agent.global_position.distance_to(nest.global_position)
