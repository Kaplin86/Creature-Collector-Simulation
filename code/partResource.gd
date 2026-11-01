extends Resource
class_name BodyPart

## An ambigious body part (The limb can be interpretted to be anything) on the creature.

## The Max HP this BodyPart supplies
@export var HP := 0
## The Attack this BodyPart supplies
@export var ATK := 0
## The Defense this BodyPart supplies
@export var DEF := 0
## The Special Attack this BodyPart supplies
@export var SpA := 0
## The Special Defense this BodyPart supplies
@export var SpD := 0
## The Speed this BodyPart supplies
@export var SP := 0

## An array of every stat type.
var stats : Array[String] = ["HP","ATK","DEF","SpA","SpD","SP"]

## A set of three, undebuffed stats. If a stat is in this, it is mutated less, and are more likely to be mutated upwards..
@export var UnDebuffedStats : Array[String] = ["HP","SpD","SP"]

## Randomly mutates the part.[br]
## Also see [GlobalVars]
func mutateRandomly() -> void:
	for I in stats:
		var mult = 1.0
		var positiveWeight = 0.8
		if I in UnDebuffedStats: 
			mult = 0.5
			positiveWeight = 1.2
		
		set(I,get(I) + randf_range(-GlobalVars.mutationDist,GlobalVars.mutationDist * positiveWeight) * mult)

## Randomly switches out one of the [member UnDebuffedStats] for a different one.
func MutateDebuff() -> void:
	UnDebuffedStats.erase(UnDebuffedStats.pick_random())
	var tempStats = stats.duplicate(true)
	for I in UnDebuffedStats: tempStats.erase(I)
	UnDebuffedStats.append(tempStats.pick_random())

## Sets all the stats on this part to be average with a different [BodyPart]
func averageWith(otherPart : BodyPart) -> void:
	for I in stats:
		set(I,(get(I) + otherPart.get(I)) / 2)
