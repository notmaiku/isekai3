#extends Node3D

#var Player: CharacterBody2D
#var Camera: Camera3D
#
#
#
#func _ready() -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
 #
#
## Sensitivity of the mouse movement
#var mouse_sensitivity: float = 0.002
#
## Minimum and maximum vertical rotation (to prevent flipping)
#var min_vertical_angle: float = deg_to_rad(-90)
#var max_vertical_angle: float = deg_to_rad(90)
#
#
#
#func _input(e: InputEvent):
	#if e is InputEventMouse:
		#var xRot = clamp(rotation.x - e.relative.y / 200 * mouse_sensitivity, min_vertical_angle, max_vertical_angle)
		#var yRot = e.relative.y * mouse_sensitivity
		#rotation = Vector3(xRot, yRot, 0)
		#
extends Camera3D

@export var target: NodePath  # Path to the character node
@export var offset = Vector3(0, 2, -5)  # Camera offset behind and above the character
@export var smooth_speed = 0.1  # Smoothing factor for camera movement

var _target_node: Node3D

func _ready():
	_target_node = get_node(target)

func _process(delta):
	if _target_node:
		# Calculate the desired camera position
		var desired_position = _target_node.global_transform.origin + offset
		# Smoothly interpolate the camera position
		global_transform.origin = global_transform.origin.linear_interpolate(desired_position, smooth_speed)
		# Make the camera look at the character
		look_at(_target_node.global_transform.origin, Vector3.UP)
