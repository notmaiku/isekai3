extends Control

func _on_refs_show_menu():
	print('notowokring')
	if visible:
		hide()
	else:
		show()
