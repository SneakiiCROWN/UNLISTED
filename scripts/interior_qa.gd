extends "res://scripts/recording_repair_qa.gd"
func run(current: Node) -> void:
	g=current
	output=OS.get_executable_path().get_base_dir().path_join("QA/interiors")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	g.new_game();g.stage=3;g.threat.enabled=false;g.events.chair=true;g.events["return"]=true
	g.presentation.clear_transients();g.player.position=Vector3(.0,.04,2.5)
	await wait(.3)
	await travel(Vector2(0,-7),"normal hall recording approach")
	await use("office");await travel(Vector2(3.3,-7.3),"office normal working aisle")
	g.caption_until=0;g.subtitle.text=""
	g.player.camera.look_at(Vector3(4.7,1.1,-8.8));await wait(.2);await shot("L01_archive_workstations")
	check("two licensed work desks replace generic tables",get_tree().get_nodes_in_group("authored_work_desks").size()==2)
	var ink: Label3D=g.targets.record.get_parent().find_children("*","Label3D",false,false)[0]
	check("record typography stays inside physical page",ink.font_size==12 and ink.pixel_size<.004)
	await use("audition_source")
	for i in 160:
		if g.horror.audition=="":break
		await wait(.1)
	check("transport remains usable",g.events.get("audition_A",false))
	await travel(Vector2(5.6,-7.3),"archive approach remains clear");await use("security",false)
	check("archive still grants service key",g.brass_key and g.presentation.section=="document")
	await action("ui_cancel");g.player.camera.look_at(Vector3(5.6,1.13,-8.7));await shot("L02_archive_screen")
	await travel(Vector2(3,-7),"office return aisle")
	if not g.doors.office.opened:await use("office")
	await travel(Vector2(0,-7),"office threshold return")
	await use("utility");await travel(Vector2(-3.5,-7.3),"utility fuse aisle remains clear");await use("fuse")
	check("fuse pickup preserved",g.fuse)
	g.player.camera.look_at(Vector3(-6.45,.8,-5.5));await wait(.2);await shot("L03_utility_rest_corner")
	await travel(Vector2(0,-7),"utility threshold return");await travel(Vector2(0,1),"hall remains walkable")
	await use("lounge");await travel(Vector2(3.0,1),"lounge memory aisle preserved")
	await travel(Vector2(2.7,3.35),"lounge chair clearance")
	await travel(Vector2(5.3,3.35),"lounge front circulation")
	await travel(Vector2(6,2.7),"approach actual rain window")
	g.player.camera.look_at(Vector3(7.35,1.6,2));g.caption_until=0;g.subtitle.text=""
	var audio:=AudioEffectRecord.new();audio.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,audio);audio.set_recording_active(true)
	await wait(2);await shot("L04_rain_at_glazing");await wait(4)
	audio.set_recording_active(false);audio.get_recording().save_to_wav(output.path_join("window_rain.wav"))
	var weather=g.get_node("BriarLaneExterior/BriarLaneWeather")
	check("rain has two real positional window sources",weather.window_rain.size()==2 and weather.window_rain[0].playing and weather.window_rain[1].playing)
	check("interior window mix is active",weather.window_rain[1].volume_db> -40)
	g.save_game();g.load_game();await wait(.2)
	check("progress and geometry survive reload",g.fuse and g.brass_key and g.player.active and get_tree().get_nodes_in_group("authored_work_desks").size()==2)
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Targeted normal movement and interactions from a labelled powered fixture; no human art or listening sign-off."},"\t"));file.close()
	print("INTERIOR_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
