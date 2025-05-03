extends MultiplayerSynchronizer

@export var _position:Vector3:
	set(val):
		if is_multiplayer_authority():
			_position = val
		else:
			get_parent().position = val
