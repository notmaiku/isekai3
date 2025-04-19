extends Button

@onready var player = $"../../../.."

func _pressed():
	Refs._spawn_player(self.name, player)
