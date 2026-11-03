extends BasicBehaviorGene
class_name WanderGene
## A special fallback gene.

## See [method BasicBehaviorGene.evaluate]
func evaluate(agent : Agent) -> float:
	return 0

## Runs [method Agent.setWanderTarget]
func act(agent : Agent) -> void:
	agent.setWanderTarget()
