using Godot;

public partial class TaxiCarP1 : Node3D {
	[Export]
	public Node3D[] Cars { get; set; }
	[Export]
	public int useCar;

	public override void _Ready() {
		Cars[useCar].Show();
	}
}
