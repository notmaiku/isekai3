using Godot;
using System;

public partial class PressureCollision : Area3D {
	// Exported variable to assign the target node in the editor
	[Export]
	public NodePath TargetNodePath;

	private AnimationPlayer _animationPlayer;

	public override void _Ready() {
		// Connect the body_entered signal
		this.BodyEntered += OnBodyEntered;
		this.BodyExited += OnBodyExited;

		// Get the AnimationPlayer from the target node
		if (TargetNodePath != null) {
			var targetNode = GetNode(TargetNodePath);
			_animationPlayer = GetNode<AnimationPlayer>(TargetNodePath);
		}
	}

	private void OnBodyEntered(Node body) {
		// Play the animation when a body enters the area
		if (_animationPlayer != null) {
			_animationPlayer.Play("moving_platform");
		}
	}

	private void OnBodyExited(Node body) {
		// Play the animation when a body enters the area
		GD.Print("body exited");
		if (_animationPlayer != null) {
			_animationPlayer.Pause();
		}
	}
}
