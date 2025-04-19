extends Node

func _ready():
	$"/root/Refs".connect("spawn_player", _on_player_spawn_me)

func _on_player_spawn_me(_location, player):
	var loc = _location if _location is int else int(_location)
	print(get_child(loc).get("position"))
	player.position = get_child(loc).get("position")
	player.up_direction = Vector3.UP
