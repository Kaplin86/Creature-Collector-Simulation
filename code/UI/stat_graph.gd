@tool
extends Control
class_name StatGraphDisplay

## A hexagonal graph that can display 6 numbers at once.

## A set pixel padding around the control node. I recommend keeping this at the default 52, that way the numbers fit cleanly inside.
@export var padding = 52:
	set(val):
		padding = val
		queue_redraw()


var _BGpolygonPositions = [ #pieces to draw a hexacomb
	Vector2(0,-1), # top
	Vector2(1,-0.5), # top right
	Vector2(1,0.5),
	Vector2(0,1),
	Vector2(-1,0.5),
	Vector2(-1,-0.5)
]

## The various stat types.
enum StatTypes {HP,ATK,DEF,SpA,SpD,SP}

## The current stat block to render.
@export var CurrentStatblock : Dictionary[StatTypes,int]= {
	StatTypes.HP: 394,
	StatTypes.ATK: 350,
	StatTypes.DEF: 125,
	StatTypes.SP: 150,
	StatTypes.SpA: 50,
	StatTypes.SpD: 270
}:
	set(val):
		CurrentStatblock = val
		queue_redraw()

## The maximum values for each stat.
@export var CurrentStatblockMAX : Dictionary[StatTypes,int]= {
	StatTypes.HP: 400,
	StatTypes.ATK: 350,
	StatTypes.DEF: 300,
	StatTypes.SP: 300,
	StatTypes.SpA: 300,
	StatTypes.SpD: 300
}:
	set(val):
		CurrentStatblockMAX = val
		queue_redraw()



func _draw():
	var accountedPolyPoints : PackedVector2Array = []
	var polyToPos = {}
	for I in _BGpolygonPositions:
		var newPos = Vector2.ZERO
		newPos.x = (inverse_lerp(-1,1,I.x) * ( size.x - padding)) + padding / 2.0
		newPos.y = (inverse_lerp(-1,1,I.y) * ( size.y - padding)) + padding / 2.0
		polyToPos[I] = newPos
		accountedPolyPoints.append(newPos)
	draw_colored_polygon(accountedPolyPoints,Color.REBECCA_PURPLE)
	
	
	
	var statPoints : PackedVector2Array = []
	var count = -1
	for I in _BGpolygonPositions:
		count += 1
		var currentStatPercent = inverse_lerp(0,CurrentStatblockMAX[count],CurrentStatblock[count])
		var currentStatPos = lerp(Vector2.ONE * 0.5 * size,polyToPos[I],currentStatPercent)
		statPoints.append(currentStatPos)
	draw_colored_polygon(statPoints,Color.AQUAMARINE)
	
	
	count = -1
	for I in _BGpolygonPositions:
		count += 1
		draw_string_outline(ThemeDB.fallback_font,polyToPos[I] - Vector2(100,0),StatTypes.find_key(count),HORIZONTAL_ALIGNMENT_CENTER,200,16,10,Color.BLACK)
		draw_string(ThemeDB.fallback_font,polyToPos[I] - Vector2(100,0),StatTypes.find_key(count),HORIZONTAL_ALIGNMENT_CENTER,200)
		
		draw_string_outline(ThemeDB.fallback_font,polyToPos[I] - Vector2(100,-20),str(CurrentStatblock[count]),HORIZONTAL_ALIGNMENT_CENTER,200,16,10,Color.BLACK)
		draw_string(ThemeDB.fallback_font,polyToPos[I] - Vector2(100,-20),str(CurrentStatblock[count]),HORIZONTAL_ALIGNMENT_CENTER,200)
		
	
	for I in _BGpolygonPositions:
		draw_line(Vector2.ONE * 0.5 * size,polyToPos[I],Color(0.0, 0.0, 0.141, 0.055),2)

func _get_minimum_size():
	return Vector2.ONE * 135

## Sets the [member CurrentStatblock] based on a [BodyPart]
func setCurrentBlockFromPart(bodyPart : BodyPart) -> void:
	for I : String in bodyPart.stats:
		CurrentStatblock[StatTypes.get(I)] = bodyPart.get(I)
	 
