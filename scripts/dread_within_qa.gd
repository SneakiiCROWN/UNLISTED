extends "res://scripts/recording_repair_qa.gd"
# Authored aftermath fixtures, separate from a fresh investigation.
func tap(button: int) -> void:
	for down in [true,false]:
		var event:=InputEventJoypadButton.new();event.button_index=button;event.pressed=down;event.set_meta("unlisted_qa_input",true)
		Input.parse_input_event(event);await wait(.08)

func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();g.new_game();g.stage=3;g.threat.enabled=false;g.threat.reset()
	g.events.chair=true;g.events["return"]=true;g.events.threat_resolved=true
	g.horror.set_process(false);g.horror.set_physics_process(false);g.horror.echo_index=-1
	g.presentation.clear_transients();g.ambient_director.enabled=true
	for light in g.lamps:light.light_energy=.6
	g.doors.lounge.set_open(true,0);g.player.position=Vector3(.5,.04,1);g.player.camera.look_at(Vector3(7.18,1.5,2));await wait(.3)
	started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	var director: Node=g.ambient_director;var room: Node=g.get_node("LivingRoomFinishes")
	check("unwitnessed anomaly cannot predict aftermath",not director.request("curtains_drawn") and not director.request("ceiling_return"))
	g.events.impossible_room_resolved=true;g.events.impossible_room_revisited=true
	check("actual doorway sightline protects curtain change",director.curtain_visible() and not director.request("curtains_drawn"))
	await shot("D01_open_curtains")
	g.player.position=Vector3(9,.04,2);g.player.camera.look_at(Vector3(7.18,1.5,2));await wait(.2)
	check("exterior glazing protects curtain destination",director.curtain_visible())
	g.player.position=Vector3(.5,.04,-4);g.player.camera.look_at(Vector3(0,1.5,-8));await wait(.2)
	check("hidden room offers eligible dressing change",not director.curtain_visible() and director.request("curtains_drawn"))
	check("drawn cloth covers its actual opening",float(room.cloth.get_shader_parameter("drawn"))==1.0)
	await wait(.5)
	await travel(Vector2(.5,1),"return through actual hall after unseen response")
	g.player.camera.look_at(Vector3(7.18,1.5,2));await wait(.3);await shot("D02_curtains_after_return")
	g.save_game(true);g.load_game();await wait(.25)
	check("drawn curtain survives visible save and load",float(room.cloth.get_shader_parameter("drawn"))==1.0 and not director.request("curtains_drawn"))
	await travel(Vector2(3.0,1.7),"investigate restored lounge through normal doorway")
	g.player.camera.look_at(Vector3(4.5,2.7,1));await wait(.2)
	phase="Restored lounge / footsteps above the ceiling"
	check("overhead response uses restored-room eligibility",director.request("ceiling_return"))
	await wait(.7)
	check("still observer receives no canned footsteps",director.ceiling_active and director.ceiling_steps==0)
	await travel(Vector2(5.4,1.7),"walking makes the restored room answer");await wait(.55)
	g.player.camera.look_at(Vector3(4.5,2.7,1));await shot("D03_empty_ceiling_after_steps")
	var overhead: Array=director.emitted.filter(func(item):return item.get("kind","")=="answering_step")
	check("actual movement receives bounded overhead contacts",not overhead.is_empty() and overhead.size()<=4 and overhead.all(func(item):return item.where.y>2.6))
	check("aftermath leaves gravity and player control intact",absf(g.player.position.y)<.08 and g.player.active and g.threat.state=="dormant" and not g.presence.visible)
	g.save_game(true);g.load_game();await wait(.2)
	check("spent overhead response cannot replay after load",not director.request("ceiling_return"))
	# A second fixture isolates partial recovery, controller pause and interruption.
	var used: Dictionary=director.policy.data.used;used.erase("ceiling_return")
	g.events.atmosphere.used=used;director.restore()
	check("saved quiet interval prevents premature fixture replay",float(director.policy.data.quiet)>0 and not director.request("ceiling_return"))
	director.policy.data.quiet=0 # Independent partial-recovery fixture, not live pacing.
	check("partial-response fixture eligible",director.request("ceiling_return"));await wait(.3)
	await tap(JOY_BUTTON_START);var clock: float=director.ceiling_elapsed;await wait(.35)
	check("controller Start pauses aftermath timing",g.menu_open and is_equal_approx(clock,director.ceiling_elapsed))
	await tap(JOY_BUTTON_B);check("controller B restores player control",not g.menu_open and g.player.active)
	g.save_game(true);g.load_game();await wait(.2)
	check("partial load consumes optional sound without replay",not director.ceiling_active and director.ceiling_pending.is_empty() and not director.request("ceiling_return"))
	used=director.policy.data.used;used.erase("ceiling_return");g.events.atmosphere.used=used;director.restore()
	director.policy.data.quiet=0 # Independent interruption fixture.
	check("interruption fixture eligible",director.request("ceiling_return"));g.events.threat_pending=true;await wait(.2)
	check("authored encounter cancels queued aftermath",not director.ceiling_active and director.ceiling_pending.is_empty())
	g.events.threat_pending=false
	# Legacy/new case resets dressing; reduced motion keeps static outcome.
	g.events.atmosphere={};g.events.erase("curtains_manual");director.restore()
	check("legacy state restores open curtains",float(room.cloth.get_shader_parameter("drawn"))==0.0)
	g.player.position=Vector3(.5,.04,-4);g.player.camera.look_at(Vector3(0,1,-8));g.presentation.prefs.data.reduced_motion=true
	check("reduced motion permits safe completed dressing",director.request("curtains_drawn") and float(room.cloth.get_shader_parameter("drawn"))==1.0)
	g.save_game(true);g.load_game();await wait(.3)
	check("reduced-motion recovery preserves changed room",float(room.cloth.get_shader_parameter("drawn"))==1.0)
	g.presentation.prefs.data.reduced_motion=false
	# Exercise the real due-time scheduler path, not only direct event requests.
	g.player.position=Vector3(3,.04,1.7);await wait(.4)
	var scheduled: Dictionary={}
	for seed_ in range(1,100):
		var probe=load("res://scripts/ambient_schedule.gd").new();probe.restore({},seed_)
		probe.data.used={"window_taps":2,"empty_room_steps":1,"kitchen_tin":1,"curtains_drawn":1}
		var candidate: Dictionary=probe.data.duplicate(true)
		var ids: Array[String]=["ceiling_return"]
		if probe.choose(ids)=="ceiling_return":scheduled=candidate;break
	director.policy.restore(scheduled,1);director.policy.data.remaining=.005
	g.events.atmosphere=director.policy.data
	var count: int=director.history.size();await wait(.25)
	check("due-time scheduler naturally dispatches eligible aftermath",director.history.size()==count+1 and director.last_event=="ceiling_return")
	await wait(4.8)
	phase="Separate fixture / Surveyor floor-contact footsteps"
	g.player.position=Vector3(3,.04,-7);g.player.camera.look_at(Vector3(0,1,-6));g.doors.office.set_open(true,0)
	g.threat.enabled=true;g.threat.begin(false,Vector3(0,.04,-4));g.threat.grace=99
	g.threat.change("investigate");g.threat.last_known=Vector3(0,0,-7);g.threat.plan(g.threat.last_known)
	var steps: int=g.threat.footstep_index;var start: Vector3=g.presence.position
	await wait(2.0)
	check("real Surveyor movement emits floor contacts",g.threat.footstep_index>steps and g.presence.position.distance_to(start)>.5)
	g.threat.set_physics_process(false);steps=g.threat.footstep_index;await wait(.4)
	check("stationary Surveyor produces no extra footsteps",g.threat.footstep_index==steps)
	g.threat.reset();g.threat.set_physics_process(true);g.threat.enabled=false
	await finish_run()
