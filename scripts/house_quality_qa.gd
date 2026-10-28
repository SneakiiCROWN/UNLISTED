extends "res://scripts/recording_repair_qa.gd"
# Focused real-world input, collision, sound and saved optional horror checks.
# State placement is explicit; this is not an earned fresh investigation.
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	phase="title weather belongs to its actual camera"
	g.player.position=Vector3(0,.03,-5);await wait(.5)
	var weather: Node3D=g.get_node("BriarLaneExterior/BriarLaneWeather")
	var camera: Camera3D=g.get_viewport().get_camera_3d()
	check("idle title rain follows title camera rather than inactive indoor player",weather.viewpoint.distance_to(camera.global_position)<.02 and weather.near_rain.position.distance_to(camera.global_position+Vector3.UP*12)<.02)
	check("title exterior is not mixed as sheltered indoor player",weather.mix_level<.05)
	await shot("Q00_title_weather")
	g.new_game();g.horror.set_process(false);g.horror.set_physics_process(false);g.threat.enabled=false;g.threat.reset();g.presence.visible=false;g.ambient_director.enabled=false
	g.events.chair=true;g.presentation.clear_transients()
	phase="careful physical placement through actual interaction input"
	g.player.position=Vector3(4.6,.03,1.05);g.player.velocity=Vector3.ZERO
	var cup: RigidBody3D=g.physical.props.cup
	g.player.camera.look_at(cup.global_position);await wait(.25);await action("interact");await wait(.35)
	check("normal input picks up actual lounge mug",g.physical.held==cup)
	g.player.camera.look_at(Vector3(4.6,.80,.10));await wait(.25);await shot("Q01_placement_aim")
	await action("interact");await wait(.8)
	check("normal release places upright mug on real table",g.physical.last_set_down.get("id","")=="cup" and g.physical.held==null and cup.global_basis.y.dot(Vector3.UP)>.97,str(cup.position)+" / "+str(g.physical.last_set_down))
	check("placed mug reaches supported rest",absf(cup.position.y-.87)<.035 and cup.linear_velocity.length()<.15,str(cup.position))
	await shot("Q02_mug_set_down")
	g.save_game(true);var placed: Vector3=cup.position;g.load_game();await wait(.4)
	check("placed physical transform survives save and load",cup.position.distance_to(placed)<.06 and g.physical.held==null)
	# Targeting a vertical wall must not right/teleport the object into it.
	g.player.camera.look_at(cup.global_position);await wait(.15);await action("interact");await wait(.2)
	check("placed object can be picked up again",g.physical.held==cup)
	g.player.camera.look_at(Vector3(7.4,1.5,.1));await wait(.15)
	var before: Transform3D=cup.global_transform
	check("careful placement rejects walls without moving the held body",not g.physical.set_down() and cup.global_transform==before and g.physical.held==cup)
	await action("interact");check("unsupported release retains ordinary drop",g.physical.held==null and not cup.freeze)
	phase="physical sound through real architecture"
	g.player.position=Vector3(3.2,.03,-7);g.player.camera.rotation=Vector3.ZERO;await wait(.25)
	var hidden: AudioStreamPlayer3D=g.sound("step",Vector3(-4.9,.03,-7.8),-23)
	var clear: AudioStreamPlayer3D=g.sound("step",Vector3(3.0,.03,-7.3),-23)
	check("solid rooms gently attenuate physical source",hidden.get_meta("architecture_occluded",false) and is_equal_approx(hidden.volume_db,-27) and hidden.attenuation_filter_cutoff_hz<=1500)
	check("same-room source keeps authored gain and filter",not clear.get_meta("architecture_occluded",true) and is_equal_approx(clear.volume_db,-23))
	var voice: AudioStreamPlayer3D=g.sound("surveyor_warning",Vector3(-4.9,1.4,-7.8),-23)
	check("voice replacement slots have no competing gain writer",not voice.has_meta("architecture_occluded"))
	await wait(.4);await shot("Q03_office_sound_sources")
	phase="house memory returns handled mug only out of sight"
	g.ambient_director.enabled=true;g.stage=3;g.events.case_v3=true;g.events.threat_pending=false;g.events.threat_resolved=true
	g.events.erase("atmosphere");g.ambient_director.restore();g.horror.echo_index=-1;g.horror.beat=""
	g.events.memory_reviewed=true;g.events.cup_repeated=false;g.events.remembered_cup=[4.6,.87,0]
	cup.call("relocate",Transform3D(Basis.IDENTITY,Vector3(3.5,.08,1.5)))
	g.player.position=Vector3(3.5,.03,2.6);g.player.camera.look_at(Vector3(3.5,.08,1.5));await wait(1.0)
	check("observed mug never returns on screen",not g.physical.repeat_placement() and not g.events.cup_repeated)
	g.player.position=Vector3(0,.03,-5);g.player.camera.look_at(Vector3(0,1.5,-8));await wait(.1)
	check("unobserved handled mug returns physically",g.physical.repeat_placement())
	await wait(.4)
	check("return reserves a quiet aftermath",g.events.cup_repeated and float(g.ambient_director.policy.data.quiet)>4)
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(g.checkpoint_path))
	check("return event is saved immediately",saved.events.get("cup_repeated",false) and saved.events.atmosphere.quiet>0)
	var captions: int=g.message_history.filter(func(m):return m.text=="A soft tap.").size()
	g.load_game();await wait(.3)
	check("load preserves return without replaying cue",g.events.cup_repeated and not g.physical.repeat_placement() and g.message_history.filter(func(m):return m.text=="A soft tap.").size()==captions)
	g.player.position=Vector3(4.6,.03,1.1);g.player.camera.look_at(cup.position);await wait(.2);await shot("Q04_returned_mug")
	for broken in [[1,2],"bad",[0,"bad",0]]:
		var damaged: Dictionary=g.save_data().duplicate(true);damaged.events.remembered_cup=broken
		check("malformed remembered position refused / "+str(broken),not g.checkpoint_usable(damaged))
	g.events.cup_repeated=false;g.events.departure_pending="accounted_for"
	check("final departure blocks optional object response",not g.physical.repeat_placement())
	g.events.departure_pending="";g.events.cup_repeated=true
	phase="chronological optional sound queue under late simulation"
	g.ambient_director.set_physics_process(false);g.ambient_director.policy.data.quiet=0
	g.ambient_director.queue=[{"at":0.0,"where":Vector3(3,.1,-7),"sound":"step","db":-30.0,"pitch":1.0},{"at":.02,"where":Vector3(3.5,.1,-7),"sound":"step","db":-30.0,"pitch":1.0}]
	g.ambient_director.elapsed=0;g.ambient_director.emitted.clear();g.ambient_director._physics_process(.04)
	check("due steps keep authored spatial order",g.ambient_director.emitted.size()==2 and g.ambient_director.emitted[0].where.x<g.ambient_director.emitted[1].where.x)
	g.ambient_director.queue=[{"at":0.0,"where":Vector3(3,.1,-7),"sound":"step","db":-30.0,"pitch":1.0},{"at":.2,"where":Vector3(3.5,.1,-7),"sound":"step","db":-30.0,"pitch":1.0}]
	g.ambient_director.elapsed=0;var count_: int=g.ambient_director.emitted.size();g.ambient_director._physics_process(1.0)
	check("obsolete cue cluster is skipped rather than burst-played",g.ambient_director.emitted.size()==count_ and g.ambient_director.skipped_late.size()==2)
	await finish_run()
