extends BasicBehaviorGene
class_name PickupFoodGene

## The creature will attempt to pick up food if it doesnt have any. This should be interpreted as an alternative for hunting / wander

## See [method BasicBehaviorGene.evaluate]
func evaluate(agent : Agent) -> float:
	if agent.holdingObject == null:
		return sanitizeOutput(agent.energy * multiplier)
	return sanitizeOutput(-9999)

## Called when the agent chooses a specific action.[br]
func act(agent : Agent) -> void:
	if agent.holdingObject == null:
		var resultOptions = agent.lookForFoods()
		var result
		for I in resultOptions:
			if is_instance_valid(I):
				if agent.has_meta("nest"):
					if agent.get_meta("lastNestPos").distance_to(I.global_position) > 20:
						result = I
						break
			
		if result:
			if result is Fruit: #CHANGE LATER TO ACCOUNT FOR LATER MEAT OPTIONS!!
				agent.targetLocation = result.global_position
				attemptToPickup(result, agent)
		
	agent.setWanderTarget()

## Checks if the target is close enough to be picked up
func attemptToPickup(target, agent : Agent):
	if agent.global_position.distance_to(target.global_position) < 5:
		agent.pickup(target)
