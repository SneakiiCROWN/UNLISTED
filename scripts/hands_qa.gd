extends "res://scripts/recording_repair_qa.gd"
# Explicit visual fixtures plus real toggle, walk, carry, throw and pause input.
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec()
	output=OS.get_executable_path().get_base_dir().path_join("QA/hands")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hands-output="):output=arg.trim_prefix("--hands-output=")
	DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path=output.path_join("fixture_checkpoint.json")
	await exact_resolution()
	g.new_game();g.threat.enabled=false;g.events.chair=true
	g.presentation.clear_transients()
	g.horror.set_process(false);g.horror.set_physics_process(false)
	await wait(3.2)
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
	started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system();recording=true
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		exact_target.size=size_
		exact_target.size_2d_override=Vector2i(roundi(720.0*float(size_.x)/size_.y),720)
		g.player.position=Vector3(0,0.04,8.2);g.player.rotation=Vector3.ZERO;g.player.camera.rotation=Vector3.ZERO
		g.player.torch.visible=true
		phase="porch / "+str(size_)
		await wait(0.6)
		g.presentation.clear_transients();g.subtitle.text=""
		await wait(0.1)
		check("torch visible "+str(size_),g.player.viewmodel.visible)
		await shot("porch_"+str(size_.x)+"x"+str(size_.y))
	await action("flashlight");await wait(0.4)
	phase="torch switch and close wall"
	check("real flashlight input switches beam off",not g.player.torch.visible)
	await shot("torch_off")
	await action("flashlight")
	check("real flashlight input restores beam",g.player.torch.visible)
	check("beam excludes hand render layer",(g.player.torch.light_cull_mask&2)==0)
	g.player.position=Vector3(0,0.04,4.31)
	await wait(0.4)
	check("close wall safely conceals hand",not g.player.viewmodel.visible)
	await shot("wall_clearance")
	g.player.position=Vector3(0,0.04,0);g.player.rotation=Vector3.ZERO;g.player.camera.rotation=Vector3.ZERO
	phase="hall / walking"
	await wait(0.4);await shot("hall")
	var before: Vector3=g.player.position
	Input.action_press("forward");await wait(0.6);Input.action_release("forward");await wait(0.15)
	check("walking preserved",g.player.position.distance_to(before)>0.7)
	g.player.position=Vector3(4.6,0.04,1.05);g.player.camera.look_at(g.physical.props.cup.global_position)
	phase="lounge / real cup pickup and throw"
	await wait(0.3);await action("interact");await wait(0.6)
	check("actual focus interaction picks up cup",g.physical.held==g.physical.props.cup)
	check("supporting palm follows held body",g.physical.support.visible and g.physical.support.global_position.distance_to(g.physical.props.cup.global_position)<0.2)
	await shot("carry_cup")
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.set_meta("unlisted_qa_input",true)
	Input.parse_input_event(click);await wait(0.2)
	check("marked throw releases physical cup",g.physical.held==null and not g.physical.props.cup.freeze)
	check("support hidden after release",not g.physical.support.visible)
	g.presentation.prefs.data.viewmodel=false;await wait(0.2)
	check("viewmodel accessibility toggle hides torch",not g.player.viewmodel.visible)
	g.presentation.prefs.data.viewmodel=true
	var key:=InputEventKey.new();key.keycode=KEY_ESCAPE;key.physical_keycode=KEY_ESCAPE;key.pressed=true;key.set_meta("unlisted_qa_input",true)
	Input.parse_input_event(key);await wait(0.2)
	check("pause suspends gameplay",get_tree().paused and not g.player.active)
	key=InputEventKey.new();key.keycode=KEY_ESCAPE;key.physical_keycode=KEY_ESCAPE;key.pressed=true;key.set_meta("unlisted_qa_input",true)
	Input.parse_input_event(key);await wait(0.2)
	check("resume restores input",not get_tree().paused and g.player.active)
	recording=false
	while capturing:await wait(0.02)
	recorder.set_recording_active(false)
	recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"))
	var frame_file:=FileAccess.open(output.path_join("frames.json"),FileAccess.WRITE)
	frame_file.store_string(JSON.stringify(frames,"\t"));frame_file.close()
	var failed:=0
	for entry in checks:
		if not entry.passed:failed+=1
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	var report:={"checks":checks,"passed":checks.size()-failed,"failed":failed,"duration_seconds":seconds(),"scope":"Focused hand/torch input and visual fixtures; not complete route playtest"}
	file.store_string(JSON.stringify(report,"\t"));file.close()
	file=FileAccess.open(output.path_join("repair_report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	await g.qa_exit(1 if failed else 0)
