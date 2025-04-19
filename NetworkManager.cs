using Godot;
using System;
using System.Collections.Generic; // For Dictionary

public partial class NetworkManager : Node
{
	[Export] // Assign the Player.tscn scene in the Godot editor
	public PackedScene PlayerScene { get; set; }

	private const int DefaultPort = 7777; // Choose a port
	private const string DefaultAddress = "127.0.0.1"; // localhost

	// Keep track of player nodes using their peer ID as the key
	private Dictionary<long, Node> _players = new Dictionary<long, Node>();

	private Button _hostButton;
	private Button _joinButton;

	public override void _Ready()
	{
		// Get UI Nodes
		_hostButton = GetNode<Button>("HostButton"); // Adjust path if needed
		_joinButton = GetNode<Button>("JoinButton"); // Adjust path if needed

		// Connect button signals
		_hostButton.Pressed += OnHostButtonPressed;
		_joinButton.Pressed += OnJoinButtonPressed;

		// Connect multiplayer signals
		Multiplayer.PeerConnected += OnPeerConnected;
		Multiplayer.PeerDisconnected += OnPeerDisconnected;
		Multiplayer.ConnectedToServer += OnConnectedToServer;
		Multiplayer.ConnectionFailed += OnConnectionFailed;
		Multiplayer.ServerDisconnected += OnServerDisconnected;

		// Ensure PlayerScene is assigned
		if (PlayerScene == null)
		{
			GD.PushError("NetworkManager: PlayerScene is not set! Assign Player.tscn in the editor.");
		}
	}

	private void OnHostButtonPressed()
	{
		GD.Print("Starting server...");
		DisableButtons();

		var peer = new ENetMultiplayerPeer();
		Error error = peer.CreateServer(DefaultPort);

		if (error != Error.Ok)
		{
			GD.PrintErr($"Failed to create server: {error}");
			EnableButtons();
			return;
		}

		Multiplayer.MultiplayerPeer = peer;
		GD.Print("Server started on port " + DefaultPort);

		// Spawn the host's player immediately
		AddPlayer(Multiplayer.GetUniqueId());
	}

	private void OnJoinButtonPressed()
	{
		GD.Print("Joining server...");
		DisableButtons();

		var peer = new ENetMultiplayerPeer();
		Error error = peer.CreateClient(DefaultAddress, DefaultPort);

		if (error != Error.Ok)
		{
			GD.PrintErr($"Failed to create client: {error}");
			EnableButtons();
			return;
		}

		Multiplayer.MultiplayerPeer = peer;
		GD.Print($"Joining {DefaultAddress}:{DefaultPort}...");
		// Player spawning for the client is handled in OnConnectedToServer
		// and via RPC from the server in OnPeerConnected
	}

	private void DisableButtons()
	{
		_hostButton.Disabled = true;
		_joinButton.Disabled = true;
	}

	private void EnableButtons()
	{
		_hostButton.Disabled = false;
		_joinButton.Disabled = false;
	}

	// --- Multiplayer Signal Handlers ---

	private void OnPeerConnected(long id)
	{
		GD.Print($"Peer connected: {id}");
		// This signal is only emitted on the server (and clients for other clients).
		// The server is responsible for spawning players for new clients.
		if (Multiplayer.IsServer())
		{
			// Tell the new client to spawn itself
			RpcId(id, nameof(AddPlayer), id);

			// Tell the new client about all existing players (including the host)
			foreach (var kvp in _players)
			{
				RpcId(id, nameof(AddPlayer), kvp.Key);
			}

			// Tell all *other* clients about the *new* client
			Rpc(nameof(AddPlayer), id); // RPC sends to all peers *except* the target of RpcId and the sender
		}
	}

	private void OnPeerDisconnected(long id)
	{
		GD.Print($"Peer disconnected: {id}");
		if (_players.TryGetValue(id, out Node playerNode))
		{
			playerNode.QueueFree(); // Remove the player node
			_players.Remove(id);

			// Tell remaining clients to remove this player
			// Ensure this RPC exists if you want clients to despawn others
			if (Multiplayer.IsServer())
			{
				 Rpc(nameof(RemovePlayer), id);
			}
		}
	}

	private void OnConnectedToServer()
	{
		GD.Print("Successfully connected to server!");
		// The server will tell us (via RPC) which players to spawn, including our own.
		// We request our own player spawn here just in case the server's PeerConnected signal
		// fires before we are fully ready, though AddPlayer(Multiplayer.GetUniqueId()) on the server
		// in OnPeerConnected should handle the primary spawning logic.
		// RpcId(1, nameof(AddPlayer), Multiplayer.GetUniqueId()); // Ask server (ID=1) to spawn us
		// Let's rely on the server's OnPeerConnected logic for spawning.
	}

	private void OnConnectionFailed()
	{
		GD.PrintErr("Connection failed!");
		Multiplayer.MultiplayerPeer = null; // Reset peer
		EnableButtons();
	}

	private void OnServerDisconnected()
	{
		GD.Print("Disconnected from server!");
		Multiplayer.MultiplayerPeer = null; // Reset peer
		EnableButtons();
		// Clean up all player nodes
		foreach (var kvp in _players)
		{
			kvp.Value.QueueFree();
		}
		_players.Clear();
	}

	// --- RPC Methods ---

	// This RPC is called by the server on clients (and locally on the server)
	// to spawn a player representation.
	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
	private void AddPlayer(long id)
	{
		if (PlayerScene == null)
		{
			GD.PrintErr("Cannot add player: PlayerScene is null.");
			return;
		}
		// Avoid adding duplicates if messages arrive strangely
		if (_players.ContainsKey(id))
		{
			 GD.Print($"Player {id} already exists. Skipping spawn.");
			 return;
		}

		GD.Print($"Adding player: {id}");
		Node playerInstance = PlayerScene.Instantiate();
		playerInstance.Name = id.ToString(); // Use ID for the node name

		// IMPORTANT: Set the network authority for the spawned player node.
		// This tells Godot which peer controls this node.
		playerInstance.SetMultiplayerAuthority((int)id);

		_players.Add(id, playerInstance); // Track the player
		AddChild(playerInstance); // Add to the scene tree
	}

	// RPC called by the server on clients to remove a player node
	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = false, TransferMode = MultiplayerPeer.TransferModeEnum.Reliable)]
	private void RemovePlayer(long id)
	{
		 GD.Print($"Removing player: {id}");
		 if (_players.TryGetValue(id, out Node playerNode))
		 {
			 playerNode.QueueFree();
			 _players.Remove(id);
		 }
	}

	// Gracefully disconnect when the game closes
	public override void _Notification(int what)
	{
		if (what == NotificationWMCloseRequest)
		{
			if (Multiplayer.MultiplayerPeer != null)
			{
				Multiplayer.MultiplayerPeer.Close();
				Multiplayer.MultiplayerPeer = null;
				GD.Print("Multiplayer peer closed.");
			}
		}
	}
}
