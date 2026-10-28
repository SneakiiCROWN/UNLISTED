extends "res://scripts/house_remembers_qa.gd"
# Placed native fixtures, not a fresh investigation or human playtest.
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	await fixture();g.ambient_director.enabled=false
	var room: Node=g.get_node("LivingRoomFinishes")
	phase="pane, frame and physical barrier"
	check("clear pane transmits sight",g.sight_line(Vector3(6,1.4,1.5),Vector3(8.5,1.4,1.5)))
	check("solid pane still blocks physical attack",not g.threat.clear_line(Vector3(6,1.4,1.5),Vector3(8.5,1.4,1.5)))
	check("wooden centre mullion blocks optics",not g.sight_line(Vector3(6,1.4,2),Vector3(8.5,1.4,2)))
	check("solid exterior wall remains opaque",not g.sight_line(Vector3(6,1.4,.5),Vector3(8.5,1.4,.5)))
	room.use_curtains();await wait(.85)
	check("closed cloth blocks the clear pane",not g.sight_line(Vector3(6,1.4,1.5),Vector3(8.5,1.4,1.5)))
	room.use_curtains();await wait(.85)
	phase="watched body must not disappear behind transparent glass"
	g.player.position=Vector3(5.55,.03,1.5);g.player.velocity=Vector3.ZERO
	g.events.threat_origin="window";g.events.threat_spawn=[8.7,.03,2];g.events.threat_pending=true;g.events.threat_resolved=false
	g.threat.enabled=true;g.threat.begin(false,Vector3(8.7,.03,2));g.threat.grace=99
	g.player.camera.look_at(g.presence.position+Vector3.UP*1.5);g.threat.change("retreat");g.threat.route.clear()
	await wait(.2)
	check("partial body through panes is genuinely in view",g.horror.visible_to_player())
	await shot("S01_watched_through_window");await wait(2.8)
	check("watched retreat retains visible colliding actor",g.presence.visible and g.presence.collision_layer==16 and g.threat.state=="retreat","state="+g.threat.state)
	await shot("S01b_still_present_after_caption")
	g.player.camera.look_at(Vector3(2,1.5,-3));await wait(.5)
	check("looking away permits concealed departure",not g.presence.visible and g.threat.state=="complete")
	g.save_game(true);g.load_game();await wait(.2)
	check("completed departure survives save recovery",g.events.get("threat_resolved",false) and not g.presence.visible)
	await fixture();g.ambient_director.enabled=false
	phase="close sealed window encounter"
	g.player.position=Vector3(7.9,.03,1.5);g.player.velocity=Vector3.ZERO
	g.events.threat_origin="window";g.events.threat_spawn=[6.9,.03,1.5];g.events.threat_pending=true;g.events.threat_resolved=false
	g.threat.enabled=true;g.threat.begin(false,Vector3(6.9,.03,1.5));g.threat.grace=0;g.threat.change("pursue")
	g.player.camera.look_at(g.presence.position+Vector3.UP*1.5)
	var misses: int=g.threat.missed_attacks;var deaths: int=g.threat.deaths
	await wait(2.2);await shot("S02_sealed_pane_presence")
	check("visible close window presence does not attempt empty grabs",g.threat.state=="pursue" and g.threat.missed_attacks==misses and g.threat.deaths==deaths,"state="+g.threat.state)
	check("glass keeps player and Surveyor on opposite sides",g.presence.position.x<7.3 and g.player.position.x>7.6 and g.presence.collision_layer==16)
	check("window watch retains floor contact",absf(g.presence.position.y)<.08)
	check("sealed pane plays living idle rather than frozen movement",g.surveyor_actor.mode=="watch" and g.surveyor_actor.animator.is_playing())
	await pad(JOY_BUTTON_START);var frozen: Vector3=g.presence.position;await wait(.2)
	check("controller pause suspends close encounter",g.menu_open and g.presence.position.is_equal_approx(frozen))
	await pad(JOY_BUTTON_B);g.save_game(true);g.load_game();await wait(.3)
	check("pending window encounter resumes safely",g.presence.visible and g.threat.active() and g.player.active)
	room.use_curtains();await wait(.9)
	check("drawing opaque cloth removes optical contact",not g.threat.can_see_player())
	await wait(2.6)
	check("lost sight retains investigation instead of magic resolution",g.threat.active() and g.threat.state not in ["attack","capture"])
	await fixture();g.ambient_director.enabled=false
	phase="controller toggle and held crouch suspicion"
	g.player.position=Vector3(0,.03,-4);g.player.velocity=Vector3.ZERO
	g.threat.enabled=true;g.threat.begin(false,Vector3(0,.03,0));g.threat.grace=0;g.threat.change("observe")
	g.player.camera.look_at(g.presence.position+Vector3.UP*1.5)
	await pad(JOY_BUTTON_B);await wait(.35)
	check("controller B crouches without held crouch action",g.player.crouched and not Input.is_action_pressed("crouch"))
	g.threat.suspicion=0;var start: float=g.threat.age;await wait(.3)
	var toggle_rate: float=g.threat.suspicion/maxf(.01,g.threat.age-start)
	await pad(JOY_BUTTON_B);await wait(.35)
	Input.action_press("crouch");await wait(.35);g.threat.change("observe");g.threat.suspicion=0;start=g.threat.age;await wait(.3)
	var hold_rate: float=g.threat.suspicion/maxf(.01,g.threat.age-start)
	check("held and toggled crouch have equal detection",absf(toggle_rate-.6)<.03 and absf(hold_rate-toggle_rate)<.03,"toggle="+str(toggle_rate)+" hold="+str(hold_rate))
	Input.action_release("crouch");await wait(.35);g.threat.change("observe");g.threat.suspicion=0;start=g.threat.age;await wait(.3)
	var standing_rate: float=g.threat.suspicion/maxf(.01,g.threat.age-start)
	check("standing remains more detectable",absf(standing_rate-1.0)<.03 and standing_rate>toggle_rate)
	await fixture();g.ambient_director.enabled=false;g.physical.set_physics_process(false)
	phase="observed physical contradiction"
	var cup: RigidBody3D=g.physical.props.cup
	cup.call("relocate",Transform3D(cup.basis,Vector3(4,.87,.3)));await wait(.6)
	g.events.remembered_cup=[4.6,.87,0];g.events.erase("cup_repeated")
	g.player.position=Vector3(8.7,.03,2.9);g.player.velocity=Vector3.ZERO;g.player.camera.look_at(cup.global_position);await wait(.2)
	g.ambient_director.policy.data.quiet=0
	check("mug is optically observed through the actual window",g.physical.placement_visible(cup,cup.transform),"cup="+str(cup.position))
	check("watched mug cannot relocate through glass",not g.physical.repeat_placement() and not g.events.get("cup_repeated",false))
	await shot("S03_observed_mug")
	var centre_was_outside:=false
	var camera_rotation: Vector3=g.player.camera.rotation
	for angle in range(0,100):
		g.player.camera.rotation=camera_rotation+Vector3(0,deg_to_rad(angle),0)
		if not g.get_viewport().get_visible_rect().has_point(g.player.camera.unproject_position(cup.global_position)) and g.physical.placement_visible(cup,cup.transform):
			centre_was_outside=true;break
	check("partially visible mug remains protected at screen edge",centre_was_outside and not g.physical.repeat_placement())
	g.player.position=Vector3(0,.03,-5);g.player.camera.look_at(Vector3(0,1.5,-8));await wait(.2);g.ambient_director.policy.data.quiet=0
	check("unseen safe mug return remains possible",g.physical.repeat_placement(),"blocked="+str(g.ambient_director.response_blocked())+" cup="+str(cup.position))
	await wait(.3);g.save_game(true);g.load_game();await wait(.2)
	check("spent mug return does not replay after load",g.events.get("cup_repeated",false) and not g.physical.repeat_placement())
	await finish_run()
