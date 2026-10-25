extends "res://scripts/recording_repair_qa.gd"
var layout_only:=false
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	layout_only="--answers-layouts" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	g.new_game();g.stage=3;g.fuse=true;g.events.chair=true;g.events.yard=true;g.events.basement=true;g.events["return"]=true;g.events.threat_resolved=true
	g.shed_read=true;g.events.field_return_read=true;g.ambient_director.enabled=false
	g.horror.echo_index=-1;g.threat.reset()
	for light in g.lamps:light.light_energy=1.1
	g.player.position=Vector3(-23,.03,-14.7);g.player.camera.look_at(Vector3(-21.0,.01,-14))
	g.presentation.clear_transients();await wait(.4)
	await wait(1.6)
	check("watched muddy ground cannot grow footprints",not g.property_memory.marks.visible)
	await shot("A01_watched_ground_before")
	g.save_game(true);g.load_game();await wait(.2)
	check("pre-reveal save remains unrevealed",not g.property_memory.marks.visible)
	g.events.threat_pending=true
	g.player.position=Vector3(-16,.03,-14);g.player.camera.look_at(Vector3(-16,1,-16))
	await wait(1.5);check("pending encounter suppresses hidden trail",not g.property_memory.marks.visible)
	g.events.threat_pending=false;g.threat.reset();g.presence.visible=false
	await wait(1.8)
	check("trail emerges only after hidden opportunity",g.property_memory.marks.visible and g.events.get("unreturned_steps",false))
	var high:=0.0
	for point in g.property_memory.sample_points:
		var q:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.3,point-Vector3.UP*.3,1)
		var hit: Dictionary=g.get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():high=maxf(high,absf(point.y-hit.position.y))
	check("sole vertices follow real terrain",high<.035,str(high))
	check("single alternating trail has seven soles",g.property_memory.marks.get_child_count()==7)
	var upward:=true;var pointed:=true
	for sole in g.property_memory.marks.get_children():
		var array: Array=sole.mesh.surface_get_arrays(0);var toe:=Vector3.ZERO;var heel:=Vector3.ZERO;var nt:=0;var nh:=0
		for i in array[Mesh.ARRAY_VERTEX].size():
			upward=upward and array[Mesh.ARRAY_NORMAL][i].y>.9
			if array[Mesh.ARRAY_TEX_UV][i].y<.1:toe+=array[Mesh.ARRAY_VERTEX][i];nt+=1
			else:heel+=array[Mesh.ARRAY_VERTEX][i];nh+=1
		pointed=pointed and (toe/nt-heel/nh).normalized().dot(Vector3(.95,0,3.02).normalized())>.95
	check("actual sole surfaces face torch and sky",upward)
	check("toes point toward abandoned wall work",pointed)
	g.player.position=Vector3(-22.8,.03,-14.3);g.player.camera.look_at(Vector3(-21.0,.005,-14))
	await wait(.35);await shot("A02_unreturned_muddy_steps")
	if "--answers-diagnostic" in OS.get_cmdline_user_args():
		var info: Array=[]
		for sole in g.property_memory.marks.get_children():
			var array: Array=sole.mesh.surface_get_arrays(0)
			info.append({"visible":sole.is_visible_in_tree(),"vertices":str(array[Mesh.ARRAY_VERTEX]),"normals":str(array[Mesh.ARRAY_NORMAL]),"uvs":str(array[Mesh.ARRAY_TEX_UV]),"opacity":sole.material_override.get_shader_parameter("opacity"),"screen":str(g.player.camera.unproject_position(array[Mesh.ARRAY_VERTEX][0]))})
			var material: StandardMaterial3D=g.mat(Color.RED).duplicate();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_DISABLED;sole.material_override=material
		var file:=FileAccess.open(output.path_join("material_diagnostic.json"),FileAccess.WRITE);file.store_string(JSON.stringify(info,"\t"));file.close()
		await wait(.2);await shot("D01_DIAGNOSTIC_RED_GEOMETRY_not_game_art");await finish_run();return
	g.player.position=Vector3(-22.1,.03,-15.6);g.player.camera.look_at(Vector3(-21.6,.005,-15.4));await wait(.2);await shot("A02b_sole_contact_close")
	g.player.camera.look_at(Vector3(-20.3,.8,-12.2));await shot("A03_abandoned_wall_feed")
	g.save_game(true);g.load_game();await wait(.25)
	check("trail remains after visible load",g.property_memory.marks.visible)
	await action("ui_cancel");await wait(.3);await action("ui_cancel")
	check("trail remains through pause",g.property_memory.marks.visible)
	# An old case has no opt-in and gets neither new optional event.
	g.events.erase("house_answers");g.events.erase("unreturned_steps");g.events.erase("recorder_answer");g.property_memory.restore()
	g.player.position=Vector3(-16,.03,-14);await wait(1.5)
	check("legacy case does not acquire new trail",not g.property_memory.marks.visible)
	g.events.house_answers=1;g.events.unreturned_steps=true;g.property_memory.restore()
	g.player.position=Vector3(3.3,.03,-7.6);g.player.camera.look_at(Vector3(3.3,1.01,-8.52));g.events.test_reel_found=true;g.field_tape.restore()
	g.events.line_feed_off=false;g.dead_line.restore()
	if not layout_only:
		g.field_tape.play();await wait(5.5)
		check("historical reel cannot trigger live response",not g.recorder_memory.running and not g.events.has("recorder_answer"))
		await wait(8.9)
		check("actual historical reel completes separately",g.events.get("test_reel_heard",false) and not g.field_tape.playing)
	else:g.events.test_reel_heard=true
	g.presentation.clear_transients();await wait(3.5)
	check("powered test equipment prevents recorder response",not g.recorder_memory.running and not g.events.has("recorder_answer"))
	g.dead_line.use("line_feed")
	var before: Array=[]
	for reel in get_tree().get_nodes_in_group("archive_reels"):before.append(reel.rotation.y)
	await wait(3.65)
	check("quiet stopped equipment starts one mechanical response",g.recorder_memory.running and g.recorder_memory.click_count==1)
	var needle: Node3D=g.get_node("ArchiveTransport/ReturnMeterNeedle")
	check("stopped return meter visibly answers",absf(needle.rotation.y+.55)>.03,str(needle.rotation.y))
	await shot("B01_reels_reverse")
	var moved: float=get_tree().get_nodes_in_group("archive_reels")[0].rotation.y-float(before[0])
	check("actual recorder reels move backwards",moved<-.03,str(moved))
	await action("ui_cancel");var angle: float=get_tree().get_nodes_in_group("archive_reels")[0].rotation.y;var needle_paused: float=needle.rotation.y;await wait(.4)
	check("pause suspends reel response",is_equal_approx(angle,get_tree().get_nodes_in_group("archive_reels")[0].rotation.y))
	check("pause suspends physical meter response",is_equal_approx(needle_paused,needle.rotation.y))
	await action("ui_cancel");g.save_game(true);var clicks: int=g.recorder_memory.click_count;var needle_saved: float=needle.rotation.y;g.load_game()
	check("partial meter angle restores without a visible jump",absf(needle.rotation.y-needle_saved)<.01)
	await wait(.1)
	check("mid-event load resumes without repeated relay",g.recorder_memory.running and g.recorder_memory.click_count==clicks)
	await wait(2.5)
	check("response ends once and leaves equipment silent",not g.recorder_memory.running and g.events.recorder_answer.phase=="spent" and g.recorder_memory.sources.is_empty())
	check("meter settles back to its real mechanical rest",absf(needle.rotation.y+.55)<.01)
	var stopped: float=get_tree().get_nodes_in_group("archive_reels")[0].rotation.y
	g.save_game(true);g.load_game();await wait(.3)
	check("stopped reel angle and spent event survive load",is_equal_approx(stopped,get_tree().get_nodes_in_group("archive_reels")[0].rotation.y) and not g.recorder_memory.running)
	await wait(3.5);check("spent response never repeats",g.recorder_memory.click_count==clicks)
	await shot("B02_deck_silent_again")
	if not layout_only:await edge_cases()
	await finish_run()

func edge_cases() -> void:
	g.events.erase("recorder_answer");g.recorder_memory.restore();g.events.threat_pending=true;await wait(3.5)
	check("pending threat reserves recorder quiet window",not g.recorder_memory.running and not g.events.has("recorder_answer"))
	g.events.threat_pending=false;g.threat.reset();g.presence.visible=false
	g.threat.enabled=false;g.presentation.prefs.data.reduced_motion=true;g.presentation.prefs.data.sound_captions=true
	var before: float=get_tree().get_nodes_in_group("archive_reels")[0].rotation.y
	await wait(3.65)
	check("story mode still permits safe recorder response",g.recorder_memory.running)
	await wait(.5)
	check("reduced motion keeps reels stationary",is_equal_approx(before,get_tree().get_nodes_in_group("archive_reels")[0].rotation.y))
	await shot("B03_reduced_motion_caption")
	g.field_tape.play();await wait(.1)
	check("new playback interrupts response without competing motor",not g.recorder_memory.running and g.events.recorder_answer.phase=="spent")
	g.field_tape.stop();g.horror.stop_audition();g.horror.echo_index=-1;g.save_game(true);g.load_game();await wait(.2)
	check("interrupted response stays spent after load",not g.recorder_memory.running and g.events.recorder_answer.phase=="spent")
	g.events.erase("house_answers");g.events.erase("recorder_answer");g.recorder_memory.restore();await wait(3.5)
	check("legacy recorder never opts into new event",not g.recorder_memory.running and not g.events.has("recorder_answer"))
	# Changing the preference during a running response freezes its current pose.
	g.events.house_answers=1;g.presentation.prefs.data.reduced_motion=false
	g.recorder_memory.start_runtime();await wait(.5)
	g.presentation.prefs.data.reduced_motion=true;await wait(.1)
	var needle: Node3D=g.get_node("ArchiveTransport/ReturnMeterNeedle")
	var stopped: float=needle.rotation.y;await wait(.3)
	check("live reduced-motion change freezes meter without reset",is_equal_approx(stopped,needle.rotation.y) and g.events.recorder_answer.reduced)
