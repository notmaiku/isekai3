extends Area3D

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body: CharacterBody3D):
	Refs._spawn_player(Refs.checkpoint,  body, 'die')

func get_local_player():
	for p in get_tree().get_nodes_in_group("players"):
		if p.is_multiplayer_authority():
			return p
	return null
