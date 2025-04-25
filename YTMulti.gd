extends Node

@export var player_scene: PackedScene

const DEFAULT_PORT = 6969

var players = {}

@onready var host_button: Button = $Net/Options/HostButton
@onready var join_button: Button = $Net/Options/JoinButton
@onready var remote: TextEdit = $Net/Options/Remote

var upnp_node := UPNP.new()
var upnp_mapped := false

func _ready():
	# Multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	if player_scene == null:
		push_error("MultiplayerManager: Player Scene is not set! Assign Player.tscn in the editor.")

	remote.text = "68.100.94.109"

func _on_host_pressed():
	print("Starting server...")
	_disable_buttons()

	# --- UPnP Logic ---
	var discover_result = upnp_node.discover()
	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
		print("UPnP discovery successful.")
		var map_result_udp = upnp_node.add_port_mapping(DEFAULT_PORT, DEFAULT_PORT, "godot_udp", "UDP", 0)
		var map_result_tcp = upnp_node.add_port_mapping(DEFAULT_PORT, DEFAULT_PORT, "godot_tcp", "TCP", 0)
		if map_result_udp == UPNP.UPNP_RESULT_SUCCESS or map_result_tcp == UPNP.UPNP_RESULT_SUCCESS:
			upnp_mapped = true
			print("UPnP port mapping successful!")
			var external_ip = upnp_node.query_external_address()
			print("Your external IP is: ", external_ip)
			remote.text = external_ip
		else:
			print("UPnP port mapping failed! You may need to set up manual port forwarding.")
	else:
		print("UPnP discovery failed! You may need to set up manual port forwarding.")

	# --- ENet Peer Creation ---
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT)
	if error != OK:
		printerr("Failed to create server: ", error)
		return

	multiplayer.multiplayer_peer = peer
	print("Server started on port ", DEFAULT_PORT)

	# Host always spawns itself as player 1
	add_player(1)

func _on_join_pressed():
	print("Joining server...", remote.text)
	_disable_buttons()

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(remote.text, DEFAULT_PORT)
	if error != OK:
		printerr("Failed to create client: ", error)
		_enable_buttons()
		return

	multiplayer.multiplayer_peer = peer
	# Client player spawning is handled by the server via RPC

# --- Multiplayer Signal Handlers ---
func _on_peer_connected(id):
	print("Peer connected: ", id)
	# Only the server should handle spawning players
	if multiplayer.is_server():
		# Tell all peers to add the new player
		rpc("add_player", id)
		# Tell the new peer to add all existing players
		for existing_id in players:
			if existing_id != id:
				rpc_id(id, "add_player", existing_id)
	_disable_buttons()

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id, " at ", Time.get_datetime_string_from_system())
	print("Players before removal: ", players.keys())
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
	print("Players after removal: ", players.keys())
	if multiplayer.is_server():
		rpc("remove_player", id)

func _on_connected_to_server():
	print("Successfully connected to server!")

func _on_connection_failed():
	printerr("Connection failed!")
	multiplayer.multiplayer_peer = null
	_enable_buttons()

func _on_server_disconnected():
	print("Disconnected from server!")
	multiplayer.multiplayer_peer = null
	_enable_buttons()
	for id in players:
		players[id].queue_free()
	players.clear()

# --- RPC Functions ---
@rpc("any_peer", "call_local", "reliable")
func add_player(id):
	if player_scene == null:
		printerr("Cannot add player: Player Scene is null.")
		return
	if players.has(id):
		print("Player %d already exists. Skipping spawn." % id)
		return

	print("Adding player: ", id)
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id)
	randomize()  # Seeds the random number generator

	if randi() % 2 == 0:
		add_to_group("green")
	else:
		add_to_group("red")
	player_instance.add_to_group('players')
	player_instance.set_multiplayer_authority(id)
	players[id] = player_instance
	add_child(player_instance)
	print("Player node name:", player_instance.name, 
		"Authority:", player_instance.get_multiplayer_authority(), 
		"My peer id:", multiplayer.get_unique_id())
	_disable_buttons()

@rpc("any_peer", "call_remote", "unreliable_ordered")
func remove_player(id):
	print("Removing player: ", id)
	if players.has(id):
		players[id].queue_free()
		players.erase(id)

# --- UI Helpers ---
func _disable_buttons():
	host_button.hide()
	join_button.hide()
	remote.hide()

func _enable_buttons():
	host_button.disabled = false
	join_button.disabled = false
	remote.show()

# --- Cleanup ---
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Remove UPnP mapping if it was set
		if upnp_mapped:
			upnp_node.delete_port_mapping(DEFAULT_PORT, "UDP")
			upnp_node.delete_port_mapping(DEFAULT_PORT, "TCP")
			print("UPnP port mapping removed.")
		if multiplayer.multiplayer_peer != null:
			multiplayer.multiplayer_peer.close()
			multiplayer.multiplayer_peer = null
			print("Multiplayer peer closed.")
