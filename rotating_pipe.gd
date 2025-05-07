extends Node3D

@export var animator: AnimationPlayer
@export var speed: float = 1 
@export var animation_name: String

func _ready():
	animator.play(animation_name)
	animator.speed_scale = speed
