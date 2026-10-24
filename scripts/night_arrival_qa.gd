extends "res://scripts/recording_repair_qa.gd"
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	g.presentation.prefs.data.reduced_motion="--arrival-reduced" in OS.get_cmdline_user_args()
	var car: Node3D=g.get_node("BriarLaneExterior/EliArrivalCar");var original: Transform3D=car.global_transform
	g.presentation.buttons["New Game"].pressed.emit();await wait(.1)
	check("actual New Game creates integrated arrival",is_instance_valid(g.presentation.arrival_sequence) and g.presentation.section=="intro" and not g.player.active)
	check("cinematic has no invisible player torch",not g.player.torch.visible)
	var movie: Node=g.presentation.arrival_sequence
	g.presentation.begin_new_game();check("repeated start cannot create a second movie",g.presentation.arrival_sequence==movie)
	await wait(1.7);await shot("N01_headlights_and_car")
	var pose: Transform3D=movie.get_node("PreviewCamera").transform;await wait(.5)
	if g.presentation.prefs.data.reduced_motion:check("reduced motion keeps first shot fixed",pose.is_equal_approx(movie.get_node("PreviewCamera").transform))
	await wait(3.5);await shot("N02_outside_driver_side")
	await wait(3.6);await shot("N03_gate_title")
	check("actual timed engine and door cues fire",movie.cue_log.size()==3,str(movie.cue_log))
	check("parked car never moves during cinematic",car.global_transform.is_equal_approx(original))
	await wait(3.8)
	check("timed handoff restores normal control and camera",g.started and g.player.active and not g.menu_open and g.presentation.section=="game" and g.get_viewport().get_camera_3d()==g.player.camera)
	check("no temporary cameras or lights survive",not is_instance_valid(g.presentation.arrival_sequence) and g.find_children("TemporaryArrivalHeadlamp","SpotLight3D",true,false).is_empty())
	check("gameplay flashlight is restored",g.player.torch.visible)
	check("spawn, gate and first knock remain intact",g.player.position.z>19 and not g.doors.front_gate.opened and g.interaction_name("front")=="Knock" and g.stage==0)
	await shot("N04_playable_handoff")
	g.save_game(true);g.load_game();await wait(.4)
	check("load does not replay cinematic",not is_instance_valid(g.presentation.arrival_sequence) and g.player.active)
	if not "--arrival-layouts" in OS.get_cmdline_user_args():
		for button in [KEY_SPACE,KEY_ESCAPE,KEY_E,JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_START]:
			g.presentation.show_menu(true);var previous:=FileAccess.get_file_as_string(g.checkpoint_path)
			g.presentation.buttons["New Game"].pressed.emit();await wait(.2)
			check("cinematic preserves existing save before handoff "+str(button),FileAccess.get_file_as_string(g.checkpoint_path)==previous)
			for pressed in [true,false]:
				var event: InputEvent
				if button>=KEY_SPACE:event=InputEventKey.new();event.physical_keycode=button;event.keycode=button
				else:event=InputEventJoypadButton.new();event.button_index=button;event.device=0
				event.pressed=pressed;event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event);await wait(.1)
			await wait(.8);check("keyboard/controller skip restores gameplay "+str(button),g.player.active and g.presentation.section=="game" and not is_instance_valid(g.presentation.arrival_sequence),"section="+g.presentation.section+" active="+str(g.player.active))
		g.presentation.show_menu(true);g.presentation.begin_new_game();await wait(.2);g.presentation.arrival_sequence.queue_free();await wait(.4)
		check("explicit removal restores gameplay safely",g.player.active and g.presentation.section=="game" and not is_instance_valid(g.presentation.arrival_sequence))
		g.presentation.show_menu(true);g.presentation.cinematic_arrival_enabled=false;g.presentation.begin_new_game();await wait(.2)
		check("original introduction remains safe fallback",g.presentation.section=="intro" and not is_instance_valid(g.presentation.arrival_sequence));g.presentation.complete_intro();g.presentation.cinematic_arrival_enabled=true
		await wait(.5)
		await travel(Vector2(-5.6,19.3),"approach parked driver side")
		g.player.rotation.y=PI;Input.action_press("forward");await wait(1);Input.action_release("forward");await wait(.2)
		check("parked body retains physical collision",g.player.position.z>19.8 and g.player.position.z<20.95)
		await travel(Vector2(-5.6,19.3),"step away from parked car");await travel(Vector2(-2.8,19.3),"round car nose");await travel(Vector2(-2.8,24),"reach open lane");await travel(Vector2(-8.4,24),"walk along lane behind car");await travel(Vector2(-8.4,19.3),"round rear of car");await travel(Vector2(0,19.3),"return outside gate")
		await travel(Vector2(0,18.3),"approach existing gate");await use("front_gate");await travel(Vector2(0,15.1),"cross existing gate");await travel(Vector2(0,5.3),"approach existing front door")
		await use("front");await wait(1.5);check("original knock still opens door ajar",g.events.get("front_ajar",false))
		await use("front");await wait(.4);check("second interaction opens normal front door",g.doors.front.opened)
	await finish_run()
