# RightAngleFlip.gd
extends Area3D

const EPSILON: float = 0.0001
const WORLD_UP: Vector3 = Vector3(0.0, 1.0, 0.0)
var _bodies_mid_flip: Array = [] # Stores bodies currently being flipped

# Removed unused signal/variable
# signal global_timer_start
# var body_exited_zone = true

func _on_body_entered(body: Node3D):
	var timestamp = Time.get_ticks_msec()
	print(timestamp, ": ", self.name, " >>> ENTERED by ", body.name)

	if body is CharacterBody3D:
		# Call timer logic if needed (ensure this doesn't interfere)
		# Refs._on_global_timer_start()

		if body in _bodies_mid_flip:
			print(timestamp, ": ", self.name, " WARNING: Entered while already in _bodies_mid_flip: ", body.name)
			# Optional: return here if you don't want re-entry during flip

		var target_up_direction: Vector3 = -global_transform.basis.x.normalized()
		body.up_direction = target_up_direction # Set target up direction early

		print(timestamp, ": ", self.name, " Scheduling deferred flip for ", body.name)
		# --- Make sure to call the ASYNC version if using await inside ---
		call_deferred("_deferred_flip", body, target_up_direction)
		Refs._on_global_timer_start()


func _on_body_exited(body: Node3D):
	var timestamp = Time.get_ticks_msec()
	print(timestamp, ": ", self.name, " <<< EXITED by ", body.name)
	print("    Current _bodies_mid_flip: ", _bodies_mid_flip) # Log list state on exit

	# Check if this exit might be caused by a recent flip
	if body in _bodies_mid_flip:
		print(timestamp, ": ", self.name, " !!! IGNORING SPURIOUS EXITED by ", body.name)
		_bodies_mid_flip.erase(body) # Consume the flag
		print("    _bodies_mid_flip after erase (spurious): ", _bodies_mid_flip)
		return # Skip the rest of the exit logic

	# If the body wasn't in the list, proceed with normal exit logic
	print(timestamp, ": ", self.name, " --- PROCESSING NORMAL EXITED by ", body.name)
	if body is CharacterBody3D:
		if Refs:
			Refs.exited_gravity_zone = true # Signal the normal exit


# --- Make this function ASYNC ---
func _deferred_flip(body: CharacterBody3D, new_up_direction: Vector3):
	var timestamp = Time.get_ticks_msec()
	print(timestamp, ": ", self.name, " --- Running _deferred_flip for ", body.name)

	# Mark the body as potentially causing a spurious exit
	if not body in _bodies_mid_flip:
		print("    Adding ", body.name, " to _bodies_mid_flip.")
		_bodies_mid_flip.append(body)
	else:
		print("    WARNING: ", body.name, " was already in _bodies_mid_flip when _deferred_flip ran.")
	print("    _bodies_mid_flip before flip: ", _bodies_mid_flip)

	# Call the actual flip logic
	if Refs and Refs.has_method("flip_direction"):
		Refs.flip_direction(new_up_direction, body)
		print(timestamp, ": ", self.name, "    Called Refs.flip_direction for ", body.name)
	else:
		# Clean up immediately if flip failed
		if body in _bodies_mid_flip: _bodies_mid_flip.erase(body)
		return

	# --- Wait for a very short time AFTER the flip ---
	# This allows the physics engine a cycle or two to potentially
	# emit the spurious exit signal while the flag is still set.
	var cleanup_delay = .6 # Adjust if needed (seconds)
	print(timestamp, ": ", self.name, "    Waiting ", cleanup_delay, "s before cleanup for ", body.name)
	await get_tree().create_timer(cleanup_delay).timeout
	# --- End Wait ---

	# --- Now, remove the body from the list ---
	timestamp = Time.get_ticks_msec() # Get fresh timestamp
	print(timestamp, ": ", self.name, " --- Cleaning up mid-flip flag for ", body.name, " after await")
	print("    _bodies_mid_flip BEFORE erase (await cleanup): ", _bodies_mid_flip)
	if body in _bodies_mid_flip:
		print("    Removing ", body.name, " from mid-flip list via await cleanup.")
		_bodies_mid_flip.erase(body)
	else:
		print("    ", body.name, " was NOT in mid-flip list during await cleanup (already removed?).")
	print("    _bodies_mid_flip AFTER erase (await cleanup): ", _bodies_mid_flip)
	# --- End Cleanup ---


# Ensure Refs.flip_direction exists and works as expected
