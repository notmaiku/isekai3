extends Area3D
@onready var finished_ui = preload("res://finish.tscn")

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(_body: Node3D) -> void:
	add_child(finished_ui.instantiate())
	get_tree().root.find_child("UI", true, false).hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
