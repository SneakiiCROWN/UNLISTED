extends "res://scripts/recording_repair_qa.gd"
var danger_snapshot: Dictionary={}
func play_place() -> void:
	await travel(Vector2(0,-7),"hall follows utility sound")
	if not g.doors.utility.opened:await use("utility")
	await travel(Vector2(-3.2,-7),"enter original utility doorway")
	await travel(Vector2(-4.8,-6.7),"walk around existing cover screen")
	await travel(Vector2(-6.4,-6.7),"reach cot along open rear aisle")
	g.player.camera.look_at(g.spare_place.COT);await shot("S01_breathing_cover")
	check("cloth is an actual shaped surface",g.spare_place.cloth.mesh.get_aabb().size.y>.2)
	g.save_game();g.load_game();await wait(.3)
	check("offered cover recovers before interaction",g.events.get("spare_offered",false) and not g.events.get("spare_uncovered",false))
	await use("spare_cover");await wait(.7)
	check("physical uncover reveals empty cot and card",g.spare_place.uncover>.99 and g.spare_place.card.visible)
	await shot("S02_empty_cot")
	await use("spare_card")
	check("birthday contradiction discovered without document popup",g.events.get("spare_card_read",false) and not g.menu_open)
	g.player.camera.look_at(g.spare_place.card.global_position);await shot("S03_false_birthday")
	for i in 30:
		if g.threat.active():break
		await wait(.1)
	check("offscreen arrival starts physical warned search",g.threat.active() and g.threat.collision_active and g.threat.grace>0)
	await action("ui_cancel");var frozen: Vector3=g.presence.position;await wait(.5)
	check("pause freezes approaching actor",g.menu_open and frozen.distance_to(g.presence.position)<.01)
	g.presentation.buttons.Resume.pressed.emit();g.save_game();g.load_game();await wait(.5)
	check("search save safely restores investigation and card",g.events.get("spare_card_read",false) and g.threat.grace>0 and g.spare_place.hunt_running)
	danger_snapshot=g.save_data().duplicate(true)
	await travel(Vector2(-5.95,-5.15),"crouch behind actual utility screen",false,true)
	await wait(5)
	check("cover blocks real pursuer sight",not g.threat.can_see_player() and g.presentation.section!="dead")
	g.player.camera.look_at(Vector3(-4.9,1.1,-5.8));await shot("S04_actual_search_cover")
	await travel(Vector2(-5.95,-6.7),"leave cover through rear aisle",false,true)
	await travel(Vector2(-4.8,-6.7),"escape around existing screen",true)
	await travel(Vector2(-4.5,-8.5),"rear service door approach",true)
	if not g.doors.service.opened:await use("service")
	await travel(Vector2(-4.5,-11.5),"escape actual rear threshold",true)
	for i in 80:
		if g.events.get("spare_hunt_done",false):break
		await wait(.1)
	check("search escape resolves without consuming cellar encounter",g.events.get("spare_hunt_done",false) and not g.events.get("threat_resolved",false) and not g.events.get("threat_pending",false))
	g.save_game();g.load_game();await wait(.4)
	check("resolved optional search does not repeat after load",not g.threat.active() and g.events.get("spare_hunt_done",false))
func risk_check() -> void:
	g.apply_save(danger_snapshot);await wait(.4);g.save_game()
	await travel(Vector2(-4,-7),"risk fixture / emerge into actual search")
	for i in 180:
		if g.presentation.section=="dead":break
		await wait(.1)
	check("new search can capture through actual detection/contact",g.presentation.section=="dead" and g.threat.state=="dead")
	if g.presentation.section!="dead":return
	await shot("S05_actual_capture")
	g.presentation.buttons["Retry Checkpoint"].pressed.emit();await wait(.5)
	check("new search death/retry retains clue and warning",g.events.get("spare_card_read",false) and g.threat.grace>2 and g.spare_place.hunt_running)
	var deaths: int=g.threat.deaths
	g.presentation.prefs.data.story_mode=true
	await travel(Vector2(-4,-7),"story-mode fixture / emerge into search")
	await wait(12)
	check("story-mode search preserves nonfatal alternative",g.presentation.section!="dead" and g.threat.deaths==deaths)
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	output=OS.get_executable_path().get_base_dir().path_join("QA/spare_place")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();g.new_game();g.stage=3;g.brass_key=true;g.shed_read=true
	g.events.chair=true;g.events["return"]=true;g.events.office=true;g.events.yard=true;g.events.impossible_room_resolved=true
	g.events.line_strip_read=true;g.events.threat_resolved=false;g.events.threat_pending=false
	g.doors.service.locked=false;g.doors.basement.locked=false;g.player.position=Vector3(0,.04,-7)
	g.presentation.clear_transients();for light in g.lamps:light.light_energy=.6
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	await wait(1)
	check("offered only after Dead Line discovery",g.events.get("spare_offered",false))
	await play_place()
	if "--spare-risk-qa" in OS.get_cmdline_user_args():await risk_check()
	recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"));recording=false;await wait(.2)
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	for spec in [["input_trace.json",trace],["frames.json",frames],["repair_report.json",{"passed":checks.size()-failed,"failed":failed,"checks":checks,"duration_seconds":seconds(),"scope":"Seeded post-Dead-Line setup, actual movement/input/AI/save recovery; not a fresh route or human playtest."}]]:
		var f=FileAccess.open(output.path_join(spec[0]),FileAccess.WRITE);f.store_string(JSON.stringify(spec[1],"\t"));f.close()
	print("SPARE_PLACE_COMPLETE ",checks.size()-failed," passed ",failed," failed");await g.qa_exit(0 if failed==0 else 1)
