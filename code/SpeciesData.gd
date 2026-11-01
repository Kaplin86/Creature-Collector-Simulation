extends Resource
class_name SpeciesDatastore

## a storage of data of species

## The species that came before this
@export var previousSpecies = -99
## The Total of each stat type on the founding agent.
@export var originStats : Dictionary[String,int] = {}
## A list of the founding agent's parts, inputted by undebuffed stats.
@export var originParts : Array = []
## The diet of the founding agent
@export var diet : Agent.Diets
## The species' signifying color.
@export var color : Color
