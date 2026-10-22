extends Node
# Native wall-clock playback: continuous fresh route, then separately labelled
# recovery scenarios. Input events drive interaction; physics inputs drive travel.
var g: Node
var output := ""
var checks: Array = []
var trace: Array = []
var frames: Array = []
var phase := "startup"
var started_at := 0
var capture_clock := 0.0
var recording := false
var capturing := false
var recorder: AudioEffectRecord
var started_unix_seconds := 0.0
var exact_target: SubViewport
func exact_resolution() -> void:
	# The shared guard owns input delivery; resizing must not add a second bridge.
	g.prepare_automated_qa()
	exact_target=g.get_viewport() as SubViewport
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--capture-size="):continue
		var parts:=arg.trim_prefix("--capture-size=").split("x")
		var size_:=Vector2i(int(parts[0]),int(parts[1]))
		assert(size_.x>=1280 and size_.x<=3840 and size_.y>=720 and size_.y<=2160)
		exact_target.size=size_
		exact_target.size_2d_override=Vector2i(roundi(720.0*float(size_.x)/size_.y),720)
		await wait(0.2)
		check("exact native render dimensions "+str(size_),Vector2i(g.get_viewport().get_texture().get_size())==size_)

func seconds() -> float:return (Time.get_ticks_usec()-started_at)/1000000.0
func check(id: String,okay: bool,detail := "") -> void:
	checks.append({"name":id,"passed":okay,"detail":detail,"seconds":seconds()})
	print("REPAIR_QA ","PASS " if okay else "FAIL ",id," ",detail)
func wait(s: float) -> void:await get_tree().create_timer(s,true).timeout
func _process(delta: float) -> void:
	if not recording:return
	capture_clock += delta
	if capture_clock>=1.0/30.0 and not capturing:
		capture_clock = 0;capture_frame()
func _physics_process(_delta: float) -> void:
	if not recording:return
	trace.append({"seconds":seconds(),"phase":phase,"player":str(g.player.position),"input":str(Input.get_vector("left","right","forward","back")),"surveyor":str(g.presence.position),"state":g.threat.state,"beat":g.horror.beat,"distance":g.player.position.distance_to(g.presence.position),"paused":get_tree().paused})
func capture_frame() -> void:
	capturing = true
	await RenderingServer.frame_post_draw
	var filename := "%05d.jpg"%frames.size()
	g.get_viewport().get_texture().get_image().save_jpg(output.path_join(filename),0.85)
	frames.append({"file":filename,"seconds":seconds(),"phase":phase})
	capturing = false
func shot(id: String) -> void:
	await RenderingServer.frame_post_draw
	g.get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))
func action(id: String) -> void:
	var event := InputEventAction.new();event.action = id;event.pressed = true
	Input.parse_input_event(event);await wait(0.08)
	event = InputEventAction.new();event.action = id;event.pressed = false
	Input.parse_input_event(event);await wait(0.12)
func travel(point: Vector2,label_: String,sprint := false,crouch := false) -> bool:
	phase = label_
	g.player.camera.rotation = Vector3.ZERO
	var start := seconds()
	var limit: float = Vector2(g.player.position.x,g.player.position.z).distance_to(point)/(1.15 if crouch else 2.15)+3
	Input.action_press("forward")
	if sprint:Input.action_press("sprint")
	if crouch:Input.action_press("crouch")
	var remaining := 100.0
	while seconds()-start<limit and not g.menu_open:
		var diff := point-Vector2(g.player.position.x,g.player.position.z)
		remaining = diff.length()
		if remaining<0.13:break
		g.player.rotation.y = atan2(-diff.x,-diff.y)
		await get_tree().physics_frame
	Input.action_release("forward");Input.action_release("sprint");Input.action_release("crouch")
	await wait(0.25)
	check(label_,remaining<0.20,"position="+str(g.player.position)+" remaining="+str(remaining))
	return remaining<0.20
func use(id: String,close := true) -> bool:
	phase = "interact "+id
	g.player.camera.look_at(g.targets[id].global_position)
	await wait(0.18)
	var ray: Dictionary = g.player.target()
	var actual: String = "none" if ray.is_empty() else str(ray.collider.get_meta("interaction","solid"))
	check("input target "+id,actual==id,"hit="+actual)
	if actual!=id:return false
	await action("interact")
	await wait(0.8)
	if close and g.menu_open:await action("ui_cancel")
	return true
func listen(channel: String) -> void:
	await use("audition_source" if channel=="A" else "audition_return")
	for i in 160:
		if g.horror.audition=="":break
		await wait(0.1)
	check("completed audition "+channel,g.events.get("audition_"+channel,false))
func recover_field_return() -> void:
	await travel(Vector2(-3.2,-7.75),"tool tin approach")
	var tin: RigidBody3D=g.physical.props.tin
	g.player.camera.look_at(tin.global_position);await wait(.3);await action("interact")
	check("tool tin picked up through normal input",g.physical.held==tin)
	await wait(.7)
	await travel(Vector2(-3.1,-7),"carried weight clears utility")
	await travel(Vector2(0,-7),"carried weight to hall")
	check("weight remains in hand through doorway",g.physical.held==tin,"tin="+str(tin.position))
	if not g.doors.basement.opened:await use("basement")
	await travel(Vector2(0,-18),"carried weight descends actual ramp")
	await travel(Vector2(1.6,-19.25),"floor release approach")
	Input.action_press("crouch");await wait(.5)
	g.player.camera.look_at(g.investigation.pad+Vector3(.22,.10,0));await wait(1)
	await action("interact");Input.action_release("crouch");await wait(2)
	check("physical weight releases original drawer",g.investigation.open,"tin="+str(tin.position))
	g.player.camera.look_at(g.investigation.pad);await wait(.2);await shot("I00_physical_weight")
	await travel(Vector2(2,-22),"weighted release holds across room")
	await travel(Vector2(3.8,-22.15),"original cabinet approach")
	g.player.camera.look_at(Vector3(3.85,-2.1,-23.65));await wait(.2)
	await shot("I01_weighted_return_drawer")
	await use("field_notebook",false)
	check("original field return discovered",g.events.get("field_return_read",false) and g.presentation.section=="document")
	await shot("I02_original_return");if g.menu_open:await action("ui_cancel")
	await travel(Vector2(2,-22),"evidence exit around generator")
	await travel(Vector2(0,-18),"evidence to ramp")
	await travel(Vector2(0,-7),"evidence reaches hallway")
func run(game: Node) -> void:
	g = game
	await exact_resolution()
	output = ProjectSettings.globalize_path("res://qa/repair_engine") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA/repair_native")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output = arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path = output.path_join("checkpoint.json")
	g.presentation.prefs.data = g.presentation.PREFS.DEFAULTS.duplicate()
	g.presentation.prefs.data.master = 1.0;g.presentation.apply_preferences(false)
	DisplayServer.window_set_size(Vector2i(1280,720))
	started_unix_seconds = Time.get_unix_time_from_system()
	started_at = Time.get_ticks_usec();recording = true
	recorder = AudioEffectRecord.new();recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
	phase = "title";await wait(2);await shot("R00_title")
	phase = "new game opening"
	g.presentation.buttons["New Game"].pressed.emit()
	for i in 260:
		if g.presentation.section=="game":break
		await wait(0.1)
	check("opening enters playable controls",g.player.active and g.presentation.section=="game")
	await wait(1)
	await travel(Vector2(0,18.3),"arrival reaches garden gate")
	await use("front_gate")
	await travel(Vector2(0,15.1),"arrival crosses garden gate")
	await travel(Vector2(-1,5.6),"fresh route porch")
	await use("order")
	await travel(Vector2(0,5.3),"front threshold approach");await use("front");await wait(.7)
	check("first knock leaves front door ajar",g.events.get("front_ajar",false) and not g.doors.front.opened)
	await shot("R00_front_ajar");await use("front")
	await travel(Vector2(0,1),"front threshold crossing");await use("lounge")
	await travel(Vector2(2.7,1),"recorded lounge doorway inward")
	await travel(Vector2(3.0,-0.2),"television approach");await use("television")
	await travel(Vector2(2.7,1),"lounge return turn")
	await travel(Vector2(0,1),"recorded lounge doorway return")
	await travel(Vector2(0,-7),"hall office approach");await use("office")
	await travel(Vector2(3.3,-7),"unpowered office standing position")
	await use("exclude_return")
	check("unpowered comparison does not open",not g.menu_open and g.stage<3)
	await shot("R01_unpowered_office")
	await travel(Vector2(0,-7),"office return");await use("utility")
	await travel(Vector2(-3.5,-7.3),"utility stock approach");await use("fuse")
	check("fresh fuse",g.fuse)
	await travel(Vector2(-3,-7),"utility exit turn");await travel(Vector2(0,-7),"utility to hall")
	await travel(Vector2(0,1),"hall kitchen return");await travel(Vector2(-2.65,2.0),"carrier standing position")
	await use("breaker");check("fresh power",g.stage==3)
	await travel(Vector2(0,1),"kitchen exit");await travel(Vector2(0,-7),"powered office approach")
	await travel(Vector2(3.3,-7),"transport approach")
	g.player.camera.look_at(Vector3(4.2,1.0,-8.6));await wait(0.2)
	await shot("R02_office_separation")
	await travel(Vector2(5.6,-7.3),"archive clear standing position");await use("security")
	check("key acquisition",g.brass_key and not g.doors.service.locked)
	await travel(Vector2(3,-7),"office exit standing");await use("office")
	await travel(Vector2(0,-7),"office to hall");await travel(Vector2(-3.1,-7),"utility circulation")
	await travel(Vector2(-4.5,-8.6),"service threshold approach");await use("service")
	await travel(Vector2(-4.5,-11.9),"recorded service threshold outward")
	await travel(Vector2(-12,-12.5),"yard west")
	g.player.camera.look_at(Vector3(-7,0.5,-13.6));await wait(0.2)
	await shot("R03_finished_yard")
	await travel(Vector2(-12.4,-14),"shed approach");await use("shed")
	await travel(Vector2(-16,-14),"shed threshold inward")
	await travel(Vector2(-18,-15.2),"shed manual standing");await use("shed_record")
	check("fresh stairwell key",g.shed_read and not g.doors.basement.locked)
	await travel(Vector2(-16,-14),"shed exit turn");await travel(Vector2(-12.4,-14),"shed threshold return")
	await travel(Vector2(-12,-12.5),"yard return turn");await travel(Vector2(-4.5,-12.5),"yard east")
	await travel(Vector2(-4.5,-8.6),"recorded service threshold return")
	await travel(Vector2(-3.1,-7),"utility exit from yard");await travel(Vector2(0,-7),"hall cellar approach")
	await travel(Vector2(0,-8.4),"stair door approach");await use("basement")
	await travel(Vector2(0,-18),"physical basement descent")
	if "--underfloor-route" in OS.get_cmdline_user_args():
		var store_test=load("res://scripts/maintenance_qa.gd").new();add_child(store_test)
		store_test.g=g;store_test.output=output;store_test.started_at=started_at;store_test.exact_target=exact_target
		await store_test.play_store();checks.append_array(store_test.checks);store_test.queue_free()
	if "--dead-line-route" in OS.get_cmdline_user_args():
		var line_test=load("res://scripts/dead_line_qa.gd").new();add_child(line_test)
		line_test.g=g;line_test.output=output;line_test.started_at=started_at;line_test.exact_target=exact_target
		await line_test.upstairs_test();checks.append_array(line_test.checks);line_test.queue_free()
		if "--spare-place-route" in OS.get_cmdline_user_args():
			var place_test=load("res://scripts/spare_place_qa.gd").new();add_child(place_test)
			place_test.g=g;place_test.output=output;place_test.started_at=started_at;place_test.exact_target=exact_target
			await place_test.play_place();checks.append_array(place_test.checks);place_test.queue_free()
			await travel(Vector2(-4.5,-8.5),"spare-place return through service door")
			await travel(Vector2(-3.1,-7),"spare-place return to utility aisle")
			await travel(Vector2(0,-7),"spare-place investigation returns to original hall")
		await travel(Vector2(0,-18),"sound investigation rejoins live cellar route")
	await travel(Vector2(-1.5,-22),"coolant approach");await use("valve1")
	await travel(Vector2(-2.7,-22),"supply approach");await use("valve0")
	await travel(Vector2(-0.3,-22),"occupancy approach");await use("valve2")
	await travel(Vector2(2,-22),"isolator approach");await use("isolate")
	check("continuous fresh route reaches isolation",g.isolated and g.valve_order==[1,0,2])
	if "--service-aisle" in OS.get_cmdline_user_args():
		await travel(Vector2(-2.8,-22),"natural route west working aisle",true)
		await travel(Vector2(-3,-18.6),"natural route beyond maintenance bench",true)
	else:
		await travel(Vector2(0,-21),"relay return clearance")
		await travel(Vector2(0,-18),"recorded Surveyor approach")
	phase = "Surveyor detection and warned contact"
	# Face and walk toward the actual actor, then stop; no AI state injection.
	for i in 400:
		if g.menu_open:break
		var diff: Vector3 = g.presence.position-g.player.position
		g.player.rotation.y = atan2(-diff.x,-diff.z)
		g.player.camera.rotation = Vector3.ZERO
		if diff.length()>0.85:Input.action_press("forward")
		else:Input.action_release("forward")
		await get_tree().physics_frame
	Input.action_release("forward")
	for i in 80:
		if g.menu_open:break
		await wait(0.1)
	# Contact now has an authored inspection before the death/retry screen.
	# Continue recording the actual sequence instead of treating its start as death.
	for i in 65:
		if not g.capture_director.active:break
		await wait(0.1)
	await wait(0.8);await shot("R04_contact_consequence")
	check("recorded encounter can kill without state injection",g.threat.state=="dead" and g.presentation.section=="dead")
	if g.presentation.section=="dead":
		g.presentation.buttons["Retry Checkpoint"].pressed.emit();await wait(0.4)
		check("basement retry preserves relay and grants warning",g.isolated and g.threat.state=="warning" and g.threat.grace>2)
		await travel(Vector2(0,-21),"retry clears generator",true)
		await travel(Vector2(0,-18),"retry escape aisle",true)
		await travel(Vector2(0,-9),"retry ramp ascent escape",true)
		await travel(Vector2(0,-7),"escape hallway",true)
		await travel(Vector2(-3.1,-7),"escape utility portal",true)
		await travel(Vector2(-4.5,-8.6),"escape service approach",true)
		await travel(Vector2(-4.5,-12),"escape yard",true)
		await wait(4)
	check("physical escape resolves encounter",g.events.get("threat_resolved",false) and not g.menu_open)
	await shot("R05_escape")
	# Entire allowed perimeter, in both directions. Maintains the original gap.
	for point in [Vector2(-12,-12.5),Vector2(-13.05,-14),Vector2(-13.05,-17.8),Vector2(-21,-17.8),Vector2(-21,-10.3),Vector2(-21,-17.8),Vector2(-13.05,-17.8),Vector2(-13.05,-14),Vector2(-12,-12.5),Vector2(-4.5,-12)]:
		await travel(point,"exterior circuit "+str(point))
	g.player.camera.look_at(Vector3(0,1.4,-12.7));await wait(0.2)
	await shot("R06_annex_and_boundaries")
	await travel(Vector2(-4.5,-8.6),"yard return after escape")
	await travel(Vector2(-3.1,-7),"return utility clear")
	await recover_field_return()
	if not g.doors.office.opened:await use("office")
	await travel(Vector2(3,-7),"office optional investigation approach")
	await travel(Vector2(3.3,-7.3),"transport clear standing")
	await listen("A");await listen("B");await use("exclude_return",false)
	await shot("R07_optional_comparison")
	if g.presentation.buttons.has("Exclude channel A"):
		g.presentation.buttons["Exclude channel A"].pressed.emit();await wait(0.2)
		check("wrong exclusion recoverable",not g.menu_open and not g.events.get("memory_confirmed",false))
		await use("exclude_return",false)
		g.presentation.buttons["Exclude channel B"].pressed.emit();await wait(0.3)
		check("correct exclusion earns receipt",g.events.get("memory_confirmed",false))
		await action("ui_cancel")
		await use("source_copy",false)
		check("physical source copy can be reread",g.presentation.section=="document" and g.events.notes.has(g.NOTES.COMPARISON_TITLE) and g.events.notes[g.NOTES.COMPARISON_TITLE]==g.NOTES.SOURCE_COPY)
		await shot("R07_source_copy");await action("ui_cancel")
	await travel(Vector2(3,-7),"office investigation exit");await travel(Vector2(0,-7),"hall final return")
	if g.events.get("case_v3",false):
		phase="Missing Minute / continuous earned investigation"
		var chapter_test=load("res://scripts/missing_minute_qa.gd").new();add_child(chapter_test)
		chapter_test.g=g;chapter_test.output=output;chapter_test.started_at=started_at
		await chapter_test.play_chapter(true)
		checks.append_array(chapter_test.checks);chapter_test.queue_free()
	await travel(Vector2(0,2.5),"final hall return")
	if not g.doors.front.opened:await use("front")
	await travel(Vector2(-0.7,5.5),"porch register return");await use("order",false)
	check("close-out starts an in-world recount",g.recount.active and not g.menu_open and not g.ended)
	g.player.camera.look_at(Vector3(0,1.5,-3));await wait(3.0)
	await shot("R08_last_departure_hall")
	await wait(6.3)
	check("recount leaves player control and completes",g.events.get("recount_complete",false) and g.player.active and not g.menu_open)
	await use("order",false)
	var earned_path:=output.path_join("earned_register_checkpoint.json")
	g.save_game();DirAccess.copy_absolute(g.checkpoint_path,earned_path)
	if g.presentation.section=="register":
		var final_choice:="Attach original / keep Simon's case open" if "--on-record-ending" in OS.get_cmdline_user_args() else "Simon Ward / PRESENT"
		check("earned final choice available",g.presentation.buttons.has(final_choice))
		if g.presentation.buttons.has(final_choice):g.presentation.buttons[final_choice].pressed.emit()
		await wait(1)
	check("signing the register preserves control for departure",not g.ended and g.player.active and str(g.events.get("departure_pending",""))!="")
	g.save_game();g.load_game();await wait(.3)
	check("signed departure survives save recovery",not g.ended and g.player.active and str(g.events.get("departure_pending",""))!="")
	await action("ui_cancel");var departure_time: float=g.investigation.departure_clock
	await wait(.5)
	check("pause suspends departure cues",g.menu_open and is_equal_approx(departure_time,g.investigation.departure_clock))
	await action("ui_cancel")
	await travel(Vector2(0,8),"leave porch with evidence")
	await travel(Vector2(0,15.1),"approach property gate")
	if not g.doors.front_gate.opened:await use("front_gate")
	await travel(Vector2(0,19.5),"cross property gate")
	g.player.rotation.y=PI;g.player.camera.rotation=Vector3.ZERO
	Input.action_press("forward")
	var leave_until:=seconds()+5
	while not g.ended and seconds()<leave_until:await get_tree().physics_frame
	Input.action_release("forward")
	check("walking into lane completes departure",g.ended and g.player.position.z>21)
	check("fresh route ending",g.ended and g.presentation.section=="ending")
	check("fresh route preserves selected outcome",g.events.get("ending","accounted_for")==("on_record" if "--on-record-ending" in OS.get_cmdline_user_args() else "accounted_for"))
	await shot("R08_ending")
	if g.ended:g.save_game()
	g.presentation.buttons["Main Menu"].pressed.emit();await wait(2)
	check("completed save clearly labelled",g.presentation.buttons.has("View Ending"))
	check("title stays without input",g.presentation.section=="title")
	if g.presentation.buttons.has("View Ending"):g.presentation.buttons["View Ending"].pressed.emit()
	await wait(0.5);check("completed save restores achieved ending",g.ended and g.presentation.section=="ending")
	check("completed menu preserves selected outcome",g.events.get("ending","accounted_for")==("on_record" if "--on-record-ending" in OS.get_cmdline_user_args() else "accounted_for"))
	if "--both-earned-endings" in OS.get_cmdline_user_args():
		phase="Alternate ending / restore naturally earned porch checkpoint"
		g.checkpoint_path=earned_path;g.presentation.restart_checkpoint();await wait(.5)
		check("earned branch restores complete investigation",not g.ended and g.events.get("bedroom_left",false) and g.events.get("memory_confirmed",false))
		await use("order",false)
		if g.presentation.buttons.has("Attach original / keep Simon's case open"):g.presentation.buttons["Attach original / keep Simon's case open"].pressed.emit()
		await travel(Vector2(0,8),"evidence branch porch departure")
		await travel(Vector2(0,15.1),"evidence branch gate approach")
		if not g.doors.front_gate.opened:await use("front_gate")
		await travel(Vector2(0,19.5),"evidence branch crosses gate")
		g.player.rotation.y=PI;g.player.camera.rotation=Vector3.ZERO;Input.action_press("forward")
		var branch_until:=seconds()+5
		while not g.ended and seconds()<branch_until:await get_tree().physics_frame
		Input.action_release("forward")
		check("earned alternate branch leaves on record",g.ended and g.events.get("ending","")=="on_record")
		await shot("R09_on_record_branch")
		g.save_game();g.load_game();await wait(.3)
		check("alternate completed save restores correct outcome",g.ended and g.events.get("ending","")=="on_record")
	recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"))
	recording = false;await wait(0.2)
	var failed := 0
	for item in checks:if not item.passed:failed += 1
	for spec in [["input_trace.json",trace],["frames.json",frames],["repair_report.json",{"passed":checks.size()-failed,"failed":failed,"checks":checks,"started_unix_seconds":started_unix_seconds,"duration_seconds":seconds(),"capture":"Native wall-clock, sampled images; actions driven by automated input, no human playtest."}]]:
		var file := FileAccess.open(output.path_join(spec[0]),FileAccess.WRITE);file.store_string(JSON.stringify(spec[1],"\t"));file.close()
	print("REPAIR_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	get_tree().paused = false;await g.qa_exit(0 if failed==0 else 1,true)
