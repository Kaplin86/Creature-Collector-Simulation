extends Button


func _on_pressed():
	Transition.transition(load("res://startMenu.tscn").instantiate())
