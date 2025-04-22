extends Node

func _ready():
	$"/root/Refs".connect("spawn_player", _on_player_spawn_me)
	

func _on_player_spawn_me(_location, player):
	var loc = _location if _location is int else int(_location)
	var new_pos = get_child(loc).get("position")
	player.position = new_pos
	player.up_direction = Vector3.UP
