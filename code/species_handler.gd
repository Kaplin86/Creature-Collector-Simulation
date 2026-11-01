extends Node2D
class_name SpeciesHandler

## Catalogues each species based on "distance"

var _Stats = ["HP","ATK","DEF","SpA","SpD","SP"]

## An array of currently held Species
var Species : Array[SpeciesDatastore] = []

## The "distance" an [Agent] needs to have to be able to found a new species.
var distThreshold := 40.0

## The "distance" added per stat-difference on an [Agent] and a species' founder
var statDifWeight := 0.5
## The "distance" added per limb-stat-affinity-difference on an [Agent] and a species' founder.
var limbDifWeight := 15.0
## The "distance" added if the diet type on a [Agent] is different than a species' founder.
var dietWeight := 45.0
## The "distance" added if the elemental type on a [Agent] is not present on a species' founder. [br]
## This checks for both elements, and disreguards order
var elementWeight := 40.0

## Adds a new species to the [member Species] array, and returns the new species number.
func AddSpecies(first : Agent, Previous : int) -> int:
	
	if !is_instance_valid(first):
		return 0
	
	var newDatastore = SpeciesDatastore.new()
	for I in _Stats:
		newDatastore.originStats[I] = first.calculateFinalStat(I)
	
	for I in first.parts:
		newDatastore.originParts.append(I.UnDebuffedStats)
	
	newDatastore.diet = first.dietType
	newDatastore.previousSpecies = Previous
	
	newDatastore.color = Color.from_hsv(randf(),1,1,1) * 5
	
	for I in first.getTyping():
		newDatastore.typings.append(I)
	
	Species.append(newDatastore)
	
	return Species.find(newDatastore)

## Checks the "distance" between an agent and a selected species.
func evaluateSpecies(check : Agent, Specie : SpeciesDatastore) -> float:
	var weight = 0
	for I in _Stats:
		weight += abs(check.calculateFinalStat(I) - Specie.originStats[I]) * statDifWeight
	weight /= check.parts.size()
	
	
	var checkDupe = check.parts.duplicate()
	var originDupe = Specie.originParts.duplicate()
	for I in originDupe:
		I.sort()
	
	for I in checkDupe:
		I.UnDebuffedStats.sort()
	
	for I in checkDupe:
		if originDupe.has(I):
			originDupe.erase(I)
			checkDupe.erase(I)
	
	weight += abs(originDupe.size() - checkDupe.size()) * limbDifWeight
	
	if check.dietType != Specie.diet:
		weight += dietWeight
	
	var agentElements = check.getTyping()
	for I in Specie.typings:
		if not I in agentElements:
			weight += elementWeight
	
	return weight

## Iterates through each species, and evaluates if the agent falls into a pre-existing species. [br]
##If it does, it returns that species[br]
##If it doesn't, it returns a new species from [method AddSpecies]
func checkChildIfNewSpecies(check : Agent, parentSpecies : int) -> int:
	for I in Species:
		var weight = evaluateSpecies(check, I)
		if weight < distThreshold:
			return Species.find(I)
	
	return AddSpecies(check, parentSpecies)
