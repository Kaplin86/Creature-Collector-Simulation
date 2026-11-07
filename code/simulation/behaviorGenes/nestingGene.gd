extends BasicBehaviorGene
class_name NestGene

## Creatures with this gene will attempt to locate a nest of same species.[br]
##They will automatically create one if they are far enough, or can't find one.

## See [method BasicBehaviorGene.evaluate]
func evaluate(agent : Agent) -> float:
	if !is_instance_valid(agent): return 0
	
	if !agent.has_meta("nest"):
		attemptToFindNest(agent)
	
	if !agent.has_meta("nest"):
		if agent.getAgeMetric() > 0.5:
			return sanitizeOutput(1* multiplier)
	else: #if the creature has nest...
		var nest  = agent.get_meta("nest")
		if is_instance_valid(nest): #if nest still exists
			return sanitizeOutput((nest.global_position.distance_squared_to(agent.global_position) / 350000) * multiplier)
		else:
			if agent.get_meta("lastNestPos",agent.global_position).distance_to(agent.global_position) <= agent.getVisionDist(): #if nest no longer exists, and its former position is in viewing range
				agent.set_meta("nest",null)
			return sanitizeOutput(0)
			
		return sanitizeOutput(1 * multiplier)
	
	return sanitizeOutput(0)

## The agent will look for a nest, and save it if it can find one. Otherwise, roll a 1 in 30 chance to create one. Costs 0.1 energy.
func act(agent : Agent) -> void:
	
	attemptToFindNest(agent)
	
	if !agent.has_meta("nest"):
		if agent.getAgeMetric() > 0.5 and ( randi_range(1,30) == 3): #only be able to 
			var newNest = Nest.new()
			newNest.species = agent.species
			newNest.global_position = agent.global_position
			agent.add_sibling(newNest)
			agent.set_meta("nest",newNest)
			agent.set_meta("lastNestPos",newNest.global_position)
			agent.energy -= 0.1
		else:
			agent.setWanderTarget()

func attemptToFindNest(agent : Agent):
	for I : Node2D in agent.lookInVision():
		if I is Nest:
			if I.species == agent.species:
				agent.set_meta("nest",I)
				agent.set_meta("lastNestPos",I.global_position)
