using Godot;
using System;

public partial class PlayerNet : MultiplayerSynchronizer // Or Node if it doesn't need its own transform
{
	private Node3D _trackedParent = null;

	// Store the latest read values if needed elsewhere in this script
	public Vector3 LastReadParentPosition { get; private set; }
	public Vector3 LastReadParentRotationDeg { get; private set; }

	public override void _Ready() {
		// Get the parent node once.
		// We expect it to be a Node3D or derived type (like your Player script's node)
		GD.Print("ready!");
		_trackedParent = GetParentOrNull<Node3D>();
		if (_trackedParent == null) {
			GD.PushError($"Parent of '{Name}' is not a Node3D or is null. Tracking cannot work.");
		} else {
			GD.Print($"'{Name}' will track parent: '{_trackedParent.Name}'");
		}
	}

	public override void _Process(double delta) {
		// Ensure we have a valid reference to the parent Node3D
		if (_trackedParent == null) {
			return; // Exit if parent wasn't found or valid in _Ready()
		}

		// --- Read the Parent's Exposed Properties ---
		// Use Global versions for world-space values, which is usually what you want
		// when tracking another object's world state.
		Vector3 parentPos = _trackedParent.GlobalPosition;
		Vector3 parentRotDeg = _trackedParent.GlobalRotationDegrees; // Euler angles

		// --- Store and/or Use the Values ---

		// Store them if other parts of this script need them
		LastReadParentPosition = parentPos;
		LastReadParentRotationDeg = parentRotDeg;

		// Example: Print the values (can be verbose)
		// GD.Print($"Parent '{_trackedParent.Name}' Pos: {parentPos}, RotDeg: {parentRotDeg}");

		// --- Optional: Apply to this node (if desired) ---
		// If this node should MIRROR the parent, and you have a MultiplayerSynchronizer
		// on THIS node watching its own transform, only the authority should set it.
		if (IsMultiplayerAuthority()) // Check authority BEFORE modifying this node
		{
			// Option A: Match exact transform (includes scale)
			// this.p = _trackedParent.GlobalTransform;

			// Option B: Match only position and rotation
			// this.GlobalPosition = parentPos;
			// this.GlobalRotationDegrees = parentRotDeg;
		}
		// If this node does NOT have its own MultiplayerSynchronizer and should
		// just visually follow the parent on all clients (because the PARENT is
		// synchronized), you might set the transform *without* the authority check:
		// this.GlobalPosition = parentPos;
		// this.GlobalRotationDegrees = parentRotDeg;
		// Choose the approach based on your synchronization strategy.
	}
}
