extends "res://scripts/recording_repair_qa.gd"
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec()
	output=ProjectSettings.globalize_path("res://qa/impossible_room") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA/impossible_room")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	g.new_game();g.presentation.clear_transients();g.report_read=true;g.stage=3;g.events.chair=true
	g.threat.enabled=false;g.horror.house_responds()
	for light in g.lamps:light.light_energy=1.1
	g.player.position=Vector3(9,.04,2);g.player.camera.look_at(Vector3(4.5,.79,.3));await wait(.3)
	check("transparent exterior window is treated as visible",g.impossible_room.can_see_changed_room())
	check("window observer prevents visible room swap",not g.impossible_room.begin() and not g.impossible_room.active)
	# A partial front-window view is not represented by the old three centres.
	for spec in [[Vector3(5.8,.04,5.2),Vector3(7.15,2.55,3.60)],[Vector3(8.4,.04,2.9),Vector3(7.1,.2,2.5)]]:
		g.player.position=spec[0];g.player.camera.look_at(spec[1]);await wait(.15)
		check("partial glazing view protects the room "+str(spec[0]),g.impossible_room.can_see_changed_room() and not g.impossible_room.begin())
	g.player.position=Vector3(.5,.04,1);g.player.velocity=Vector3.ZERO
	g.chapter.set_room(true);g.events.memory_bedroom_active=true
	check("copied bedroom keeps exclusive ownership",not g.impossible_room.begin() and not g.impossible_room.active)
	g.chapter.set_room(false);g.events.memory_bedroom_active=false
	await wait(3.2)
	started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	await use("lounge");await wait(1)
	await travel(Vector2(4.5,1.7),"enter normal lounge")
	g.player.camera.look_at(Vector3(3.2,1.13,-1.85));await wait(1.7)
	check("normal lounge visited through actual doorway",g.events.get("lounge_seen_before",false) and not g.impossible_room.active)
	check("occupying the lounge prevents a room swap",not g.impossible_room.begin())
	await shot("I01_normal_lounge")
	var initial_tv: Transform3D=g.targets.television.global_transform
	await travel(Vector2(2.3,1.3),"normal lounge exit aisle")
	await travel(Vector2(.5,1),"normal lounge exit threshold")
	await use("lounge");await wait(1.2)
	check("closed door hides interior before change",g.impossible_room.closed() and not g.impossible_room.can_see_changed_room())
	g.presentation.show_menu(false);var waiting: float=g.impossible_room.quiet
	await wait(.4);check("pause does not advance unseen transformation",is_equal_approx(waiting,g.impossible_room.quiet))
	g.presentation.resume_game()
	await wait(8.8)
	check("authored room turns over only while unoccupied and closed",g.impossible_room.active)
	check("inverted television collider follows real furniture",g.targets.television.global_position.distance_to(initial_tv.origin)>2.0)
	check("no journal prediction before witnessing",not g.events.get("impossible_room_seen",false))
	await use("lounge");await wait(1)
	g.player.camera.look_at(Vector3(4.5,2.2,.5));await wait(.4)
	check("actual line of sight records witnessed change",g.events.get("impossible_room_seen",false))
	await shot("I02_actual_reveal")
	await travel(Vector2(4.5,1.7),"enter inverted lounge with actual inputs")
	check("normal gravity retained under inverted furnishings",absf(g.player.position.y)<.08)
	await wait(1.5)
	check("inverted table settles once after entering",g.events.get("impossible_room_settled",false))
	await travel(Vector2(4.2,-1.6),"walk under inverted table with ordinary collision")
	g.player.camera.look_at(Vector3(4.6,2.1,2.3));await wait(.25);await shot("I03_inside")
	var cup_position: Vector3=g.physical.props.cup.global_position
	await travel(Vector2(cup_position.x,cup_position.z+.65),"approach fallen cup within real carrying range")
	g.player.camera.look_at(g.physical.props.cup.global_position);await wait(.2);await action("interact");await wait(.35)
	check("loose cup remains physically collectible in changed room",g.physical.held==g.physical.props.cup,"body="+str(g.physical.props.cup.global_position)+" camera="+str(g.player.camera.global_position)+" ray="+str(g.player.target()))
	await action("interact");await wait(.5)
	check("cup release retains ordinary gravity",g.physical.held==null and not g.physical.props.cup.freeze and g.physical.props.cup.position.y>-.05)
	await travel(Vector2(4.5,1.7),"return to safe active-room checkpoint")
	var active_save: Dictionary=g.save_data().duplicate(true)
	g.save_game();g.load_game();await wait(.4)
	check("active-room checkpoint preserves room and player floor",g.impossible_room.active and g.player.position.distance_to(Vector3(4.5,0,1.7))<.25 and g.events.impossible_room_active)
	check("load does not double-invert TV or collision",g.targets.television.global_position.distance_to(Vector3(3.2,1.67,2.85))<.02)
	check("overhead response stays spent after reload",g.events.get("impossible_room_settled",false))
	g.presentation.show_menu(false);var frozen: Transform3D=g.lounge_contents.transform
	await wait(.3)
	check("pause freezes environmental memory",get_tree().paused and g.lounge_contents.transform==frozen)
	g.presentation.resume_game();await wait(.15)
	await travel(Vector2(2.3,1.3),"inverted lounge return aisle")
	await travel(Vector2(.5,1),"inverted lounge return threshold")
	await wait(.5)
	check("open doorway never resets a visible room",g.impossible_room.active)
	await use("lounge");await wait(1.6)
	check("leaving and closing safely restores normal room",not g.impossible_room.active and g.events.get("impossible_room_resolved",false))
	check("real TV collider returns to its original placement",g.targets.television.global_transform.is_equal_approx(initial_tv))
	check("journal does not claim unwitnessed restoration",not g.events.get("impossible_room_revisited",false))
	await use("lounge");await wait(1);g.player.camera.look_at(Vector3(4.5,1.4,.3));await wait(.3)
	check("return visit completes only observed journal entry",g.events.get("impossible_room_revisited",false))
	await shot("I04_restored")
	g.save_game();g.load_game();await wait(.3)
	check("resolved room survives checkpoint without repeat",not g.impossible_room.active and g.events.get("impossible_room_resolved",false))
	var resolved_save: Dictionary=g.save_data().duplicate(true)
	# A separate restored scenario proves the real enemy can navigate this room.
	phase="separate restored scenario / Surveyor in active room"
	g.apply_save(active_save);g.player.position=Vector3(4.2,.04,-1.6);g.player.camera.look_at(Vector3(1.5,1.5,1))
	g.threat.enabled=true;await wait(.2);g.threat.arm()
	# Readback/debugger stalls can consume wall time without simulating movement.
	# Preserve the original 18-second simulation allowance; keep a bounded wall
	# deadline so an actual hang is never silently tolerated.
	var contact_simulated:=0.0
	var limit:=seconds()+60.0
	while contact_simulated<18.0 and seconds()<limit and not g.capture_director.active:
		await get_tree().physics_frame;contact_simulated+=g.get_physics_process_delta_time()
	check("real Surveyor reaches warned contact in inverted room",g.capture_director.active,"state="+g.threat.state+" actor="+str(g.presence.position)+" physics_seconds="+str(contact_simulated))
	if g.capture_director.active:
		await wait(1.0);await shot("I05_room_contact")
		limit=seconds()+5
		while seconds()<limit and g.presentation.section!="dead":await wait(.05)
		check("active room preserves real death and retry menu",g.presentation.section=="dead" and g.presentation.buttons.has("Retry Checkpoint"))
		if g.presentation.buttons.has("Retry Checkpoint"):
			g.presentation.buttons["Retry Checkpoint"].pressed.emit();await wait(.3)
			check("retry restores active room and playable controls",g.impossible_room.active and g.player.active and not get_tree().paused)
	g.threat.enabled=false;g.apply_save(resolved_save);await wait(.2)
	recording=false
	while capturing:await wait(.02)
	var recorded_duration:=seconds()
	recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"))
	for spec in [["frames.json",frames],["input_trace.json",trace]]:
		var log_=FileAccess.open(output.path_join(spec[0]),FileAccess.WRITE);log_.store_string(JSON.stringify(spec[1],"\t"));log_.close()
	# Legacy schema-one saves have no room fields and must remain ordinary rooms.
	var legacy: Dictionary=g.save_data().duplicate(true)
	for key in legacy.events.keys():
		if str(key).begins_with("impossible_"):legacy.events.erase(key)
	g.apply_save(legacy);await wait(.2)
	check("legacy checkpoint has no phantom inverted room",not g.impossible_room.active and g.lounge_contents.transform==Transform3D.IDENTITY)
	g.apply_save(active_save);await wait(.2);g.new_game();await wait(.2)
	check("New Game resets active room, surfaces and event flags",not g.impossible_room.active and not g.impossible_room.surfaces.visible and not g.events.get("impossible_room_active",false))
	# Resolution captures restore an explicit saved-state fixture after recording.
	g.apply_save(active_save);g.player.position=Vector3(.5,.04,1);g.player.camera.look_at(Vector3(4.5,2.2,.5))
	var reduced: bool=g.presentation.prefs.data.reduced_motion
	g.presentation.prefs.data.reduced_motion=true
	check("reduced motion preserves physical room and player camera control",g.impossible_room.active and g.player.active and not get_tree().paused)
	await wait(.2)
	check("load clears stale arrival fade, message and lens",g.presentation.fade.color.a==0 and g.subtitle.text=="" and is_equal_approx(g.player.camera.fov,77))
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		exact_target.size=size_;exact_target.size_2d_override=Vector2i(roundi(720.0*float(size_.x)/size_.y),720)
		await wait(.25);await shot("I02_reveal_"+str(size_.x)+"x"+str(size_.y))
		check("exact impossible-room render "+str(size_),exact_target.get_texture().get_image().get_size()==size_)
	g.presentation.prefs.data.reduced_motion=reduced
	# Separate close-up fixtures verify that the physical story clues are visible.
	g.apply_save(resolved_save);exact_target.size=Vector2i(1920,1080);exact_target.size_2d_override=Vector2i(1280,720)
	for spec in [["I06_loose_lead",Vector3(4.4,.04,-2.3),Vector3(3.85,.2,-2.55)],["I07_child_drawing",Vector3(4.35,.04,-.6),Vector3(3.8,.82,-1.63)]]:
		g.player.position=spec[1];g.player.camera.look_at(spec[2]);await wait(.25);await shot(spec[0])
	var failed:=0
	for entry in checks:
		if not entry.passed:failed+=1
	var file:=FileAccess.open(output.path_join("repair_report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"duration_seconds":recorded_duration,"test_duration_seconds":seconds(),"scope":"Story prerequisite fixture; actual input drives both room visits, door reveal, reset and save/retry scenarios. Three-resolution images are separate restored fixtures. Not human playtesting."},"\t"));file.close()
	print("IMPOSSIBLE_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
