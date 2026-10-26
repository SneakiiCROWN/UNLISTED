extends "res://scripts/recording_repair_qa.gd"
# Eligible-event fixture, not a fresh investigation or human fear assessment.
func fixture() -> void:
	g.new_game();g.stage=3;g.threat.enabled=false;g.threat.reset()
	g.events.chair=true;g.events["return"]=true;g.events.threat_resolved=true
	g.events.memory_echo=true;g.events.memory_confirmed=true;g.horror.echo_index=-1
	g.presentation.clear_transients();g.ambient_director.enabled=true
	g.horror.set_process(false);g.horror.set_physics_process(false)
	for light in g.lamps:light.light_energy=.6
	g.doors.office.set_open(true,0);g.doors.utility.set_open(false,0)
	g.player.position=Vector3(2.3,.04,-7);g.player.velocity=Vector3.ZERO
	g.player.camera.look_at(Vector3(-1.5,1.12,-7))
	await wait(.35)

func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();await fixture()
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	var director: Node=g.ambient_director
	var handle: Node3D=g.doors.utility.pivot.get_node("HandleFront")
	phase="Office / something approaches the utility door"
	await shot("L01_quiet_door")
	check("real closed door accepts eligible existing footsteps",director.request("empty_room_steps"))
	check("latch reservation protects recorder and authored responses",director.response_blocked())
	await wait(2.8)
	check("four footsteps approach actual doorway",director.emitted.size()==4)
	var last: Vector3=director.emitted.back().where
	check("last step remains inside utility room",last.distance_to(Vector3(-1.95,.03,-7))<.02)
	check("anticipation leaves leaf and lever still",not g.doors.utility.opened and absf(handle.rotation.z)<.001)
	await wait(1.25);await shot("L02_handle_depressed")
	check("actual lever turns around its spindle",absf(handle.rotation.z)>.2,str(handle.rotation.z))
	await action("ui_cancel");var frozen: float=handle.rotation.z;var clock: float=director.latch_clock
	await wait(.35)
	check("pause freezes physical lever and quiet timing",g.menu_open and is_equal_approx(frozen,handle.rotation.z) and is_equal_approx(clock,director.latch_clock))
	await action("ui_cancel");await wait(2.0)
	check("handle settles without opening or locking door",director.latch_clock<0 and absf(handle.rotation.z)<.001 and not g.doors.utility.opened and not g.doors.utility.locked)
	check("no actor or automatic pursuit created",not g.presence.visible and g.threat.state=="dormant")
	g.save_game(true);g.load_game();await wait(.3)
	check("spent sound survives load without replay",int(director.policy.data.used.get("empty_room_steps",0))==1 and director.latch_clock<0 and not director.request("empty_room_steps"))
	await shot("L03_silent_utility")
	# Partial load consumes the event rather than replaying a hand at the latch.
	await fixture();check("partial recovery fixture accepted",director.request("empty_room_steps"))
	await wait(4.05);g.save_game(true);g.load_game();await wait(.2)
	check("mid-event recovery returns hardware safely to rest",director.latch_clock<0 and absf(handle.rotation.z)<.001 and not director.request("empty_room_steps"))
	await fixture();check("opening interruption fixture accepted",director.request("empty_room_steps"))
	await wait(3.9);g.doors.utility.set_open(true,.3);await wait(.4)
	check("player opening always wins over staged movement",director.latch_clock<0 and absf(handle.rotation.z)<.001 and g.doors.utility.opened)
	await fixture();check("pending encounter fixture accepted",director.request("empty_room_steps"))
	await wait(.3);g.events.threat_pending=true;await wait(.2)
	check("pending authored encounter clears sound and lever",director.queue.is_empty() and director.latch_clock<0)
	g.events.threat_pending=false
	await fixture();g.presentation.prefs.data.reduced_motion=true
	check("reduced motion fixture accepted",director.request("empty_room_steps"));await wait(4.05)
	check("reduced motion preserves positional sound without lever movement",absf(handle.rotation.z)<.001 and director.emitted.any(func(item):return item.get("kind","")=="utility_latch" and item.playing))
	await wait(1.8);g.presentation.prefs.data.reduced_motion=false
	# Player may simply leave the office. Ordinary doors/traversal remain live.
	await travel(Vector2(0,-7),"player retains office exit and hall movement")
	g.player.camera.look_at(Vector3(-1.5,1.12,-7));await use("utility");await wait(.3)
	check("utility remains normally usable after the event",g.doors.utility.opened)
	await travel(Vector2(-3,-7),"player can investigate the empty utility room")
	await shot("L04_nobody_inside")
	await finish_run()
