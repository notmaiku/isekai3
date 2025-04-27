extends Area3D

const EPSILON: float = 0.0001
const WORLD_UP: Vector3 = Vector3(0.0, 1.0, 0.0)

var body_exited_zone = true
@export var use_x_or_z: String = 'x'

var colors = [
	"red",
	"green"
]

var check_timer: Timer

var platform

func _ready():
	platform = $".."
	if Refs.player_group == 'green':
		$"../StaticBody3D".hide()

func _process(_delta):
	var bodies = get_overlapping_bodies()
	var found = false
	for body in bodies:
		if body is CharacterBody3D:
			found = true
			break
	if found:
		Refs.exited_gravity_zone = false
		Refs._on_global_timer_start()
	else:
		Refs.exited_gravity_zone = true
		
func _on_body_entered(body: Node3D) -> void:
	if !body.is_multiplayer_authority(): return
	var player = get_local_player()
	if body is CharacterBody3D:
		var obj = get_parent().get_parent()
		var obj_groups = obj.get_groups()
		if obj_groups.size() > 1 && not obj_groups[1] in body.get_groups():
			remove_platform(body, obj)
		Refs._on_global_timer_start()
		var target_up_direction: Vector3
		if use_x_or_z == 'x':
			target_up_direction = - global_transform.basis.x.normalized()
		else:
			target_up_direction = - global_transform.basis.z.normalized()
		Refs.flip_direction(target_up_direction, body)
		body.up_direction = target_up_direction


func remove_platform(body, obj_hide):
	get_parent().get_child(1).collision_layer = 0
	get_parent().get_parent().hide()
	body.rpc("HideObject", obj_hide.name)
	await get_tree().create_timer(1.5).timeout
	obj_hide.show()
	obj_hide.get_child(0).get_child(1).collision_layer = 1


func _on_body_exited(body: Node3D):
	if body is CharacterBody3D:
		Refs.exited_gravity_zone = true

func is_correct_group_platform(player_groups, platform_groups):
	var player_color = player_groups.filter(func(c): return colors.has(str(c)))
	var platform_color = platform_groups.filter(func(c): return colors.has(str(c)))
	return platform_color == player_color


func _on_timer_timeout() -> void:
	platform.hide()
	$"../Gravity".collision_layer = 1
	
@rpc("any_peer", "call_remote", "reliable")
func get_local_player():
	for p in get_tree().get_nodes_in_group("players"):
		if p.is_multiplayer_authority():
			return p
	return null
