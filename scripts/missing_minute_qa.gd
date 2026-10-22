extends "res://scripts/recording_repair_qa.gd"
func pointer(point: Vector2,pressed: bool,motion:=false) -> void:
	point=g.get_viewport().get_stretch_transform()*point # Logical UI position -> native input pixels.
	var event: InputEvent
	if motion:
		var m:=InputEventMouseMotion.new();m.position=point;m.global_position=point;m.button_mask=MOUSE_BUTTON_MASK_LEFT;event=m
	else:
		var b:=InputEventMouseButton.new();b.position=point;b.global_position=point;b.button_index=MOUSE_BUTTON_LEFT;b.pressed=pressed;event=b
	event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event);await get_tree().process_frame
func rubbing_widget() -> Control:
	for node in g.presentation.card_body.get_children():
		if node.get_script() and str(node.get_script().resource_path).ends_with("carbon_rubbing.gd"):return node
	return null
func receiver_widget() -> Control:
	for node in g.presentation.card_body.get_children():
		if node.get_script() and str(node.get_script().resource_path).ends_with("return_receiver.gd"):return node
	return null
func play_chapter(accessibility:=false) -> void:
	await travel(Vector2(3,-7),"original reaches archive")
	await travel(Vector2(5.7,-7.2),"writing surface approach")
	await use("carbon_return",false)
	var rubbing=rubbing_widget()
	check("original exposes rubbing interaction",rubbing!=null)
	if rubbing==null:return
	if accessibility:
		g.presentation.buttons["Slow automatic scan"].pressed.emit();await wait(10.1)
	else:
		for row in 3:
			var origin: Vector2=rubbing.global_position
			await pointer(origin+Vector2(55,113+row*74),true)
			for i in 22:await pointer(origin+Vector2(55+i*29,113+row*74),true,true)
			await pointer(origin+Vector2(690,113+row*74),false)
	check("rubbing reveals impressions through input",g.events.get("carbon_read",false),str(g.events.get("carbon_coverage",[])))
	await shot("M01_carbon_rubbing")
	g.presentation.buttons["Put sheet down"].pressed.emit();await wait(.3)
	if g.events.get("inspection_search_pending",false) or (g.events.get("inspection_search_started",false) and not g.events.get("inspection_search_done",false)):
		var hiding=load("res://scripts/storage_hide_qa.gd").new();add_child(hiding)
		hiding.g=g;hiding.output=output;hiding.started_at=started_at;hiding.exact_target=exact_target
		await hiding.survive_search();checks.append_array(hiding.checks);hiding.queue_free()
	g.save_game();g.load_game();await wait(.3)
	check("impressions persist through save recovery",g.events.get("carbon_read",false))
	await travel(Vector2(4.9,-7.3),"receiver approach");await use("return_receiver",false)
	var receiver=receiver_widget();check("receiver uses real slider",receiver!=null)
	if receiver==null:return
	receiver.dial.value=103.0;g.presentation.buttons["Listen to receiver"].pressed.emit();await wait(.2)
	check("wrong frequency cannot change room",not g.events.get("receiver_found",false))
	receiver.dial.value=g.PUZZLES.station(g.events);await shot("M02_tuned_receiver")
	g.presentation.buttons["Listen to receiver"].pressed.emit();await wait(2)
	check("return is heard before exploring",g.events.get("receiver_found",false))
	await travel(Vector2(3,-7),"archive chapter exit");await travel(Vector2(0,-7),"chapter hallway")
	await travel(Vector2(0,1),"closed lounge approach")
	check("closed unobserved room changes",g.chapter.active and not g.lounge_contents.visible)
	await use("lounge");await travel(Vector2(2.7,1),"memory threshold")
	g.player.camera.look_at(Vector3(6.1,.8,-1.5));await wait(.3);await shot("M03_remembered_bedroom")
	check("original television collider disabled",g.targets.television.collision_layer==0)
	g.save_game();g.load_game();await wait(.4)
	check("save inside changed room restores same room",g.chapter.active and not g.lounge_contents.visible and g.player.active)
	await travel(Vector2(4.1,-.5),"bedroom clear aisle")
	await travel(Vector2(4.1,-1.25),"bedside front approach")
	await travel(Vector2(5.15,-1.25),"bedside drawer approach")
	await use("memory_drawer")
	check("actual drawer opens",g.chapter.drawer_open)
	await shot("M04_open_drawer")
	await use("memory_page",false)
	check("missing page obtained physically",g.events.get("last_page_read",false) and g.presentation.section=="document")
	await shot("M05_missing_page")
	if g.menu_open:await action("ui_cancel")
	# The new bedside location is behind the solid part of the east wall.
	# Let the natural off-screen appearance happen, then walk to its actual window.
	await travel(Vector2(4.1,-.4),"leave bedside for window")
	await travel(Vector2(4.1,1.9),"window viewing approach")
	check("window presence starts outside view",g.events.get("memory_watch_started",false) and g.presence.visible)
	g.player.camera.look_at(g.presence.position+Vector3.UP*1.65);await wait(.25)
	check("window presence is actually visible through glass",g.chapter.point_visible(g.presence.position+Vector3.UP*1.65))
	await shot("M06_window_presence")
	await travel(Vector2(4.1,-1.25),"return around open cabinet")
	await travel(Vector2(4,1),"memory return aisle")
	await travel(Vector2(2.7,1),"memory door return")
	await travel(Vector2(0,1),"leave bedroom into hall")
	check("leaving memory earns final investigation",g.events.get("bedroom_left",false))
	await use("lounge");await wait(2)
	check("closed unseen room safely returns",not g.chapter.active and g.lounge_contents.visible and g.targets.television.collision_layer!=0)
	g.save_game();g.load_game();await wait(.3)
	check("completed chapter persists",g.events.get("bedroom_left",false) and not g.chapter.active)
func confrontation() -> void:
	# Labelled outside fixture: subsequent movement/contact use the actual AI.
	g.presentation.clear_transients();g.chapter.set_room(false);g.threat.reset();g.threat.enabled=true
	g.events.memory_watch_pending=false;g.events.memory_watch_done=false;g.events.memory_watch_started=true
	g.chapter.watch_clock=0;g.chapter.watch_seen=true;g.chapter.watch_walk=0
	g.presence.position=Vector3(9.15,.04,2);g.presence.visible=true;g.threat.set_collision(true)
	g.player.position=Vector3(9.15,.04,5.3);g.player.velocity=Vector3.ZERO
	await travel(Vector2(9.15,4.5),"approach window figure outside")
	check("approach hands same body to warned AI",g.threat.state=="warning" and g.threat.grace>2 and g.presence.position.distance_to(Vector3(9.15,0,2))<.3)
	await travel(Vector2(9.15,6),"outside pursuit spacing")
	await wait(7)
	check("AI moves along real east property route",g.presence.position.z>2.6,"body="+str(g.presence.position))
	for i in 180:
		if g.presentation.section=="dead":break
		await wait(.1)
	check("outside confrontation has real death consequence",g.presentation.section=="dead")
	await shot("M07_outside_consequence")
	if g.presentation.section=="dead":
		g.presentation.buttons["Retry Checkpoint"].pressed.emit();await wait(.5)
		check("outside retry preserves page and fair warning",g.events.get("last_page_read",false) and g.presence.position.x>7.7 and g.threat.grace>2 and g.player.active)
		await travel(Vector2(9.15,6),"retry east approach escape",true)
		await travel(Vector2(5,8),"retry turns around house",true)
		await travel(Vector2(0,7),"retry reaches front approach",true)
		check("physical escape from outside encounter",g.player.active and not g.menu_open)
	g.threat.reset();g.presence.visible=false
func edge_checks() -> void:
	# Focused fixtures verify prerequisite edges; this is not a new full-route proof.
	g.new_game();g.presentation.clear_transients();g.player.position=Vector3(3.4,.04,-8.0)
	g.doors.office.locked=false;g.doors.office.set_open(true,.01);await wait(.3)
	await use("record",false)
	check("physical site history readable without power",g.stage<3 and g.presentation.section=="document" and g.events.get("notes",{}).has("BRIAR LANE / TEMPORARY OFFICE"))
	check("site paper cannot grant archive key",not g.brass_key)
	g.presentation.resume_game();g.events.field_return_read=true
	g.chapter.open_carbon();await wait(.2)
	check("inspection requires the physical light attachment",rubbing_widget()==null and not g.events.get("carbon_read",false))
	g.equipment.data.uv=true;g.equipment.data.mode=2;g.equipment.apply_light()
	g.chapter.open_carbon();await wait(.3)
	var rubbing=rubbing_widget();var origin: Vector2=rubbing.global_position
	await pointer(origin+Vector2(55,113),true)
	for i in 4:await pointer(origin+Vector2(75+i*29,113),true,true)
	await pointer(origin+Vector2(190,113),false)
	var partial: Array=g.events.carbon_coverage.duplicate()
	check("partial rubbing is genuinely incomplete",float(partial[0])>0 and float(partial[0])<.78 and not g.events.get("carbon_read",false))
	g.presentation.resume_game();g.save_game();g.load_game();await wait(.3)
	check("partial rubbing survives checkpoint",is_equal_approx(float(g.events.carbon_coverage[0]),float(partial[0])) and is_equal_approx(float(g.events.carbon_coverage[1]),float(partial[1])) and is_equal_approx(float(g.events.carbon_coverage[2]),float(partial[2])) and not g.events.get("carbon_read",false))
	g.stage=3;g.isolated=false;g.chapter.open_receiver();await wait(.3)
	var receiver=receiver_widget();receiver.dial.value=g.PUZZLES.station(g.events)
	g.presentation.buttons["Listen to receiver"].pressed.emit();await wait(.2)
	check("live feed blocks even correct frequency",not g.events.get("receiver_found",false) and g.menu_open and receiver.display.text.to_lower().contains("interference"),receiver.display.text)
	g.isolated=true;g.presentation.buttons["Listen to receiver"].pressed.emit();await wait(.3)
	check("known frequency needs no invisible clue flag",g.events.get("receiver_found",false) and not g.events.get("carbon_read",false))
	g.threat.reset();g.presence.visible=false
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		exact_target.size=size_;exact_target.size_2d_override=Vector2i(roundi(720.0*size_.x/size_.y),720)
		for ending in ["accounted_for","on_record"]:
			g.events.ending=ending;g.events.bedroom_left=true;g.events.case_v3=true;g.presentation.show_ending();await wait(1.2)
			var bottom:=0.0
			for button in g.presentation.buttons.values():bottom=maxf(bottom,button.get_global_rect().end.y)
			check("settled ending fits "+ending+str(size_),bottom<=g.get_viewport().get_visible_rect().size.y and g.presentation.body.modulate.a>.99)
			await shot("M10_"+ending+"_"+str(size_.x))
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Focused prerequisite fixtures and settled ending layouts; actual site input and mouse rubbing. No route-completion claim."},"\t"));file.close()
	print("CHAPTER_EDGE_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	output=OS.get_executable_path().get_base_dir().path_join("QA/missing_minute")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	if "--chapter-edge-qa" in OS.get_cmdline_user_args():
		await edge_checks();return
	g.new_game();g.presentation.clear_transients();g.stage=3;g.report_read=true;g.shed_read=true;g.isolated=true
	g.events.inspection_search_started=true;g.events.inspection_search_done=true # Isolate the existing chapter fixture.
	g.equipment.data.uv=true;g.equipment.data.mode=2;g.equipment.apply_light() # Labelled post-equipment chapter fixture.
	g.events.field_return_read=true;g.events.threat_resolved=true;g.events["return"]=true;g.events.chair=true;g.events.impossible_room_resolved=true
	g.threat.enabled=false;g.threat.reset();g.investigation.restore()
	for id in ["office","front"]:g.doors[id].locked=false;g.doors[id].set_open(true,.01)
	g.player.position=Vector3(0,.04,-7);await wait(.3)
	check("new ending cannot skip missing page",not g.finish_attendance("accounted_for"))
	g.events.receiver_found=true;g.player.position=Vector3(9,.04,2);g.player.camera.look_at(Vector3(6,.8,1));await wait(1.5)
	check("outside observer prevents visible bedroom swap",not g.chapter.active)
	g.events.receiver_found=false;g.chapter.quiet=0;g.player.position=Vector3(0,.04,-7)
	await play_chapter()
	if "--window-confrontation" in OS.get_cmdline_user_args():await confrontation()
	# Final presentation snapshots; no additional gameplay assertions from fixture placement.
	g.threat.reset();g.presence.visible=false
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		exact_target.size=size_;exact_target.size_2d_override=Vector2i(roundi(720.0*size_.x/size_.y),720)
		g.chapter.open_carbon();await wait(.3)
		check("rubbing layout fits "+str(size_),g.presentation.card_body.get_global_rect().end.x<=g.get_viewport().get_visible_rect().size.x and g.presentation.card_body.get_global_rect().end.y<=g.get_viewport().get_visible_rect().size.y)
		await shot("M08_rubbing_"+str(size_.x));g.presentation.resume_game()
		g.events.memory_confirmed=true;g.presentation.show_register();await wait(.3)
		check("earned new-case register fits "+str(size_),g.presentation.card_body.get_global_rect().end.y<=g.get_viewport().get_visible_rect().size.y)
		await shot("M09_register_"+str(size_.x));g.presentation.resume_game()
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	var f=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Labelled post-report fixture. Actual movement, rubbing mouse input, tuning callbacks, drawer/page interactions and checkpoint restores. Not a human playthrough."},"\t"));f.close()
	print("MISSING_MINUTE_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
