extends "res://scripts/director_qa.gd"
# Spatial/input/audio fixtures plus fast deterministic policy simulations.
func run(current: Node) -> void:
	if "--dread-focus" in OS.get_cmdline_user_args():
		var focus=load("res://scripts/dread_within_qa.gd").new();focus.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(focus)
		await focus.run(current);return
	if "--identity-latch" in OS.get_cmdline_user_args():
		var focus=load("res://scripts/identity_latch_qa.gd").new();focus.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(focus)
		await focus.run(current);return
	g=current;started_at=Time.get_ticks_usec()
	output=OS.get_executable_path().get_base_dir().path_join("QA/ambient")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();g.new_game();g.stage=3;g.threat.enabled=false;g.threat.reset()
	g.events.chair=true;g.events["return"]=true;g.events.threat_resolved=true
	g.presentation.clear_transients();g.ambient_director.enabled=false
	for light in g.lamps:light.light_energy=.6
	for door in g.doors.values():door.locked=false;door.set_open(true,0)
	await wait(.7)
	var shelf: Node3D=g.lounge_contents.get_node("LoungeWallShelf")
	var bottles: Node3D=g.lounge_contents.get_node("LoungeShelfBottles")
	var bottle_base: AABB=render_bounds(bottles)
	check("lounge bottles rest on actual shelf",absf(bottle_base.position.y-top_at(shelf,bottle_base.get_center()))<.008,str(bottle_base))
	check("unsupported lower book row removed",g.lounge_contents.find_children("LoungeShelfBook*","",true,false).is_empty())
	g.events.memory_echo=true;g.events.memory_confirmed=true;g.horror.echo_index=-1
	g.player.position=Vector3(0,.04,1)
	await travel(Vector2(3,1),"existing lounge doorway route")
	await travel(Vector2(2.7,3.35),"lounge chair clearance")
	await travel(Vector2(5.3,3.35),"lounge front circulation")
	g.player.camera.look_at(Vector3(6,1.5,-2.7));await wait(.3);await shot("A01_lounge_shelf")
	# Remaining rare-story conditions must refer to the clue the player has.
	check("register recognises recovered page",g.NOTES.unfinished_return({"last_page_read":true}).contains("I've got"))
	check("register recognises decoded impressions",g.NOTES.unfinished_return({"carbon_read":true}).contains("radio"))
	var distribution: Array=[];var signatures: Dictionary={};var total_events:=0;var invariants:=true
	var ids: Array[String]=["window_taps","empty_room_steps","kitchen_tin"]
	for seed_ in range(16):
		var policy=load("res://scripts/ambient_schedule.gd").new();policy.restore({},seed_+321)
		var played: Array=[];var last:="";var last_time:=-1000
		for second in 1200:
			var event: String=policy.tick(1,ids,second%300<35)
			if event=="":continue
			if event==last or second-last_time<82:invariants=false
			policy.consume(event);played.append({"id":event,"at":second});last=event;last_time=second
		for entry in policy.EVENTS:
			if int(policy.data.used.get(entry.id,0))>entry.limit:invariants=false
		var replay=load("res://scripts/ambient_schedule.gd").new();replay.restore(policy.data,9999)
		check("seeded snapshot draw repeatability "+str(seed_),policy.choose(ids)==replay.choose(ids))
		var key:=JSON.stringify(played);signatures[key]=true;total_events+=played.size()
		distribution.append({"seed":seed_+321,"events":played})
	check("seeded policy respects quiet spacing and event limits",invariants)
	check("seeds produce varied combinations and timings",signatures.size()>8 and total_events>20,"variants="+str(signatures.size())+" events="+str(total_events))
	var out=FileAccess.open(output.path_join("seeded_distribution.json"),FileAccess.WRITE);out.store_string(JSON.stringify(distribution,"\t"));out.close()
	# Actual window source, followed by a real pause; nothing is directed at the player.
	g.ambient_director.enabled=true;g.player.position=Vector3(5.8,.04,2)
	g.player.camera.look_at(Vector3(7.37,1.6,2))
	var recorder:=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
	check("window event spatially eligible",g.ambient_director.request("window_taps"))
	var room: Node=g.get_node("LivingRoomFinishes")
	check("window response uses existing accepted event",room.response>0 or g.presentation.prefs.data.reduced_motion)
	await wait(.2);await action("ui_cancel")
	var phase_: float=g.ambient_director.elapsed;var curtain_phase: float=room.response;await wait(.5)
	check("pause freezes ambient sequence",g.menu_open and is_equal_approx(phase_,g.ambient_director.elapsed))
	check("pause freezes curtain response",is_equal_approx(curtain_phase,room.response))
	g.presentation.buttons.Resume.pressed.emit();await wait(1.2)
	check("two actual window sources play",g.ambient_director.emitted.size()==2 and g.ambient_director.emitted[0].playing and g.ambient_director.emitted[1].playing)
	await shot("A02_window_taps")
	g.save_game();g.load_game();await wait(.2)
	check("saved event is consumed without replay",int(g.ambient_director.policy.data.used.get("window_taps",0))==1 and g.ambient_director.queue.is_empty())
	check("reload clears transient curtain movement",room.response==0)
	var reduced_before: bool=g.presentation.prefs.data.reduced_motion
	g.presentation.prefs.data.reduced_motion=true;room.respond_window()
	check("reduced motion suppresses curtain tug",room.response==0)
	g.presentation.prefs.data.reduced_motion=reduced_before
	check("two fitted curtains belong to lounge memory",g.lounge_contents.find_children("FittedWindowCurtain*","MeshInstance3D",true,false).size()==2)
	check("office chair preserves original collision",g.get_node("OfficeTaskChair").find_children("*","CollisionShape3D",true,false).size()>0)
	check("cellar storage replaces bottle rows",g.get_node("CellarPartsRack").find_children("*","MeshInstance3D",true,false).size()>6)
	var actor: Node=g.presence.get_child(0)
	# Resolve the actual active skeleton modifier rather than a replacement model.
	var modifiers: Array=g.presence.find_children("*","SkeletonModifier3D",true,false)
	for modifier in modifiers:
		if not modifier.has_method("attention_point"):continue
		actor=modifier.actor
		g.threat.state="search";g.threat.last_known=Vector3(1,0,-7)
		actor.attention_override=null
		var point: Vector3=modifier.attention_point()
		g.player.position=Vector3(5,.04,-5)
		check("active Surveyor search gaze ignores hidden player movement",modifier.attention_point().is_equal_approx(point) and point.is_equal_approx(g.threat.last_known+Vector3.UP*1.45))
		actor.attention_override=Vector3(-3,1,-8)
		check("authored gaze override retains priority",modifier.attention_point().is_equal_approx(actor.attention_override))
		actor.attention_override=null;g.threat.reset()
	# Across-hall steps are interrupted by the existing physical encounter.
	g.player.position=Vector3(3,.04,-7);g.player.camera.look_at(Vector3(5.6,1,-8.7))
	check("empty utility footsteps eligible from office",g.ambient_director.request("empty_room_steps"))
	await wait(.2);g.threat.begin(false,Vector3(0,.04,-4));await wait(.2)
	check("authored threat cancels queued ambient cues",g.ambient_director.queue.is_empty())
	check("no ambient event replaces a live actor",not g.ambient_director.request("window_taps") and g.threat.state=="warning")
	g.threat.reset();g.presence.visible=false
	# A genuine rigid-body fall, never a teleported object or automatic enemy spawn.
	g.player.position=Vector3(-3,.04,0);g.player.camera.look_at(Vector3(0,1,-4))
	var tin: RigidBody3D=g.physical.props.can0
	check("unobserved kitchen fall eligible",g.ambient_director.request("kitchen_tin"))
	await wait(2.8)
	check("tin physically leaves countertop",tin.position.y<.3 and tin.position.z<3.3,str(tin.position))
	check("fall does not summon an enemy",g.threat.state=="dormant" and not g.presence.visible)
	g.player.camera.look_at(tin.position);await shot("A03_fallen_tin")
	g.save_game();var position_: Vector3=tin.position;g.load_game();await wait(.3)
	check("fallen tin and spent event survive reload",tin.position.distance_to(position_)<.10 and int(g.ambient_director.policy.data.used.get("kitchen_tin",0))==1)
	check("no repeated fall",not g.ambient_director.request("kitchen_tin"))
	recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"))
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	var report=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Seeded policy simulations plus native spatial/sound/physics/pause/save fixtures. Forced eligible events are not normal-play frequency evidence or subjective listening."},"\t"));report.close()
	print("AMBIENT_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
