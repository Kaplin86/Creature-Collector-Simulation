extends BasicBehaviorGene
class_name BasicHuntingGene
## A gene where the creature will attempt to hunt by walking to the food

## See [method BasicBehaviorGene.evaluate]
func evaluate(agent : Agent) -> float:
	return sanitizeOutput((1 - agent.energy) * multiplier)

## Called when the agent chooses a specific action.[br]
##If an action needs to keep memory of something, it should be saved on the gene and be limited.
func act(agent : Agent) -> void:
	agent.lookingForMate = false
	var result = agent.lookForFood()
	if result:
		agent.targetLocation = result.global_position
		attemptToEat(result, agent)
	else:
		if agent.memoryFoodPosition:
			agent.targetLocation = agent.memoryFoodPosition
			if agent.global_position.distance_to(agent.memoryFoodPosition) < agent._SpDHash * GlobalVars.PixelVisionPerSPD:
				agent.memoryFoodPosition = null
		else:
			agent.setWanderTarget()

## Checks if the target is close enough to be eaten.
func attemptToEat(target, agent : Agent):
	if agent.global_position.distance_to(target.global_position) < 5:
		if target is Fruit:
			var val = min(0.05,target.NutritionalValue)
			agent.energy += val
			target.NutritionalValue -= val
			if target.NutritionalValue <= 0.0:
				target.queue_free()
			#target.queue_free()
		if target is Agent:
			agent.battle(target)
