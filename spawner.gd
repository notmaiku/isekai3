extends Node

func _ready():
	$"/root/Refs".connect("spawn_player", _on_player_spawn_me)
	
	
func _on_player_spawn_me(_location, player: CharacterBody3D, die):
	var uid = multiplayer.get_unique_id()
	var loc = _location if _location is int else int(_location)
	var new_pos = get_child(loc).get("position")
	var players = get_tree().get_nodes_in_group("players")
	var multi_p = players.find(get_instance_id())
	if die:
		player.TeleportPlayerLocal(new_pos)
	if die: return
	player.rpc_id(player.get_multiplayer_authority(), "TeleportPlayerRemote", new_pos)

func teleport_player(player, new_position, local = true):
	player.rotation = Vector3.UP
	player.velocity = Vector3.ZERO
	if player.is_multiplayer_authority() || local:
		print("Calling TeleportPlayerLocal on", player.name)
		player.TeleportPlayerLocal(new_position)
	else:
		print("Calling TeleportPlayerRemote via rpc_id to", player.get_multiplayer_authority())
		player.rpc_id(player.get_multiplayer_authority(), "TeleportPlayerRemote", new_position)
