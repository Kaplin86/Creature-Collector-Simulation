extends Node2D
class_name SpeciesHandler

## Catalogues each species based on "distance"

var _Stats = ["HP","ATK","DEF","SpA","SpD","SP"]

## An array of currently held Species
var Species : Array[SpeciesDatastore] = []

## The "distance" an [Agent] needs to have to be able to found a new species.
var distThreshold := 600.0

## The "distance" added per stat-difference on an [Agent] and a species' founder
var statDifWeight := 0.5
## The "distance" added per limb-stat-affinity-difference on an [Agent] and a species' founder.
var limbDifWeight := 15.0
## The "distance" added if the diet type on a [Agent] is different than a species' founder.
var dietWeight := 45.0
## The "distance" added if the elemental type on a [Agent] is not present on a species' founder. [br]
## This checks for both elements, and disreguards order
var elementWeight := 40.0
## The "distance" added for each behavior TYPE difference (per missing or added behavior)
var behaviorWeight := 40.0
## The "distance" added for each behavior VALUE difference (per each 0.1 difference in value)
var behaviorValueWeight := 1.0

## Adds a new species to the [member Species] array, and returns the new species number.
func AddSpecies(first : Agent, Previous : int) -> int:
	
	if !is_instance_valid(first):
		return 0
	
	var newDatastore = SpeciesDatastore.new()
	for I in _Stats:
		newDatastore.originStats[I] = first.calculateBaseStat(I)
	
	for I in first.parts:
		newDatastore.originParts.append(I.UnDebuffedStats)
	
	newDatastore.diet = first.dietType
	newDatastore.previousSpecies = Previous
	
	newDatastore.color = Color.from_hsv(randf(),randf(),1,1) * 1
	
	for I in first.getTyping():
		newDatastore.typings.append(I)
	
	for I in first.genes:
		newDatastore.behaviors.append(I)
	
	Species.append(newDatastore)
	
	return Species.find(newDatastore)

## Checks the "distance" between an agent and a selected species.
func evaluateSpecies(check : Agent, Specie : SpeciesDatastore, maximum : float) -> float:
	var weight = 0
	for I in _Stats:
		weight += abs(check.calculateBaseStat(I) - Specie.originStats[I]) * statDifWeight
	weight /= check.parts.size()
	
	if weight > maximum: return weight
	
	var checkDupe = check.parts.duplicate()
	var originDupe = Specie.originParts.duplicate()
	
	# im uncertain if the old code that was here even worked, given that parts are a custom resource
	#for I in originDupe:
	#	I.sort()
	
	#for I in checkDupe:
	#	I.UnDebuffedStats.sort()
	
	#for I in checkDupe:
	#	if originDupe.has(I):
	#		originDupe.erase(I)
	#		checkDupe.erase(I)
	
	weight += abs(originDupe.size() - checkDupe.size()) * limbDifWeight
	
	if weight > maximum: return weight
	
	if check.dietType != Specie.diet:
		weight += dietWeight
	
	if weight > maximum: return weight
	
	var agentElements = check.getTyping()
	for I in Specie.typings:
		if not I in agentElements:
			weight += elementWeight
	
	for I in agentElements:
		if not I in Specie.typings:
			weight += elementWeight
	
	if weight > maximum: return weight
	
	var scriptToGeneResource : Dictionary[GDScript,BasicBehaviorGene] = {}
	for I in check.genes:
		scriptToGeneResource[I.get_script()] = I
	for I in Specie.behaviors:
		var currentScript = I.get_script()
		var checkVersion : BasicBehaviorGene = scriptToGeneResource.get(currentScript,null)
		
		if checkVersion:
			# The creature has a behavior the species has.
			
			weight += (abs(checkVersion.minimum - I.minimum) / 0.1) * behaviorValueWeight
			weight += (abs(checkVersion.maximum - I.maximum) / 0.1) * behaviorValueWeight
			weight += (abs(checkVersion.multiplier - I.multiplier) / 0.1) * behaviorValueWeight
			weight += (abs(checkVersion.ageRestriction - I.ageRestriction) / 0.1) * behaviorValueWeight
			scriptToGeneResource.erase(currentScript)
			if weight > maximum: return weight
		else:
			# The creature lacks a behavior the species has.
			weight += behaviorWeight
			if weight > maximum: return weight

	
	weight += scriptToGeneResource.size() * behaviorWeight #if all behaviors are accounted for, the dictionary should be empty.
	
	
	
	return weight

## Iterates through each species, and evaluates if the agent falls into a pre-existing species. [br]
##If it does, it returns that species[br]
##If it doesn't, it returns a new species from [method AddSpecies]
func checkChildIfNewSpecies(check : Agent, parentSpecies : int) -> int:
	var closestSpecies = 0
	var closestSpeciesDistance = 99999
	for I in range(Species.size()):
		var weight = evaluateSpecies(check, Species[I], closestSpeciesDistance)
		if weight < closestSpeciesDistance:
			closestSpecies = I
			closestSpeciesDistance = weight
	
	if closestSpeciesDistance < distThreshold:
		return closestSpecies
	
	return AddSpecies(check, parentSpecies)
