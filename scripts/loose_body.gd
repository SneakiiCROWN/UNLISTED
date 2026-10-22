extends RigidBody3D
# One-shot relocations are committed in the physics integration callback so sleeping
# bodies cannot restore an older transform over a load/recovery/paranormal placement.
var supports: Array[Dictionary] = []
var reset_pending := false
var reset_transform := Transform3D.IDENTITY
func relocate(value: Transform3D) -> void:
	reset_transform = value
	reset_pending = true
	supports.clear()
	freeze = false
	sleeping = false
	transform = value
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	supports.clear()
	for i in state.get_contact_count():
		# 'Local' identifies this body; the normal uses world axes (Godot physics).
		var normal: Vector3=state.get_contact_local_normal(i)
		if normal.y>.55:
			supports.append({"id":state.get_contact_collider_id(i),"point":state.get_contact_collider_position(i)})
	if not reset_pending:return
	state.transform = reset_transform
	state.linear_velocity = Vector3.ZERO
	state.angular_velocity = Vector3.ZERO
	reset_pending = false
