extends Node

@export var player: CharacterBody3D
@export var rotation: float


func _ready() -> void:
	player.rotate_y(deg_to_rad(rotation))
