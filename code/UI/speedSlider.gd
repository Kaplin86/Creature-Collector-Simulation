extends HSlider



func _on_value_changed(value):
	Engine.time_scale = value
	$"../Label".text = "SPEED - " + str(snapped(value,0.5))
