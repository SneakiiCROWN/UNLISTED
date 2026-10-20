extends "res://scripts/recording_repair_qa.gd"
# A labelled pre-isolation fixture, then real input and live pursuit. The separate
# full-route run repeats this aisle after naturally solving all three valves.
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	await exact_resolution()
	output=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	assert(output!="");DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path=output.path_join("checkpoint.json")
	g.new_game();g.presentation.clear_transients();g.subtitle.text=""
	g.stage=3;g.fuse=true;g.report_read=true;g.shed_read=true;g.brass_key=true
	g.events={"chair":true};g.valve_order.assign([1,0,2])
	g.horror.variant=1 if "--east-entry" in OS.get_cmdline_user_args() else 0
	for door in g.doors.values():door.locked=false
	g.doors.basement.set_open(true,.01)
	for lamp in g.lamps:lamp.light_energy=.6
	g.player.position=Vector3(0,-2.96,-18.4);g.player.camera.look_at(Vector3(-4.25,-1.9,-17.5))
	await wait(.6);await shot("S01_service_layout")
	var test_transform:=Transform3D(Basis.IDENTITY,Vector3(-3.7,-2.97,-16.1))
	var obstructed: bool=g.presence.test_move(test_transform,Vector3(.9,0,-2.2))
	var baseline: bool="--expect-obstruction" in OS.get_cmdline_user_args()
	check("baseline capsule obstruction" if baseline else "west pursuit link has body clearance",obstructed if baseline else not obstructed)
	g.player.position=Vector3(2,-2.96,-22);g.player.velocity=Vector3.ZERO
	await wait(.2)
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	phase="restored pre-isolation scenario / actual isolator input"
	await use("isolate")
	await travel(Vector2(-2.8,-22),"west working aisle",true)
	await travel(Vector2(-3,-18.6),"stand beyond recorded table",true)
	g.player.camera.look_at(g.presence.position+Vector3.UP*1.65)
	var until:=seconds()+13
	while seconds()<until and not g.capture_director.active:await wait(.1)
	await shot("S02_west_pursuit")
	if not baseline and not g.capture_director.active:
		print("SERVICE_PATH_DIAGNOSTIC route=",g.threat.route," actor=",g.presence.position," player=",g.player.position)
		for pair in g.threat.service_edges:
			var a: Vector3=g.threat.graph.get_point_position(pair[0]);var b: Vector3=g.threat.graph.get_point_position(pair[1])
			print("SERVICE_EDGE ",pair," clear=",g.threat.route_clear(a,b)," connected=",g.threat.graph.are_points_connected(pair[0],pair[1]))
	check("recorded obstruction reproduced" if baseline else "real pursuit reaches player beyond bench",not g.capture_director.active if baseline else g.capture_director.active,"actor="+str(g.presence.position)+" state="+g.threat.state)
	if not baseline and g.capture_director.active:
		while g.capture_director.active:await wait(.1)
		check("warned capture reaches death menu",g.presentation.section=="dead")
		g.presentation.buttons["Retry Checkpoint"].pressed.emit();await wait(.4)
		check("retry restores isolated relay and fair warning",g.isolated and g.threat.grace>2 and g.player.active)
		await travel(Vector2(0,-21),"retry physical clearance",true)
		g.threat.stop_voice();g.threat.last_voice=-100
		var first: AudioStreamPlayer3D=g.threat.voice("pursuit",-45)
		var repeated: AudioStreamPlayer3D=g.threat.voice("pursuit",-45)
		check("repeated pursuit vocal is suppressed",first!=null and repeated==null)
		check("replaceable vocal follows actual body",first.get_parent()==g.presence and first.get_meta("voice_slot","")=="surveyor_pursuit" and first.stream.get_length()>0)
		g.threat.stop_voice()
	recording=false
	while capturing:await wait(.02)
	recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"))
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	for spec in [["repair_report.json",{"passed":checks.size()-failed,"failed":failed,"checks":checks,"duration_seconds":seconds(),"scope":"Pre-isolation fixture followed by actual interaction/movement and live AI; separate full-route proof required."}],["frames.json",frames],["input_trace.json",trace]]:
		var file:=FileAccess.open(output.path_join(spec[0]),FileAccess.WRITE);file.store_string(JSON.stringify(spec[1],"\t"));file.close()
	print("SERVICE_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
