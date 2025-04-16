extends Timer

var stop_grav

func _ready():
	$"/root/Refs".connect("start_timerg", _on_refs_start_timerg)
	$"/root/Refs".connect("stop_timerg", _on_refs_stop_timerg)
	
func _on_refs_start_timerg():
	start()
	
func _on_refs_stop_timerg():
	Refs.timer_stopped = true
	stop()
