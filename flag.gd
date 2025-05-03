extends Area3D

func _on_body_entered(_body: CharacterBody3D) -> void:
	Refs.checkpoint = owner.name.to_int()
