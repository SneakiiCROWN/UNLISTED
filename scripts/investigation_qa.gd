extends "res://scripts/recording_repair_qa.gd"
# Labelled late-game fixture; all carrying, release and reading use real input.
func run(current: Node) -> void:
	g=current;output=OS.get_executable_path().get_base_dir().path_join("QA/investigation")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();started_at=Time.get_ticks_usec()
	g.new_game();g.stage=3;g.isolated=true;g.report_read=true;g.shed_read=true;g.brass_key=true
	g.events.threat_resolved=true;g.events["return"]=true;g.events.chair=true
	g.threat.enabled=false;g.threat.reset()
	for id in ["utility","basement","front"]:g.doors[id].locked=false;g.doors[id].set_open(true,0)
	g.player.position=Vector3(-3.1,.04,-7);g.presentation.clear_transients();await wait(.5)
	check("new case starts with sealed original",g.events.case_v2 and not g.investigation.open)
	check("new case cannot close without original",not g.finish_attendance("accounted_for"))
	# Explicit fixture placements test the pressure response independently of carrying.
	g.player.position=g.investigation.pad+Vector3.UP*.04;await wait(.8)
	check("player weight also depresses release",g.investigation.open)
	g.player.position+=Vector3(0,0,1.3);await wait(1)
	check("walking off release shuts drawer",not g.investigation.open)
	var cup: RigidBody3D=g.physical.props.cup
	cup.call("relocate",Transform3D(Basis.IDENTITY,g.investigation.pad+Vector3.UP*.12));await wait(1)
	check("light mug cannot hold spring release",not g.investigation.open)
	cup.call("relocate",g.physical.homes.cup)
	g.player.position=Vector3(-3.1,.04,-7);await wait(.2)
	Input.action_press("crouch");await wait(.4)
	check("crouch lowers actual collision",g.player.crouched and g.player.body_shape.shape.height<1.1)
	# The temporary beam is test-only and proves standing cannot penetrate cover.
	var beam:=Node3D.new();g.add_child(beam)
	g.box(beam,g.player.position+Vector3(0,1.4,0),Vector3(1,.22,1),Color.GRAY,true)
	await wait(.2);Input.action_release("crouch");await wait(.3)
	check("cannot stand through an overhead solid",g.player.crouched and not g.player.can_stand())
	beam.queue_free();await wait(.4)
	var probe:=CapsuleShape3D.new();probe.radius=.25;probe.height=1.68
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=probe;q.transform=Transform3D(g.player.global_basis,g.player.global_position+Vector3.UP*.87);q.exclude=[g.player.get_rid()];q.collision_mask=1|16|32
	var obstruction: Array=g.get_world_3d().direct_space_state.intersect_shape(q)
	check("standing restores when clear",not g.player.crouched and g.player.body_shape.shape.height>1.7,str(obstruction))
	await recover_field_return()
	g.save_game();g.events.field_return_read=false;g.load_game();await wait(.4)
	check("original discovery and drawer survive checkpoint",g.events.get("field_return_read",false) and g.investigation.open)
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		exact_target.size=size_;exact_target.size_2d_override=Vector2i(roundi(720.0*size_.x/size_.y),720)
		g.presentation.show_register();await wait(.4)
		var view: Vector2=g.get_viewport().get_visible_rect().size
		check("new register fits "+str(size_),g.presentation.card_body.get_global_rect().end.y<view.y)
		check("new register text stays inside screen "+str(size_),g.presentation.card_body.get_global_rect().end.x<view.x)
		check("new register has no arbitrary Eli choice "+str(size_),not g.presentation.buttons.has("Eli Ward / PRESENT"))
		await shot("I04_register_"+str(size_.x));g.presentation.resume_game()
	await travel(Vector2(0,-7),"hall cover approach")
	if not g.doors.utility.opened:await use("utility")
	await travel(Vector2(-3.1,-7),"utility cover approach")
	await travel(Vector2(-4.8,-3.5),"maintenance screen north approach")
	await travel(Vector2(-6.1,-3.5),"behind maintenance screen")
	await travel(Vector2(-6.1,-4.0),"crouch inside screened rest corner",false,true)
	Input.action_press("crouch");await wait(.4)
	check("cover is physically nearby",g.player.near_cover())
	g.presence.position=Vector3(-4.6,0,-4.0)
	check("real screen blocks crouched eye and torso rays",not g.threat.clear_line(g.presence.position+Vector3.UP*1.75,g.player.camera.global_position) and not g.threat.clear_line(g.presence.position+Vector3.UP*1.75,g.player.position+Vector3.UP*.55))
	g.player.camera.look_at(Vector3(-5.55,.9,-4.7));await shot("I03_screened_crouch")
	Input.action_release("crouch")
	# Labelled porch fixture follows the independently tested continuous route.
	g.player.position=Vector3(-.7,.04,5.5);g.events.recount_complete=true;g.recount.restore_state()
	g.presentation.show_register();await wait(.2)
	g.presentation.buttons["Simon Ward / PRESENT"].pressed.emit();await wait(.2)
	check("new close-out remains playable",not g.ended and g.player.active and g.events.get("departure_pending","")=="accounted_for")
	g.save_game();g.load_game();await wait(.3)
	check("departure pending survives reload",not g.ended and g.events.get("departure_pending","")=="accounted_for")
	await travel(Vector2(0,8),"porch departure fixture")
	await travel(Vector2(0,15.1),"lane departure fixture")
	if not g.doors.front_gate.opened:await use("front_gate")
	await travel(Vector2(0,19.5),"cross gate departure fixture")
	g.player.rotation.y=PI;g.player.camera.rotation=Vector3.ZERO;Input.action_press("forward")
	var until:=seconds()+5
	while not g.ended and seconds()<until:await get_tree().physics_frame
	Input.action_release("forward")
	check("accounted ending requires leaving property",g.ended and g.events.get("ending","")=="accounted_for")
	await shot("I05_accounted_departure")
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Late-game fixture; real carrying, movement, crouch, obstruction and checkpoint interactions. Not a human playtest."},"\t"));file.close()
	print("INVESTIGATION_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
