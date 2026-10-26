extends "res://scripts/recording_repair_qa.gd"
# Matching powered player-eye fixtures; no changing resolution during gameplay.
func setup() -> void:
	g.new_game();g.stage=3;g.fuse=true;g.report_read=true;g.brass_key=true
	g.events.chair=true;g.events.yard=true;g.events.basement=true;g.events["return"]=true
	g.events.threat_resolved=true;g.events.impossible_room_resolved=true
	g.threat.reset();g.threat.enabled=false;g.presence.visible=false
	g.horror.beat="";g.horror.echo_index=-1;g.ambient_director.enabled=false
	for light in g.lamps:light.light_energy=1.1
	for door in g.doors.values():door.locked=false;door.set_open(true,0)
	g.presentation.clear_transients()
func views() -> void:
	for v in [["P01_office_entry",Vector3(2.75,.04,-5.3),Vector3(5.15,1.1,-8.75)],["P02_transport",Vector3(3.3,.04,-7.6),Vector3(3.3,.9,-8.52)],["P03_cellar",Vector3(0,-2.99,-17.2),Vector3(-1.5,-1.5,-23)],["P04_cellar_aisle",Vector3(2,-2.99,-22),Vector3(-4.3,-1.6,-18.2)]]:
		g.player.position=v[1];g.player.velocity=Vector3.ZERO;g.player.restore_stance(false);g.player.camera.look_at(v[2]);g.presentation.clear_transients();await wait(.5);await shot(v[0])
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec()
	output=OS.get_executable_path().get_base_dir().path_join("QA/experience")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	started_unix_seconds=Time.get_unix_time_from_system();capture_interval=.10
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	setup();await views()
	g.player.position=Vector3(3.3,.04,-7.6);g.presentation.show_exclusion();await wait(.3);await shot("P09_comparison_controls");await action("ui_cancel")
	if not "--experience-before" in OS.get_cmdline_user_args():await changed_systems()
	await finish_run()
func changed_systems() -> void:
	phase="physical recorder comparison"
	g.player.position=Vector3(3.3,.04,-7.6);g.player.camera.look_at(Vector3(3.3,.94,-8.52))
	g.events.memory_trace=[[0,0,-6,0,"step",1.0],[0,0,-5,.5,"step",1.0],[0,0,-4,1,"step",1.0],[0,0,-3,1.5,"step",1.0]]
	g.events.memory_hall=[];g.events.memory_confirmed=false
	await use("audition_return")
	check("B input depresses actual transport key",g.recorder_memory.transport=="B" and g.get_node("ArchiveTransport/TransportKey1").position.y<.065)
	var peak:=-.55;var reached_tail:=false
	for i in 90:
		await wait(.07);peak=maxf(peak,g.recorder_memory.needle.rotation.y)
		if g.horror.audition_tail:reached_tail=true;break
	check("recorded steps visibly drive VU",peak>-.30,str(peak))
	check("B reaches stopped-deck listening gap",reached_tail and g.horror.audition=="B" and g.recorder_memory.transport=="")
	var reels: Array=get_tree().get_nodes_in_group("archive_reels");var stopped_angle: float=reels[0].rotation.y
	await wait(.4)
	check("actual reels remain still before room answer",is_equal_approx(reels[0].rotation.y,stopped_angle))
	await shot("P05_stopped_transport")
	await joy(JOY_BUTTON_START);var paused_clock: float=g.horror.audition_clock;await wait(.3)
	check("controller Start freezes comparison gap",get_tree().paused and is_equal_approx(paused_clock,g.horror.audition_clock))
	await joy(JOY_BUTTON_START);await wait(2)
	check("doorway answer grants B without driving meter",g.events.get("audition_B",false) and g.recorder_memory.transport=="" and absf(g.recorder_memory.needle.rotation.y+.55)<.02)
	check("optional caption names real doorway source",g.message_history.any(func(m):return str(m).contains("OFFICE DOORWAY")))
	await shot("P06_room_answer_after_stop")
	await use("audition_source");await wait(.7);g.save_game(true);g.load_game();await wait(.3)
	check("load during playback releases transport keys",g.horror.audition=="" and g.recorder_memory.transport=="" and is_equal_approx(g.get_node("ArchiveTransport/TransportKey0").position.y,.07))
	g.presentation.prefs.data.reduced_motion=true
	g.events.test_reel_found=true;await use("test_reel_deck",false)
	check("historical reel remains a separate loading action",g.presentation.buttons.has("Load reel and listen"))
	if g.presentation.buttons.has("Load reel and listen"):
		g.presentation.buttons["Load reel and listen"].grab_focus();await joy(JOY_BUTTON_A)
	await wait(.9)
	check("controller can load historical reel",g.field_tape.playing and g.field_tape.remote==false and g.recorder_memory.transport=="FIELD")
	await shot("P07_historical_reel")
	await wait(13.5)
	check("historical evidence still finishes and releases deck",g.events.get("test_reel_heard",false) and g.recorder_memory.transport=="")
	g.save_game(true);g.load_game();await wait(.3)
	check("heard history and completed B survive load",g.events.get("test_reel_heard",false) and g.events.get("audition_B",false))
	g.presentation.prefs.data.reduced_motion=false
	phase="physical search around last heard position"
	g.player.position=Vector3(0,.04,-5);g.player.camera.look_at(Vector3(0,1.5,-8))
	g.threat.enabled=true;g.events.threat_resolved=false;g.events.threat_pending=true
	g.threat.begin(false,Vector3(0,.04,2.6));g.threat.last_known=Vector3(0,.04,-5)
	await travel(Vector2(0,-7),"Eli reaches utility doorway in hall",true)
	await travel(Vector2(-3.1,-7),"Eli takes existing utility opening",true)
	await travel(Vector2(-3.1,-8.5),"Eli conceals behind actual wall",false,true)
	g.doors.utility.set_open(false,.1);g.player.camera.look_at(Vector3(-1.5,1.2,-7));await wait(.2)
	check("closed-room cover removes real line of sight",not g.threat.can_see_player())
	# An audible throw in the hall establishes an inspectable last-heard point.
	g.threat.grace=0;g.threat.change("investigate");g.sound("prop_impact",Vector3(0,.04,-6),-25);g.threat.hear(Vector3(0,.04,-6),15)
	g.threat.last_known=Vector3(0,.04,-6);g.threat.plan(g.threat.last_known)
	var searched:=false;var probed:=false;var original_last: Vector3=g.threat.last_known
	for i in 150:
		await wait(.1)
		if g.threat.state=="search":searched=true
		if g.threat.search_leg>0:probed=true
		if g.threat.state=="complete":break
	check("heard point leads to a bounded adjacent physical search",searched and probed,"state="+g.threat.state+" legs="+str(g.threat.search_leg))
	check("hidden player does not overwrite last heard position",g.threat.last_known.distance_to(original_last)<.15)
	check("actual cover still permits escape without a grab",g.presentation.section=="game" and not g.ended)
	check("hall search does not open unrelated utility door",not g.doors.utility.opened)
	check("search gives up rather than patrolling forever",g.threat.state in ["retreat","complete"],g.threat.state)
	g.threat.reset();g.presence.visible=false
	# Changed work lights follow actual power and do not invent a room lock.
	g.stage=0;await wait(.2)
	check("desk work lights obey supply",g.get_node("TransportWorkPool").light_energy==0 and g.get_node("OfficePaperTaskLight").light_energy==0)
	g.stage=3;await wait(.2)
	check("powered work pools return without new puzzle state",g.get_node("TransportWorkPool").light_energy>0)
	phase="walk repaired room circulation"
	g.doors.utility.set_open(true,0);await travel(Vector2(-3.1,-7),"utility aisle reaches actual doorway")
	await travel(Vector2(0,-7),"utility return to hall")
	await travel(Vector2(3,-7),"office doorway remains clear")
	await travel(Vector2(4.4,-7.4),"equipment bench approach remains clear")
	await travel(Vector2(3,-7),"office leaves through real doorway")
	await travel(Vector2(0,-7),"office back to cellar approach")
	for p in [Vector2(0,-9),Vector2(0,-15.5),Vector2(0,-18),Vector2(2,-22),Vector2(0,-18)]:await travel(p,"existing cellar aisle clearance")
	await shot("P08_cellar_return")
func joy(button: int) -> void:
	for down in [true,false]:
		var event:=InputEventJoypadButton.new();event.button_index=button;event.pressed=down;event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event);await wait(.08)
