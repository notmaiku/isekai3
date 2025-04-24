extends Button

func _pressed():
	var local_player = get_local_player()
	print('called pressed', local_player)
	if local_player:
		Refs._spawn_player(self.name, local_player, true)
	else:
		print("No local player found!")

func get_local_player():
	for p in get_tree().get_nodes_in_group("players"):
		if p.is_multiplayer_authority():
			return p
	return null
