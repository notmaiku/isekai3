extends Control


@onready var spawner :Node= %Spawner

func _on_pressed(btn):
    print('pressed button')
    var level = btn.name
    spawner._on_player_spawn_me(level)
    