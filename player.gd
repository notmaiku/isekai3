extends CharacterBody3D

@export_group("Movement")
@export var move_speed := 8.0
@export var acceleration := 20.0
@export var rotation_speed := 12.0
@export var jump_impulse := 12.0

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export var tilt_upper_limit := PI / 3.0
@export var tilt_lower_limit := -PI / 8.0

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
@export var _gravity := -15.0

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: Node3D = %GobotSkin

signal spawn_me

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("reset"):
		spawn_me.emit(0)
		

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
	
	if Refs.timer_stopped && Refs.exited_gravity_zone:
		up_direction = Vector3.UP

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
			
			



func _on_timer_g_reset_velo():
	velocity = Vector3.ZERO
	up_direction = Vector3.UP
