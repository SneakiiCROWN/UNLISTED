extends "res://scripts/recording_repair_qa.gd"
var lifecycle: Array=[]
func particles(label_: String) -> Dictionary:
	var found: Dictionary={}
	for node in g.find_children("*","GPUParticles3D",true,false):
		found[str(node.get_instance_id())]={"path":str(node.get_path()),"rid":str(node.get_base()),"mesh":node.draw_pass_1.get_instance_id() if node.draw_pass_1 else 0,"material":node.process_material.get_instance_id() if node.process_material else 0,"emitting":node.emitting,"visible":node.is_visible_in_tree(),"queued":node.is_queued_for_deletion()}
	for node in g.find_children("*","CPUParticles3D",true,false):
		found[str(node.get_instance_id())]={"path":str(node.get_path()),"type":"CPU particles","rid":str(node.get_base()),"mesh":node.mesh.get_instance_id() if node.mesh else 0,"emitting":node.emitting,"visible":node.is_visible_in_tree(),"queued":node.is_queued_for_deletion()}
	for node in g.find_children("*","GPUParticlesCollisionHeightField3D",true,false):
		found[str(node.get_instance_id())]={"path":str(node.get_path()),"type":"Heightfield collision","rid":str(node.get_base()),"size":str(node.size),"visible":node.is_visible_in_tree(),"queued":node.is_queued_for_deletion()}
	lifecycle.append({"label":label_,"seconds":seconds(),"particles":found})
	var file:=FileAccess.open(output.path_join("particle_lifecycle.json"),FileAccess.WRITE);file.store_string(JSON.stringify(lifecycle,"\t"));file.close()
	return found
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	var source:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
		if arg.begins_with("--earned-source="):source=arg.trim_prefix("--earned-source=")
	assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	var initial:=particles("ordinary world constructed")
	if "--menu-idle" in OS.get_cmdline_user_args():
		var duration:=150.0
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--menu-idle-seconds="):duration=clampf(float(arg.trim_prefix("--menu-idle-seconds=")),30,900)
		await wait(duration);particles(str(duration)+" seconds isolated menu")
		check("Normal title remains responsive in isolated native window",g.presentation.section=="title" and g.menu_open)
		await shot("N00_idle_title");await finish_run();return
	if "--particle-lifecycle" in OS.get_cmdline_user_args():
		assert(not source.is_empty());var earned: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
		for i in 12:
			g.apply_save(earned);await wait(.25);particles("completed ending load "+str(i))
			g.presentation.show_menu(true);await wait(.25);particles("title return "+str(i))
			var open_case: Dictionary=earned.duplicate(true);open_case.ended=false;open_case.events.erase("ending");open_case.events.erase("final_account");open_case.events.departure_pending="";open_case.pos=[0,.03,7.5]
			g.apply_save(open_case);await wait(.25);particles("earned porch recovery "+str(i))
		var final:=particles("last recovery")
		check("Particle nodes and base RIDs survive repeated recovery",initial.keys()==final.keys() and initial.values().map(func(p):return p.rid)==final.values().map(func(p):return p.rid))
		await shot("N00_lifecycle_recovery");await finish_run();return
	g.new_game();g.horror.echo_index=-1;g.threat.enabled=false;g.ambient_director.enabled=false
	g.presentation.clear_transients();g.player.position=Vector3(-17.25,.03,-15.2);g.player.camera.look_at(g.physical.props.spare.global_position);await wait(.3)
	await action("interact");await wait(.6)
	check("Physical input collects shed fitting",g.physical.held==g.physical.props.spare)
	await travel(Vector2(-16,-14),"carry fitting away from original support")
	var saved: Dictionary=g.save_data().duplicate(true)
	var carried_before: Vector3=g.physical.held.position
	g.save_game(true);g.load_game();await wait(.25)
	check("Load preserves carried fitting and nearby physical position",g.physical.held==g.physical.props.spare and g.physical.props.spare.position.distance_to(carried_before)<.4)
	await shot("N01_restored_grip")
	await action("interact")
	check("Restored object releases into real physics",g.physical.held==null and not g.physical.props.spare.freeze,"position="+str(g.physical.props.spare.position)+" frozen="+str(g.physical.props.spare.freeze))
	var legacy:=saved.duplicate(true);legacy.events.erase("carried_prop");g.apply_save(legacy);await wait(.2)
	check("Legacy prop positions load without invented grip",g.physical.held==null)
	for invalid in [4,[1,2,3],{ "spare":[0,0,0,0,"bad",0]}]:
		var damaged:=saved.duplicate(true);damaged.events.props=invalid
		check("Malformed nested physical checkpoint rejected "+str(invalid),not g.checkpoint_usable(damaged))
	var unreachable:=saved.duplicate(true);unreachable.pos=[0,.03,8];g.apply_save(unreachable);await wait(.2)
	check("Restore never pulls a distant object through the house",g.physical.held==null)
	# Hearing fixture: player behind a solid service-room wall, real actor floor.
	g.player.position=Vector3(-6,.03,-7);g.presence.position=Vector3(0,-2.99,-18)
	g.threat.enabled=true;g.threat.begin(true,g.presence.position);g.threat.grace=0;g.threat.change("observe")
	var noise:=Vector3(-2.8,-2.99,-18.3);g.threat.hear(noise,12)
	check("Sound starts an actual listening investigation",g.threat.state=="investigate" and g.threat.hearing_pause>.5 and g.threat.last_known==noise)
	var origin: Vector3=g.presence.position;await wait(.35)
	check("Surveyor listens before walking",Vector2(g.presence.position.x-origin.x,g.presence.position.z-origin.z).length()<.05)
	g.threat.hear(Vector3(-2,-2.99,-20),3)
	check("Quiet competing rattle does not erase stronger source",g.threat.last_known==noise)
	await wait(1.4);check("Surveyor physically approaches heard source",g.presence.position.distance_to(noise)<origin.distance_to(noise)-.15)
	g.player.position=Vector3(-2.5,-2.99,-22);g.player.camera.look_at(g.presence.position+Vector3.UP*1.2)
	await shot("N02_heard_source_investigation")
	g.threat.change("pursue");g.threat.hear(Vector3(-2,-2.99,-20),40)
	check("Noise cannot magically cancel pursuit",g.threat.state=="pursue")
	g.threat.reset();g.threat.enabled=false;g.presence.visible=false
	# Actual existing event, no new voice, actor or supernatural explanation.
	g.player.position=Vector3(5.8,.03,2);g.player.camera.look_at(Vector3(7.4,1.5,2));g.stage=3
	g.events.case_v3=true;g.events.threat_pending=false;g.events.threat_resolved=true;g.horror.beat="";g.horror.echo_index=-1
	g.ambient_director.enabled=true;g.ambient_director.restore();g.ambience.volume_db=-35
	check("Existing window event reserves a quiet aftermath",g.ambient_director.request("window_taps") and float(g.ambient_director.policy.data.quiet)>5)
	await wait(1.2);await action("pause");var quiet: float=g.ambient_director.policy.data.quiet;await wait(.3)
	check("Pause freezes aftermath timing",get_tree().paused and is_equal_approx(quiet,g.ambient_director.policy.data.quiet))
	await action("pause");await wait(1.2)
	check("Score makes room for the physical sound",g.ambience.volume_db< -39)
	g.save_game(true);g.load_game();await wait(.2)
	check("Quiet aftermath survives load without replaying event",float(g.ambient_director.policy.data.quiet)>0 and g.ambient_director.queue.is_empty() and g.ambient_director.policy.data.used.window_taps==1)
	await shot("N03_window_aftermath");await finish_run()
