extends "res://scripts/recording_repair_qa.gd"
func survive_search() -> void:
	# Starts with genuinely earned UV evidence in the full route, not an injected AI state.
	await travel(Vector2(6.15,-6.0),"leave inspection desk")
	await travel(Vector2(6.25,-4.85),"storage cupboard approach")
	g.player.camera.look_at(g.targets.storage_door.global_position);await wait(.2);await shot("H01_storage_cupboard")
	await use("storage_door");await wait(.3)
	check("fitted doors physically open",g.storage_hide.opened and g.storage_hide.leaves.size()==2)
	await travel(Vector2(6.35,-3.65),"walk inside storage cupboard",false,true)
	Input.action_press("crouch");await wait(.2)
	check("cupboard interior has real crouch clearance",g.storage_hide.inside() and g.player.crouched)
	await use("storage_door");await wait(.4)
	check("closed wood blocks actual Surveyor sight",not g.storage_hide.opened and not g.threat.can_see_player())
	# Turn the torch off through its actual mode action, retaining real cover.
	for i in 3:
		if int(g.equipment.data.mode)==0:break
		await action("flashlight")
	await shot("H02_inside_cover")
	var nearest:=100.0;var until:=seconds()+35
	while seconds()<until and not g.events.get("inspection_search_done",false) and not g.menu_open:
		nearest=minf(nearest,g.presence.position.distance_to(g.storage_hide.global_position))
		await wait(.1)
	check("Surveyor searches close to quiet physical cover",nearest<2.0,"nearest="+str(nearest))
	check("unseen quiet player survives search",g.presentation.section!="dead" and not g.storage_hide.opened and g.events.get("inspection_search_done",false))
	g.save_game();g.load_game();await wait(.3);Input.action_press("crouch")
	check("save restores player inside closed cupboard",g.storage_hide.inside() and not g.storage_hide.opened and g.player.active)
	await use("storage_door");await wait(.3)
	await travel(Vector2(6.35,-4.85),"walk out of storage cupboard",false,true)
	Input.action_release("crouch");await wait(.3)
	check("standing recovers outside storage cupboard",not g.player.crouched and not g.storage_hide.inside())
	await shot("H03_after_search");await travel(Vector2(5.7,-7.2),"return to inspection desk")
	if int(g.equipment.data.mode)==0:await action("flashlight")
func risk_tests() -> void:
	g.presentation.clear_transients();g.threat.reset();g.presence.visible=false
	g.storage_hide.set_open(true);await wait(.7)
	g.player.position=Vector3(6.25,.04,-4.85);g.player.velocity=Vector3.ZERO
	g.events.inspection_search_started=true;g.events.inspection_search_done=false
	g.events.threat_origin="inspection";g.events.threat_spawn=[6.25,.04,-6.4];g.events.threat_pending=true;g.events.threat_resolved=false
	g.save_game(true);var safe: Dictionary=g.save_data().duplicate(true)
	g.threat.begin(false,Vector3(6.25,.04,-6.4))
	await travel(Vector2(6.35,-3.65),"enter cupboard in actor sight",false,true);Input.action_press("crouch")
	await use("storage_door");await wait(.2)
	check("seen entry is remembered through closed doors",g.storage_hide.suspected)
	var until:=seconds()+12
	while seconds()<until and not g.storage_hide.opened and not g.menu_open:await wait(.05)
	check("Surveyor opens cover after seeing entry",g.storage_hide.opened and g.threat.grace>.5 and g.presentation.section!="dead")
	await shot("H04_seen_entry_breach")
	var deaths: int=g.threat.deaths;until=seconds()+15
	while seconds()<until and g.presentation.section!="dead":await wait(.1)
	check("exposed player faces real death",g.presentation.section=="dead" and g.threat.deaths>deaths)
	if g.presentation.section=="dead":
		g.presentation.buttons["Retry Checkpoint"].pressed.emit();await wait(.3)
		check("retry returns to safe approach with warning",g.player.position.distance_to(Vector3(6.25,0,-4.85))<.3 and g.threat.grace>2 and g.player.active)
		await travel(Vector2(5,-4.8),"retry clears cupboard approach",true)
		await travel(Vector2(3.2,-6.8),"retry escape across office",true)
		check("retry supports actual escape",g.player.active and g.presentation.section!="dead")
	# A fresh closed-cover fixture tests an actual carried-object impact, not hear() injection.
	g.threat.reset();g.presence.visible=false;g.events.threat_pending=false;g.events.threat_resolved=true
	g.player.position=Vector3(6.35,.04,-3.65);g.player.velocity=Vector3.ZERO;Input.action_press("crouch")
	g.storage_hide.set_open(false);await wait(.7)
	var mug: RigidBody3D=g.physical.props.cup;mug.call("relocate",Transform3D(Basis.IDENTITY,Vector3(6.35,.08,-3.6)));await wait(.7)
	g.player.camera.look_at(mug.global_position);await wait(.2);await action("interact")
	check("loose mug can be picked up inside cover",g.physical.held==mug)
	g.events.threat_pending=true;g.events.threat_resolved=false;g.events.threat_spawn=[6.25,.04,-4.85]
	g.threat.begin(false,Vector3(6.25,.04,-4.85));await wait(4.8)
	check("quiet closed cover initially conceals player",not g.threat.can_see_player() and not g.storage_hide.opened)
	g.player.camera.look_at(Vector3(6.35,1,-4.1))
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.set_meta("unlisted_qa_input",true);Input.parse_input_event(click)
	await wait(.2);click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=false;click.set_meta("unlisted_qa_input",true);Input.parse_input_event(click)
	until=seconds()+6
	while seconds()<until and not g.storage_hide.opened and not g.menu_open:await wait(.1)
	check("real impact gives away closed hiding place",g.storage_hide.opened and g.storage_hide.suspected and g.physical.held==null)
	await shot("H05_noise_breach");Input.action_release("crouch")
	g.threat.reset();g.presence.visible=false

func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	output=OS.get_executable_path().get_base_dir().path_join("QA/storage")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();g.new_game();g.stage=3;g.shed_read=true;g.isolated=true;g.threat.enabled=true;g.threat.reset()
	g.events.chair=true;g.events["return"]=true;g.events.yard=true;g.events.office=true;g.events.threat_resolved=true
	g.events.field_return_read=true;g.events.carbon_read=true;g.events.inspection_search_pending=true
	g.presentation.clear_transients();g.player.position=Vector3(5.7,.04,-7.2);g.player.velocity=Vector3.ZERO
	g.doors.office.set_open(true,0);g.doors.front.set_open(true,0)
	for light in g.lamps:light.light_energy=.6
	g.investigation.restore()
	await survive_search()
	if "--storage-risk-qa" in OS.get_cmdline_user_args():await risk_tests()
	var failed:=0
	for entry in checks:
		if not entry.passed:failed+=1
	var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Seeded post-inspection setup. Real movement, fitted doors, authored AI search, sight blocking and recovery. Full route separately earns this event."},"\t"));file.close()
	print("STORAGE_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed");await g.qa_exit(0 if failed==0 else 1)
