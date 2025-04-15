extends Node

@onready var player :CharacterBody3D= %Player


func _on_player_spawn_me(location):
	print("called spawn")
	player.position = get_child(location).position
