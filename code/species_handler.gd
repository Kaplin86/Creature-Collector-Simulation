extends Node2D
class_name SpeciesHandler

var Stats = ["HP","ATK","DEF","SpA","SpD","SP"]

var Species : Array[SpeciesDatastore] = []

var distThreshold = 30

var statDifWeight = 0.5
var limbDifWeight = 15
var dietWeight = 10

func AddSpecies(first : Agent, Previous : int) -> int:
	var newDatastore = SpeciesDatastore.new()
	for I in Stats:
		newDatastore.originStats[I] = first.calculateFinalStat(I)
	
	for I in first.parts:
		newDatastore.originParts.append(I.UnDebuffedStats)
	
	newDatastore.diet = first.dietType
	newDatastore.previousSpecies = Previous
	
	newDatastore.color = Color.from_hsv(randf(),1,1,1) * 5
	
	Species.append(newDatastore)
	print(Species)
	return Species.find(newDatastore)

func evaluateSpecies(check : Agent, Specie : SpeciesDatastore):
	var weight = 0
	for I in Stats:
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
	
	return weight

func checkChildIfNewSpecies(check : Agent, parentSpecies : int) -> int:
	for I in Species:
		var weight = evaluateSpecies(check, I)
		if weight < distThreshold:
			return Species.find(I)
	
	return AddSpecies(check, parentSpecies)
