extends Area3D

const EPSILON: float = 0.0001
const WORLD_UP: Vector3 = Vector3(0.0, 1.0, 0.0)

signal global_timer_start
var body_exited_zone = true

func _ready():
	print(await Refs.player_group)
	if Refs.player_group == 'green':
		$"../StaticBody3D".hide()

func _process(_delta):
	if !body_exited_zone:
		Refs._on_global_timer_start()
		
func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		if body.get_groups().size() > 0 && get_groups().size() > 0  && body.get_groups()[0] != get_groups()[0]:
			print('enter')
			get_parent_node_3d().hide()
			$"../StaticBody3D".queue_free()
		Refs._on_global_timer_start()
		var target_up_direction: Vector3 = -global_transform.basis.x.normalized()
		Refs.flip_direction(target_up_direction, body)
		body.up_direction = target_up_direction

func _on_body_exited(body: Node3D):
	if body.get_slide_collision_count() > 0: return
	if body is CharacterBody3D:
		Refs.exited_gravity_zone = true 
