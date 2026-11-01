extends Resource
class_name SpeciesDatastore

# a storage of data of species

@export var previousSpecies = -99
@export var originStats : Dictionary = {} #The total of each stat type on the founding creature
@export var originParts : Array = [] #A summary of parts. Holds arrays of undebuffed stats
@export var diet : Agent.Diets
@export var color : Color
