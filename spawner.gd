extends Node

func _ready():
	$"/root/Refs".connect("spawn_player", _on_player_spawn_me)
	

func _on_player_spawn_me(_location, player, name):
	print("player signal", player)
	if player is not CharacterBody3D: return
	var loc = _location if _location is int else int(_location)
	var new_pos = get_child(loc).get("position")
	print('is authority?', player.is_multiplayer_authority())
	print(get_tree().get_nodes_in_group("player").filter(func(p): p == name))
	player.position = new_pos
	player.up_direction = Vector3.UP
