extends Button

@onready var spawner :Node= %Spawner

func _pressed():
	spawner._on_player_spawn_me(self.name)
