extends "res://scripts/field_qa.gd"
# Staged native interaction/visual fixtures, not an earned story route.
func widget(suffix: String) -> Control:
	for node in g.presentation.card_body.get_children():
		if node.get_script() and str(node.get_script().resource_path).ends_with(suffix):return node
	return null
func saved() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string(g.checkpoint_path))
func key(code: int) -> void:
	for pressed in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed;event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event);await wait(.10)
func leave(mode: int,button: String) -> void:
	if mode==0:await tap(JOY_BUTTON_B)
	elif mode==1:await key(KEY_ESCAPE)
	elif mode==2:
		await tap(JOY_BUTTON_START);check("Start from inspection opens Pause",g.presentation.section=="pause");await tap(JOY_BUTTON_B)
	else:g.presentation.buttons[button].grab_focus();await tap(JOY_BUTTON_A)
func setup() -> void:
	g.new_game();g.threat.enabled=false;g.threat.reset();g.fuse=true;g.interact("breaker");g.presentation.clear_transients()
	g.equipment.data.contact_wait=500.0;g.ambient_director.enabled=false
	g.player.position=Vector3(4.6,.04,-7.4);await wait(.4)
func execute() -> void:
	await setup()
	if not "--continuation-views-only" in OS.get_cmdline_user_args():
		await inspections();await portable();await feedback();await arrival()
	await views()
	var failed:=0
	for c in checks:
		if not c.passed:failed+=1
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Staged exported native widgets, portable props, arrival and visual fixtures. No human approval or fresh story-route claim."},"\t"));file.close();g.qa_exit(0 if failed==0 else 1)
func inspections() -> void:
	g.events.receiver_frequency=94.0;g.save_game(true)
	for mode in 4:
		g.chapter.open_receiver();await wait(.15);var radio: Control=widget("return_receiver.gd")
		var before: String=FileAccess.get_file_as_string(g.checkpoint_path)
		radio.dial.grab_focus();await key(KEY_RIGHT);var value: float=radio.dial.value
		check("radio dial moves through actual GUI "+str(mode),value>94)
		check("dial movement does not write checkpoint "+str(mode),FileAccess.get_file_as_string(g.checkpoint_path)==before)
		await leave(mode,"Leave radio")
		check("radio exit commits dial "+str(mode),not g.menu_open and is_equal_approx(float(saved().events.receiver_frequency),value))
		g.load_game();await wait(.12);g.chapter.open_receiver();await wait(.12)
		check("radio reopens at committed frequency "+str(mode),is_equal_approx(float(widget("return_receiver.gd").dial.value),value))
		await tap(JOY_BUTTON_B)
	g.events.field_return_read=true;g.equipment.data.uv=true;g.equipment.data.mode=2;g.equipment.apply_light()
	for mode in 4:
		g.events.erase("carbon_read");g.events.carbon_coverage=[0.0,0.0,0.0];g.events.carbon_cells=[];g.events.uv_rows=[false,false,false]
		g.chapter.open_carbon();await wait(.15);var scan_: Control=widget("carbon_rubbing.gd")
		await axis(JOY_AXIS_RIGHT_X,.8);await wait(.12);await axis(JOY_AXIS_RIGHT_X,0)
		var coverage_: Array=scan_.coverage.duplicate();check("raw stick makes partial UV coverage "+str(mode),float(coverage_[1])>0 and not g.events.get("carbon_read",false),str(coverage_))
		await leave(mode,"Put sheet down")
		var stored: Array=saved().events.carbon_coverage
		var same:=stored.size()==coverage_.size()
		for i in mini(stored.size(),coverage_.size()):same=same and is_equal_approx(float(stored[i]),float(coverage_[i]))
		check("partial UV survives exit "+str(mode),same and not saved().events.get("carbon_read",false),str(stored)+" / "+str(coverage_))
	# Ordinary documents must keep Down navigation when a loose contact exists.
	g.equipment.data.contact_fault=true;g.inspect_text("FIXTURE","An ordinary paper.")
	var extra: Button=g.presentation.add_button("Fixture second control",func():pass,true,g.presentation.card_body)
	await wait(.15) # Let the new control participate in the actual GUI focus layout.
	g.presentation.buttons["Close record  /  ESC"].grab_focus();await tap(JOY_BUTTON_DPAD_DOWN)
	check("ordinary document Down is navigation, not torch tap",g.equipment.data.contact_fault and g.get_viewport().gui_get_focus_owner()==extra,"fault="+str(g.equipment.data.contact_fault)+" focus="+str(g.get_viewport().gui_get_focus_owner())+" expected="+str(extra))
	await tap(JOY_BUTTON_B);g.equipment.tap_contact()
	# Use the real transform widget, change it with actual controller input, then exit.
	g.report_read=true;g.events.test_reel_found=true;g.last_call.open_plans();await wait(.2)
	var plan: Control=widget("plan_lightbox.gd");plan.place_sheet();await axis(JOY_AXIS_RIGHT_X,.7);await wait(.12);await axis(JOY_AXIS_RIGHT_X,0)
	var pose: Vector2=plan.offset;await tap(JOY_BUTTON_START);await tap(JOY_BUTTON_B)
	check("partial plan survives Start exit",Vector2(saved().events.call_plan_pose[0],saved().events.call_plan_pose[1]).is_equal_approx(pose) and not g.events.get("call_plan_aligned",false))
	g.load_game();await wait(.15);g.last_call.open_plans();await wait(.15);check("plan reopens with exact partial placement",widget("plan_lightbox.gd").offset.is_equal_approx(pose));await tap(JOY_BUTTON_B)
func portable() -> void:
	await setup();await wait(1)
	for spec in [["counter_vase",Vector3(-4.15,.04,2.3)],["utility_mug",Vector3(-2.1,.04,-8.05)],["shed_parts",Vector3(-17.85,.04,-14.7)],["water_bottle",Vector3(-6.50,.04,-.1)],["parts_tin",Vector3(-3.45,-2.99,-17.88)],["wash_pan",Vector3(-5.9,.04,-8.2)]]:
		var body: RigidBody3D=g.physical.props[spec[0]];g.player.position=spec[1];await wait(.2);g.player.camera.look_at(body.global_position);await tap(JOY_BUTTON_X)
		check("actual ray/pad pickup "+spec[0],g.physical.held==body)
		if g.physical.held==body:await tap(JOY_BUTTON_X)
		await wait(1.2) # A dropped object must finish falling before checking a stationary saved pose.
		g.save_game(true);var position_: Array=saved().events.props[spec[0]];g.load_game();await wait(.1)
		check("portable saved position "+spec[0],body.position.distance_to(Vector3(position_[0],position_[1],position_[2]))<.05)
	# Real supported-mass mechanism, using new ordinary household props.
	g.isolated=true;g.events.erase("field_return_read");g.investigation.restore();g.player.position=Vector3(0,-2.99,-18)
	for spec in [["counter_vase",1.40],["utility_mug",1.80]]:
		var body: RigidBody3D=g.physical.props[spec[0]];var shape=body.get_node("PropShape").shape
		var height: float=shape.height if shape is CylinderShape3D else shape.size.y
		body.call("relocate",Transform3D(Basis.IDENTITY,Vector3(spec[1],-2.995+height*.5+.004,-20)))
	await wait(1.2);check("new vase and mug transmit real weight to drawer",g.investigation.supported_weight()>=.8 and g.investigation.open,str(g.investigation.supported_weight()))
func feedback() -> void:
	g.presentation.notify("Older notification");await wait(2.3);g.presentation.notify("Newer notification");await wait(.55)
	check("new notification survives old fade deadline",g.presentation.toast.text=="Newer notification" and g.presentation.toast.modulate.a>.95);await wait(2.6)
	check("new notification eventually fades",g.presentation.toast.modulate.a<.05)
	g.player.stamina=.20;g.player.exhausted=true;g.player.stamina_delay=.65;g.save_game(true);g.load_game();await wait(.10)
	check("fatigue recovery delay and exhausted latch restore",g.player.exhausted and g.player.stamina_delay>.3 and g.player.stamina_delay<.7)
func arrival() -> void:
	g.started=false;g.presentation.show_menu(true);await wait(.2)
	var bytes_: String=FileAccess.get_file_as_string(g.checkpoint_path)
	var original: bool=g.dev_mode;g.dev_mode=false
	var denied=load("res://scenes/arrival_study.tscn").instantiate();denied.game=g;g.add_child(denied);await wait(.1)
	check("ordinary export rejects arrival study",not is_instance_valid(denied) and g.presentation.section=="title")
	g.dev_mode=true
	for mode in 5:
		var camera: Camera3D=g.get_viewport().get_camera_3d();var reduced: bool=g.presentation.prefs.data.reduced_motion
		g.presentation.prefs.data.reduced_motion=mode==4
		var preview=load("res://scenes/arrival_study.tscn").instantiate();preview.game=g;g.add_child(preview);await wait(.25)
		check("study owns camera and actual engine cue "+str(mode),g.presentation.section=="arrival_study" and g.get_viewport().get_camera_3d()==preview.get_node("PreviewCamera") and preview.streams[0].playing)
		if mode==4:
			await wait(1);await shot("A01_car_study");await wait(3.2);await shot("A02_gate_study");await wait(4.2)
		elif mode==3:await key(KEY_ESCAPE)
		else:await tap([JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_START][mode])
		await wait(.15)
		check("study restores title/camera and preserves save "+str(mode),not is_instance_valid(preview) and g.presentation.section=="title" and g.get_viewport().get_camera_3d()==camera and not g.started and FileAccess.get_file_as_string(g.checkpoint_path)==bytes_)
		g.presentation.prefs.data.reduced_motion=reduced
	g.dev_mode=original
func views() -> void:
	await setup()
	g.subtitle.text="";g.caption_until=0
	var selected: Array=[["V01_kitchen",Vector3(-3.5,.04,1.6),Vector3(-5.7,1.05,3.6)],["V02_office",Vector3(3.3,.04,-7.1),Vector3(3.3,.9,-8.6)]]
	if not "--continuation-views-only" in OS.get_cmdline_user_args():selected.append_array([["V03_mic",Vector3(.1,.04,-2.2),Vector3(1.4,1.62,-3.05)],["V04_cot",Vector3(-5.6,.04,-6.8),Vector3(-6.8,.55,-5.25)],["V05_cellar",Vector3(0,-2.99,-20),Vector3(-1.5,-1.2,-23.5)],["V06_shed",Vector3(-17,.04,-14.1),Vector3(-19.5,1.6,-13.5)],["V07_rainwater",Vector3(9,.04,6.3),Vector3(7.66,2.3,4.1)]])
	for spec in selected:
		g.player.position=spec[1];g.player.restore_stance(false);g.player.camera.look_at(spec[2]);await wait(.35);await shot(spec[0])
	check("representative native room captures completed",g.player.active and not g.menu_open)
