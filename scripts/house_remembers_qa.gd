extends "res://scripts/recording_repair_qa.gd"
# Input-driven placed fixtures. No claim of an earned fresh investigation.
func pad(button: int) -> void:
	for down in [true,false]:
		var event:=InputEventJoypadButton.new();event.button_index=button;event.pressed=down;event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event);await wait(.06)

func fixture() -> void:
	g.new_game();g.stage=3;g.events.case_v3=true;g.events.threat_resolved=true;g.events.threat_pending=false
	g.events.chair=true;g.events["return"]=true;g.threat.enabled=false;g.threat.reset();g.presence.visible=false
	g.horror.set_process(false);g.horror.set_physics_process(false);g.horror.echo_index=-1;g.horror.beat=""
	g.events.impossible_room_resolved=true;g.events.impossible_room_revisited=true
	g.ambient_director.enabled=true;g.ambient_director.policy.data.remaining=90;g.ambient_director.policy.data.quiet=0
	g.presentation.clear_transients();g.player.position=Vector3(5.55,.03,1.8);g.player.velocity=Vector3.ZERO
	g.player.camera.look_at(g.targets.lounge_curtains.global_position);await wait(.25)

func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	if "--idle-no-recorder" in OS.get_cmdline_user_args():
		var before:=AudioServer.get_bus_effect_count(0)
		var idle:=330.0
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--idle-seconds="):idle=clampf(float(arg.trim_prefix("--idle-seconds=")),30,900)
		await wait(idle)
		check("isolated title survives "+str(idle)+" seconds without a QA audio recorder",g.menu_open and g.presentation.section=="title" and recorder==null and AudioServer.get_bus_effect_count(0)==before)
		await shot("R00_no_recorder_idle")
		var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"failed":0 if checks.all(func(c):return c.passed) else 1,"checks":checks,"scope":"Isolated native title; no AudioEffectRecord or continuous image readback. Not ordinary foreground-owner stability clearance."},"\t"));file.close()
		await g.qa_exit(0 if checks.all(func(c):return c.passed) else 1,true);return
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	await fixture()
	var room: Node=g.get_node("LivingRoomFinishes");var director: Node=g.ambient_director
	phase="player operated curtain and actual visibility"
	await shot("R01_open_window")
	check("actual curtain pull is reachable",g.player.target().get("collider")==g.targets.lounge_curtains)
	await action("interact");await wait(.15);await pad(JOY_BUTTON_START)
	var drawn: float=room.cloth.get_shader_parameter("drawn");await wait(.25)
	check("pause freezes physical curtain movement",g.menu_open and is_equal_approx(drawn,float(room.cloth.get_shader_parameter("drawn"))))
	await pad(JOY_BUTTON_B);await wait(.8)
	check("keyboard interaction closes the real cloth",room.curtains_closed() and float(room.cloth.get_shader_parameter("drawn"))>.99)
	await shot("R02_drawn_cloth")
	g.player.position=Vector3(5.8,.03,1.5);g.player.velocity=Vector3.ZERO;g.presence.position=Vector3(8.7,.03,1.5);g.presence.look_at(Vector3(5.8,.03,1.5));await wait(.15)
	check("closed cloth blocks actual Surveyor sight",not g.threat.can_see_player())
	check("cloth never becomes a solid movement barrier",g.targets.lounge_curtains.collision_layer==4)
	check("actual centre gap is not falsely opaque",not room.blocks_sight(Vector3(8.5,1.6,2),Vector3(6,1.6,2)))
	g.save_game(true);g.load_game();await wait(.2)
	check("closed choice survives load",room.curtains_closed() and float(room.cloth.get_shader_parameter("drawn"))>.99)
	g.player.position=Vector3(5.55,.03,1.8);g.player.camera.look_at(g.targets.lounge_curtains.global_position);await wait(.15);await pad(JOY_BUTTON_X);await wait(.85)
	check("controller reopens the same physical curtain",not room.curtains_closed() and float(room.cloth.get_shader_parameter("drawn"))<.01)
	g.player.position=Vector3(5.8,.03,1.5);g.presence.position=Vector3(8.7,.03,1.5);g.presence.look_at(Vector3(5.8,.03,1.5));await wait(.15)
	var origin: Vector3=g.presence.position+Vector3.UP*1.65
	var ray:=PhysicsRayQueryParameters3D.create(origin,g.player.camera.global_position,1);ray.exclude=[g.player.get_rid(),g.presence.get_rid()]
	var obstruction: Dictionary=g.get_world_3d().direct_space_state.intersect_ray(ray)
	check("open window restores actual sight through real glazing",g.threat.can_see_player(),"from="+str(origin)+" to="+str(g.player.camera.global_position)+" hit="+str(obstruction.get("collider"))+" cloth="+str(room.blocks_sight(origin,g.player.camera.global_position))+" heading="+str(-g.presence.global_basis.z))
	g.save_game(true);g.load_game();await wait(.2)
	check("reopened choice is not overwritten by history",not room.curtains_closed() and float(room.cloth.get_shader_parameter("drawn"))<.01)
	g.presentation.prefs.data.reduced_motion=true;room.use_curtains()
	check("reduced motion applies completed cloth state",float(room.cloth.get_shader_parameter("drawn"))==1.0)
	g.lounge_contents.visible=false;await wait(.1)
	check("copied-bedroom visibility disables old pull and old cover",g.targets.lounge_curtains.collision_layer==0 and not room.blocks_sight(Vector3(8.5,1.6,1.5),Vector3(6,1.6,1.5)))
	g.lounge_contents.visible=true;g.presentation.prefs.data.reduced_motion=false
	var legacy: Dictionary=g.save_data().duplicate(true);legacy.events.erase("curtains_manual");legacy.events.atmosphere.used.curtains_drawn=1;g.apply_save(legacy);await wait(.2)
	check("legacy automatic curtain state still restores",room.curtains_closed() and float(room.cloth.get_shader_parameter("drawn"))==1.0)
	legacy.events.curtains_manual="bad";check("invalid optional curtain state is refused",not g.checkpoint_usable(legacy))
	await fixture();room.use_curtains();await wait(.9);g.player.position=Vector3(0,.03,-5);g.player.camera.look_at(Vector3(0,1.5,-8));director.policy.data.quiet=0
	check("already closed curtains cannot waste the unseen event",not director.request("curtains_drawn"))
	room.use_curtains();await wait(.9);director.policy.data.quiet=0
	check("eligible unseen contradiction still draws the actual cloth",director.request("curtains_drawn"))
	g.player.position=Vector3(5.55,.03,1.8);g.player.camera.look_at(g.targets.lounge_curtains.global_position);await wait(.2);await shot("R03_return_to_closed_window")
	await action("interact");await wait(.85);g.save_game(true);g.load_game();await wait(.15)
	check("player can undo the anomaly without it replaying",not room.curtains_closed() and int(director.policy.data.used.curtains_drawn)==1 and not director.request("curtains_drawn"))
	phase="overhead contacts answer actual movement"
	await fixture();g.player.position=Vector3(2.35,.03,-.85);g.player.velocity=Vector3.ZERO;g.player.camera.look_at(Vector3(5.5,1.6,-.85));await wait(.2)
	check("existing aftermath accepts a witnessed restored room",director.request("ceiling_return"))
	await wait(.7)
	check("standing still produces no manufactured footsteps",director.ceiling_active and director.ceiling_steps==0)
	await travel(Vector2(3.25,-.85),"actual first movement in the restored room");await wait(.55)
	check("real walking schedules a delayed overhead contact",director.ceiling_steps>0 and director.emitted.any(func(e):return e.get("kind","")=="answering_step" and e.where.y>2.6))
	var stopped: int=director.ceiling_steps;await wait(.8)
	check("stopping ends the sound train",director.ceiling_steps==stopped)
	await travel(Vector2(5.4,-.85),"player crosses existing lounge after hearing the answer");await wait(.5)
	check("bounded response preserves gravity and control",director.ceiling_steps<=4 and g.player.active and absf(g.player.position.y)<.08 and not g.presence.visible)
	await shot("R04_after_answering_steps")
	g.save_game(true);g.load_game();await wait(.2)
	check("save recovery never replays spent movement response",not director.ceiling_active and int(director.policy.data.used.ceiling_return)==1 and not director.request("ceiling_return"))
	await fixture();g.player.position=Vector3(3,.03,-.85);await wait(.1);check("interruptible movement fixture starts",director.request("ceiling_return"))
	await pad(JOY_BUTTON_START);var clock: float=director.ceiling_elapsed;await wait(.2)
	check("controller pause freezes response clock",g.menu_open and is_equal_approx(clock,director.ceiling_elapsed))
	await pad(JOY_BUTTON_B);g.events.threat_pending=true;await wait(.15)
	check("enemy reservation cancels optional response",not director.ceiling_active and director.ceiling_pending.is_empty())
	g.events.threat_pending=false
	await finish_run()
