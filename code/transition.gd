@tool
extends CanvasItem

@export var dt = 0.0:
	set(val):
		dt = val
		queue_redraw()

func _draw():
	draw_line(Vector2(0,648/2),Vector2(1152 * pingpong(dt,0.5) * 2,(648/2)),Color("000000ff"),400)
	draw_line(Vector2(1152,0),Vector2(1152 - (1152 * pingpong(dt,0.5) * 2 ),0),Color("00c2feff"),250)
	draw_line(Vector2(1152,648),Vector2(1152 - (1152 * pingpong(dt,0.5) * 2 ),648),Color("0400ceff"),250)


	
