extends CharacterBody3D

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var jump_impulse := 6.5

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := 180
@export var tilt_lower_limit := -180

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
@export var _gravity := -18.0

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: Node3D = %GobotSkin
@onready var ui = preload("res://ui.tscn")
@onready var timer_g: Timer = %Timer_G
@onready var cooldown: Timer = %Timer_C


var is_multi = true

func _enter_tree():
	set_multiplayer_authority(int(name))
	
func _ready() -> void:
	Refs.player_group = get_groups()[0]
	Refs.player_id = multiplayer.get_unique_id()
	_camera.current = is_multiplayer_authority()
	check_condition_every_second()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority(): return
	if event.is_action_pressed("ui_exit"):
		add_child(ui.instantiate()) if !get_node_or_null("UI") else get_node("UI").queue_free()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("reset"):
		if !is_multiplayer_authority(): return
		Refs._spawn_player(Refs.checkpoint, self)
		

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(
		_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit
	)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta

	_camera_input_direction = Vector2.ZERO

	if !is_multiplayer_authority(): return

	velocity += up_direction * _gravity * delta

	var raw_input := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction = move_direction.slide(up_direction).normalized()

	var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()

	var vertical_velocity_component := velocity.project(up_direction)
	var horizontal_velocity_component := velocity - vertical_velocity_component
	var target_horizontal_velocity := move_direction * move_speed

	horizontal_velocity_component = horizontal_velocity_component.move_toward(
		target_horizontal_velocity, acceleration * delta
	)

	velocity = horizontal_velocity_component + vertical_velocity_component

	if is_starting_jump:
		velocity = horizontal_velocity_component + up_direction * jump_impulse
	
	move_and_slide()

	Refs.exited_gravity_zone = true

	if move_direction.length_squared() > 0.01:
		_last_movement_direction = move_direction

	if _last_movement_direction.length_squared() > 0.01:
		var local_move_direction = transform.basis.inverse() * _last_movement_direction.normalized()
		var target_angle = Vector3.BACK.signed_angle_to(local_move_direction, Vector3.UP)
		_skin.rotation.y = lerp_angle(
			_skin.rotation.y, target_angle, rotation_speed * delta
		)

	var horizontal_velocity_for_anim := velocity - velocity.project(up_direction)
	var ground_speed := horizontal_velocity_for_anim.length()

	if is_starting_jump:
		_skin.jump()
	elif not is_on_floor() and velocity.dot(up_direction) < 0:
		_skin.fall()
	elif is_on_floor():
		if ground_speed > 0.1:
			_skin.run()
		else:
			_skin.idle()

func flip_player():
	Refs.flip_direction(Vector3.UP, self)

func _mouse_mode_change(_event):
	if !is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _player_spawner(loc):
	global_position = loc
	up_direction = Vector3.UP
	velocity = Vector3.ZERO


func check_condition_every_second() -> void:
	while true:
		await get_tree().create_timer(1.0).timeout
		if Refs.exited_gravity_zone && Refs.timer_stopped:
			up_direction = Vector3.UP
			Refs.flip_direction(Vector3.UP, self)

			
@rpc("any_peer", "call_remote", "reliable")
func HideObject(o_name: StringName):
	var obj_to_hide = Refs.find_node_by_name(get_tree().current_scene, o_name)
	obj_to_hide.hide()
	obj_to_hide.get_child(0).get_child(1).collision_layer = 0
	await get_tree().create_timer(1.5).timeout
	obj_to_hide.show()
	obj_to_hide.get_child(0).get_child(1).collision_layer = 1


@rpc("any_peer", "call_local", "reliable")
func TeleportPlayerLocal(new_position: Vector3) -> void:
	global_position = new_position
	velocity = Vector3.ZERO

@rpc("any_peer", "call_remote", "reliable")
func TeleportPlayerRemote(new_position: Vector3) -> void:
	global_position = new_position
	velocity = Vector3.ZERO
	
@rpc("authority", "call_local", "reliable")
func TeleportAuthority(new_position: Vector3) -> void:
	global_position = new_position
	velocity = Vector3.ZERO
