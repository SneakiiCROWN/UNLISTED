extends Node
# Confirmed physical contact starts one short inspection, not a second attack.
# Body/capsule never teleports. A paused capture resumes at its exact phase.
var game: Node
var active:=false
var clock:=0.0
var duration:=4.0
var repeats:=0
var saved_camera: Transform3D
var saved_fov:=77.0
var saved_torch_energy:=1.1
var saved_torch_rotation:=Vector3.ZERO
var saved_viewmodel:=true
var camera_start:=Quaternion.IDENTITY
var sounds: Array=[]
var last_phase:=""
var saved_collision_mask:=1
var closing_step_played:=false

func begin() -> void:
	if active:return
	active=true;clock=0;last_phase=""
	closing_step_played=false
	saved_collision_mask=game.presence.collision_mask
	game.presence.collision_mask=1|2
	sounds.clear()
	if game.physical.held:game.physical.release(false)
	duration=4.0 if repeats==0 else 2.7
	repeats+=1
	saved_camera=game.player.camera.transform
	saved_fov=game.player.camera.fov
	camera_start=game.player.camera.global_basis.get_rotation_quaternion()
	saved_torch_energy=game.player.torch.light_energy
	saved_torch_rotation=game.player.torch.rotation
	saved_viewmodel=game.player.viewmodel.visible
	game.player.viewmodel.visible=false
	game.player.active=false;game.player.velocity=Vector3.ZERO
	game.menu_open=true
	game.presentation.clear_transients()
	game.presentation.hud.visible=false
	game.presentation.section="capture"
	game.surveyor_actor.capture_amount=0
	game.surveyor_actor.set_mode("capture")
	phase("contact")

func phase(name_: String) -> void:
	if name_==last_phase:return
	last_phase=name_
	if name_=="contact":
		pass # Warned contact has just occurred. A short physical closing step follows.
	elif name_=="inspection":
		sounds.append(game.sound("capture_contact",game.player.position+Vector3.UP*1.4,-22))
		var breath=game.sound("breath",game.presence.position+Vector3.UP*1.6,-23)
		sounds.append(breath)
		game.sound_caption("Breathing against your ear.",2,"VERY CLOSE",breath)
	elif name_=="register":
		sounds.append(game.sound("capture_register",game.presence.position+Vector3.UP*1.4,-24))
	if is_instance_valid(game.dev_tools):game.dev_tools.log_event("capture_phase",{"phase":name_,"time":clock,"separation":game.player.position.distance_to(game.presence.position)})

func _process(delta: float) -> void:
	if not active:return
	clock+=delta
	var t:=clock/duration
	var camera: Camera3D=game.player.camera
	var target: Vector3=game.presence.global_position+Vector3.UP*1.77
	var wanted:=Basis.looking_at(target-camera.global_position).get_rotation_quaternion()
	var reduced: bool=game.presentation.prefs.data.reduced_motion
	var acquire:=smoothstep(0,0.26,t)
	# Reduced motion holds the existing view under a brief black cut, then frames
	# the inspection. No forced spin, shake, flashing frame or camera translation.
	var cut_reveal: bool=reduced or camera_start.angle_to(wanted)>deg_to_rad(50)
	if cut_reveal:
		if t<0.09:game.presentation.fade.color.a=smoothstep(0,0.09,t)
		elif t<0.12:
			camera.global_basis=Basis(wanted)
			game.presentation.fade.color.a=1
		elif t<0.2:
			game.presentation.fade.color.a=1-smoothstep(0.12,0.2,t)
	else:
		camera.global_basis=Basis(camera_start.slerp(wanted,acquire))
	if not reduced:
		camera.fov=lerpf(saved_fov,54.0,smoothstep(0.15,0.65,t))
	game.player.torch.light_energy=lerpf(saved_torch_energy,saved_torch_energy*0.62,smoothstep(0.15,0.5,t))
	game.player.torch.rotation.x=saved_torch_rotation.x-0.1*smoothstep(0.12,0.5,t)
	game.surveyor_actor.capture_amount=smoothstep(0.12,0.36,t)
	game.surveyor_actor.capture_phase=t
	if t>=0.67:phase("register")
	elif t>=0.25:phase("inspection")
	# The real attached glove approaches the lens; darkness closes over the view.
	# Save the full body/camera separation until black. No post-contact chase logic.
	if t>=0.76:
		game.presentation.fade.color.a=smoothstep(0.76,0.93,t)
		game.player.torch.light_energy=saved_torch_energy*(1-smoothstep(0.76,0.95,t))
	if t>=1:
		finish()

func _physics_process(delta: float) -> void:
	if not active:return
	var body: CharacterBody3D=game.presence
	var toward: Vector3=game.player.position-body.position
	toward.y=0
	# Close the last fraction of a metre through real collision, never teleporting
	# either body. This keeps a normal human arm length sufficient for contact.
	if clock<0.9 and toward.length()>0.71:
		body.velocity=toward.normalized()*minf(0.65,(toward.length()-0.70)/maxf(delta,0.001))
		body.velocity.y=-0.2
		var before:=body.position
		body.move_and_slide()
		game.surveyor_actor.locomotion(body.position.distance_to(before)/maxf(delta,0.001))
		if not closing_step_played and clock>0.2:
			closing_step_played=true;sounds.append(game.sound("step",body.position,-25))
	else:
		body.velocity=Vector3.ZERO
		game.surveyor_actor.set_mode("capture")

func restore_camera() -> void:
	game.player.camera.transform=saved_camera
	game.player.camera.fov=saved_fov
	game.player.torch.light_energy=saved_torch_energy
	game.player.torch.rotation=saved_torch_rotation
	game.player.viewmodel.visible=saved_viewmodel
	game.surveyor_actor.capture_amount=0
	game.surveyor_actor.capture_phase=0
	game.presence.collision_mask=saved_collision_mask

func finish() -> void:
	active=false
	restore_camera()
	game.threat.state="dead"
	game.presentation.show_death(true)

func cancel() -> void:
	if not active:return
	active=false
	restore_camera()
	for sound_ in sounds:
		if is_instance_valid(sound_):sound_.stop()
	sounds.clear()
	game.presentation.fade.color.a=0
