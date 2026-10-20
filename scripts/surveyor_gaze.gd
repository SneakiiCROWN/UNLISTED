extends SkeletonModifier3D
var actor: Node3D
var yaw := 0.0
var target_yaw := 0.0

func _process_modification_with_delta(delta: float) -> void:
	var s := get_skeleton()
	if not is_instance_valid(actor.game.player) or not actor.get_parent().visible:return
	var id := s.find_bone("Head")
	var head := s.get_bone_global_pose(id).origin
	var local := s.to_local(actor.game.player.camera.global_position)-head
	target_yaw = clampf(atan2(local.x,local.z),-0.38,0.38)
	yaw = lerpf(yaw,target_yaw,1.0-exp(-maxf(delta,0)*0.8))
	var transform := s.get_bone_global_pose(id)
	transform.basis = Basis(Vector3.UP,yaw)*transform.basis*Basis(Vector3.RIGHT,-0.065)
	if actor.capture_amount>0:
		var tilt: float=sin(smoothstep(0.25,0.67,actor.capture_phase)*PI*0.7)*0.3
		transform.basis=Basis(Vector3.FORWARD,tilt)*transform.basis
	s.set_bone_global_pose(id,transform)
	# Relax the source animation's clenched fingers. The worker listens with open,
	# gloved hands; a reaching pose closes them only during the warned grab.
	for bone in s.get_bone_count():
		var name_ := s.get_bone_name(bone)
		if name_.begins_with("index") or name_.begins_with("middle") or name_.begins_with("ring") or name_.begins_with("pinky"):
			var pose := s.get_bone_pose_rotation(bone)
			s.set_bone_pose_rotation(bone,pose.slerp(Quaternion.IDENTITY,0.4 if actor.mode=="capture" else (0.7 if actor.mode!="attack" else 0.25)))
	if actor.capture_amount>0:
		var camera: Camera3D=actor.game.player.camera
		for side in ["l","r"]:
			# Facing bodies have mirrored left/right screen coordinates. Sending the
			# actor's left hand to screen-left crossed both arms over its own chest.
			var offset:=Vector3(0.22 if side=="l" else -0.22,-0.22,-0.36)
			if side=="r":offset=offset.lerp(Vector3(0,0,-0.30),smoothstep(0.6,0.83,actor.capture_phase))
			solve_arm(s,side,s.to_local(camera.global_position+camera.global_basis*offset),actor.capture_amount)

func solve_arm(s: Skeleton3D,side: String,target: Vector3,weight: float) -> void:
	var upper:=s.find_bone("upperarm_"+side)
	var lower:=s.find_bone("lowerarm_"+side)
	var hand:=s.find_bone("hand_"+side)
	if upper<0 or lower<0 or hand<0:return
	var a:=s.get_bone_global_pose(upper)
	var b:=s.get_bone_global_pose(lower)
	var c:=s.get_bone_global_pose(hand)
	var first:=a.origin.distance_to(b.origin)
	var second:=b.origin.distance_to(c.origin)
	var vector:=target-a.origin
	var distance:=clampf(vector.length(),0.05,(first+second)*0.985)
	var direction:=vector.normalized()
	var bend:=b.origin-a.origin
	bend-=direction*bend.dot(direction)
	if bend.length()<0.01:bend=Vector3.DOWN-direction*Vector3.DOWN.dot(direction)
	bend=bend.normalized()
	var cosine:=clampf((first*first+distance*distance-second*second)/(2*first*distance),-1,1)
	var elbow:=a.origin+direction*first*cosine+bend*first*sqrt(maxf(0,1-cosine*cosine))
	var turn:=Quaternion((b.origin-a.origin).normalized(),(elbow-a.origin).normalized())
	a.basis=Basis(Quaternion.IDENTITY.slerp(turn,weight))*a.basis
	s.set_bone_global_pose(upper,a)
	b=s.get_bone_global_pose(lower);c=s.get_bone_global_pose(hand)
	var wrist:=a.origin+direction*distance
	turn=Quaternion((c.origin-b.origin).normalized(),(wrist-b.origin).normalized())
	b.basis=Basis(Quaternion.IDENTITY.slerp(turn,weight))*b.basis
	s.set_bone_global_pose(lower,b)
	actor.capture_diagnostics[side]={"target":str(s.to_global(target)),"hand":str(s.to_global(s.get_bone_global_pose(hand).origin)),"error":s.get_bone_global_pose(hand).origin.distance_to(target),"first":first,"second":second,"reach":distance}
