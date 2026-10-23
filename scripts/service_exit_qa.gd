extends "res://scripts/recording_repair_qa.gd"
# Targeted native fixtures; no claim these staged starting states are a fresh route.
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	if output.is_empty():output=OS.get_executable_path().get_base_dir().path_join("QA/service_exit")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	g.new_game();g.presentation.clear_transients();g.stage=3;g.report_read=true;g.shed_read=true;g.brass_key=true
	g.events.chair=true;g.events["return"]=true;g.events.underfloor_read=true;g.events.underfloor_echo_complete=true
	g.events.threat_resolved=true;g.threat.enabled=false;g.threat.reset();g.events.archive_rack_open=true;g.events.archive_rack_x=3.15;g.maintenance.restore()
	g.presentation.prefs.data.story_mode=false;g.presentation.prefs.data.flicker_reduction=true
	if "--exit-layouts-only" in OS.get_cmdline_user_args():await layouts();await finish();return
	g.player.position=Vector3(13.25,.1,-8.35);g.player.restore_stance(false);await wait(.5)
	g.player.camera.look_at(Vector3(9.8,.5,-8.35));await shot("X01_exterior_bulkhead")
	await use("exit_outer_handle");await wait(1.6)
	check("outside handle opens without inventing an unwitnessed departure",g.events.get("exit_open",false) and not g.events.get("exit_false_departure",false))
	await travel(Vector2(12.0,-8.35),"outside landing approach")
	if not await travel(Vector2(9.0,-8.35),"real crouched descent through bulkhead",false,true):await finish();return
	check("incline remains grounded below the terrain",g.player.position.y< -1 and g.player.is_on_floor() and g.service_exit.in_passage(g.player.position),str(g.player.position))
	g.save_game();var p: Vector3=g.player.position;g.load_game();await wait(.2)
	check("new incline save restores stance and position",g.player.crouched and g.player.position.distance_to(p)<.15)
	if not await travel(Vector2(5.1,-8.35),"service incline enters records aisle",false,true):await finish();return
	await wait(.3)
	check("standing recovery in existing records store",not g.player.crouched and g.player.can_stand())
	g.player.camera.look_at(Vector3(7.5,-1.6,-8.35));await shot("X02_records_access")
	# Independent jammed-catch fixture, using the real shared carry/throw body.
	g.events.exit_open=false;g.events.exit_angle=0.0;g.events.exit_catch_free=false;g.service_exit.restore()
	var tin: RigidBody3D=g.physical.props.tin
	tin.relocate(Transform3D(Basis.IDENTITY,Vector3(5.0,-2.86,-8.9)));await wait(.4)
	g.player.camera.look_at(tin.global_position);await action("interact")
	check("existing tool tin picks up through real input",g.physical.held==tin)
	if not await travel(Vector2(10.25,-8.35),"carry existing weight up physical incline",false,true):await finish();return
	g.player.camera.look_at(g.targets.exit_catch.global_position);await wait(.4)
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.set_meta("unlisted_qa_input",true);Input.parse_input_event(click)
	await wait(.1);click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=false;click.set_meta("unlisted_qa_input",true);Input.parse_input_event(click);await wait(2)
	check("thrown shared prop physically frees seized catch",g.events.get("exit_catch_free",false) and g.physical.held==null)
	await use("exit_grille");await action("ui_cancel");var angle: float=g.service_exit.grille.rotation.y;await wait(.3)
	check("pause freezes moving grille",g.menu_open and is_equal_approx(angle,g.service_exit.grille.rotation.y))
	g.presentation.buttons.Resume.pressed.emit();g.save_game();g.load_game();await wait(.2)
	check("partial grille pose restores without snapping",absf(g.service_exit.grille.rotation.y-angle)<.22)
	await wait(2)
	check("departure printed before crossing disconnected contact",g.events.get("exit_false_departure",false) and g.player.position.x<11 and g.service_exit.receipt.visible)
	if not g.events.get("exit_false_departure",false):await finish();return
	g.player.camera.look_at(Vector3(11.8,.6,-8.35));await shot("X03_open_return")
	await travel(Vector2(5.0,-8.35),"return below before collecting impossible receipt",false,true)
	if not await travel(Vector2(5.0,-9.6),"contact logger approach"):await finish();return
	await use("exit_receipt",false)
	check("new evidence distinguishes false departure from Simon returning",g.events.get("exit_receipt_read",false) and g.events.notes.has(g.service_exit.TITLE) and g.presentation.note.text.contains("hadn't gone through"))
	await shot("X04_false_departure_evidence");await action("ui_cancel")
	var encounter_checkpoint: Dictionary=g.save_data().duplicate(true)
	g.threat.enabled=true;await wait(.5)
	check("blackout starts real existing Surveyor with fair warning",g.events.get("exit_blackout_running",false) and g.threat.active() and g.threat.grace>3 and g.events.threat_origin=="service_exit")
	await action("ui_cancel");var energy: float=g.maintenance.lamp.light_energy;await wait(.3)
	check("pause suspends local blackout",g.menu_open and is_equal_approx(energy,g.maintenance.lamp.light_energy))
	g.presentation.buttons.Resume.pressed.emit();g.save_game();g.load_game();await wait(.5)
	check("blackout checkpoint resumes real encounter and collected evidence",g.events.get("exit_blackout_running",false) and g.threat.active() and not g.service_exit.receipt.visible)
	await wait(2);g.player.camera.look_at(Vector3(3.25,-2,-10.4));await shot("X05_blackout_store")
	await travel(Vector2(5.0,-8.35),"blackout working aisle")
	await travel(Vector2(10.4,-8.35),"escape uses new real crawl route",false,true)
	if not await travel(Vector2(12.2,-8.35),"new service exit reaches actual yard",false,true):await finish();return
	await wait(.4)
	check("standing recovers outside without jump or teleport",g.player.position.y>-.2 and g.player.is_on_floor() and not g.player.crouched and g.presentation.section!="dead",str(g.player.position))
	await travel(Vector2(13.7,-8.35),"clear outward grille sweep")
	g.player.camera.look_at(Vector3(10.5,.4,-8.35));await shot("X06_yard_escape")
	for i in 240:
		if g.events.get("exit_blackout_done",false):break
		await wait(.15)
	check("escaping resolves local search and restores prior story state",g.events.get("exit_blackout_done",false) and not g.threat.active() and g.events.get("threat_resolved",false) and not g.events.get("threat_pending",false))
	await wait(1.6)
	check("local lighting returns without changing flashlight",absf(g.maintenance.lamp.light_energy-.7)<.02 and g.player.torch.visible)
	g.save_game();g.load_game();await wait(.4)
	check("completed discovery does not replay after load",g.events.get("exit_blackout_done",false) and not g.events.get("exit_blackout_running",true) and not g.threat.active())
	await use("exit_grille");await wait(2.2)
	check("grille can close from actual exterior",absf(g.service_exit.grille.rotation.y)<.02)
	await travel(Vector2(13.25,-8.35),"approach closed exterior handle within reach")
	await use("exit_outer_handle");await wait(2.2)
	await travel(Vector2(12,-8.35),"outside return landing")
	await travel(Vector2(5.0,-8.35),"new route works in reverse after search",false,true);await wait(.2)
	check("records store remains usable after reverse return",g.maintenance.inside(g.player.position) and g.player.position.y< -2.9 and not g.player.crouched and g.player.can_stand())
	await wait(2)
	check("return without reloading cannot restart consumed blackout",g.events.get("exit_blackout_done",false) and not g.events.get("exit_blackout_running",true) and not g.threat.active())
	# Old outdoor saves in the new bulkhead footprint recover to adjacent open ground.
	var old: Dictionary=g.save_data();old.pos=[9.5,0,-8.35];old.events.erase("exit_version");g.apply_save(old);await wait(.2)
	check("legacy exterior save avoids new roof geometry",g.player.position.z> -7.1 and not g.player.crouched)
	if "--exit-risk-qa" in OS.get_cmdline_user_args():await risk_cases(encounter_checkpoint)
	await finish()
func layouts() -> void:
	# Explicit layout/knowledge fixtures; earned progression is covered by the route.
	g.player.position=Vector3(5,-2.999,-9.6);g.player.restore_stance(false)
	g.events.exit_false_departure=true;g.events.exit_receipt_read=false;g.service_exit.restore();await wait(.4)
	g.player.camera.look_at(g.targets.exit_receipt.global_position);await shot("X09_terminal_contact_strip")
	g.report_read=false;await use("exit_receipt",false)
	check("early discovery does not reveal unread 1998 findings",not g.presentation.note.text.contains("EMPTY") and not g.presentation.note.text.contains("Dad's terminal"))
	await shot("X10_early_contact_evidence");await action("ui_cancel")
	g.report_read=true;g.events.exit_receipt_read=false;g.service_exit.restore();await wait(.2)
	await use("exit_receipt",false)
	var view: Vector2=g.get_viewport().get_visible_rect().size
	check("new evidence fits actual viewport",g.presentation.card.get_global_rect().position.x>=0 and g.presentation.card_body.get_global_rect().end.y<=view.y)
	await shot("X04_false_departure_evidence");await action("ui_cancel")
	g.events.memory_confirmed=true;g.events.witness_carbon_read=true;g.presentation.show_register();await wait(1)
	check("discovery-context register fits actual viewport",g.presentation.card.get_global_rect().position.x>=0 and g.presentation.card_body.get_global_rect().end.y<=view.y)
	var previous_end:=-INF
	for child in g.presentation.card_body.get_children():
		if child is Button and child.visible:
			check("register choice remains separate / "+child.text,child.get_global_rect().position.y>=previous_end and child.get_global_rect().end.y<=view.y);previous_end=child.get_global_rect().end.y
	await shot("X11_discovery_register")
func expose_to_actor(story: bool) -> void:
	await travel(Vector2(3.25,-9.3),"deliberate exposure / records aisle")
	await travel(Vector2(3.25,-14.0),"deliberate exposure / protected crawl",false,true)
	phase="deliberate live contact / story" if story else "deliberate live contact / lethal"
	var start: float=seconds()
	Input.action_press("forward")
	while seconds()-start<22:
		if g.presentation.section=="dead" or (story and g.threat.state=="recovery"):break
		var diff: Vector3=g.presence.position-g.player.position
		g.player.rotation.y=atan2(-diff.x,-diff.z);g.player.camera.rotation=Vector3.ZERO
		await get_tree().physics_frame
	Input.action_release("forward");await wait(.3)
func risk_cases(snapshot: Dictionary) -> void:
	g.checkpoint_path=output.path_join("risk_checkpoint.json")
	g.apply_save(snapshot);g.threat.enabled=true;g.presentation.prefs.data.story_mode=false;await wait(.5)
	check("pre-contact recovery begins safely in records store",g.maintenance.inside(g.player.position) and g.threat.state=="warning" and g.threat.grace>3)
	await expose_to_actor(false)
	check("deliberate exposure to real Surveyor can kill in new branch",g.presentation.section=="dead" and g.threat.deaths>0)
	await wait(1.2);await shot("X07_deliberate_contact_death")
	if g.presentation.section!="dead":return
	g.presentation.buttons["Retry Checkpoint"].pressed.emit();await wait(.5)
	check("new encounter retry restores safe store and evidence",g.player.active and g.presentation.section=="game" and g.maintenance.inside(g.player.position) and g.events.get("exit_receipt_read",false) and g.threat.grace>3)
	g.presentation.prefs.data.story_mode=true;await expose_to_actor(true)
	check("story-mode contact remains nonlethal in new encounter",g.presentation.section=="game" and g.threat.state=="recovery")
	await shot("X08_story_contact");g.threat.reset();g.events.threat_pending=false;g.presence.visible=false
func finish() -> void:
	recording=false;recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"));await wait(.2)
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	for spec in [["input_trace.json",trace],["frames.json",frames],["report.json",{"passed":checks.size()-failed,"failed":failed,"checks":checks,"duration_seconds":seconds(),"scope":"Native staged service-exit movement, actual prop throw, physical contact test, local blackout/live AI, pause and save. Not a fresh full-route or human playtest."}]]:
		var file=FileAccess.open(output.path_join(spec[0]),FileAccess.WRITE);file.store_string(JSON.stringify(spec[1],"\t"));file.close()
	print("SERVICE_EXIT_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed");await g.qa_exit(0 if failed==0 else 1)
