extends Button

func _pressed():
	Refs.checkpoint = 0
	var local_player = get_local_player()
	print('called pressed', local_player)
	if local_player:
		Refs._spawn_player(0, local_player, true)
	else:
		print("No local player found!")
	get_tree().root.find_child("FINISH", true, false).hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func get_local_player():
	for p in get_tree().get_nodes_in_group("players"):
		if p.is_multiplayer_authority():
			return p
	return null
