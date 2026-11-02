extends CanvasLayer

func transition(toNode):
	var tween = create_tween()
	tween.tween_property($Node2D,"dt",0.5,0.5)
	await get_tree().create_timer(0.52).timeout
	tween =  create_tween()
	get_tree().change_scene_to_node(toNode)
	tween.tween_property($Node2D,"dt",0,0.5)
