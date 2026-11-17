extends Node3D
class_name SpatialGrid

## A system to efficiently seperate the map into a grid for faster vision-searching

## The size of each cell
@export var cellSize : float = 120

## The grid, with keys being cells, and the arrays being objects inside that cell
var grid : Dictionary[Vector3i,Array] = {}

## Returns the current cell the position is inside of
func getCell(pos : Vector3) -> Vector3i:
	return Vector3i(floori(pos.x / cellSize),floori(pos.y / cellSize),floori(pos.z / cellSize))

## Adds an entity into its designated cell
func addEntity(entity : Node3D) -> void:
	var cell = getCell(entity.global_position)
	
	if !grid.has(cell):
		grid[cell] = []
	
	grid[cell].append(entity)

## Removes the entity from the grid
func removeEntity(entity : Node3D) -> void:
	var cell = getCell(entity.global_position)
	if grid.has(cell):
		grid[cell].erase(entity)
		for I in grid[cell]: 
			if !is_instance_valid(I):
				grid[cell].erase(I)
		if grid[cell].is_empty():
			grid.erase(cell)

## Updates the cell the entity resides in.
func updateEntity(entity : Node3D, lastPos : Vector3) -> void:
	var newCell = getCell(entity.global_position)
	var oldcell = getCell(lastPos)
	
	if newCell == oldcell:
		return
	
	if grid.has(oldcell):
		grid[oldcell].erase(entity)
		
		if grid[oldcell].is_empty():
			grid.erase(oldcell)
	
	if !grid.has(newCell):
		grid[newCell] = []
	
	grid[newCell].append(entity)

## Returns all entities in the cells that are reached from radius
func getEntitiesUsingDist(pos : Vector3,radius : float) -> Array:
	var results = []
	
	var topLeftCell = getCell(pos - (Vector3.ONE*radius) )
	var bottomRightCell = getCell(pos + (Vector3.ONE*radius) )
	
	for x in range(topLeftCell.x,bottomRightCell.x+1):
		for y in range(topLeftCell.y,bottomRightCell.y + 1):
			for z in range(topLeftCell.z,bottomRightCell.z + 1):
				var cell = Vector3i(x,y,z)
							
				if grid.has(cell):
					results.append_array(grid[cell])
	
	return results
