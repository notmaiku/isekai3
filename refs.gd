extends Node

signal reset_velo
signal global_timer_timeout
signal start_timerg
signal stop_timerg
signal reset_timerg
signal spawn_player

var timer_stopped = true
var exited_gravity_zone = true
var checkpoint = 1
const EPSILON: float = 0.0001
var player_group
var player_id
@export var World: PackedScene

var mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_global_timer_start():
	emit_signal("start_timerg")
	timer_stopped = false
	exited_gravity_zone = false

func _on_timer_g_timeout():
	emit_signal("stop_timerg")

func _on_reset_timer():
	emit_signal("reset_timerg")
	
func _spawn_player(location, player, is_author = true):
	print('spawnplayer: ', player)
	emit_signal("spawn_player", location, player, is_author)



func flip_direction(new_up_direction: Vector3, body: CharacterBody3D) -> void:
	var current_up_direction: Vector3 = body.global_transform.basis.y.normalized()
	# print("Current Up: ", current_up_direction)

	var angle_between: float = current_up_direction.angle_to(new_up_direction)
	# print("Angle Between: ", rad_to_deg(angle_between))
	print('called flip direction')

	var rotation_axis: Vector3
	if abs(angle_between - PI) < EPSILON:
		rotation_axis = current_up_direction.cross(Vector3.UP)
		if rotation_axis.length_squared() < EPSILON:
			rotation_axis = current_up_direction.cross(Vector3.RIGHT)
		if rotation_axis.length_squared() > EPSILON:
			rotation_axis = rotation_axis.normalized()
		else:
			rotation_axis = Vector3.FORWARD
	else:
		rotation_axis = current_up_direction.cross(new_up_direction)
		if rotation_axis.length_squared() > EPSILON:
			rotation_axis = rotation_axis.normalized()
		else:
			# print("Vectors nearly parallel, using fallback axis.")
			rotation_axis = current_up_direction.cross(Vector3.RIGHT)
			if rotation_axis.length_squared() < EPSILON:
				rotation_axis = current_up_direction.cross(Vector3.UP)
			if rotation_axis.length_squared() > EPSILON:
				rotation_axis = rotation_axis.normalized()
			else:
				rotation_axis = Vector3.FORWARD

	var rotation_difference := Quaternion(rotation_axis, angle_between)
	body.quaternion = rotation_difference * body.quaternion
