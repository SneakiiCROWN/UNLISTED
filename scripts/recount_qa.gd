extends "res://scripts/capture_qa.gd"
func run(current: Node) -> void:
	g=current
	output=OS.get_executable_path().get_base_dir().path_join("QA/recount")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path=output.path_join("checkpoint.json")
	started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	await exact_resolution()
	g.new_game();g.events.chair=true;g.events["return"]=true
	g.stage=3;g.report_read=true;g.shed_read=true;g.brass_key=true
	g.events.threat_resolved=true;g.threat.enabled=false
	g.presentation.clear_transients()
	g.player.position=Vector3(-.7,.04,5.5)
	await wait(.2)
	check("loaded circuit keeps original strip covered",g.recount.shutter.position.y==0 and g.targets.relay_record.collision_layer==0)
	g.isolated=true
	await wait(1.7)
	check("isolation physically uncovers return strip",g.recount.shutter.position.y>.65 and g.targets.relay_record.collision_layer==1)
	g.player.position=Vector3(3.85,-2.96,-22.15)
	g.player.camera.look_at(g.targets.relay_record.global_position);await wait(.2)
	await shot("C00_open_return_drawer")
	await use("relay_record",false)
	check("physical field return is readable",g.presentation.section=="document" and g.events.notes.has("FIELD RETURN / 1998"))
	await shot("C01_original_field_return");await action("ui_cancel")
	g.player.position=Vector3(-.7,.04,5.5)
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
	await use("order",false)
	check("sheet initiates environment instead of ending panel",g.recount.active and g.player.active and not g.menu_open)
	check("front view opens physically",g.doors.front.opened)
	g.player.camera.look_at(Vector3(0,1.5,-4));await wait(1.7)
	check("real positional footsteps emitted",g.recount.sources.size()>0 and g.recount.hall.size()>0)
	await shot("C02_empty_hall_recount")
	await action("ui_cancel");var saved_clock: float=g.recount.clock;await wait(.7)
	check("pause freezes recount",get_tree().paused and is_equal_approx(g.recount.clock,saved_clock))
	g.presentation.buttons.Resume.pressed.emit();await wait(.1)
	g.save_game();var phase_saved: float=g.recount.clock
	g.load_game();await wait(.1)
	check("mid-recount save restores elapsed phase",g.recount.active and absf(g.recount.clock-phase_saved)<.3)
	await wait(7)
	check("completion remains interactive",not g.recount.active and g.player.active and not g.menu_open)
	check("two arrivals become physical evidence",g.recount.sheet.text.contains("S. WARD / IN") and g.events.notes.has("TWO ARRIVALS / NO EXIT"))
	g.player.camera.look_at(g.targets.order.global_position);await shot("C03_two_arrivals_sheet")
	await use("order",false)
	check("choices offered after witnessed sequence",g.presentation.section=="register" and g.presentation.buttons.has("Simon Ward / PRESENT"))
	await shot("C04_contextual_register")
	g.presentation.resume_game()
	g.events.recount_complete=false;g.events.recount_started=false;g.events.recount_elapsed=0
	g.recount.restore_state();g.recount.request();await wait(.2)
	await action("ui_cancel")
	check("optional skip appears in pause",g.presentation.buttons.has("Skip recount"))
	g.presentation.buttons["Skip recount"].pressed.emit();await wait(.2)
	check("skip completes evidence without restarting",g.events.recount_complete and not g.recount.active and g.player.active)
	await use("order",false)
	g.presentation.buttons["Simon Ward / PRESENT"].pressed.emit();await wait(.2)
	check("acknowledgement ending preserved",g.ended and g.events.ending=="accounted_for")
	await finish_report()
