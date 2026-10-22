extends "res://scripts/maintenance_qa.gd"
var layout_fixture:=false
func layouts() -> void:
	layout_fixture=true
	g.events.underfloor_read=true;g.events.underfloor_taps=3;g.events.line_calibrated=true
	g.events.line_feed_off=true;g.events.line_return_out=true;g.events.line_test_armed=true;g.events.line_response_complete=true
	g.player.position=Vector3(4.8,.04,-4.6);g.player.restore_stance(false);g.dead_line.restore()
	g.player.camera.look_at(g.dead_line.PANEL);await wait(1)
	check("visual fixture / no evidence extrusion while observed",not g.dead_line.strip.visible and g.dead_line.station_visible())
	await shot("D10_station_layout")
	g.player.camera.look_at(Vector3(3,1,-8));await wait(1)
	check("visual fixture / evidence introduced only outside view",g.dead_line.strip.visible)
	await use("line_note",false);await shot("D11_annotation_layout");await action("ui_cancel")
	await use("line_strip",false);await shot("D12_evidence_layout");await action("ui_cancel")
	check("layout fixture / isolated motor stays silent",g.dead_line.motor.volume_db<=-80)
func upstairs_test() -> void:
	await travel(Vector2(0,-7),"climb original ramp with test evidence")
	if g.impossible_room.active:
		await travel(Vector2(0,1),"observe existing room before acoustic experiment")
		if not g.doors.lounge.opened:await use("lounge")
		g.player.camera.look_at(Vector3(4.5,1.8,.5));await wait(.5)
		check("existing impossible room remains observable",g.events.get("impossible_room_seen",false))
		await use("lounge");g.player.camera.look_at(Vector3(0,1,-5));await wait(1)
		check("existing impossible room safely clears before experiment",not g.impossible_room.active)
		await travel(Vector2(0,-7),"resume office investigation after room event")
	if not g.doors.office.opened:await use("office")
	await travel(Vector2(3,-7),"office entry for physical continuity test")
	await travel(Vector2(4.8,-4.6),"wall station approach through clear aisle")
	g.player.camera.look_at(g.dead_line.PANEL);await shot("D01_continuity_station")
	await use("line_note",false)
	check("service annotation is a readable physical interaction",g.presentation.section=="document")
	await shot("D02_simon_test");await action("ui_cancel")
	await use("line_strike")
	check("connected test calibrates from underfloor discovery",g.events.get("line_calibrated",false))
	check("personal underfloor rhythm is retained",g.events.get("underfloor_pattern",[]).size()==3,str(g.events.get("underfloor_pattern",[])))
	await wait(2)
	await use("line_feed")
	await use("line_strike")
	check("feed disconnected alone cannot arm house response",not g.events.get("line_test_armed",false) and not g.dead_line.pilot.visible and g.dead_line.motor.volume_db<=-80)
	await use("line_return")
	await use("line_strike")
	check("both physical disconnects arm isolated experiment",g.events.get("line_test_armed",false) and g.dead_line.isolated())
	g.save_game();g.load_game();await wait(.25)
	check("isolated test controls and arming recover",g.dead_line.isolated() and g.events.get("line_test_armed",false) and not g.dead_line.strip.visible)
	# Looking at the station must never manufacture evidence in plain sight.
	g.player.camera.look_at(g.dead_line.PANEL);await wait(.6)
	check("station visibility includes its own interaction colliders",g.dead_line.station_visible())
	await travel(Vector2(3,-7),"experiment leaves office aisle")
	await travel(Vector2(0,-7),"experiment returns to hall")
	if g.doors.lounge.opened:
		await travel(Vector2(0,1),"close empty lounge before listening");await use("lounge")
	await travel(Vector2(0,-2.5),"walk toward sound beyond closed lounge")
	g.player.camera.look_at(Vector3(1.5,1.5,1));await wait(.2)
	check("response starts only at closed lounge",g.events.get("line_response_started",false) and g.impossible_room.closed())
	await action("ui_cancel");var pending: int=g.dead_line.sequence.size();await wait(.6)
	check("pause suspends pending acoustic sequence",g.menu_open and pending==g.dead_line.sequence.size())
	g.presentation.buttons.Resume.pressed.emit();await wait(.2)
	# Save during the dangerous acoustic transition; resume must re-arm, not eat the discovery.
	g.save_game();g.load_game();await wait(.25)
	check("interrupted response safely restarts",g.events.get("line_response_started",false) and not g.events.get("line_response_complete",false))
	await wait(7)
	check("closed-room response completes with both leads disconnected",g.events.get("line_response_complete",false) and g.dead_line.isolated())
	check("counter strip appears only after witnessed test",g.events.get("line_printed",false) and g.dead_line.strip.visible)
	await shot("D03_closed_room_answer")
	await travel(Vector2(0,-7),"unlocked return from sound investigation")
	await travel(Vector2(3,-7),"return to disconnected equipment")
	await travel(Vector2(4.8,-4.6),"inspect dead circuit output")
	g.player.camera.look_at(g.targets.line_strip.global_position);await shot("D04_unpowered_counter_strip")
	await use("line_strip",false)
	check("impossible arrival is discovered through normal input",g.events.get("line_strip_read",false) and g.presentation.section=="document")
	await shot("D05_unwitnessed_arrival");await action("ui_cancel")
	g.save_game();g.load_game();await wait(.3)
	check("completed clue survives save without replay",g.events.get("line_strip_read",false) and g.dead_line.sequence.is_empty())
	await use("line_feed");await use("line_return");await use("line_strike")
	check("reconnecting cannot consume or duplicate the discovery",g.events.get("line_strip_read",false) and g.dead_line.strip.visible)
	await travel(Vector2(3,-7),"station keeps office circulation open");await travel(Vector2(0,-7),"optional investigation rejoins original route")
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	output=OS.get_executable_path().get_base_dir().path_join("QA/dead_line")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	check("new module instantiated",is_instance_valid(g.dead_line))
	if not is_instance_valid(g.dead_line):await g.qa_exit(1);return
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	g.new_game();g.stage=3;g.report_read=true;g.shed_read=true
	g.events.chair=true;g.events["return"]=true;g.events.impossible_room_resolved=true;g.events.threat_resolved=true;g.threat.enabled=false;g.threat.reset()
	g.player.position=Vector3(0,.04,-8.3);g.doors.basement.locked=false;g.presentation.clear_transients()
	for light in g.lamps:light.light_energy=.6
	if "--line-layouts-only" in OS.get_cmdline_user_args():await layouts();await finish();return
	await wait(.3);await use("basement");await travel(Vector2(0,-18),"actual ramp descent")
	await play_store();await upstairs_test()
	await finish()
func finish() -> void:
	recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"));recording=false;await wait(.2)
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	for spec in [["input_trace.json",trace],["frames.json",frames],["report.json",{"passed":checks.size()-failed,"failed":failed,"checks":checks,"duration_seconds":seconds(),"scope":"Explicit seeded native layout and visibility fixture, no traversal claim." if layout_fixture else "Native targeted setup. Actual ramp, crawl, shelving, controls, hall response and save recovery use isolated movement and interaction input. Not a fresh route or human playtest."}]]:
		var file=FileAccess.open(output.path_join(spec[0]),FileAccess.WRITE);file.store_string(JSON.stringify(spec[1],"\t"));file.close()
	print("DEAD_LINE_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
