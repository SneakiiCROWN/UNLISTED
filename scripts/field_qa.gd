extends "res://scripts/recording_repair_qa.gd"
# Explicitly staged native fixtures; joypad events travel through the real private viewport.
func pad(button: int,pressed:=true) -> void:
	var e:=InputEventJoypadButton.new();e.button_index=button;e.pressed=pressed;e.set_meta("unlisted_qa_input",true);Input.parse_input_event(e);await wait(.10)
func tap(button: int) -> void:
	await pad(button);await pad(button,false)
func axis(id: int,value: float) -> void:
	var e:=InputEventJoypadMotion.new();e.axis=id;e.axis_value=value;e.set_meta("unlisted_qa_input",true);Input.parse_input_event(e);await wait(.06)
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	if "--tape-only" in OS.get_cmdline_user_args():await tape_run();return
	if "--field-layouts-only" in OS.get_cmdline_user_args():await field_layouts();return
	g.new_game();g.presentation.clear_transients();g.threat.enabled=false;g.threat.reset()
	g.stage=2;g.events.chair=true;g.events.yard=true;g.events["return"]=true;g.player.position=Vector3(0,.04,9);await wait(.4)
	var origin: Vector3=g.player.position
	await axis(JOY_AXIS_LEFT_Y,-1);await wait(.5);await axis(JOY_AXIS_LEFT_Y,0)
	check("raw pad left stick drives real player physics",g.player.position.distance_to(origin)>.8)
	var yaw: float=g.player.rotation.y
	await axis(JOY_AXIS_RIGHT_X,.8);await wait(.3);await axis(JOY_AXIS_RIGHT_X,0)
	check("raw pad right stick changes world facing",absf(g.player.rotation.y-yaw)>.25)
	yaw=g.player.rotation.y;await axis(JOY_AXIS_RIGHT_X,.1);await wait(.2);await axis(JOY_AXIS_RIGHT_X,0)
	check("configured deadzone rejects stick drift",is_equal_approx(yaw,g.player.rotation.y))
	var pitch: float=g.player.camera.rotation.x
	g.player.invert_y=true;await axis(JOY_AXIS_RIGHT_Y,.8);await wait(.2);await axis(JOY_AXIS_RIGHT_Y,0)
	check("invert Y applies to pad look",g.player.camera.rotation.x>pitch+.1);g.player.invert_y=false
	await pad(JOY_BUTTON_LEFT_SHOULDER);await wait(.2)
	check("raw LB crouches real collision capsule",g.player.crouched and g.player.body_shape.shape.height<1.1)
	await pad(JOY_BUTTON_LEFT_SHOULDER,false);await wait(.25)
	check("LB release stands when clear",not g.player.crouched)
	await tap(JOY_BUTTON_START);var pos: Vector3=g.player.position
	await axis(JOY_AXIS_LEFT_Y,-1);await wait(.2);await axis(JOY_AXIS_LEFT_Y,0)
	check("Start pauses physics and releases controls",g.menu_open and pos.distance_to(g.player.position)<.001)
	check("pause navigation legend follows real pad input",g.presentation.menu_navigation.text.contains("A SELECT"))
	var focus: Control=g.get_viewport().gui_get_focus_owner()
	await tap(JOY_BUTTON_DPAD_DOWN)
	check("pad D-pad navigates actual pause focus",g.get_viewport().gui_get_focus_owner()!=focus)
	await tap(JOY_BUTTON_DPAD_UP);await tap(JOY_BUTTON_A);await wait(.3)
	check("A activates Resume through actual GUI",not g.menu_open and g.player.active)
	if g.menu_open:g.presentation.resume_game();await wait(.3)
	g.equipment.data.mode=1;g.equipment.data.charge=100.0;g.equipment.data.contact_wait=500.0;g.equipment.apply_light()
	var charge: float=g.equipment.data.charge;await wait(1)
	check("normal native gameplay really drains the battery",charge-float(g.equipment.data.charge)>.20 and charge-float(g.equipment.data.charge)<.40)
	g.equipment.data.charge=100.0;g.equipment.step_power(60)
	check("normal light has roughly six minutes per pack",absf(float(g.equipment.data.charge)-83.2)<.03)
	g.equipment.data.uv=true;g.equipment.data.mode=2;g.equipment.data.charge=100.0;g.equipment.step_power(60)
	check("UV has roughly four minutes per pack",absf(float(g.equipment.data.charge)-74.8)<.03)
	g.equipment.data.mode=0;charge=g.equipment.data.charge;await wait(.2)
	check("switched-off torch does not drain",is_equal_approx(charge,g.equipment.data.charge))
	g.equipment.data.mode=1;g.equipment.data.charge=19.0;g.equipment.data.spares=1;g.equipment.notified_low=false;await wait(.2)
	check("low charge warning uses current pad control",g.presentation.toast.text.contains("Y fits"))
	await shot("F01_low_pack_warning");await tap(JOY_BUTTON_Y)
	check("Y fits one spare pack",g.equipment.data.charge>99 and int(g.equipment.data.spares)==0)
	g.equipment.data.charge=0;g.equipment.data.mode=2;g.equipment.apply_light();await pad(JOY_BUTTON_Y);await wait(3.4);await pad(JOY_BUTTON_Y,false)
	check("pad hold winds real emergency backup",g.equipment.data.charge>24 and g.equipment.is_uv())
	g.equipment.data.mode=1;g.equipment.data.charge=70.0;g.equipment.data.contact_wait=.01;g.presentation.prefs.data.torch_contacts=true
	await wait(.7)
	check("eligible native timer produces one loose contact",g.equipment.data.contact_fault and g.player.torch.light_energy<.01)
	await shot("F02_loose_contact");charge=g.equipment.data.charge;await tap(JOY_BUTTON_DPAD_DOWN)
	check("D-pad Down restores contact without consuming a pack",not g.equipment.data.contact_fault and g.player.torch.light_energy>1 and absf(charge-g.equipment.data.charge)<.15)
	await shot("F03_tapped_light_restored")
	g.equipment.data.contact_wait=.01;await wait(.1);g.save_game();g.load_game();await wait(.2)
	check("contact condition survives save/load",g.equipment.data.contact_fault)
	await action("torch_tap")
	check("keyboard action also restores contact",not g.equipment.data.contact_fault)
	g.equipment.data.contact_count=0;g.equipment.data.contact_wait=.01;g.presentation.prefs.data.torch_contacts=false;await wait(.2)
	check("optional setting disables random contact trouble",not g.equipment.data.contact_fault)
	g.presentation.prefs.data.torch_contacts=true;g.equipment.data.mode=2;await wait(.2)
	check("UV evidence work never triggers a contact fault",not g.equipment.data.contact_fault)
	await tap(JOY_BUTTON_START);charge=g.equipment.data.charge;await wait(.3)
	check("pause suspends battery and contact clock",is_equal_approx(charge,g.equipment.data.charge))
	await tap(JOY_BUTTON_START)
	# A danger warning restores an already loose contact, never creating an unfair grab.
	g.equipment.data.contact_count=0;g.equipment.data.contact_fault=true;g.equipment.fault_fade=0;g.equipment.apply_light()
	g.threat.enabled=true;g.threat.begin(false,Vector3(0,0,2));await wait(.2)
	check("actual threat warning restores failed contact",g.threat.active() and not g.equipment.data.contact_fault and g.player.torch.light_energy>0)
	check("active danger cannot start another contact fault",not g.equipment.start_contact_fault())
	g.threat.enabled=false;g.threat.reset();g.equipment.data.mode=1;g.equipment.data.contact_count=2
	check("contact faults are capped at two per case",not g.equipment.start_contact_fault())
	g.equipment.data.contact_wait=500.0
	# Physical prop controls: actual ray pickup, supported rotation and real throw velocity.
	g.player.position=Vector3(-3.2,.04,-8.1);await wait(.3)
	var tin: RigidBody3D=g.physical.props.tin;g.player.camera.look_at(tin.global_position);await wait(.15);await tap(JOY_BUTTON_X)
	check("X picks up existing physical tool tin",g.physical.held==tin)
	var basis_: Basis=tin.global_basis
	await axis(JOY_AXIS_TRIGGER_LEFT,1);await axis(JOY_AXIS_RIGHT_X,.9);await wait(.3);await axis(JOY_AXIS_RIGHT_X,0);await axis(JOY_AXIS_TRIGGER_LEFT,0)
	check("LT and right stick rotate held prop",not tin.global_basis.is_equal_approx(basis_))
	await axis(JOY_AXIS_TRIGGER_RIGHT,1);await axis(JOY_AXIS_TRIGGER_RIGHT,0)
	check("RT throws real rigid body",g.physical.held==null and tin.linear_velocity.length()>1)
	# Reuse the wall terminal: short physical explanation, no unearned historical revelation.
	g.player.position=Vector3(5,-2.99,-9.6);g.player.restore_stance(false);g.report_read=false;await wait(.3)
	await use("exit_terminal",false)
	check("existing wall terminal now explains actual contact and supply",g.presentation.section=="document" and g.presentation.note.text.contains("no supply") and not g.presentation.note.text.contains("EMPTY"))
	await shot("F04_unpowered_recorder");await tap(JOY_BUTTON_B)
	g.stage=3;await use("exit_terminal",false)
	check("powered terminal explains disconnected exit observation",g.presentation.note.text.contains("feed is live") and g.presentation.note.text.contains("wire loose"))
	await shot("F05_powered_recorder");await tap(JOY_BUTTON_B)
	g.presentation.show_settings();g.presentation.fill_settings("Input");await wait(.2)
	g.presentation.controls.pad_sensitivity.value=2.2;g.presentation.controls.pad_deadzone.value=.23
	var pref=load("res://scripts/preferences.gd").new();pref.path=g.presentation.prefs.path;pref.load_file()
	check("controller settings persist through actual controls",is_equal_approx(pref.data.pad_sensitivity,2.2) and is_equal_approx(pref.data.pad_deadzone,.23))
	await shot("F06_controller_settings")
	var back: Button=g.presentation.buttons.Back
	check("settings Back remains inside native viewport",back.get_global_rect().end.y<=g.get_viewport().get_visible_rect().size.y and back.get_global_rect().position.y>=0)
	g.presentation.settings_back();g.presentation.resume_game();await wait(.2)
	g.controller.clear()
	check("released/disconnected controller has no latched movement",g.controller.move==Vector2.ZERO and g.controller.look==Vector2.ZERO and not Input.is_action_pressed("crouch"))
	var failed:=0
	for c in checks:
		if not c.passed:failed+=1
	var f:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"scope":"Staged native field input, battery, contact and recorder fixtures; no human hardware approval","passed":checks.size()-failed,"failed":failed,"checks":checks},"\t"));f.close()
	print("FIELD_QA_COMPLETE passed=",checks.size()-failed," failed=",failed)
	g.qa_exit(0 if failed==0 else 1)

func tape_run() -> void:
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	g.new_game();g.stage=3;g.events.chair=true;g.events["return"]=true;g.events.yard=true;g.threat.enabled=false;g.threat.reset();g.presentation.clear_transients()
	g.doors.basement.locked=false;g.doors.basement.set_open(true,0)
	g.player.position=Vector3(4.52,-2.999,-8.25);g.player.restore_stance(false);await wait(.3)
	await use("test_reel");check("real shelf interaction collects historical reel",g.events.get("test_reel_found",false) and not g.field_tape.reel.visible and not g.events.get("test_reel_heard",false))
	await shot("T01_reel_taken");g.save_game();g.load_game();await wait(.2)
	check("carried reel survives save without replay credit",g.events.get("test_reel_found",false) and not g.events.get("test_reel_loaded",false) and not g.events.get("test_reel_heard",false))
	await travel(Vector2(3.25,-9.3),"recording clears records aisle")
	await travel(Vector2(3.25,-12.8),"carry tape through original low passage",false,true)
	await travel(Vector2(3.25,-16.1),"recording returns to cellar",false,true)
	await travel(Vector2(0,-18),"recording joins original ramp")
	await travel(Vector2(0,-7),"bring reel upstairs by actual ramp")
	g.doors.office.locked=false;g.doors.office.set_open(true,0)
	await travel(Vector2(3.3,-7.3),"office deck approach")
	if not await use("test_reel_deck",false):recording=false;g.qa_exit(1);return
	await shot("T02_reel_load_panel")
	check("deck distinguishes historical recording from tonight",g.presentation.section=="document" and g.presentation.buttons.has("Load reel and listen") and not g.events.get("test_reel_heard",false))
	g.presentation.buttons["Load reel and listen"].grab_focus();await tap(JOY_BUTTON_A);await wait(1.5)
	check("actual pad A loads reel and starts spatial audio",g.field_tape.playing and g.events.get("test_reel_loaded",false) and is_instance_valid(g.field_tape.motor) and g.field_tape.motor.playing and g.horror.audition=="FIELD")
	await tap(JOY_BUTTON_START);var clock_: float=g.field_tape.clock;await wait(.5)
	check("pause suspends tape chronology",g.menu_open and is_equal_approx(clock_,g.field_tape.clock))
	await tap(JOY_BUTTON_START);g.save_game();g.load_game();await wait(.2)
	check("interrupted tape load preserves reel but does not award unheard evidence",g.events.get("test_reel_loaded",false) and not g.events.get("test_reel_heard",false) and not g.field_tape.playing)
	await use("test_reel_deck",false);g.presentation.buttons["Replay service test"].grab_focus();await tap(JOY_BUTTON_A)
	await wait(6)
	check("recording motor audibly stops before late knocks",g.field_tape.playing and is_instance_valid(g.field_tape.motor) and not g.field_tape.motor.playing and not g.events.get("test_reel_heard",false))
	await shot("T03_silent_motor");await wait(8.5)
	check("full playback earns historical observation only",g.events.get("test_reel_heard",false) and g.events.notes.has(g.field_tape.NOTE_TITLE) and not g.events.get("memory_confirmed",false))
	await use("test_reel_deck",false);await shot("T04_reel_observation");await tap(JOY_BUTTON_B)
	g.save_game();g.load_game();await wait(.2)
	check("listened reel and natural observation persist",g.events.get("test_reel_heard",false) and g.events.notes[g.field_tape.NOTE_TITLE].contains("no working line"))
	# No hidden underfloor prerequisite: the physical office box answers after supply.
	g.events.erase("underfloor_read");g.events.erase("underfloor_taps");g.events.erase("line_calibrated");g.events.line_feed_off=false;g.events.line_return_out=false;g.events.underfloor_pattern=[0.0];g.dead_line.restore()
	await travel(Vector2(4.8,-4.6),"investigate wall test after historical recording")
	await use("line_note",false);await shot("T05_machine_context");await tap(JOY_BUTTON_B)
	await use("line_strike");check("powered connected machine responds without hidden note gate",g.events.get("line_calibrated",false))
	check("partly tried joist still produces documented three-tap reference",g.dead_line.sources.size()+g.dead_line.sequence.size()==3)
	await use("line_feed");await use("line_return");await use("line_strike")
	check("both disconnected controls arm observable experiment",g.dead_line.isolated() and g.events.get("line_test_armed",false))
	recording=false;recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"))
	var failed:=0
	for c in checks:
		if not c.passed:failed+=1
	var f:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"scope":"Native staged reel pickup, physical return, pad loading, positional playback, pause/save recovery and actual machine controls; no subjective listening claim","passed":checks.size()-failed,"failed":failed,"checks":checks},"\t"));f.close()
	print("TAPE_QA_COMPLETE passed=",checks.size()-failed," failed=",failed)
	g.qa_exit(0 if failed==0 else 1)

func check_card(label_: String) -> void:
	await wait(.2)
	var rect: Rect2=g.presentation.card.get_global_rect();var view: Rect2=g.get_viewport().get_visible_rect()
	check(label_+" fits native viewport",view.encloses(rect),str(rect)+" in "+str(view))
	for child in g.presentation.card_body.get_children():
		if child is Label and child.text.length()>100:check(label_+" text wraps inside card",child.autowrap_mode!=TextServer.AUTOWRAP_OFF and child.get_global_rect().end.x<=rect.end.x)
func field_layouts() -> void:
	g.new_game();await wait(2.2);g.presentation.clear_transients();g.stage=3;g.threat.enabled=false;g.threat.reset();g.events.chair=true;g.events["return"]=true;g.controller.used=true
	g.events.test_reel_found=true;g.events.test_reel_loaded=true;g.events.test_reel_heard=true;g.field_tape.restore()
	g.field_tape.use("test_reel_deck");await check_card("historical observation");await shot("FL01_reel_observation")
	g.presentation.resume_game();await wait(.1);g.presentation.show_exclusion();await check_card("tonight comparison");await shot("FL02_tonight_comparison")
	g.presentation.show_settings();g.presentation.fill_settings("Input");await wait(.2)
	var back: Button=g.presentation.buttons.Back
	check("Input settings Back is visible",g.get_viewport().get_visible_rect().encloses(back.get_global_rect()))
	await shot("FL03_pad_settings")
	g.presentation.fill_settings("Gameplay");await wait(.2)
	check("contact setting exists and is real",g.presentation.controls.has("torch_contacts"));g.presentation.controls.torch_contacts.button_pressed=false
	var cfg=load("res://scripts/preferences.gd").new();cfg.path=g.presentation.prefs.path;cfg.load_file()
	check("contact setting persists",not cfg.data.torch_contacts);await shot("FL04_contact_setting")
	g.presentation.settings_back();g.presentation.resume_game();await wait(.2)
	g.events.test_reel_heard=true;g.events.erase("underfloor_read");g.events.line_test_armed=true;g.player.position=Vector3(4.8,.04,-4.6)
	check("optional guidance follows test arming without underfloor prerequisite",g.NOTES.clue(g).contains("Both leads"))
	var failed:=0
	for c in checks:
		if not c.passed:failed+=1
	var f:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"scope":"Explicit native UI and hint fixtures; not a gameplay route","passed":checks.size()-failed,"failed":failed,"checks":checks},"\t"));f.close()
	print("FIELD_LAYOUT_COMPLETE passed=",checks.size()-failed," failed=",failed);g.qa_exit(0 if failed==0 else 1)
