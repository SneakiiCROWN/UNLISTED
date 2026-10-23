extends "res://scripts/missing_minute_qa.gd"
# Staged regression fixtures. The separate continuous helper earns the same route.
func plan_widget() -> Control:
	for node in g.presentation.card_body.get_children():
		if node.get_script() and str(node.get_script().resource_path).ends_with("plan_lightbox.gd"):return node
	return null
func wheel(point: Vector2) -> void:
	var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_WHEEL_UP;e.pressed=true
	e.position=g.get_viewport().get_stretch_transform()*point;e.global_position=e.position;e.set_meta("unlisted_qa_input",true);Input.parse_input_event(e);await wait(.08)
func wait_for(flag: String,limit: float) -> bool:
	var end: float=seconds()+limit
	while not g.events.get(flag,false) and seconds()<end:await wait(.05)
	return g.events.get(flag,false)
func finish() -> void:
	recording=false
	if recorder:
		recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"))
	var failed:=0
	for item in checks:
		if not item.passed:failed+=1
	var f:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"scope":"Explicit native Windows plan, bay, real audio/search and recovery fixtures; not a fresh route or human approval","passed":checks.size()-failed,"failed":failed,"checks":checks,"duration_seconds":seconds(),"frames":frames},"\t"));f.close()
	print("LAST_CALL_QA_COMPLETE passed=",checks.size()-failed," failed=",failed);await g.qa_exit(0 if failed==0 else 1)
func start_recording() -> void:
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
func risk_checks(source: String) -> void:
	g.new_game();g.apply_save(JSON.parse_string(FileAccess.get_file_as_string(source)));await wait(.5)
	g.presentation.clear_transients();g.threat.enabled=true;g.presentation.prefs.data.story_mode=false
	await wait_for("call_search_running",4)
	check("earned cold bay checkpoint restores real search target",g.events.get("call_search_running",false) and g.threat.active() and g.threat.last_known.distance_to(Vector3(-3.25,-3,-15.7))<.1)
	var deadline: float=seconds()+24
	while seconds()<deadline and not (g.threat.can_see_player() and g.threat.state in ["pursue","attack"]) and g.presentation.section!="dead":await wait(.05)
	check("unhidden player is genuinely acquired in bay",g.threat.can_see_player() and g.threat.state in ["pursue","attack"],g.threat.state+" / "+str(g.presence.position))
	await use("call_remote")
	await wait(.55)
	check("visible pursuit ignores real playing recording",g.field_tape.playing and g.threat.last_known.distance_to(g.field_tape.DECK)>3 and g.threat.state in ["pursue","attack","capture","dead"],g.threat.state+" / "+str(g.threat.last_known))
	await shot("K01_visible_pursuit_ignores_reel")
	deadline=seconds()+18;var captured:=false
	while g.presentation.section!="dead" and seconds()<deadline:
		if g.capture_director.active and g.capture_director.clock>1.3 and not captured:
			await shot("K01_physical_contact");captured=true
		await wait(.1)
	check("remaining exposed has real death consequence",g.presentation.section=="dead")
	await wait(1.1);await shot("K02_bay_consequence")
	if g.presentation.section!="dead":return
	g.presentation.buttons["Retry Checkpoint"].pressed.emit();await wait(.4)
	check("bay retry restores hardware evidence and fair warning",g.events.get("call_disconnected",false) and g.events.get("call_note_read",false) and g.doors.call_niche.opened and g.threat.grace>3 and g.player.active)
	# Same saved physical encounter, story mode only changes lethal contact.
	g.presentation.prefs.data.story_mode=true
	var contacts: int=g.threat.deaths;deadline=seconds()+22;var recovered:=false
	while seconds()<deadline and g.presentation.section!="dead":
		if g.threat.state=="recovery":recovered=true;break
		await wait(.05)
	check("story mode preserves threatening contact without death",recovered and g.threat.deaths==contacts and g.player.active)
	await shot("K03_story_mode_contact")
	g.presentation.prefs.data.story_mode=false
func pad(button: int,pressed:=true) -> void:
	var e:=InputEventJoypadButton.new();e.button_index=button;e.pressed=pressed;e.set_meta("unlisted_qa_input",true);Input.parse_input_event(e);await wait(.10)
func tap(button: int) -> void:await pad(button);await pad(button,false)
func axis(id: int,value: float) -> void:
	var e:=InputEventJoypadMotion.new();e.axis=id;e.axis_value=value;e.set_meta("unlisted_qa_input",true);Input.parse_input_event(e);await wait(.06)
func pad_checks() -> void:
	await tap(JOY_BUTTON_X);var widget:=plan_widget()
	check("controller X opens physical plan cabinet",widget!=null)
	if widget==null:return
	await tap(JOY_BUTTON_A);var initial: Vector2=widget.offset
	await axis(JOY_AXIS_RIGHT_X,-1);await wait(.45);await axis(JOY_AXIS_RIGHT_X,0)
	check("controller places and slides actual tracing",widget.placed and widget.offset.x<initial.x-40 and not g.events.get("call_plan_aligned",false))
	var partial: Vector2=widget.offset;await tap(JOY_BUTTON_B);g.save_game();g.load_game();await wait(.3);await tap(JOY_BUTTON_X);widget=plan_widget()
	check("controller partial placement persists",widget!=null and widget.offset.distance_to(partial)<2 and not g.events.get("call_plan_aligned",false))
	if widget==null:return
	await tap(JOY_BUTTON_DPAD_DOWN)
	check("controller can leave paper focus for controls",g.get_viewport().gui_get_focus_owner()==g.presentation.buttons["Place tracing"])
	await tap(JOY_BUTTON_DPAD_RIGHT);var angle_: float=widget.angle;await tap(JOY_BUTTON_A)
	check("controller turns tracing through real focused control",widget.angle<angle_-.05)
	await tap(JOY_BUTTON_DPAD_RIGHT);await tap(JOY_BUTTON_DPAD_RIGHT);await tap(JOY_BUTTON_A);await wait(3)
	check("optional steady control completes gradual accessible alignment",g.events.get("call_plan_aligned",false) and widget.offset.is_zero_approx())
	await shot("K04_controller_aligned_plans");await tap(JOY_BUTTON_B)
	check("controller closes plans and restores play",not g.menu_open and g.player.active)
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json");await exact_resolution()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--last-call-landing="):
			start_recording();g.new_game();g.apply_save(JSON.parse_string(FileAccess.get_file_as_string(arg.trim_prefix("--last-call-landing="))));await wait(.4)
			check("landing continuation uses fully earned original investigation",g.events.get("bedroom_left",false) and g.events.get("memory_confirmed",false) and g.events.get("test_reel_loaded",false) and g.events.get("call_plan_aligned",false) and not g.events.get("call_disconnected",false))
			await play_from_landing()
			for result in checks:
				if not result.passed:await finish_run(false);return
			await finish_departure();return
		if arg.begins_with("--last-call-resume="):
			start_recording();await resume_earned(arg.trim_prefix("--last-call-resume="));return
		if arg.begins_with("--last-call-legacy="):
			g.new_game();g.apply_save(JSON.parse_string(FileAccess.get_file_as_string(arg.trim_prefix("--last-call-legacy="))));await wait(.4)
			check("real older earned checkpoint has no new case gate",not g.events.get("case_v4",false) and not g.events.get("call_complete",false))
			check("real legacy completed save restores existing ending",g.ended and g.presentation.section=="ending" and g.events.get("ending","")=="on_record")
			g.save_game();g.presentation.buttons["Main Menu"].pressed.emit();await wait(.3)
			check("legacy completed menu retains View Ending",g.presentation.buttons.has("View Ending"))
			if g.presentation.buttons.has("View Ending"):g.presentation.buttons["View Ending"].pressed.emit();await wait(.3)
			check("legacy completed view remains correct",g.ended and g.presentation.section=="ending")
			# Explicit derived porch fixture: preserve all genuinely earned flags, only restore pre-departure placement.
			var previous: Dictionary=g.save_data().duplicate(true);previous.ended=false;previous.pos=[-.7,.04,5.5];previous.events.departure_pending=""
			g.apply_save(previous);await wait(.3);await use("order",false)
			check("derived legacy porch keeps both earned choices without new chapter",g.presentation.section=="register" and g.presentation.buttons.has("Simon Ward / PRESENT") and g.presentation.buttons.has("Attach original / keep Simon's case open"))
			await shot("K05_legacy_choices");await finish();return
		if arg.begins_with("--last-call-risk="):
			start_recording();await risk_checks(arg.trim_prefix("--last-call-risk="));await finish();return
	if "--last-call-record" in OS.get_cmdline_user_args():start_recording()
	g.new_game();await wait(2);g.presentation.clear_transients();g.threat.enabled=false;g.threat.reset()
	g.stage=3;g.report_read=true;g.shed_read=true;g.brass_key=true;g.events.chair=true;g.events["return"]=true;g.events.yard=true
	g.events.test_reel_found=true;g.events.test_reel_loaded=true;g.events.test_reel_heard=true;g.field_tape.restore()
	g.events.exit_catch_free=true;g.events.exit_open=true;g.events.exit_angle=1.65;g.service_exit.restore() # Known-exit fixture; full route earns this normally.
	g.equipment.data.contact_wait=500;g.doors.basement.locked=false;g.doors.office.locked=false
	g.player.position=Vector3(3,.04,-4.65);g.player.camera.look_at(g.targets.call_lightbox.global_position);await wait(.3)
	if "--last-call-pad" in OS.get_cmdline_user_args():await pad_checks();await finish();return
	await shot("L00_office_lightbox");await use("call_lightbox",false)
	var widget:=plan_widget();check("physical lightbox opens the two sourced plans",widget!=null and g.last_call.plans_available())
	if widget==null:await finish();return
	await shot("L01_unregistered_sheets")
	check("no clue awarded merely by opening lightbox",not g.events.get("call_plan_aligned",false))
	var from: Vector2=widget.global_position+widget.CENTRE+widget.offset
	var to: Vector2=widget.global_position+widget.CENTRE+Vector2(15,8)
	await pointer(from,true);await pointer(to,true,true);await pointer(to,false);await wait(.2)
	check("actual drag places tracing with generous positional tolerance",widget.placed and widget.offset.distance_to(Vector2(15,8))<3 and not g.events.get("call_plan_aligned",false),str(widget.offset))
	g.save_game();g.load_game();await wait(.2);await use("call_lightbox",false);widget=plan_widget()
	check("partly placed sheet survives save/load without granting solution",widget!=null and widget.placed and widget.offset.length()<22 and not g.events.get("call_plan_aligned",false))
	if widget==null:await finish();return
	to=widget.global_position+widget.CENTRE+widget.offset
	for i in 3:await wheel(to)
	check("actual rotation registers shared landmarks without pixel precision",g.events.get("call_plan_aligned",false) and widget.offset.is_zero_approx() and is_zero_approx(widget.angle))
	check("discrepancy names both origins and the physical landing",g.events.notes.get(g.last_call.PLAN_TITLE,"").contains("issued in 1998") and g.events.notes[g.last_call.PLAN_TITLE].contains("west side"))
	await shot("L02_registered_missing_door")
	check("lightbox card fits native viewport",g.get_viewport().get_visible_rect().encloses(g.presentation.card.get_global_rect()),str(g.presentation.card.get_global_rect()))
	if "--last-call-layouts-only" in OS.get_cmdline_user_args():
		g.presentation.buttons["Put down"].pressed.emit();await wait(.4);g.events.call_complete=true
		for compared in [false,true]:
			g.events.memory_confirmed=compared;g.presentation.show_register();await wait(.2);await shot("L03_earned_choice_layout_"+str(compared))
			var end_: float=0
			for button in g.presentation.buttons.values():end_=maxf(end_,button.get_global_rect().end.y)
			check("evidence-aware ending controls fit / compared="+str(compared),g.get_viewport().get_visible_rect().encloses(g.presentation.card.get_global_rect()) and end_<=g.get_viewport().get_visible_rect().end.y,str(end_))
		g.presentation.resume_game();g.last_call.use("call_page");await wait(.3);await shot("L07_dated_page_layout")
		check("later page visibly dates and explains the 1998 test",g.presentation.note.text.begins_with("17 BRIAR LANE / S. WARD / 1998") and g.presentation.note.text.contains("After the lounge inspection"))
		await finish();return
	g.presentation.buttons["Put down"].pressed.emit();await wait(.2)
	await travel(Vector2(3.3,-7),"lightbox investigation leaves office")
	if not g.doors.office.opened:await use("office")
	await travel(Vector2(0,-7),"plans reach stairwell")
	await travel(Vector2(0,-8.4),"reach cellar door handle")
	if not g.doors.basement.opened:
		if not await use("basement"):await finish();return
	if not await travel(Vector2(0,-18),"real lower landing"):await finish();return
	g.player.camera.look_at(g.targets.call_niche.global_position);await shot("L04_landing_context")
	await travel(Vector2(-3.25,-16.15),"find marked west landing wall")
	g.player.camera.look_at(g.targets.call_niche.global_position);await shot("L04_unlisted_doorway")
	if not g.doors.call_niche.opened:await use("call_niche")
	await wait(1)
	await travel(Vector2(-3.25,-14.1),"walk through real doorway into the bay")
	check("new bay has real standing clearance and floor contact",g.player.position.y< -2.8 and g.player.is_on_floor() and g.player.can_stand() and not g.player.crouched)
	g.player.camera.look_at(Vector3(-4.0,-2.65,-13.3));await shot("L05_supported_bay_floor")
	g.player.camera.look_at(Vector3(-3.25,-1.4,-13));await shot("L05_physical_call_evidence")
	await use("call_bridge");check("signal bridge actually leaves its contacts",g.events.get("call_disconnected",false) and g.last_call.jumper.position.y<-.15 and g.targets.call_bridge.collision_layer==0)
	await use("call_remote");await wait(3)
	check("real remote runs audible upstairs reel",g.field_tape.playing and g.field_tape.remote and is_instance_valid(g.field_tape.motor) and g.field_tape.motor.playing and g.field_tape.motor.max_distance>g.field_tape.motor.global_position.distance_to(g.player.camera.global_position))
	await action("ui_cancel");var t: float=g.field_tape.clock;await wait(.4)
	check("pause freezes remote test chronology",g.menu_open and is_equal_approx(t,g.field_tape.clock))
	await action("ui_cancel");g.save_game();g.load_game();await wait(.2)
	check("interrupted test retains hardware without awarding unheard reply",g.events.get("call_disconnected",false) and not g.field_tape.playing and not g.events.get("call_test_complete",false))
	await use("call_remote");await wait_for("call_test_complete",18)
	check("disconnected monitor visibly and audibly completes a real test",g.events.get("call_test_complete",false) and g.events.get("call_search_pending",false))
	await shot("L06_dead_monitor_answers")
	await use("call_page",false)
	check("discovery explains why Simon stayed without revealing an identity",g.events.get("call_note_read",false) and g.presentation.note.text.contains("It was using things I knew") and not g.presentation.note.text.contains("Simon is the Surveyor"))
	await shot("L07_after_the_lounge");await action("ui_cancel")
	var checkpoint: Dictionary=g.save_data().duplicate(true);var out:=FileAccess.open(output.path_join("earned_bay_checkpoint.json"),FileAccess.WRITE);out.store_string(JSON.stringify(checkpoint));out.close()
	g.threat.enabled=true;await wait_for("call_search_running",3)
	check("new search starts off-screen with actual warned AI",g.events.get("call_search_running",false) and g.threat.active() and g.threat.grace>2.5)
	await action("ui_cancel");var energy: float=g.last_call.bay_light.light_energy;var position_: Vector3=g.presence.position;await wait(.4)
	check("blackout pause freezes lighting and physical enemy",g.menu_open and is_equal_approx(energy,g.last_call.bay_light.light_energy) and g.presence.position.distance_to(position_)<.001)
	await action("ui_cancel");g.save_game();g.load_game();await wait(.3)
	check("saved search resumes correct origin with a fresh fair warning",g.threat.active() and g.events.threat_origin=="last_call" and g.threat.grace>3)
	await use("call_remote")
	var end: float=seconds()+12
	while g.threat.last_known.distance_to(g.field_tape.DECK)>.1 and seconds()<end:await wait(.05)
	check("recording draws real search to its actual upstairs source",g.threat.last_known.distance_to(g.field_tape.DECK)<.1 and g.field_tape.sources.any(func(a):return is_instance_valid(a) and a.playing and a.global_position.distance_to(g.field_tape.DECK)<.1) and g.threat.active() and not g.events.get("call_search_done",false),g.threat.state+" / "+str(g.threat.last_known))
	g.player.camera.look_at(Vector3(-3.25,-1.6,-15.8));await shot("L08_playback_draws_search")
	# The original low return remains a physical escape, never a teleport or hidden flag.
	await travel(Vector2(-3.25,-16.1),"leave bay while deck runs")
	await travel(Vector2(0,-18),"cross actual cellar landing")
	await travel(Vector2(3.25,-16.1),"reach original low return")
	await travel(Vector2(3.25,-12.8),"crouch through original maintenance passage",false,true)
	await travel(Vector2(3.25,-9.3),"reach records cover",false,true)
	await travel(Vector2(5,-8.35),"clear aisle towards known service exit")
	await travel(Vector2(9,-8.35),"escape up real service incline",false,true)
	await travel(Vector2(12.3,-8.35),"reach actual east yard",false,true)
	check("physical escape retains control without death or jumping",g.player.position.y>-.2 and g.player.active and g.presentation.section!="dead")
	await wait_for("call_complete",20)
	check("surviving test and finding final page completes coherent act",g.events.get("call_complete",false) and g.events.notes.has("ELI / THE LAST CALL"))
	g.save_game();g.load_game();await wait(.3)
	check("earned act and evidence survive save recovery",g.events.get("call_complete",false) and not g.events.get("call_search_running",false))
	await shot("L09_east_yard_escape")
	await finish()

func play_continuous() -> void:
	await travel(Vector2(0,-7),"last-call investigation returns to office")
	if not g.doors.office.opened:await use("office")
	await travel(Vector2(3,-7),"recovered tracing enters office")
	await travel(Vector2(3,-4.65),"sourced plan cabinet approach")
	await use("call_lightbox",false)
	var widget:=plan_widget();check("earned reel supplies actual cellar tracing",widget!=null and g.last_call.plans_available())
	if widget==null:return
	var from: Vector2=widget.global_position+widget.CENTRE+widget.offset
	var to: Vector2=widget.global_position+widget.CENTRE+Vector2(15,8)
	await pointer(from,true);await pointer(to,true,true);await pointer(to,false)
	for i in 3:await wheel(to)
	check("earned manual plan comparison identifies missing doorway",g.events.get("call_plan_aligned",false))
	await shot("L02_registered_missing_door");g.presentation.buttons["Put down"].pressed.emit();await wait(.2)
	await travel(Vector2(3.3,-7),"lightbox investigation leaves office")
	if not g.doors.office.opened:await use("office")
	await travel(Vector2(0,-7),"plans reach stairwell")
	await travel(Vector2(0,-8.4),"reach cellar door handle")
	if not g.doors.basement.opened:
		if not await use("basement"):return
	if not await travel(Vector2(0,-18),"real lower landing"):return
	await play_from_landing()
func play_from_landing() -> void:
	g.player.camera.look_at(g.targets.call_niche.global_position);await shot("L04_landing_context")
	await travel(Vector2(-3.25,-16.15),"find marked west landing wall")
	g.player.camera.look_at(g.targets.call_niche.global_position);await shot("L04_unlisted_doorway")
	if not g.doors.call_niche.opened:await use("call_niche")
	await wait(1)
	await travel(Vector2(-3.25,-14.1),"walk through real doorway into the bay")
	check("new bay has real standing clearance and floor contact",g.player.position.y< -2.8 and g.player.is_on_floor() and g.player.can_stand() and not g.player.crouched)
	g.player.camera.look_at(Vector3(-4.0,-2.65,-13.3));await shot("L05_supported_bay_floor")
	g.player.camera.look_at(Vector3(-3.25,-1.4,-13));await shot("L05_physical_call_evidence")
	await use("call_bridge");check("signal bridge actually leaves its contacts",g.events.get("call_disconnected",false) and g.last_call.jumper.position.y<-.15 and g.targets.call_bridge.collision_layer==0)
	await use("call_remote");await wait(3)
	check("real remote runs audible upstairs reel",g.field_tape.playing and g.field_tape.remote and is_instance_valid(g.field_tape.motor) and g.field_tape.motor.playing and g.field_tape.motor.max_distance>g.field_tape.motor.global_position.distance_to(g.player.camera.global_position))
	await action("ui_cancel");var t: float=g.field_tape.clock;await wait(.4)
	check("pause freezes remote test chronology",g.menu_open and is_equal_approx(t,g.field_tape.clock))
	await action("ui_cancel");g.save_game();g.load_game();await wait(.2)
	check("interrupted test retains hardware without awarding unheard reply",g.events.get("call_disconnected",false) and not g.field_tape.playing and not g.events.get("call_test_complete",false))
	await use("call_remote");await wait_for("call_test_complete",18)
	check("disconnected monitor visibly and audibly completes a real test",g.events.get("call_test_complete",false) and (g.events.get("call_search_pending",false) or g.events.get("call_search_running",false)))
	await shot("L06_dead_monitor_answers")
	await use("call_page",false)
	check("discovery explains why Simon stayed without revealing an identity",g.events.get("call_note_read",false) and g.presentation.note.text.contains("It was using things I knew") and not g.presentation.note.text.contains("Simon is the Surveyor"))
	await shot("L07_after_the_lounge");await action("ui_cancel")
	var checkpoint: Dictionary=g.save_data().duplicate(true);var out:=FileAccess.open(output.path_join("earned_bay_checkpoint.json"),FileAccess.WRITE);out.store_string(JSON.stringify(checkpoint));out.close()
	await wait_for("call_search_running",3)
	check("new search starts off-screen with actual warned AI",g.events.get("call_search_running",false) and g.threat.active() and g.threat.grace>2.5)
	await action("ui_cancel");var energy: float=g.last_call.bay_light.light_energy;var position_: Vector3=g.presence.position;await wait(.4)
	check("blackout pause freezes lighting and physical enemy",g.menu_open and is_equal_approx(energy,g.last_call.bay_light.light_energy) and g.presence.position.distance_to(position_)<.001)
	await action("ui_cancel");g.save_game();g.load_game();await wait(.3)
	check("saved search resumes correct origin with a fresh fair warning",g.threat.active() and g.events.threat_origin=="last_call" and g.threat.grace>3)
	await use("call_remote")
	var end: float=seconds()+12
	while g.threat.last_known.distance_to(g.field_tape.DECK)>.1 and seconds()<end:await wait(.05)
	check("recording draws real search to its actual upstairs source",g.threat.last_known.distance_to(g.field_tape.DECK)<.1 and g.field_tape.sources.any(func(a):return is_instance_valid(a) and a.playing and a.global_position.distance_to(g.field_tape.DECK)<.1) and g.threat.active() and not g.events.get("call_search_done",false),g.threat.state+" / "+str(g.threat.last_known))
	g.player.camera.look_at(Vector3(-3.25,-1.6,-15.8));await shot("L08_playback_draws_search")
	# The original low return remains a physical escape, never a teleport or hidden flag.
	await travel(Vector2(-3.25,-16.1),"leave bay while deck runs")
	await travel(Vector2(0,-18),"cross actual cellar landing")
	await travel(Vector2(3.25,-16.1),"reach original low return")
	await travel(Vector2(3.25,-12.8),"crouch through original maintenance passage",false,true)
	await travel(Vector2(3.25,-9.3),"reach records cover",false,true)
	await travel(Vector2(5,-8.35),"clear aisle towards known service exit")
	await travel(Vector2(9,-8.35),"escape up real service incline",false,true)
	await travel(Vector2(12.3,-8.35),"reach actual east yard",false,true)
	check("physical escape retains control without death or jumping",g.player.position.y>-.2 and g.player.active and g.presentation.section!="dead")
	await wait_for("call_complete",20)
	check("surviving test and finding final page completes coherent act",g.events.get("call_complete",false) and g.events.notes.has("ELI / THE LAST CALL"))
	g.save_game();g.load_game();await wait(.3)
	check("earned act and evidence survive save recovery",g.events.get("call_complete",false) and not g.events.get("call_search_running",false))
	await shot("L09_east_yard_escape")

	await travel(Vector2(12.3,-3),"evidence leaves service yard along house")
	await travel(Vector2(9,6.5),"evidence returns around east property")
	await travel(Vector2(0,7),"last call reaches porch approach")
	if not g.doors.front.opened:
		await travel(Vector2(0,5.5),"enter front after cellar test");await use("front")
	await travel(Vector2(0,2.5),"last call rejoins final hall")

func resume_earned(source: String) -> void:
	g.new_game();g.apply_save(JSON.parse_string(FileAccess.get_file_as_string(source)));await wait(.4)
	check("resume uses continuous route's genuinely earned bay evidence",g.events.get("bedroom_left",false) and g.events.get("memory_confirmed",false) and g.events.get("test_reel_loaded",false) and g.events.get("call_note_read",false) and g.events.get("call_test_complete",false) and g.events.get("call_disconnected",false))
	await wait_for("call_search_running",4)
	check("earned saved bay resumes a fair real search",g.threat.active() and g.threat.grace>2)
	await use("call_remote")
	var end: float=seconds()+12
	while g.threat.last_known.distance_to(g.field_tape.DECK)>.1 and seconds()<end:await wait(.05)
	check("recording draws real search to its actual upstairs source",g.threat.last_known.distance_to(g.field_tape.DECK)<.1 and g.field_tape.sources.any(func(a):return is_instance_valid(a) and a.playing and a.global_position.distance_to(g.field_tape.DECK)<.1) and g.threat.active() and not g.events.get("call_search_done",false),g.threat.state+" / "+str(g.threat.last_known))
	g.player.camera.look_at(Vector3(-3.25,-1.6,-15.8));await shot("L08_playback_draws_search")
	var heard: Vector3=g.threat.last_known;g.save_game();g.load_game();await wait(.3)
	check("save after distraction restores last heard source and fair warning",g.threat.active() and g.threat.last_known.distance_to(heard)<.1 and g.events.call_search_target.size()==3 and g.threat.grace>3)

	# The original low return remains a physical escape, never a teleport or hidden flag.
	await travel(Vector2(-3.25,-16.1),"leave bay while deck runs")
	await travel(Vector2(0,-18),"cross actual cellar landing")
	await travel(Vector2(3.25,-16.1),"reach original low return")
	await travel(Vector2(3.25,-12.8),"crouch through original maintenance passage",false,true)
	await travel(Vector2(3.25,-9.3),"reach records cover",false,true)
	await travel(Vector2(5,-8.35),"clear aisle towards known service exit")
	await travel(Vector2(9,-8.35),"escape up real service incline",false,true)
	await travel(Vector2(12.3,-8.35),"reach actual east yard",false,true)
	check("physical escape retains control without death or jumping",g.player.position.y>-.2 and g.player.active and g.presentation.section!="dead")
	await wait_for("call_complete",20)
	check("surviving test and finding final page completes coherent act",g.events.get("call_complete",false) and g.events.notes.has("ELI / THE LAST CALL"))
	g.save_game();g.load_game();await wait(.3)
	check("earned act and evidence survive save recovery",g.events.get("call_complete",false) and not g.events.get("call_search_running",false))
	await shot("L09_east_yard_escape")

	await travel(Vector2(12.3,-3),"evidence leaves service yard along house")
	await travel(Vector2(9,6.5),"evidence returns around east property")
	await travel(Vector2(0,7),"last call reaches porch approach")
	if not g.doors.front.opened:
		await travel(Vector2(0,5.5),"enter front after cellar test");await use("front")
	await travel(Vector2(0,2.5),"last call rejoins final hall")

	await finish_departure()
