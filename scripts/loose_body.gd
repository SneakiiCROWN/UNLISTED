extends RigidBody3D
# One-shot relocations are committed in the physics integration callback so sleeping
# bodies cannot restore an older transform over a load/recovery/paranormal placement.
var reset_pending := false
var reset_transform := Transform3D.IDENTITY
func relocate(value: Transform3D) -> void:
	reset_transform = value
	reset_pending = true
	freeze = false
	sleeping = false
	transform = value
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not reset_pending:return
	state.transform = reset_transform
	state.linear_velocity = Vector3.ZERO
	state.angular_velocity = Vector3.ZERO
	reset_pending = false
