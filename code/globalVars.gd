extends Node

@export var mutationDist = 1.5 #the max distance of mutation in a body part

enum SimulationReproductionType {Duplication, TwoParents}
@export var reproductionType : SimulationReproductionType = SimulationReproductionType.Duplication

var AgeToReproducePerStat = 1 #the amount of seconds it takes for a creature to be able to reproduce, multiplied by BST. So if the value is 1, it will take 300 seconds for a creature with 300 bst to be ready to reproduce.

var TimeForSmallCreatureToDieOfStarvation = 120

var PixelVisionPerSPD = 3 #how many inworld units / pixels the agent can see based on their SpD stat
