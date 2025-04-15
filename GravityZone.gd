# RightAngleFlip.gd
extends Area3D

# Threshold to avoid rotating if already very close to the target orientation.
const ANGLE_THRESHOLD: float = 0.001
# Small value for floating point comparisons
const EPSILON: float = 0.0001
const WORLD_UP: Vector3 = Vector3(0.0, 1.0, 0.0)
@export var grav := -30.0

signal global_timer_start

var body_exited_zone = true

func _process(delta):
	if !body_exited_zone:
		Refs._on_global_timer_start()

# This function is called automatically when a PhysicsBody3D enters the Area3D,
# provided the signal is connected (see instructions above).
func _on_body_entered(body: CharacterBody3D) -> void:
	# Check if the entering body is a PhysicsBody3D (like RigidBody3D, CharacterBody3D)
	if body is CharacterBody3D:
		Refs._on_global_timer_start()
		body_exited_zone = false
		# Use the Area3D's negative Z-axis (forward) as the target up direction for the body
		var target_up_direction: Vector3 = -global_transform.basis.x.normalized()
		flip_direction(target_up_direction, body)


# Rotates the 'body' so its local up direction aligns with 'new_up_direction'.
func flip_direction(new_up_direction: Vector3, body: CharacterBody3D) -> void:
	# Get the body's current up direction in global space.
	var current_up_direction: Vector3 = body.global_transform.basis.y.normalized()

	# Calculate the angle between the current up and the target up direction.
	var angle_between: float = current_up_direction.angle_to(new_up_direction)

	# If the angle is very small, don't bother rotating.
	if angle_between < ANGLE_THRESHOLD:
		return

	var rotation_axis: Vector3
	# Check if vectors are nearly anti-parallel (angle close to PI)
	if abs(angle_between - PI) < ANGLE_THRESHOLD:
		# Cross product is near zero, so find an arbitrary perpendicular axis.
		# Try crossing with global UP.
		rotation_axis = current_up_direction.cross(Vector3.UP)
		# If current_up was parallel to global UP, cross product is zero.
		# In that case, cross with global RIGHT instead.
		if rotation_axis.length_squared() < EPSILON:
			rotation_axis = current_up_direction.cross(Vector3.RIGHT)
		# Normalize the chosen axis
		rotation_axis = rotation_axis.normalized()
	else:
		# Standard case: Calculate the rotation axis using the cross product.
		rotation_axis = current_up_direction.cross(new_up_direction)
		body.up_direction = new_up_direction
		# Normalize the axis (important for quaternion creation)
		# Check length_squared first to avoid normalizing a zero vector if they are parallel
		if rotation_axis.length_squared() > EPSILON:
			rotation_axis = rotation_axis.normalized()
		else:
			# Vectors are parallel (angle is near 0), already handled by ANGLE_THRESHOLD check.
			# No rotation needed.
			return

	# Create the rotation quaternion around the calculated axis by the calculated angle.
	var rotation_difference := Quaternion(rotation_axis, angle_between)

	# Apply the rotation difference to the body's current rotation.
	# Quaternion multiplication order matters: new_rotation = delta * old_rotation
	body.quaternion = rotation_difference * body.quaternion


func _on_body_exited(body: CharacterBody3D):
	#if body is CharacterBody3D:
		# Use the Area3D's negative Z-axis (forwkuard) as the target up direction for the body
		# flip_direction(WORLD_UP, body)
		#if Refs.timer_stopped:
			#body.rotation = Vector3.ZERO	
			#body._gravity = 0.0
	body_exited_zone = true
	if !Refs.timer_stopped && body_exited_zone:
			Refs.exited_gravity_zone = true
			body.rotation = Vector3.ZERO	
	return
