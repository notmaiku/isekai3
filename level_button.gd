extends Button


func _pressed():
	Refs._spawn_player(self.name)
