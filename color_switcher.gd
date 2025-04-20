extends MeshInstance3D

var red = preload("res://red.tres")
var green = preload("res://green.tres")

var colors = {
	"red": red,
	"green": green
}

#
func _ready():
	var has_groups = get_parent().get_groups().size() > 0
	if has_groups:
		material_override =  colors[get_parent().get_groups()[0]]
		set_surface_override_material(0, green)

	
