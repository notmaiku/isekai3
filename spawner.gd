extends Node

@onready var player :CharacterBody3D= %Player


func _on_player_spawn_me(_location):
	player.position = get_child(_location).position
	player.up_direction = Vector3.UP
