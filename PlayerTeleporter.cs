using Godot;
using System.Linq;

public partial class PlayerTeleporter : Area3D {
	private bool _bodyInside;
	private CharacterBody3D _player;
	public override void _Ready() {
		Connect("body_entered", new Callable(this, "_on_body_entered"));
		Connect("body_exited", new Callable(this, "_on_body_exited"));
	}

	private void _on_body_entered(CharacterBody3D body) {
		GD.Print(body);
		_player = body;
		_bodyInside = true;
	}
	private void _on_body_exited(CharacterBody3D body) {
		GD.Print(body);
		_bodyInside = false;
	}

	public override void _Input(InputEvent @event) {
		if (!IsMultiplayerAuthority() && !_player.IsMultiplayerAuthority()) return;
		if (_bodyInside && @event.IsActionPressed("teleport")) {
			GD.Print("calling teleport");
			Node3D world = GetParentNode3D().GetParentOrNull<Node3D>();
			world.GetTree().GetNodesInGroup("players").OfType<CharacterBody3D>().ToList().ForEach(player => {
				if (player.IsMultiplayerAuthority()) player.GlobalPosition = GlobalPosition; else player.Rpc("TeleportPlayer", GlobalPosition);
			});
		}
	}
}
