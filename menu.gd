extends Control

func _on_refs_show_menu():
	if visible:
		hide()
	else:
		show()

func _process(delta: float) -> void:
	var unhide_levels = get_children()[0].get_children().filter(func(level): return int(level.name) == Refs.checkpoint)
	for level in unhide_levels:
		level.show()
