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
		check("explicit removal leaves no glowing lamps",g.get_node("BriarLaneExterior/EliArrivalCar").get_meta("headlight_materials",[]).all(func(m):return not m.emission_enabled))
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
	if "--production-assets" in OS.get_cmdline_user_args():await asset_checks()
	await finish_run()

func asset_checks() -> void:
	g.fuse=true;g.interact("breaker");g.events.chair=true;g.events.yard=true;g.events.basement=true;g.events["return"]=true;g.threat.reset();g.threat.enabled=false;g.presence.visible=false;g.ambient_director.enabled=false
	var car: Node3D=g.get_node("BriarLaneExterior/EliArrivalCar");var bounds:=AABB();var first:=true
	for mesh in g.all_meshes(car):
		var actual: AABB=mesh.global_transform*mesh.get_aabb();bounds=actual if first else bounds.merge(actual);first=false
	check("new car grounded at believable scale",bounds.size.x>4.4 and bounds.size.x<5 and bounds.size.y>1.4 and bounds.size.y<1.7 and absf(bounds.position.y)<.06,str(bounds))
	g.player.position=Vector3(-18.24,.03,-14.9);g.player.camera.look_at(g.physical.props.work_wrench.global_position);g.presentation.clear_transients();await wait(.7)
	for pressed in [true,false]:
		var key:=InputEventKey.new();key.keycode=KEY_ALT;key.physical_keycode=KEY_ALT;key.pressed=pressed;key.set_meta("unlisted_qa_input",true);Input.parse_input_event(key);await wait(.08)
	g.presentation.clear_transients();g.subtitle.text="";g.caption_until=0
	await shot("P01_supported_workshop_tools")
	var tool: RigidBody3D=g.physical.props.work_wrench
	check("spanner settles on real bench",tool.position.y>.79 and tool.position.y<.85 and not tool.supports.is_empty(),str(tool.position))
	check("keyboard hint uses licensed glyph",g.presentation.prompt_icon.visible and g.presentation.prompt_icon.texture.resource_path.ends_with("keyboard_e.png") and not "[ E ]" in g.prompt.text,"controller="+str(g.controller.used)+" texture="+g.presentation.prompt_icon.texture.resource_path)
	await action("interact");check("spanner picked up with actual interaction",g.physical.held==tool);await wait(.4);await shot("P02_spanner_held")
	check("blocked carry never stretches beyond reach",not g.physical.forearm.visible or tool.global_position.distance_to(g.player.camera.global_position)<=1.05)
	g.player.camera.look_at(Vector3(-15.5,1.2,-14));await wait(.6);await shot("P02b_spanner_clear_of_bench")
	check("free carry restores support hand",g.physical.support.visible and tool.global_position.distance_to(g.player.camera.global_position)<1.05)
	await action("throw_prop");check("spanner throws as physical body",g.physical.held==null and tool.linear_velocity.length()>.5,str(tool.linear_velocity));await wait(.5)
	g.save_game(true);var where: Vector3=tool.position;g.load_game();await wait(.2);check("new optional prop survives saved restore",tool.position.distance_to(where)<.6)
	g.player.position=Vector3(4.88,.03,-7.5);g.player.camera.look_at(g.targets.return_receiver.global_position);await wait(.3);await shot("P03_atlas_receiver")
	g.controller.used=true;await wait(.1)
	check("Xbox interaction hint uses X glyph",g.presentation.prompt_icon.visible and g.presentation.prompt_icon.texture.resource_path.ends_with("xbox_x.png"))
	await use("return_receiver",false);check("receiver still opens its working dial",g.menu_open and g.presentation.section=="document")
	var widget: Control
	for child in g.presentation.card_body.get_children():
		if child.get_script() and child.get_script().resource_path.ends_with("return_receiver.gd"):widget=child
	check("real tuning widget remains installed",is_instance_valid(widget))
	var tuned: float=0
	if is_instance_valid(widget):
		var before: float=widget.dial.value;await action("ui_right");tuned=widget.dial.value;check("actual dial still responds",tuned>before)
	await action("ui_cancel")
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(g.checkpoint_path));check("leaving radio saves partial tuning",is_equal_approx(float(saved.events.get("receiver_frequency",0)),tuned))
	g.load_game();await wait(.2);check("receiver closes and restores gameplay",g.player.active and not g.menu_open)
