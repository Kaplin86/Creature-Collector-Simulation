extends Resource
class_name BodyPart

@export var HP = 10
@export var ATK = 10
@export var DEF = 10
@export var SpA = 10
@export var SpD = 10
@export var SP = 10

var stats = ["HP","ATK","DEF","SpA","SpD","SP"]

@export var UnDebuffedStats = ["HP","SpD","SP"]

func mutateRandomly():
	for I in stats:
		set(I,get(I) + randf_range(-GlobalVars.mutationDist,GlobalVars.mutationDist))

func MutateDebuff():
	UnDebuffedStats.erase(UnDebuffedStats.pick_random())
	var tempStats = stats.duplicate(true)
	for I in UnDebuffedStats: tempStats.erase(I)
	UnDebuffedStats.append(tempStats.pick_random())
