extends Resource
class_name BodyPart

@export var HP = 0
@export var ATK = 0
@export var DEF = 0
@export var SpA = 0
@export var SpD = 0
@export var SP = 0

var stats = ["HP","ATK","DEF","SpA","SpD","SP"]

@export var UnDebuffedStats = ["HP","SpD","SP"]

func mutateRandomly():
	for I in stats:
		var mult = 1.0
		if not I in UnDebuffedStats: mult = 0.5
		
		set(I,get(I) + randf_range(-GlobalVars.mutationDist,GlobalVars.mutationDist) * mult)

func MutateDebuff():
	UnDebuffedStats.erase(UnDebuffedStats.pick_random())
	var tempStats = stats.duplicate(true)
	for I in UnDebuffedStats: tempStats.erase(I)
	UnDebuffedStats.append(tempStats.pick_random())

func averageWith(otherPart : BodyPart):
	for I in stats:
		set(I,(get(I) + otherPart.get(I)) / 2)
