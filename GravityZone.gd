extends Area3D

const EPSILON: float = 0.0001
const WORLD_UP: Vector3 = Vector3(0.0, 1.0, 0.0)

var body_exited_zone = true
@export var use_x_or_z: String = 'x' 

var colors = [
	"red",
	"green"
]

func _ready():
	if Refs.player_group == 'green':
		$"../StaticBody3D".hide()

func _process(_delta):
	if !body_exited_zone:
		Refs._on_global_timer_start()
		
func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		if body.get_groups().size() > 0 && get_parent().get_groups().size() > 0 && !is_correct_group_platform(body.get_groups(), get_parent().get_groups()):
			get_parent_node_3d().hide()
			$"../StaticBody3D".collision_layer = 0
		Refs._on_global_timer_start()
		var target_up_direction: Vector3
		if use_x_or_z == 'x':
			target_up_direction = - global_transform.basis.x.normalized()
		else:
			target_up_direction = - global_transform.basis.z.normalized()
		Refs.flip_direction(target_up_direction, body)
		body.up_direction = target_up_direction

func _on_body_exited(body: Node3D):
	if body is CharacterBody3D:
		if body.get_slide_collision_count() > 0: return
		Refs.exited_gravity_zone = true

func is_correct_group_platform(player_groups, platform_groups):
	var player_color = player_groups.filter(func(c): return colors.has(str(c)))
	var platform_color = platform_groups.filter(func(c): return colors.has(str(c)))
	return platform_color == player_color
