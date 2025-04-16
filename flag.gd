extends Area3D

signal _change_respawn

func _on_body_entered(body: CharacterBody3D) -> void:
	Refs.checkpoint = owner.name.to_int()
