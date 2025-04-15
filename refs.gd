extends Node

signal reset_velo
signal global_timer_timeout
signal start_timerg
signal stop_timerg
signal reset_timerg

var timer_stopped = true
var exited_gravity_zone = true

func _on_global_timer_start():
	emit_signal("start_timerg")
	timer_stopped = false
	exited_gravity_zone = false

func _on_timer_g_timeout():
	timer_stopped = true
	emit_signal("stop_timerg")
	print("timer stopped")

func _on_reset_timer():
	emit_signal("reset_timerg")
