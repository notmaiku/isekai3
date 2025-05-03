extends Label

func _ready():
	var fps = Engine.get_frames_per_second()
	# Update the label's text to display the FPS, formatted to 1 decimal place
	text = "FPS: " + str(fps).pad_decimals(1)
