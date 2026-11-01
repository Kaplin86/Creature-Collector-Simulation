extends Node2D
class_name SpatialGrid

# This is meant to alleviate some of the INSANE lag that happens at higher creature counts

@export var cellSize : float = 120

var grid : Dictionary[Vector2i,Array] = {}

func getCell(pos : Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / cellSize),floori(pos.x / cellSize))

func addEntity(entity : Node2D):
	var cell = getCell(entity.global_position)
	
	if !grid.has(cell):
		grid[cell] = []
	
	grid[cell].append(entity)

func removeEntity(entity : Node2D):
	var cell = getCell(entity.global_position)
	
	if grid.has(cell):
		grid[cell].erase(entity)
		
		if grid[cell].is_empty():
			grid.erase(cell)

func updateEntity(entity : Node2D, lastPos : Vector2):
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

func getEntitiesUsingDist(pos : Vector2,radius : float):
	var results = []
	
	var topLeftCell = getCell(pos - (Vector2.ONE*radius) )
	var bottomRightCell = getCell(pos + (Vector2.ONE*radius) )
	
	for x in range(topLeftCell.x,bottomRightCell.x+1):
		for y in range(topLeftCell.y,bottomRightCell.y + 1):
			var cell = Vector2i(x,y)
						
			if grid.has(cell):
				results.append_array(grid[cell])
	
	return results
