extends MeshInstance3D

var red = preload("res://red.tres")
var green = preload("res://green.tres")

var colors = {
	"red": red,
	"green": green
}

#
func _ready():
	var has_groups = get_groups().size() > 0
	if has_groups:
		material_override =  colors[get_groups().filter(func(group): return colors.has(group))[0]]
	
