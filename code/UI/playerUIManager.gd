extends CanvasLayer

func render(player : Player):
	for C in %PartyArea.get_children(): C.queue_free()
	for creature : Agent in player.party:
		print(creature)
