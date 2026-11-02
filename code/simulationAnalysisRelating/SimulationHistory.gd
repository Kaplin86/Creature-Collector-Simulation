extends Resource
class_name SimulationHistory

## A stored resource that holds data about a previous simulation

## An array of sample dictionaries.
@export var cachedHistory : Array = []

## The seconds between each sample.
@export var timePerSample = 60
