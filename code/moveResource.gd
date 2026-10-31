extends Resource
class_name Move

enum DamageTypes {Physical, Special}

@export var name = "Punch"
@export var damageType : DamageTypes = DamageTypes.Physical
@export var typing : GlobalVars.Typings = GlobalVars.Typings.Fire

func getRelevantStats(attacker : Agent, defender : Agent) -> Array[float]:
	if damageType == DamageTypes.Physical:
		return [attacker.calculateFinalStat("ATK"),defender.calculateFinalStat("DEF")]
	else:
		return [attacker.calculateFinalStat("SpA"),defender.calculateFinalStat("SpD")]
