extends Node

@export var mutationDist = 5 #the max distance of mutation in a body part

enum SimulationReproductionType {Duplication, TwoParents}
@export var reproductionType : SimulationReproductionType = SimulationReproductionType.Duplication

var AgeToReproducePerStat = 2 #the amount of seconds it takes for a creature to be able to reproduce, multiplied by BST. So if the value is 1, it will take 300 seconds for a creature with 300 bst to be ready to reproduce.

var TimeForSmallCreatureToDieOfStarvation = 120

var PixelVisionPerSPD = 4 #how many inworld units / pixels the agent can see based on their SpD stat

var bstPerBirthTimer = 0.5







enum Typings {Fire,Water,Green,Turqoise,Robot}

func getMoveEffectiveness(moveTyping : Typings, recipientTyping : Typings):
	return 1

func calculateDamage(move : Move, attacker : Agent,defender : Agent):
	var statstuff =  move.getRelevantStats(attacker,defender)
	var level = 5
	
	var rawDMG = ((2 * level) / 5.0) + 5
	var defendedDamage = rawDMG * statstuff[0]/statstuff[1]
	var finalAttack = (defendedDamage / 5) + 2
	var fullAttack = getMoveEffectiveness(move.typing,defender.getTyping()) * finalAttack
	
	return fullAttack
