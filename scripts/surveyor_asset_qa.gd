extends "res://scripts/recording_repair_qa.gd"
# Matched art fixtures followed by real collision-driven movement/contact.
# These are isolated tests, not naturally earned narrative encounters.
func run(game: Node) -> void:
	g=game;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	g.new_game();g.events.chair=true;g.presentation.clear_transients()
	g.threat.enabled=false;g.threat.reset()
	g.horror.set_process(false);g.horror.set_physics_process(false);g.ambient_director.set_process(false)
	g.player.active=false
	var actor: Node3D=g.surveyor_actor
	var candidate: bool="--surveyor-assets" in OS.get_cmdline_user_args() or "--surveyor-revision" in OS.get_cmdline_user_args()
	check("candidate is isolated and fallback selection is explicit",actor.asset_candidate==candidate)
	check("65 original gameplay bones retained",actor.skeleton.get_bone_count()==65)
	for clip in ["listen","watch","walk","run","attack","capture","react"]:check("working clip / "+clip,actor.clips.has(clip))
	if "--assets-live-only" in OS.get_cmdline_user_args():await live_review();await finish_run(false);return
	var fill:=OmniLight3D.new();fill.position=Vector3(0,2.5,-3.7);fill.light_color=Color(.84,.87,.87);fill.light_energy=.7;fill.omni_range=6;g.add_child(fill)
	g.presence.position=Vector3(0,.04,-6.2);g.presence.visible=true;g.presence.look_at(Vector3(0,.04,-3.5));actor.set_mode("watch")
	phase="matched neutral construction fixtures"
	for spec in [["front",Vector3(0,.04,-2.8),Vector3(0,1.05,-6.2)],
		["face",Vector3(0,.04,-5.25),Vector3(0,1.72,-6.2)],
		["side",Vector3(.9,.04,-4.7),Vector3(0,1.1,-6.2)],
		["rear",Vector3(0,.04,-9.5),Vector3(0,1.05,-6.2)]]:
		g.player.position=spec[1];g.player.camera.look_at(spec[2]);await wait(.5);await shot("neutral_"+spec[0])
	fill.visible=false;phase="ordinary hall light"
	g.player.position=Vector3(0,.04,.4);g.player.camera.look_at(Vector3(0,1.1,-6.2));await wait(.6);await shot("hall_silhouette")
	if candidate and not actor.art_revision:
		var found:=""
		for clip in actor.animator.get_animation_list():
			if clip.begins_with("Asset_HeadResponse"):found=clip;break
		check("UAL2 rest-corrected response exported",not found.is_empty())
		if not found.is_empty():
			phase="UAL2 response retarget preview - no automatic gameplay use"
			actor.animator.play(found,.25);await wait(1.2);await shot("ual2_response");actor.set_mode("watch")
	# Real production movement method outside the actual lounge window. No world
	# edits or invented substitute wall are added for the camera.
	phase="window walkby collision fixture"
	g.presence.position=Vector3(8.7,.04,3.3);g.presence.rotation.y=0;g.presence.velocity=Vector3.ZERO
	g.threat.set_collision(true);g.threat.route=PackedVector3Array([Vector3(8.7,.04,.55)])
	g.player.position=Vector3(5.9,.04,2.6);g.player.camera.look_at(Vector3(8.7,1.5,2))
	var start: Vector3=g.presence.position
	for i in 220:
		await get_tree().physics_frame;g.threat.move_route(g.get_physics_process_delta_time(),1.15,true)
	check("window actor moves on real ground",g.presence.position.distance_to(start)>2 and g.presence.position.z<1.1,str(g.presence.position))
	await shot("window_outside")
	g.threat.route.clear();actor.set_mode("watch")
	g.presence.position=Vector3(5.2,.04,2.4);g.presence.look_at(Vector3(9.3,.04,2.7))
	g.player.position=Vector3(9.3,.04,2.7);g.player.camera.look_at(g.presence.position+Vector3.UP*1.4);await wait(.5);await shot("window_inside")
	phase="rain and actual yard lighting"
	g.presence.position=Vector3(8.7,.04,2.4);g.presence.look_at(Vector3(10.4,.04,4.2))
	g.player.position=Vector3(10.4,.04,4.2);g.player.camera.look_at(g.presence.position+Vector3.UP*1.25);await wait(.7);await shot("rain_outdoors")
	phase="cellar light fixture"
	g.presence.position=Vector3(0,-2.97,-20.5);g.presence.look_at(Vector3(0,-2.97,-17.2))
	g.player.position=Vector3(0,-2.97,-17.2);g.player.camera.look_at(g.presence.position+Vector3.UP*1.25);await wait(.7);await shot("cellar")
	if "--assets-views-only" in OS.get_cmdline_user_args():await finish_run(false);return
	phase="actual walking and running with production collision"
	g.presence.position=Vector3(0,.04,-8);g.presence.velocity=Vector3.ZERO;g.player.position=Vector3(0,.04,-1)
	g.player.camera.look_at(g.presence.position+Vector3.UP*1.3)
	g.threat.route=PackedVector3Array([Vector3(0,.04,-5)])
	start=g.presence.position
	for i in 150:
		await get_tree().physics_frame;g.threat.move_route(g.get_physics_process_delta_time(),1.1,true)
	check("actual walk travels with capsule",g.presence.position.distance_to(start)>1.8)
	await shot("walk_motion")
	g.threat.route=PackedVector3Array([Vector3(0,.04,-2)])
	start=g.presence.position
	for i in 65:
		await get_tree().physics_frame;g.threat.move_route(g.get_physics_process_delta_time(),2.7,true)
	check("actual run travels with capsule",g.presence.position.distance_to(start)>1.8)
	await shot("run_motion")
	if actor.art_revision:await noise_search()
	await live_review()
	await finish_run(false)

func live_review() -> void:
	phase="real AI pursuit and contact"
	g.new_game();g.events.chair=true;g.player.position=Vector3(0,.04,-4);g.player.rotation.y=PI;g.player.camera.rotation=Vector3.ZERO
	g.threat.enabled=true;g.threat.arm();g.player.active=true
	check("real perception reaches pursuit",await until_state("pursue",20))
	await shot("pursuit")
	check("warned contact reaches capture",await until_state("capture",10))
	if g.capture_director.active:
		await wait(1.0);await shot("capture_face")
		check("capsule keeps camera outside enemy",g.player.position.distance_to(g.presence.position)>.64)
		await action("ui_cancel");var clock: float=g.capture_director.clock;await wait(.3)
		check("capture pause freezes time",get_tree().paused and is_equal_approx(clock,g.capture_director.clock))
		g.presentation.buttons.Resume.pressed.emit()
	check("contact completes death",await until_state("dead",8))
	if g.presentation.buttons.has("Retry Checkpoint"):
		g.presentation.buttons["Retry Checkpoint"].pressed.emit();await wait(.5)
		check("retry recovers living controls",not g.capture_director.active and g.player.active and g.presentation.section=="game")
	else:check("retry button exists",false)

func until_state(value: String,limit: float) -> bool:
	var deadline:=seconds()+limit
	while seconds()<deadline:
		if g.threat.state==value:return true
		await wait(.05)
	return g.threat.state==value

func noise_search() -> void:
	phase="actual noise investigation - isolated starting state"
	g.new_game();g.events.chair=true;g.threat.enabled=true
	g.player.position=Vector3(0,.04,-1);g.player.active=false
	g.threat.arm();g.threat.grace=0;g.threat.change("observe")
	g.presence.position=Vector3(0,.04,-5.3);g.presence.rotation.y=0
	g.sound("prop_metal",Vector3(-2.8,.04,-7.75),-20)
	g.threat.hear(Vector3(-2.8,.04,-7.75),10.0)
	check("sound starts actual investigation",g.threat.state=="investigate")
	var origin: Vector3=g.presence.position
	for i in 65:
		g.player.camera.look_at(g.presence.position+Vector3.UP*1.25);await wait(.1)
	check("investigation moves toward source",g.presence.position.distance_to(origin)>1.0)
	await shot("searching")
