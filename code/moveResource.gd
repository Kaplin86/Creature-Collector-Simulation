extends Resource
class_name Move

## A resource that refers to a move an [Agent] can do.

## The two damage types a move can be
enum DamageTypes {
	Physical, ## Uses physical stats (ATK and DEF) 
	Special ## Uses special stats (SpA and SpD)
	}

## The display name of the move
@export var name := "Punch"

## The damage type of the move
@export var damageType : DamageTypes = DamageTypes.Physical

## The typing of the movie
@export var typing : GlobalVars.Typings = GlobalVars.Typings.Fire

## A function that returns an array of relevant stats.[br]
## The first element in the array is the appropriate attack stat on the attacker[br]
## The second element in the array is the appropriate defense stat on the attacker
func getRelevantStats(attacker : Agent, defender : Agent) -> Array[float]:
	if damageType == DamageTypes.Physical:
		return [attacker.calculateFinalStat("ATK"),defender.calculateFinalStat("DEF")]
	else:
		return [attacker.calculateFinalStat("SpA"),defender.calculateFinalStat("SpD")]
