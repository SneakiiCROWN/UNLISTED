extends "res://scripts/missing_minute_qa.gd"
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	output=OS.get_executable_path().get_base_dir().path_join("QA/inspection")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();g.new_game();g.stage=3;g.brass_key=true;g.shed_read=true;g.threat.enabled=false;g.threat.reset()
	g.events.inspection_search_started=true;g.events.inspection_search_done=true # Mechanics fixture; search has separate native coverage.
	g.events.chair=true;g.events.office=true;g.events.yard=true;g.events["return"]=true
	g.presentation.clear_transients();for light in g.lamps:light.light_energy=.7
	var frequencies: Dictionary={};var configurations: Dictionary={};var valid:=true
	for seed_ in 96:
		var e: Dictionary={};g.PUZZLES.generate(e,seed_+111)
		frequencies[g.PUZZLES.station(e)]=true;configurations[str(g.PUZZLES.sequence(e))]=true
		var order: Array[int]=g.PUZZLES.sequence(e);var sorted:=order.duplicate();sorted.sort()
		valid=valid and sorted==[0,1,2] and g.PUZZLES.station(e)>=88 and g.PUZZLES.station(e)<=108 and not is_equal_approx(g.PUZZLES.station(e),104.6)
		var saved: Dictionary=JSON.parse_string(JSON.stringify(e));g.PUZZLES.ensure(saved)
		valid=valid and is_equal_approx(g.PUZZLES.station(e),g.PUZZLES.station(saved)) and g.PUZZLES.sequence(e)==g.PUZZLES.sequence(saved)
	check("96 saved puzzle configurations are tunable and stable",valid)
	check("all station choices and all six pipe mappings occur",frequencies.size()==7 and configurations.size()==6)
	check("UV unavailable before equipment discovery",not g.equipment.is_uv() and not g.equipment.data.uv)
	g.player.position=Vector3(-16.5,.04,-14);g.doors.shed.locked=false;g.doors.shed.set_open(true,0)
	await travel(Vector2(-18.4,-15.1),"shed equipment approach");g.player.camera.look_at(g.targets.inspection_kit.global_position);await wait(.2);await shot("I01_inspection_case")
	await use("inspection_kit");check("physical inspection head installs UV mode",g.equipment.data.uv and g.equipment.is_uv())
	await shot("I02_uv_in_shed")
	var packs: int=g.equipment.data.spares;await use("battery_shed")
	check("real shed pack increases saved spares",int(g.equipment.data.spares)==packs+1)
	g.equipment.data.charge=40.0;await action("battery_replace")
	check("replacement consumes one pack",float(g.equipment.data.charge)>99 and int(g.equipment.data.spares)==packs)
	g.save_game();g.load_game();await wait(.2)
	check("equipment and mode restore",g.equipment.data.uv and g.equipment.is_uv() and float(g.equipment.data.charge)>99)
	g.equipment.data.charge=0.0;g.equipment.data.spares=0;g.equipment.apply_light()
	check("empty battery retains usable white emergency beam",g.player.torch.visible and g.player.torch.light_energy>.2 and not g.equipment.is_uv())
	Input.action_press("battery_replace");await wait(1);await action("ui_cancel")
	var progress: float=g.equipment.winding;await wait(.5)
	check("pause freezes emergency winding",g.menu_open and is_equal_approx(progress,g.equipment.winding))
	g.presentation.buttons.Resume.pressed.emit();await wait(2.6);Input.action_release("battery_replace")
	check("manual backup restores inspection without consumables",float(g.equipment.data.charge)>24 and g.equipment.is_uv())
	g.events.field_return_read=true;g.isolated=true;g.player.position=Vector3(5.7,.04,-7.2);g.equipment.data.mode=1;g.equipment.apply_light()
	await use("carbon_return",false);var widget=rubbing_widget();check("physical sleeve opens inspection surface",widget!=null)
	if widget==null:await finish_inspection();return
	for row in 3:
		var origin: Vector2=widget.global_position;await pointer(origin+Vector2(55,113+row*74),true)
		for i in 22:await pointer(origin+Vector2(55+i*29,113+row*74),true,true)
		await pointer(origin+Vector2(690,113+row*74),false)
	check("white light cannot reveal clue",not g.events.get("carbon_read",false))
	await shot("I03_white_paper");await action("flashlight")
	check("mode switches while inspecting paused surface",g.equipment.is_uv())
	check("switching UV alone does not award answer",not g.events.get("carbon_read",false))
	var origin: Vector2=widget.global_position
	await pointer(origin+Vector2(80,113),true);await pointer(origin+Vector2(110,113),true,true);await pointer(origin+Vector2(115,113),false)
	await shot("I04_local_uv_beam")
	g.save_game();g.load_game();await wait(.2);await use("carbon_return",false);widget=rubbing_widget()
	check("partial UV coverage survives load",float(g.events.carbon_coverage[0])>0 and not g.events.get("carbon_read",false))
	# Reading the actual frequency must not require rubbing blank paper margins.
	origin=widget.global_position;await pointer(origin+Vector2(55,113),true)
	var end: float=58+widget.HAND.get_string_size(widget.TEXT[0],HORIZONTAL_ALIGNMENT_LEFT,-1,28).x
	for x in range(55,ceili(end)+20,10):await pointer(origin+Vector2(x,113),true,true)
	await pointer(origin+Vector2(end,113),false)
	check("actual frequency is enough without scanning blank paper",g.events.get("carbon_read",false))
	check("journal does not invent unread lower lines",not g.events.notes.get(g.NOTES.INSPECTION_TITLE,"").contains("I phoned home"))
	await pointer(origin+Vector2(end-30,113),false);await shot("I04b_frequency_under_beam")
	for row in 3:
		for pass_ in 2:
			origin=widget.global_position;await pointer(origin+Vector2(55,113+row*74),true)
			for i in 24:await pointer(origin+Vector2(55+i*28,113+row*74),true,true)
			await pointer(origin+Vector2(720,113+row*74),false)
	check("physical mouse sweep discovers current station",g.events.get("carbon_read",false) and g.events.notes[g.NOTES.INSPECTION_TITLE].contains("%.1f"%g.PUZZLES.station(g.events)),"coverage="+str(widget.coverage)+" beam="+str(widget.beam))
	await shot("I05_discovered_uv_paper");await action("flashlight");await action("flashlight");await shot("I06_white_after_discovery")
	check("recording clue never locks UV permanently on",not g.equipment.is_uv())
	g.presentation.buttons["Put sheet down"].pressed.emit();await wait(.2)
	# Same mechanism offers a slow, visible controller/accessibility scan, not an instant answer.
	g.events.erase("carbon_read");g.events.erase("carbon_cells");g.events.erase("carbon_coverage");g.events.erase("uv_rows")
	g.equipment.data.mode=2;g.equipment.apply_light();await use("carbon_return",false);widget=rubbing_widget()
	g.presentation.buttons["Slow automatic scan"].pressed.emit();await wait(.3)
	check("accessible scan is gradual",not g.events.get("carbon_read",false))
	await wait(9.7);check("accessible scan reveals the actual clue",g.events.get("carbon_read",false))
	var cursor_x: float=widget.beam.x;Input.action_press("inspect_left");await wait(.2);Input.action_release("inspect_left")
	check("controller inspection action moves the beam",widget.beam.x<cursor_x)
	g.presentation.buttons["Put sheet down"].pressed.emit();await wait(.2)
	g.player.camera.look_at(Vector3(6.27,.84,-8.56));await wait(.3);await shot("I08_world_uv_seal")
	var seal: MeshInstance3D=g.get_node("ReportSleeveInspectionSeal")
	check("world seal reacts to inspection illumination",float(seal.ink.get_shader_parameter("beam_active"))>.9)
	var blocker:=Node3D.new();g.add_child(blocker)
	g.box(blocker,g.player.torch.global_position.lerp(seal.global_position,.6),Vector3(.5,.5,.5),Color.GRAY,true)
	await wait(.2);check("real occluder blocks fluorescent seal",float(seal.ink.get_shader_parameter("beam_active"))<.1)
	blocker.queue_free();await wait(.2)
	g.equipment.data.mode=1;g.equipment.apply_light();await wait(.2);await shot("I09_world_white_seal")
	check("white light never activates fluorescent shader",float(seal.ink.get_shader_parameter("beam_active"))<.1)
	g.player.position=Vector3(4.9,.04,-7.3);await use("return_receiver",false)
	var receiver=receiver_widget();receiver.dial.value=104.6;g.presentation.buttons["Listen"].pressed.emit();await wait(.2)
	check("old universal frequency is rejected on new game",not g.events.get("receiver_found",false))
	receiver.dial.value=g.PUZZLES.station(g.events);await shot("I07_saved_station")
	g.presentation.buttons["Listen"].pressed.emit();await wait(.3)
	check("generated frequency operates real receiver",g.events.get("receiver_found",false))
	# Three distinct saved mappings operate real wheels and the isolator.
	for seed_ in [45,68,91]:
		g.PUZZLES.generate(g.events,seed_);g.refresh_puzzle_labels();g.valve_order.clear();g.isolated=false;g.shed_read=true
		g.player.position=Vector3(-1.5,-2.99,-22);await wait(.2)
		var order: Array[int]=g.PUZZLES.sequence(g.events)
		var wrong: int=order[-1];await travel(Vector2(-2.7+wrong*1.2,-22),"wrong line fixture");await use("valve"+str(wrong))
		check("wrong service order releases safely "+str(seed_),g.valve_order.is_empty())
		for index in order:
			await travel(Vector2(-2.7+index*1.2,-22),"mapped line "+str(index));await use("valve"+str(index))
		check("wheel sequence matches visible service plates "+str(seed_),g.valve_order==order and g.valve_labels[order[0]].text.contains("COOLING") and g.valve_labels[order[2]].text.contains("COUNTER"))
		await travel(Vector2(2,-22),"isolator approach");await use("isolate")
		check("mapped service system isolates "+str(seed_),g.isolated)
		g.save_game();g.load_game();await wait(.2)
		check("pipe solution persists with completed work "+str(seed_),g.isolated and g.valve_order==order and g.PUZZLES.sequence(g.events)==order)
	await shot("I10_service_mapping")
	var state: Dictionary=g.save_data().duplicate(true);state.events.erase("torch");state.events.erase("puzzles");state.events.carbon_read=true;state.valves=[1,0,2]
	g.apply_save(state);await wait(.2)
	check("legacy station and pipe order remain valid",is_equal_approx(g.PUZZLES.station(g.events),104.6) and g.PUZZLES.sequence(g.events)==[1,0,2])
	check("old completed paper receives inspection equipment",g.equipment.data.uv and g.events.get("carbon_read",false))
	await finish_inspection()
func finish_inspection() -> void:
	var failed:=0
	for entry in checks:
		if not entry.passed:failed+=1
	var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Native equipment, physical UI and migration fixtures; seeded algorithm checks are not full routes or human playtests."},"\t"));file.close()
	print("INSPECTION_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed");await g.qa_exit(0 if failed==0 else 1)
