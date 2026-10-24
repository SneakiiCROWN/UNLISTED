extends "res://scripts/recording_repair_qa.gd"
var scenario:="normal"
var seen_frames:=0
var watched_retirement:=false
var last_visible:=false
var samples: Array=[]
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
		if arg.begins_with("--vent-case="):scenario=arg.trim_prefix("--vent-case=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	g.new_game();g.events.chair=true;g.events.yard=true;g.events.basement=true;g.events["return"]=true
	g.fuse=true;g.interact("breaker");g.presentation.clear_transients();g.ambient_director.enabled=false
	g.doors.utility.locked=false;g.doors.utility.set_open(scenario!="closed",0)
	g.doors.basement.locked=false;g.doors.basement.set_open(true,0)
	g.player.position=Vector3(3.25,-2.999,-16.15);g.player.restore_stance(false);g.threat.reset()
	if scenario=="legacy":g.events.erase("vent_first_pass")
	if scenario=="busy":g.threat.enabled=false;g.events.threat_pending=true
	if scenario=="story":g.threat.enabled=false
	if scenario=="active":g.threat.begin(true,Vector3(-3.7,-2.99,-16.1))
	g.player.camera.look_at(Vector3(1.65,-2.05,-13.8))
	await wait(.3)
	await travel(Vector2(3.25,-13.0),"first physical crawl to midpoint",false,true)
	if scenario=="active":
		check("active encounter retains actor ownership",not g.horror.vent_owned and g.threat.active() and g.presence.visible)
		check("no staged start during existing encounter",g.horror.vent_history.is_empty())
		await shot("V_active_encounter_not_replaced");await finish();return
	if scenario in ["legacy","busy","closed"]:
		check("ineligible case does not take actor ownership",not g.horror.vent_owned and not g.presence.visible)
		await travel(Vector2(3.25,-9.3),"uninterrupted forward crawl and standing recovery",false,true)
		await wait(.3)
		check("records store remains reachable",g.player.position.y< -2.8 and g.player.can_stand())
		if scenario!="legacy":check("missed first crossing is safely spent",g.events.get("vent_first_pass","")=="spent")
		else:check("legacy save is not opted into a new scare",not g.events.has("vent_first_pass"))
		await finish();return
	check("first crawl starts shared working actor",g.horror.vent_owned and g.presence.visible and g.surveyor_model_path()=="res://assets/original/surveyor_presence.glb")
	check("no pursuit begins while player is confined",not g.threat.active())
	g.player.camera.look_at(Vector3(1.65,-2.05,-13.8))
	if scenario=="save":
		await action("ui_cancel");var body: Vector3=g.presence.position;var clock: float=g.surveyor_actor.animator.current_animation_position
		await wait(.5)
		check("pause suspends body and animation",g.presence.position.distance_to(body)<.001 and is_equal_approx(clock,g.surveyor_actor.animator.current_animation_position))
		await action("ui_cancel");g.save_game(true);body=g.presence.position;g.load_game();await wait(.05)
		check("load restores same physical crossing",g.horror.vent_owned and g.presence.position.distance_to(body)<.15 and g.events.vent_first_pass=="walking")
	elif scenario=="reverse":
		await travel(Vector2(3.25,-16.15),"fast reversal out of actual crawl",false,true)
		g.player.camera.look_at(g.presence.position+Vector3.UP*1.2)
	elif scenario in ["follow","story"]:
		await travel(Vector2(3.25,-16.15),"reverse to lower landing",false,true)
		g.player.restore_stance(false)
		await travel(Vector2(0,-16.15),"follow naturally toward stair",true,false)
		var before: Vector3=g.presence.position
		var jump:=0.0;var following:=seconds()
		g.player.rotation.y=PI;g.player.camera.rotation=Vector3.ZERO
		Input.action_press("forward");Input.action_press("sprint")
		while g.horror.vent_owned and seconds()-following<5:
			await get_tree().physics_frame
			jump=maxf(jump,g.presence.position.distance_to(before));before=g.presence.position
		Input.action_release("forward");Input.action_release("sprint")
		check("follow handoff has no positional jump",jump<.15,str(jump))
		if scenario=="follow":
			check("following transfers the same physical actor",not g.horror.vent_owned and g.threat.active() and g.events.get("threat_origin","")=="vent_follow")
			check("following retains fair warning",g.threat.grace>0 and g.player.active and not g.capture_director.active)
			await shot("V_follow_same_body");await finish();return
		check("story mode follow never activates threat",not g.threat.active() and g.player.active and not g.capture_director.active)
	elif scenario=="forward":
		await travel(Vector2(3.25,-9.3),"fast forward exit into records store",false,true)
		g.player.camera.look_at(Vector3(0,-1.8,-13.8))
	var start:=seconds();var got_shot:=false
	while g.horror.vent_owned and seconds()-start<24:
		var visible_now: bool=g.horror.visible_to_player()
		if visible_now:
			seen_frames+=1
			if not got_shot:await shot("V01_actual_grille_silhouette");got_shot=true
		if g.horror.vent_protected():check_once("confined player is never attacked",not g.threat.active() and not g.capture_director.active)
		samples.append({"time":seconds(),"player":str(g.player.position),"actor":str(g.presence.position),"visible":visible_now,"phase":g.events.get("vent_first_pass",""),"mode":g.surveyor_actor.mode})
		await wait(.08)
	check("staged body clears into real utility cover",not g.horror.vent_owned and g.events.vent_first_pass=="spent")
	var retired:=false
	for entry in g.horror.vent_history:
		if entry.event=="retired":retired=true
	check("normal retirement happens without threat or death",retired and not g.threat.active() and g.player.active)
	if scenario in ["normal","save"]:check("actual player camera sees the passing silhouette",seen_frames>0,str(seen_frames))
	await shot("V02_after_body_clears")
	g.save_game(true);g.load_game();await wait(.2)
	check("completed sighting survives load without respawn",not g.horror.vent_owned and not g.presence.visible and g.events.vent_first_pass=="spent")
	# Exact opening collision: the visible bars, rather than a hidden panel,
	# prevent the actual crouched player passing into the stairwell sleeve.
	if scenario=="normal":
		g.player.rotation.y=PI/2;g.player.camera.rotation=Vector3.ZERO
		Input.action_press("forward");await wait(1.0);Input.action_release("forward");await wait(.1)
		check("physical grille retains player inside crawl",g.player.position.x>2.65)
	await finish()
func check_once(id: String,okay: bool) -> void:
	for item in checks:
		if item.name==id:
			if not okay:item.passed=false
			return
	check(id,okay)
func finish() -> void:
	var f:=FileAccess.open(output.path_join("vent_samples.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"scenario":scenario,"samples":samples,"event_history":g.horror.vent_history},"\t"));f.close()
	await finish_run()
