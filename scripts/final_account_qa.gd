extends "res://scripts/recording_repair_qa.gd"
var earned: Dictionary={}
var original: Dictionary={}
var exposed_packet_frames:=0
func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(g) and is_instance_valid(g.final_account) and not g.menu_open and g.final_account.phase()=="boarding" and g.final_account.packet.visible and g.presentation.fade.color.a<.99:exposed_packet_frames+=1
func tap(button: int) -> void:
	for down in [true,false]:
		var event:=InputEventJoypadButton.new();event.button_index=button;event.pressed=down;event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event);await wait(.07)
func physical_use(id: String,pad: bool) -> void:
	g.player.camera.look_at(g.targets[id].global_position);await wait(.18)
	var hit: Dictionary=g.player.target();check("physical input target "+id,not hit.is_empty() and hit.collider==g.targets[id])
	if pad:await tap(JOY_BUTTON_X)
	else:await action("interact")
	await wait(.8)
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	var source:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
		if arg.begins_with("--final-earned-source="):source=arg.trim_prefix("--final-earned-source=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	original=JSON.parse_string(FileAccess.get_file_as_string(source));earned=original.duplicate(true)
	# Derived pre-decision placement from the earlier genuinely completed route.
	# Remove only its outcome, not its earned discoveries, puzzles or eligibility.
	earned.ended=false;earned.pos=[4.95,.03,-7.5];earned.events.erase("ending");earned.events.erase("final_account");earned.events.departure_pending=""
	g.new_game()
	if not is_instance_valid(g.final_account):check("final account module loads",false);await finish_run();return
	g.apply_save(earned);await wait(.4)
	check("branch source has genuinely earned final evidence",g.report_read and g.isolated and g.events.get("field_return_read",false) and g.events.get("bedroom_left",false) and g.events.get("call_complete",false) and g.events.get("memory_confirmed",false) and g.events.get("recount_complete",false),"Derived placement/outcome reset only: "+source)
	if not "--final-layouts" in OS.get_cmdline_user_args():
		g.events.memory_confirmed=false;check("comparison ending cannot be selected without evidence",not g.finish_attendance("on_record"));g.events.memory_confirmed=true
		g.events.call_complete=false;check("unfinished final investigation cannot be closed",not g.finish_attendance("accounted_for"));g.events.call_complete=true
		g.events.recount_complete=false;check("unwitnessed recount cannot be bypassed",not g.finish_attendance("accounted_for"));g.events.recount_complete=true
		g.equipment.data.uv=false;g.final_account.sync();g.final_account.use("account_compare");check("stock comparison is unavailable before the head is collected",g.targets.account_compare.collision_layer==0 and not g.events.get("equipment_date_compared",false));g.equipment.data.uv=true
		var known: String=g.events.notes.get("INSPECTION KIT","");g.events.notes.erase("INSPECTION KIT");g.final_account.sync();g.final_account.use("account_compare")
		check("legacy UV entitlement cannot invent a discovered label",not g.events.get("equipment_date_compared",false) and g.targets.account_compare.collision_layer==0);g.events.notes["INSPECTION KIT"]=known
	g.player.camera.look_at(g.targets.account_compare.global_position);await wait(.2);await shot("F01_existing_office_context")
	await use("account_compare",false);check("physical comparison keeps stock date unverified",g.events.get("equipment_date_compared",false) and g.final_account.tag_card.visible and g.recount.archive.text.contains("DATE OF USE UNKNOWN"))
	g.save_game(true);g.load_game();await wait(.3);check("label comparison survives load without new visitor evidence",g.events.get("equipment_date_compared",false) and g.final_account.tag_card.visible and g.events.get("call_complete",false));await shot("F02_separate_dated_sources")
	var compared: Dictionary=g.save_data().duplicate(true)
	if "--final-layouts" in OS.get_cmdline_user_args():
		await branch("on_record" if "--final-on-record" in OS.get_cmdline_user_args() else "accounted_for","--final-story" in OS.get_cmdline_user_args())
	else:
		await branch("accounted_for",false)
		g.apply_save(compared);await wait(.3);await branch("on_record",true)
		g.apply_save(original);await wait(.3);check("legacy completed save keeps achieved ending",g.ended and g.presentation.section=="ending" and g.events.get("ending","")==original.events.get("ending",""))
		var legacy: Dictionary=earned.duplicate(true);legacy.pos=[0,.03,21.1];legacy.events.departure_pending="accounted_for";legacy.events.erase("final_account")
		g.apply_save(legacy);await wait(.3);check("already pending legacy departure keeps its lane exit",g.ended and g.events.get("ending","")=="accounted_for")
	check("papers never appear in the car before the black cut",exposed_packet_frames==0)
	await finish_run()
func branch(outcome: String,story: bool) -> void:
	g.presentation.prefs.data.story_mode=story;g.presentation.prefs.data.reduced_motion=story
	phase="Earned branch / "+outcome+" / story="+str(story)
	await travel(Vector2(3,-7),"leave archive desk");await travel(Vector2(0,-7),"enter original hall");await travel(Vector2(0,2.5),"return along original hall")
	if not g.doors.front.opened:await use("front")
	await travel(Vector2(-.7,5.5),"reach original porch register");await use("order",false)
	check("earned choices use existing register",g.presentation.section=="register" and g.presentation.buttons.has("Simon Ward / PRESENT") and g.presentation.buttons.has("Attach original / keep Simon's case open"))
	await shot("F03_choices_"+outcome)
	var choice: Button=g.presentation.buttons["Simon Ward / PRESENT" if outcome=="accounted_for" else "Attach original / keep Simon's case open"]
	if story:choice.grab_focus();await tap(JOY_BUTTON_A)
	else:choice.pressed.emit()
	await wait(.3)
	check("choice produces actual receipt and preserves control",g.final_account.phase()=="receipt" and g.final_account.receipt.visible and g.player.active and not g.ended)
	check("receipt records the selected meaning",g.final_account.receipt_ink.text.contains("WITNESS") if outcome=="on_record" else g.final_account.receipt_ink.text.contains("CALL CLOSED"))
	g.save_game(true);g.load_game();await wait(.25);check("uncollected receipt is recovered",g.final_account.phase()=="receipt" and g.targets.account_receipt.collision_layer==1)
	g.player.camera.look_at(g.targets.account_receipt.global_position);await wait(.15);await shot("F04_physical_receipt_"+outcome)
	await physical_use("account_receipt",story);check("taking receipt is a physical once-only action",g.final_account.phase()=="ready" and not g.final_account.receipt.visible and g.targets.account_receipt.collision_layer==0)
	check("choice cannot be silently changed after taking receipt",not g.finish_attendance("accounted_for" if outcome=="on_record" else "on_record") and g.events.departure_pending==outcome)
	g.save_game(true);g.load_game();await wait(.25);check("retained receipt survives save",g.final_account.phase()=="ready" and g.player.active)
	await travel(Vector2(0,8),"leave porch with receipt");await travel(Vector2(0,15.1),"walk to existing front gate")
	if not g.doors.front_gate.opened:await use("front_gate")
	await travel(Vector2(0,19.5),"physically leave property")
	check("crossing gate no longer cuts straight to menu",not g.ended and g.player.active and g.final_account.phase()=="ready")
	check("house response is spent once beyond gate",g.final_account.state().get("gate_echo",false))
	g.player.camera.look_at(Vector3(0,1.5,4));await shot("F05_house_behind_"+outcome)
	g.save_game(true);g.load_game();await wait(.2);check("gate response does not repeat after load",g.final_account.state().get("gate_echo",false) and g.final_account.sources.is_empty())
	await travel(Vector2(-5.5,19.4),"return to Eli's actual car")
	g.player.camera.look_at(g.targets.account_car.global_position);await wait(.15)
	var hit: Dictionary=g.player.target();check("driver handle is reachable outside fitted car collision",not hit.is_empty() and hit.collider==g.targets.account_car,str(hit));await shot("F06_driver_door_"+outcome)
	if story:await tap(JOY_BUTTON_X)
	else:await action("interact")
	check("boarding starts only through car interaction",g.final_account.phase()=="boarding" and not g.ended)
	if story:await tap(JOY_BUTTON_START)
	else:await action("pause")
	var elapsed: float=g.final_account.elapsed;await wait(.35);check("pause safely freezes boarding",get_tree().paused and is_equal_approx(elapsed,g.final_account.elapsed))
	g.save_game(true);g.load_game();await wait(.2);check("interrupted boarding restores control and retained receipt",g.final_account.phase()=="ready" and g.player.active and not g.menu_open and g.presentation.fade.color.a==0)
	await physical_use("account_car",story);await wait(1.0)
	check("stowing papers completes intended ending",g.ended and g.presentation.section=="ending" and g.events.get("ending","")==outcome and g.player.position.z>18.5)
	await shot("F07_ending_"+outcome)
	g.save_game(true);g.presentation.buttons["Main Menu"].pressed.emit();await wait(.2);check("completed save offers its ending",g.presentation.buttons.has("View Ending"))
	if g.presentation.buttons.has("View Ending"):g.presentation.buttons["View Ending"].pressed.emit();await wait(.2)
	check("completed save preserves choice without replaying departure",g.ended and g.events.get("ending","")==outcome and g.final_account.phase()=="departed")
