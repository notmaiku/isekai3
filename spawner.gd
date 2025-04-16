extends Node

@onready var player :CharacterBody3D= %Player


func _on_player_spawn_me(_location):
	var loc = _location if _location is int else int(_location)
	player.position = get_child(loc).position
	player.up_direction = Vector3.UP
