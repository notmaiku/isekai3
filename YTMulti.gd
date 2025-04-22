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
		print(map_result_tcp, 'did work? or ')
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
		#_enable_buttons()
		return

	multiplayer.multiplayer_peer = peer
	print("Server started on port ", DEFAULT_PORT)
	add_player(multiplayer.get_unique_id())

func _on_join_pressed():
	print("Joining server...", remote.text)
	_disable_buttons()

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(remote.text, DEFAULT_PORT)
	if error != OK:
		printerr("Failed to create client: ", error)
		_enable_buttons()
		return
	_disable_buttons()

	multiplayer.multiplayer_peer = peer
	# Client player spawning is handled by the server via RPC

# --- Multiplayer Signal Handlers ---
func _on_peer_connected(id):
	print("Peer connected: ", id)
	rpc("add_player", id)
	for existing_id in players:
		rpc_id(id, "add_player", existing_id)
	rpc("add_player", id)
	_disable_buttons()

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
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
	if id == 1:
		player_instance.add_to_group('red')
	else:
		player_instance.add_to_group('green')
	player_instance.add_to_group('players')
	print('add player groups: ', player_instance.get_groups())
	player_instance.set_multiplayer_authority(id)
	players[id] = player_instance
	add_child(player_instance)
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
