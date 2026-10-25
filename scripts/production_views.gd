extends "res://scripts/recording_repair_qa.gd"
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec()
	output=OS.get_executable_path().get_base_dir().path_join("QA/views")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();g.new_game();g.stage=3;g.threat.enabled=false;g.threat.reset()
	g.events.chair=true;g.events["return"]=true;g.events.impossible_room_resolved=true;g.events.threat_resolved=true
	g.presentation.clear_transients()
	for light in g.lamps:light.light_energy=.6
	for door in g.doors.values():door.locked=false;door.set_open(true,.01)
	if "--foreground-profile" in OS.get_cmdline_user_args():
		await profile_rooms();await g.qa_exit(0);return
	if "--room-tour" in OS.get_cmdline_user_args():
		await room_tour();return
	var views=[
		["V01_porch",Vector3(0,.04,7.2),Vector3(0,1.4,3.7)],
		["V02_lounge",Vector3(2.7,.04,2.6),Vector3(5.5,.9,.2)],
		["V03_kitchen",Vector3(-2.8,.04,-1),Vector3(-5.8,.9,2.5)],
		["V04_office",Vector3(2.8,.04,-5.3),Vector3(5.5,1.1,-8.8)],
		["V05_utility",Vector3(-3.5,.04,-7.2),Vector3(-6.45,.8,-5.4)],
		["V06_shed",Vector3(-15,.04,-14.1),Vector3(-18.1,1,-15)],
		["V07_cellar",Vector3(0,-2.99,-17.2),Vector3(-1.5,-1.5,-23)],
		["V08_lane",Vector3(0,.04,17),Vector3(0,1.5,2)],
		["V09_rear",Vector3(-9,.04,-12.5),Vector3(-15,1.1,-14)]
	]
	for view in views:
		g.player.position=view[1];g.player.velocity=Vector3.ZERO;g.player.restore_stance(false)
		g.player.camera.look_at(view[2]);g.caption_until=0;g.subtitle.text="";await wait(.6);await shot(view[0])
	g.chapter.set_room(true)
	for view in [["V10_bedroom",Vector3(3.9,.04,2),Vector3(5.7,.9,-1.8)],["V11_work_corner",Vector3(5,.04,1.5),Vector3(7.03,.9,.10)],["V12_bedding",Vector3(5.3,.04,-.1),Vector3(6.35,.6,-1.65)]]:
		g.player.position=view[1];g.player.velocity=Vector3.ZERO;g.player.restore_stance(false);g.player.camera.look_at(view[2]);g.caption_until=0;g.subtitle.text="";await wait(.6);await shot(view[0])
	var file=FileAccess.open(output.path_join("VIEW_SCOPE.txt"),FileAccess.WRITE)
	file.store_string("Actual Windows viewport captures at player eye height, using labelled powered visual fixtures. Camera/position placement is deliberate for inspection; these are not movement-route or human quality approval tests.");file.close()
	await g.qa_exit(0)

func room_tour() -> void:
	# Labelled powered fixture: actual isolated movement, not a fresh investigation.
	started_unix_seconds=Time.get_unix_time_from_system();capture_interval=.1
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	g.events.memory_echo=true;g.events.memory_confirmed=true;g.horror.echo_index=-1
	g.player.position=Vector3(0,.04,1);phase="lounge walk and existing window event"
	await travel(Vector2(3,1),"lounge doorway with fitted finishes")
	g.player.camera.look_at(Vector3(7.2,1.4,2));g.presentation.clear_transients()
	check("existing window event accepted in room fixture",g.ambient_director.request("window_taps"))
	await wait(3.0);await shot("T01_lounge")
	await travel(Vector2(0,1),"return through lounge opening")
	await travel(Vector2(0,-7),"hall to records room")
	await travel(Vector2(3,-7),"office door clearance")
	phase="records office";g.player.camera.look_at(Vector3(5.5,1.1,-8.8));await wait(2);await shot("T02_office")
	await travel(Vector2(0,-7),"office return past existing furniture")
	for point in [Vector2(0,-9),Vector2(0,-15.5),Vector2(0,-18),Vector2(0,-21)]:await travel(point,"existing cellar approach")
	phase="cellar relay room";g.player.camera.look_at(Vector3(-1.5,-1.5,-23));await wait(2);await shot("T03_cellar")
	await finish_run()

func profile_rooms() -> void:
	var results: Array=[]
	g.player.active=false
	for resolution in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		g.get_viewport().size=resolution
		for view in [["porch",Vector3(0,.04,7.2),Vector3(0,1.4,3.7)],["lounge",Vector3(2.7,.04,2.6),Vector3(5.5,.9,.2)],["office",Vector3(2.8,.04,-5.3),Vector3(5.5,1.1,-8.8)],["cellar",Vector3(0,-2.99,-17.2),Vector3(-1.5,-1.5,-23)]]:
			g.player.position=view[1];g.player.camera.look_at(view[2]);await wait(1.5)
			var samples: Array=[];var unfocused:=0;var draws: Array=[]
			var stop:=Time.get_ticks_usec()+3500000;var previous:=Time.get_ticks_usec()
			while Time.get_ticks_usec()<stop:
				await get_tree().process_frame
				var now:=Time.get_ticks_usec()
				if get_tree().root.has_focus():
					samples.append((now-previous)/1000.0);draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
				else:unfocused+=1
				previous=now
			samples.sort();draws.sort()
			results.append({"view":view[0],"render_size":str(resolution),"focused_frames":samples.size(),"excluded_unfocused":unfocused,"median_ms":samples[samples.size()/2] if samples.size()>0 else null,"p95_ms":samples[int(samples.size()*.95)] if samples.size()>0 else null,"median_draw_calls":draws[draws.size()/2] if draws.size()>0 else null})
	var file=FileAccess.open(output.path_join("foreground_profile.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"Exported Windows, actual native-resolution private viewport presented in a 1280x720 desktop window; 60fps cap, no readback during measurement. Only focused frames counted. Fixed powered fixtures, not an uninterrupted gameplay benchmark. Shared desktop activity can invalidate focus. No ultrawide display claim.","results":results},"\t"));file.close()
