extends Node

# Export the player scene so you can assign it in the editor
@export var player_scene: PackedScene

const DEFAULT_PORT = 7777
const DEFAULT_ADDRESS = "127.0.0.1" # localhost

# Dictionary to store player nodes, keyed by peer ID
var players = {}

# References to UI buttons (adjust paths if needed)
@onready var host_button: Button = $UI/Net/Options/JoinButton
@onready var join_button: Button = $UI/Net/Options/HostButton

func _ready():
	# --- Connect Signals ---
	# Multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


	# Ensure player scene is assigned
	if player_scene == null:
		push_error("MultiplayerManager: Player Scene is not set! Assign Player.tscn in the editor.")


# --- Button Callbacks ---
func _on_host_pressed():
	print("Starting server...")
	_disable_buttons()

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT)

	if error != OK:
		printerr("Failed to create server: ", error)
		_enable_buttons()
		return

	multiplayer.multiplayer_peer = peer
	print("Server started on port ", DEFAULT_PORT)

	# Add the host's own player
	add_player(multiplayer.get_unique_id())


func _on_join_pressed():
	print("Joining server...")
	_disable_buttons()

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_ADDRESS, DEFAULT_PORT)

	if error != OK:
		printerr("Failed to create client: ", error)
		_enable_buttons()
		return

	multiplayer.multiplayer_peer = peer
	print("Joining %s:%s..." % [DEFAULT_ADDRESS, DEFAULT_PORT])
	# Client player spawning is handled by the server via RPC


# --- Multiplayer Signal Handlers ---
func _on_peer_connected(id):
	print("Peer connected: ", id)
	# This signal runs on the server when a client connects,
	# and on clients when another client connects (if server relays).
	# The server is responsible for spawning players.
	if multiplayer.is_server():
		# Tell the newly connected peer (id) to spawn itself
		rpc_id(id, "add_player", id)

		# Tell the newly connected peer about all existing players (incl. host)
		for existing_id in players:
			rpc_id(id, "add_player", existing_id)

		# Tell all *other* peers about the new peer
		# Note: rpc() sends to all peers *except* the sender.
		# Since the server is the sender here, it won't call add_player on itself again.
		rpc("add_player", id)


func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	if players.has(id):
		players[id].queue_free() # Remove the node from the scene
		players.erase(id)       # Remove from our tracking dictionary

		# If we are the server, tell remaining clients to remove this player
		if multiplayer.is_server():
			rpc("remove_player", id)


func _on_connected_to_server():
	print("Successfully connected to server!")
	# The server will now tell us (via RPC) which players to spawn, including our own.


func _on_connection_failed():
	printerr("Connection failed!")
	multiplayer.multiplayer_peer = null # Reset peer
	_enable_buttons()


func _on_server_disconnected():
	print("Disconnected from server!")
	multiplayer.multiplayer_peer = null # Reset peer
	_enable_buttons()
	# Clean up all player nodes
	for id in players:
		players[id].queue_free()
	players.clear()


# --- RPC Functions ---

# Called by the server on all peers (including itself via call_local)
# to spawn a player instance.
@rpc("any_peer", "call_local", "reliable")
func add_player(id):
	if player_scene == null:
		printerr("Cannot add player: Player Scene is null.")
		return
	# Prevent adding duplicates if messages arrive weirdly
	if players.has(id):
		print("Player %d already exists. Skipping spawn." % id)
		return

	print("Adding player: ", id)
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id) # Set node name to peer ID

	# *** IMPORTANT: Set network authority ***
	# This tells Godot which peer controls this node.
	player_instance.set_multiplayer_authority(id)

	players[id] = player_instance # Track the player node
	add_child(player_instance)    # Add to the scene tree


# Called by the server on clients to remove a player node.
@rpc("any_peer", "call_remote", "unreliable_ordered") # Don't call on server itself
func remove_player(id):
	print("Removing player: ", id)
	if players.has(id):
		players[id].queue_free()
		players.erase(id)


# --- UI Helpers ---
func _disable_buttons():
	host_button.disabled = true
	join_button.disabled = true

func _enable_buttons():
	host_button.disabled = false
	join_button.disabled = false


# --- Cleanup ---
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Gracefully close connection when closing the game window
		if multiplayer.multiplayer_peer != null:
			multiplayer.multiplayer_peer.close()
			multiplayer.multiplayer_peer = null
			print("Multiplayer peer closed.")
