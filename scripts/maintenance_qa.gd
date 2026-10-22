extends "res://scripts/recording_repair_qa.gd"
func supported_records() -> void:
	var frame: Node3D=g.maintenance.rack.find_child("RackSourceFrame",true,false)
	for root in g.maintenance.rack.get_children():
		if not str(root.name).begins_with("Archive"):continue
		var bounds:=AABB();var first:=true
		for mesh in g.all_meshes(root):
			var world_bounds: AABB=mesh.global_transform*mesh.get_aabb()
			bounds=world_bounds if first else bounds.merge(world_bounds);first=false
		var below:=-INF
		for mesh in g.all_meshes(frame):
			for surface in mesh.mesh.get_surface_count():
				var arrays: Array=mesh.mesh.surface_get_arrays(surface)
				var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
				for i in vertices.size():
					if (mesh.global_basis*normals[i]).normalized().y<.95:continue
					var point: Vector3=mesh.global_transform*vertices[i]
					if point.y<=bounds.position.y+.012:below=maxf(below,point.y)
		check("visible record support / "+str(root.name),not first and absf(bounds.position.y-below)<.012,"gap="+str(bounds.position.y-below))
func play_store() -> void:
	await get_tree().physics_frame
	supported_records()
	var collider_size:=Vector3.ZERO
	for node in g.maintenance.rack.find_children("*","CollisionShape3D",true,false):
		if node.shape is BoxShape3D and node.shape.size.y>1.6:collider_size=(node.global_transform*AABB(-node.shape.size*.5,node.shape.size)).size
	check("rack world collision preserves surveyed footprint",collider_size.is_equal_approx(Vector3(1.35,1.65,.50)),str(collider_size))
	await travel(Vector2(3.25,-16.1),"service opening approach")
	g.player.rotation.y=PI;g.player.camera.rotation=Vector3.ZERO
	Input.action_press("forward");await wait(1.1);Input.action_release("forward");await wait(.2)
	check("standing body cannot enter low opening",g.player.position.z< -15.15 and not g.player.crouched,str(g.player.position))
	g.player.camera.look_at(Vector3(3.25,-2.1,-12));await shot("U01_service_opening")
	await travel(Vector2(3.25,-13.2),"physical crouch into service void",false,true)
	check("real crouch clearance under roof",g.player.crouched and not g.player.can_stand() and g.player.body_shape.shape.height<1.1)
	g.save_game();g.load_game();await wait(.3)
	check("crawl save restores stance without head clipping",g.player.crouched and not g.player.can_stand() and g.player.camera.position.y<1.05)
	g.player.camera.look_at(Vector3(3.25,-2,-10.4));await shot("U02_crawl_clearance")
	await travel(Vector2(3.25,-10.75),"crawl reaches store transition",false,true)
	await travel(Vector2(3.25,-9.3),"enter original records store")
	check("standing recovers in full-height store",not g.player.crouched and g.player.can_stand())
	g.player.camera.look_at(Vector3(4.7,-1.75,-7.1));await shot("U03_records_store")
	await travel(Vector2(4.95,-8.2),"archive shelf approach")
	await use("archive_rack")
	await action("ui_cancel");var frozen: float=g.maintenance.rack.position.x;await wait(.6)
	check("pause freezes moving shelving",g.menu_open and is_equal_approx(frozen,g.maintenance.rack.position.x))
	g.presentation.buttons.Resume.pressed.emit();await wait(.3)
	var saved_rack_x: float=g.maintenance.rack.position.x
	g.save_game();g.load_game();await wait(.1)
	check("mid-move save preserves carriage phase",g.maintenance.moving and absf(g.maintenance.rack.position.x-saved_rack_x)<.08)
	await wait(4)
	check("physical shelf rolls along rails",g.events.get("archive_rack_open",false) and not g.maintenance.moving and absf(g.maintenance.rack.position.x-3.15)<.03)
	g.player.camera.look_at(g.targets.underfloor_sheet.global_position);await shot("U04_open_record_bay")
	await use("underfloor_sheet",false)
	check("historical test obtained through real interaction",g.events.get("underfloor_read",false) and g.presentation.section=="document")
	await shot("U05_historical_test");await action("ui_cancel")
	await travel(Vector2(4.35,-8.8),"timber test approach")
	for i in 3:await use("test_joist")
	check("player taps create actual delayed answers",g.events.get("underfloor_taps",0)==3)
	g.player.camera.look_at(Vector3(3.25,-2,-11.8));await wait(3)
	check("unobserved shelving disturbance occurs",g.events.get("underfloor_echo_complete",false))
	g.player.camera.look_at(g.maintenance.rack.position+Vector3.UP);await shot("U06_shelf_disturbance")
	await wait(3)
	g.save_game();g.load_game();await wait(.3)
	check("historical discovery and completed disturbance persist",g.events.get("underfloor_read",false) and g.events.get("underfloor_echo_complete",false))
	await travel(Vector2(3.25,-9.3),"store return aisle")
	await travel(Vector2(3.25,-12.8),"crawl back toward cellar",false,true)
	await travel(Vector2(3.25,-16.1),"physical return to cellar",false,true)
	await wait(.3)
	check("standing recovers after cellar return",not g.player.crouched and g.player.position.y< -2.9)
	await travel(Vector2(0,-18),"existing relay aisle remains accessible")
func cover_check() -> void:
	# Labelled pursuit fixture; live AI/movement/collision continue without invulnerability.
	g.player.position=Vector3(3.25,-2.99,-15.8);g.player.restore_stance(false)
	g.events.threat_resolved=false;g.events.threat_pending=true;g.threat.enabled=true
	g.presentation.prefs.data.story_mode=false
	g.threat.begin(false,Vector3(2.4,-2.99,-18.3))
	for i in 80:
		if g.threat.state=="pursue":break
		await wait(.1)
	check("exposure starts actual live pursuit",g.threat.state=="pursue" and g.threat.can_see_player())
	await travel(Vector2(3.25,-13.1),"escape live pursuit through low opening",false,true)
	await wait(6)
	check("tall pursuer cannot penetrate crawl roof",g.presence.position.z< -15.15 and g.presentation.section!="dead",str(g.presence.position)+" state="+g.threat.state)
	check("cover breaks actual detection",not g.threat.can_see_player())
	g.player.camera.look_at(g.presence.position+Vector3.UP);await shot("U07_actual_cover")
	g.threat.reset();g.events.threat_pending=false;g.events.threat_resolved=true;g.presence.visible=false
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	output=OS.get_executable_path().get_base_dir().path_join("QA/underfloor")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	check("underfloor geometry loaded",is_instance_valid(g.maintenance))
	if not is_instance_valid(g.maintenance):await g.qa_exit(1);return
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	g.new_game();g.presentation.clear_transients();g.stage=3;g.report_read=true;g.shed_read=true
	g.events.chair=true;g.events["return"]=true;g.events.threat_resolved=true;g.threat.enabled=false;g.threat.reset()
	g.player.position=Vector3(0,.04,-8.3);g.doors.basement.locked=false;await wait(.3)
	await use("basement");await travel(Vector2(0,-18),"actual ramp descent")
	await play_store()
	# A player standing in the swept carriage path is protected without a force shove.
	g.player.position=Vector3(4.0,-2.99,-7.18);g.player.restore_stance(false)
	g.events.archive_rack_open=false;g.events.archive_rack_x=4.95;g.maintenance.restore();await wait(.2)
	g.maintenance.push_rack()
	check("rack refuses to sweep through player",not g.maintenance.moving and g.maintenance.rack.position.x>4.9)
	# Recovery fixture: moving shelving paused by a body must not snap into it on load.
	g.events.archive_rack_open=true;g.events.archive_rack_x=4.95;g.maintenance.restore();await wait(.2)
	g.save_game();g.load_game();await wait(.2)
	check("blocked mid-move reload cannot crush player",g.maintenance.rack.position.x>4.8 and g.maintenance.moving and g.player.position.distance_to(Vector3(4.0,-3,-7.18))<.2)
	await cover_check()
	recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"));recording=false;await wait(.2)
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	for spec in [["input_trace.json",trace],["frames.json",frames],["repair_report.json",{"passed":checks.size()-failed,"failed":failed,"checks":checks,"duration_seconds":seconds(),"capture":"Native wall-clock Windows fixture. Actual walking, crouching, rack/page/timber input and checkpoint recovery; separately labelled live cover encounter. Not a human playtest."}]]:
		var file=FileAccess.open(output.path_join(spec[0]),FileAccess.WRITE);file.store_string(JSON.stringify(spec[1],"\t"));file.close()
	print("UNDERFLOOR_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
