extends BasicBehaviorGene
class_name NestGene

## Creatures with this gene will attempt to locate a nest of same species.
##They will automatically create one if they are far enough.

## See [method BasicBehaviorGene.evaluate]
func evaluate(agent : Agent) -> float:
	if !agent.has_meta("nest"):
		return sanitizeOutput(999)
	else:
		var nest :Node2D = agent.get_meta("nest")
		if is_instance_valid(nest):
			return sanitizeOutput((nest.global_position.distance_squared_to(agent.global_position) / 350000) * multiplier)
		return sanitizeOutput(999)
	return sanitizeOutput(0)

## Called when the agent chooses a specific action.[br]
##If an action needs to keep memory of something, it should be saved on the gene and be limited.
func act(agent : Agent) -> void:
	
	for I : Node2D in agent.lookInVision():
		if I is Nest:
			if I.species == agent.species:
				agent.set_meta("nest",I)
				return
	
	if randi_range(1,30) == 3:
		var newNest = Nest.new()
		newNest.species = agent.species
		newNest.global_position = agent.global_position
		agent.add_sibling(newNest)
		agent.set_meta("nest",newNest)
		agent.energy -= 0.1
	else:
		agent.setWanderTarget()
