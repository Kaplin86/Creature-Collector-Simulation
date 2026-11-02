@abstract
extends Resource
class_name BasicBehaviorGene

## A basic behavior gene. The creature determines its action by checking the value of all genes.

## A multiplier used by the evaluate.[br] 
##In the context of a hunting behavior gene, a creature with a 2 multiplier should be twice as prone to hunting compared to that of a creature with a 1 multiplier
@export var multiplier := 1.0

## The minimum value this gene can return
@export var minimum := 0.0

## The maximum value this gene can return
@export var maximum := 1.0

## This function returns the current value of the gene.[br] 
##All outputs should be ran through [method _sanitizeOutput] before returned.
@abstract 
func evaluate(agent : Agent) -> float

## Makes sure the gene's value is within the correct
func sanitizeOutput(input : float) -> float:
	return clamp(input,minimum,maximum)

## Called when the agent chooses a specific action.[br]
##If an action needs to keep memory of something, it should be saved on the gene and be limited.
@abstract
func act(agent : Agent) -> void

## Slightly alters the multiplier, minimum, and maximum on the creature.
func mutate():
	multiplier += randf_range(-0.05,0.05)
	minimum += randf_range(-0.05,0.05)
	maximum += randf_range(-0.05,0.05)
