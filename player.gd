extends CharacterBody3D


const SPEED = 10.0

func get_input_direction() -> Vector3:
	var direction = Vector3.ZERO
	if Input.is_action_pressed("forward"):
		direction.z += 1
	if Input.is_action_pressed("backward"):
		direction.z -= 1
	if Input.is_action_pressed("right"):
		direction.x -= 1
	if Input.is_action_pressed("left"):
		direction.x += 1
	return direction.normalized()

func _physics_process(delta: float) -> void:
	var direction := get_input_direction()
	velocity = direction * SPEED
	move_and_slide()


# Rotation speed in radians per second
var rotation_speed = 2.0

func _process(delta):
	# Check if Q is pressed (rotate counter-clockwise)
	if Input.is_action_pressed("rotate_left"):
		rotate_y(-rotation_speed * delta)

	# Check if E is pressed (rotate clockwise)
	if Input.is_action_pressed("rotate_right"):
		rotate_y(rotation_speed * delta)
