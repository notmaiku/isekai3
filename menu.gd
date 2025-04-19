extends Control

func _on_refs_show_menu():
	if visible:
		hide()
	else:
		show()
