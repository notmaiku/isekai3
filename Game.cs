using Godot;

public partial class Game : Node3D // Or Node2D.
{
	public override void _Ready()
	{
		// Preconfigure game.

		Lobby.Instance.RpcId(1, Lobby.MethodName.PlayerLoaded); // Tell the server that this peer has loaded.
	}

	// Called only on the server.
	public void StartGame()
	{
		// All peers are ready to receive RPCs in this scene.
	}
}
