extends Node

## The global simulation variables.

## The mutatian "distance", as in how far up and down a stat can go when a mutation is called on it. Called for every stat, every mutation.
var mutationDist := 2

## The reproduction modes 
## @experimental: This will likely be changed out and placed on the specific [Agent] / species at a later date
enum SimulationReproductionType {
	Duplication, # The agents will do mitosis. Does not require a mate.
	TwoParents # The agents requires a mate to reproduce
	}

## The current reproduction type set for the simulation
## @experimental: This will likely be changed out and placed on the specific [Agent] / species at a later date
var reproductionType : SimulationReproductionType = SimulationReproductionType.TwoParents

## The Age required for an [Agent] to reproduce, per stat total. 
var AgeToReproducePerStat := 2

## An arbitrary value that i honestly dont really know what it means anymore lol.
var HungerRate := 0.003

## The pixel distance an [Agent] can see, per Special Defense stat.
var PixelVisionPerSPD := 4

## The cooldown on reproducing placed on an [Agent], per stat total.
var bstPerBirthTimer := 0.5

## The pixel speed on an [Agent], per Speed stat.
var SpeedPerSpeed := 0.9

## The chance for an [Agent] to grow a new [BodyPart] when mutating
var newLimbChance := 0.03
## The chance for [BodyPart] to change it's stat affinities when mutating.
var MutateLimbDebuffChance := 0.03
## The chance for an [Agent] to change [enum Agent.Diets] when mutating.
var changedDietChance := 0.03
## The chance for an [Agent] to change a [enum Move.DamageType] on a move.
var changeMoveDamageTypeChance := 0.03
## The chance for an [Agent] to change the typing on a move
var changeMoveElementalTypeChance := 0.03
## The chance for an [Agent] to alter their [member Agent.genes]
var changeBehaviorGenesChance := 0.03

## Genes that the creatures can potentially gain
var genePool : Array[GDScript]= [
	BasicHuntingGene,
	BasicMateGene,
	NestDestroyingGene,
	NestGene,
	DropOffAtNestGene,
	PickupFoodGene
]


## The various elemental typings.
enum Typings {
	Fire, ##Fire, which beats Green.
	Water, ##Water, which beats Fire and Robot.
	Green, ##Green, which beats Water
	Turqoise, ##Turqoise, which... sorry?
	Robot ## Robot, which resists all except water
	} 

## Gets the move effectiveness for two typings, with moveTyping being the offensive type, and recipientTyping being the defensive type
func getMoveEffectiveness(moveTyping : Typings, recipientTyping : Typings) -> float:
	if !recipientTyping:
		return 1.0
	
	if moveTyping == Typings.Fire and recipientTyping == Typings.Green:
		return 2.0
	if moveTyping == Typings.Water and recipientTyping == Typings.Fire:
		return 2.0
	if moveTyping == Typings.Green and recipientTyping == Typings.Water:
		return 2.0
	if moveTyping == Typings.Water and recipientTyping == Typings.Robot:
		return 2.0
	if recipientTyping == Typings.Robot:
		return 0.5
	
	return 1.0

## Calculates damage that the move does, accounting for the stats on both parties.
func calculateDamage(move : Move, attacker : Agent,defender : Agent) -> int:
	var statstuff =  move.getRelevantStats(attacker,defender)
	var level = 5
	
	var rawDMG = ((2 * level) / 5.0) + 5
	var defendedDamage = rawDMG * statstuff[0]/statstuff[1]
	var finalAttack = (defendedDamage / 5) + 2
	
	var type1Effectiveness = getMoveEffectiveness(move.typing,defender.getTyping()[0])
	var type2Effectivness = 1
	if defender.getTyping().size() != 1: 
		type2Effectivness = getMoveEffectiveness(move.typing,defender.getTyping()[1])
		
	var fullAttack = type1Effectiveness * type2Effectivness * finalAttack

	
	return floor(fullAttack)
