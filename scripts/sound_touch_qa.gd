extends "res://scripts/recording_repair_qa.gd"
# Isolated player-input/physics fixtures; not a complete investigation playthrough.
func joy(button: int) -> void:
	for down in [true,false]:
		var event:=InputEventJoypadButton.new();event.button_index=button;event.pressed=down;event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event);await wait(.07)
func axis(id: int,value: float) -> void:
	var event:=InputEventJoypadMotion.new();event.axis=id;event.axis_value=value;event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event);await wait(.04)
func quiet() -> void:
	g.threat.reset();g.threat.enabled=false;g.presence.visible=false;g.ambient_director.enabled=false
	g.events.chair=true;g.events.yard=true;g.events.basement=true;g.events["return"]=true
	g.horror.beat="";g.horror.echo_index=-1
func pickup_fixture(id: String) -> RigidBody3D:
	if g.physical.held:g.physical.release(false)
	# Each fixture starts clear of bodies thrown/dropped by the previous case.
	for other in g.physical.props:
		g.physical.props[other].call("relocate",g.physical.homes[other])
	await wait(.18)
	g.player.position=Vector3(-17.8,.03,-13.9);g.player.velocity=Vector3.ZERO
	g.player.camera.look_at(Vector3(-15,1.35,-14.2));await wait(.1)
	var body: RigidBody3D=g.physical.props[id]
	var target: Vector3=g.player.camera.to_global(Vector3(0,-.22,-1.05))
	body.call("relocate",Transform3D(Basis.IDENTITY,target))
	for frame in 20:
		await get_tree().physics_frame
		if not body.reset_pending:break
	# Fixture suspension is static. Reusing a previous carry's kinematic freeze
	# while teleporting the tiny tool leaves its broadphase behind the new pose.
	body.freeze_mode=RigidBody3D.FREEZE_MODE_STATIC;body.freeze=true
	await get_tree().physics_frame;await get_tree().physics_frame
	g.player.camera.look_at(body.global_position);await wait(.12)
	var hit: Dictionary=g.player.target()
	check("focused fixture body "+id,not hit.is_empty() and hit.collider==body,str(hit)+" body="+str(body.position)+" target="+str(target)+" pending="+str(body.reset_pending))
	await action("interact");await wait(.55)
	check("actual pickup "+id,g.physical.held==body)
	return body
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	g.new_game();quiet();g.presentation.prefs.data.reduced_motion="--touch-reduced" in OS.get_cmdline_user_args()
	g.fuse=true;g.interact("breaker");g.presentation.clear_transients()
	var light_speed:=0.0
	for id in ["work_wrench","work_tape","cup","spare"]:
		var body: RigidBody3D=await pickup_fixture(id);g.presentation.clear_transients();g.subtitle.text="";g.caption_until=0;await wait(.06)
		check("unchanged physical mass and collision "+id,body.mass>0 and body.continuous_cd and body.collision_mask==(1|2|16|32))
		var contact: Node3D=g.physical.tool_hand if id in ["work_wrench","work_tape"] else g.physical.support
		check("appropriate supported grip "+id,contact.visible and contact.global_transform.is_finite())
		await shot("G_"+id)
		var before: Basis=body.basis
		await axis(JOY_AXIS_TRIGGER_LEFT,1);await axis(JOY_AXIS_RIGHT_X,.7);await wait(.25);await axis(JOY_AXIS_RIGHT_X,0);await axis(JOY_AXIS_TRIGGER_LEFT,0)
		check("controller rotation changes physical prop "+id,not body.basis.is_equal_approx(before))
		await shot("R_"+id)
		if id=="work_wrench":
			await axis(JOY_AXIS_TRIGGER_RIGHT,1);light_speed=body.linear_velocity.length();check("controller throw retains velocity",g.physical.held==null and body.linear_velocity.length()>1);await axis(JOY_AXIS_TRIGGER_RIGHT,0)
		elif id=="spare":
			await action("throw_prop");check("heavy fitting throws more slowly than spanner",body.linear_velocity.length()>1 and body.linear_velocity.length()<light_speed,str(body.linear_velocity.length())+" / "+str(light_speed))
		else:
			await action("interact");check("release keeps ordinary collision "+id,g.physical.held==null and not body.freeze and not g.physical.forearm.visible)
		await wait(.2)
	var tool: RigidBody3D=await pickup_fixture("work_wrench")
	var carried_pose: Vector3=tool.position
	g.save_game(true);g.load_game();await wait(.3);quiet()
	check("carried save preserves supported tool in hand",g.physical.held==tool and g.physical.tool_hand.visible and tool.position.distance_to(carried_pose)<.3)
	# Actual bench keeps the prop beyond reach: no visual fix may bypass its sweep.
	# This is a separate bench fixture now that loading no longer returns it home.
	g.physical.release(false);tool.call("relocate",g.physical.homes.work_wrench);await wait(.2)
	g.player.position=Vector3(-18.24,.03,-14.9);g.player.camera.look_at(tool.global_position);await wait(.2);await action("interact");await wait(.5)
	check("bench pickup preserves contact clearance",g.physical.held==tool and tool.position.y>.79)
	check("blocked arm is concealed",not g.physical.tool_hand.visible or tool.global_position.distance_to(g.player.camera.global_position)<=1.05)
	await shot("B_blocked_bench");g.physical.release(false);await wait(.1)
	# Existing battery gameplay is driven by the real action and controller button.
	g.player.position=Vector3(-17.8,.03,-13.9);g.player.camera.look_at(Vector3(-15,1.3,-14.2));g.equipment.data.charge=25;g.equipment.data.spares=2
	await action("battery_replace")
	var service: Node3D=g.player.viewmodel.service
	for frame in 60:
		if service.cell_hand.visible or not service.running:break
		await get_tree().process_frame
	check("cell exchange uses fitted cell grip",service.running and service.cell_hand.visible and not service.cap_hand.visible,str(service.animation.current_animation_position))
	g.presentation.clear_transients();await shot("T_cell_exchange")
	check("render frame cannot reveal a duplicate support hand",not service.cap_hand.is_visible_in_tree() and service.cell_hand.is_visible_in_tree())
	var t: float=service.animation.current_animation_position;await action("pause");var paused: float=service.animation.current_animation_position;await wait(.25)
	check("pause holds actual exchange pose",get_tree().paused and is_equal_approx(paused,service.animation.current_animation_position))
	await action("pause");await wait(1)
	check("exchange consumes one spare and cleans hand and sounds",not service.running and int(g.equipment.data.spares)==1 and not service.cell_hand.visible and service.service_sounds.is_empty())
	g.equipment.data.charge=25;await joy(JOY_BUTTON_Y)
	for frame in 60:
		if service.cell_hand.visible or not service.running:break
		await get_tree().process_frame
	await shot("T_controller_exchange")
	check("controller starts same battery exchange",service.running)
	g.save_game(true);g.load_game();await wait(.25);quiet()
	check("load interrupts exchange without duplicate consumption",not service.running and not service.cell_hand.visible and int(g.equipment.data.spares)==0)
	if not "--touch-layouts" in OS.get_cmdline_user_args():await audio_checks()
	await finish_run()
func audio_checks() -> void:
	# Real impact callback uses the same velocity-derived hearing, independent of sample.
	var tool: RigidBody3D=g.physical.props.work_wrench
	g.player.position=Vector3(-17.8,.03,-13.9);g.presence.position=Vector3(-16.6,.03,-14)
	# Freeze unrelated fixture bodies so their return-to-home contacts cannot
	# consume the shared impact debounce while this one real fall is observed.
	for id in g.physical.props:
		if g.physical.props[id]!=tool:g.physical.props[id].freeze=true
	tool.call("relocate",Transform3D(Basis.IDENTITY,Vector3(-17,.9,-14)))
	for frame in 30:
		await get_tree().physics_frame
		if not tool.reset_pending:break
	g.physical.impact_cooldown=0;g.threat.state="observe";g.threat.grace=0;g.threat.last_known=Vector3.ZERO
	tool.linear_velocity=Vector3(0,-3,0)
	for frame in 90:
		await get_tree().physics_frame
		if g.threat.state=="investigate":break
	check("actual falling metal remains an enemy noise",g.threat.state=="investigate" and g.threat.last_known.distance_to(tool.position)<1.2,str(g.threat.last_known))
	quiet()
	var metal: AudioStreamPlayer3D=g.sound("prop_metal",g.player.position,-28);var sample: String=metal.stream.resource_path
	await wait(.05);check("selected metal plays on existing spatial bus",metal.playing and sample.contains("sound_touch/metal_light_") and metal.max_distance==12)
	var step: AudioStreamPlayer3D=g.sound("step",Vector3(0,0,1),-30)
	check("wood steps retain original four-sample routing",step.get_meta("sample").begins_with("foley/walk_wood_"))
	await wait(.7);check("one shot source releases itself",not is_instance_valid(metal))
	# Rain remains one existing shelter-aware system, not another layered storm.
	var weather: Node=g.get_node("BriarLaneExterior/BriarLaneWeather")
	g.player.position=Vector3(0,.03,8);await wait(1.1);var exterior: float=weather.outside.volume_db
	g.player.position=Vector3(0,.03,0);await wait(1.1)
	check("roof transition attenuates same exterior rain",weather.outside.volume_db<exterior-25 and weather.sheltered.playing and weather.outside.playing)
	g.player.position=Vector3(4.88,.03,-7.5);g.player.camera.look_at(g.targets.return_receiver.global_position);await use("return_receiver",false)
	var widget: Control
	for child in g.presentation.card_body.get_children():
		if child.get_script() and child.get_script().resource_path.ends_with("return_receiver.gd"):widget=child
	check("working receiver has mechanical dial source",is_instance_valid(widget) and widget.dial_sound.stream.resource_path.ends_with("radio_dial.ogg"))
	if is_instance_valid(widget):
		await action("ui_right");check("dial movement emits sound without per-tick save",widget.dial_sound.playing)
	await action("ui_cancel");await wait(.15);check("closing receiver restores gameplay",g.player.active and not g.menu_open)
	# Existing saved recorder event: new click, unchanged trigger and interruption.
	g.player.position=Vector3(3.3,.03,-7.6);g.player.camera.look_at(Vector3(3.3,1,-8.52));g.events.test_reel_heard=true;g.events.line_feed_off=true;g.events.erase("recorder_answer");g.recorder_memory.restore();g.presentation.clear_transients()
	await wait(3.5)
	check("quiet recorder response retains saved timing",g.recorder_memory.running and g.recorder_memory.click_count>0)
	await shot("A_recorder_response");g.save_game(true);var clicks: int=g.recorder_memory.click_count;g.load_game();await wait(.2);quiet()
	check("mid-response load does not replay click",g.recorder_memory.click_count==clicks)
	await wait(2.5);check("recorder returns to silence",not g.recorder_memory.running and g.recorder_memory.sources.is_empty())
