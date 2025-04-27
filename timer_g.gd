extends Timer

var stop_grav

func _ready():
	$"/root/Refs".connect("start_timerg", _on_refs_start_timerg)
	$"/root/Refs".connect("stop_timerg", _on_refs_stop_timerg)
	
func _on_refs_start_timerg():
	#print('started timer')
	start()
	
func _on_refs_stop_timerg():
	Refs.timer_stopped = true
	stop()

func timeout():
	Refs.exited_gravity_zone = true
	Refs.timer_stopped = true
	$"../..".flip_player()
	
#func _process(delta: float) -> void:
	#print(time_left)
