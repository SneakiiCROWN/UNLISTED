extends "res://scripts/recording_repair_qa.gd"
# Real movement and focused interaction; only legacy migration uses a fixture.
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec()
	output=OS.get_executable_path().get_base_dir().path_join("QA/arrival")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	if "--comparison-reread-only" in OS.get_cmdline_user_args():
		var source:=""
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--earned-checkpoint="):source=arg.trim_prefix("--earned-checkpoint=")
		var earned: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
		earned.ended=false # Revisit the earned evidence in an explicit post-route fixture.
		g.apply_save(earned);g.player.position=Vector3(3.3,.04,-7.3);g.player.velocity=Vector3.ZERO;g.presentation.clear_transients();await wait(.4)
		check("earned comparison is already present",g.events.get("memory_confirmed",false))
		await use("source_copy",false)
		check("physical source copy uses canonical title and body",g.presentation.section=="document" and g.events.notes.has(g.NOTES.COMPARISON_TITLE) and g.events.notes[g.NOTES.COMPARISON_TITLE]==g.NOTES.SOURCE_COPY)
		await shot("R07_corrected_comparison");await finish_arrival();return
	g.new_game();g.presentation.clear_transients();await wait(1)
	check("new case starts outside front gate",g.player.position.z>18.5 and not g.doors.front_gate.opened)
	await shot("G01_arrival_at_gate")
	await travel(Vector2(0,18.3),"walk to garden gate");await use("front_gate")
	await travel(Vector2(0,15.1),"walk through garden gate")
	await travel(Vector2(0,5.3),"walk from gate to front door")
	check("first door prompt is knock",g.interaction_name("front")=="Knock")
	await shot("G02_knock_prompt")
	g.player.camera.look_at(g.targets.front.global_position);await wait(.2)
	await action("interact");await action("interact")
	check("extra press cannot bypass knock",g.doors.front.arrival_busy and not g.doors.front.opened)
	await action("ui_cancel");var angle: float=g.doors.front.pivot.rotation.y;await wait(.5)
	check("pause freezes first-door movement",g.menu_open and is_equal_approx(angle,g.doors.front.pivot.rotation.y))
	g.presentation.buttons.Resume.pressed.emit();await wait(1.5)
	check("one knock eases physical leaf ajar",g.events.get("front_checked",false) and g.events.get("front_ajar",false) and not g.doors.front.opened and absf(g.doors.front.pivot.rotation.y)>.15 and absf(g.doors.front.pivot.rotation.y)<.25)
	check("next prompt opens door",g.interaction_name("front")=="Open door")
	await shot("G03_door_ajar")
	g.save_game();g.load_game();await wait(.2)
	check("retry restores ajar without replaying knock",g.events.get("front_ajar",false) and not g.doors.front.arrival_busy and absf(g.doors.front.pivot.rotation.y)>.15)
	await use("front");await wait(.3)
	check("second press fully opens leaf",g.doors.front.opened and absf(g.doors.front.pivot.rotation.y)>1.4 and not g.events.get("front_ajar",false))
	await travel(Vector2(0,1),"enter through front door");await travel(Vector2(0,2.5),"inside door approach")
	await use("front");await wait(.3)
	check("subsequent close is normal",not g.doors.front.opened and absf(g.doors.front.pivot.rotation.y)<.02)
	await use("front");await wait(.3)
	check("subsequent open is normal",g.doors.front.opened and absf(g.doors.front.pivot.rotation.y)>1.4)
	await shot("G04_normal_door")
	# A pre-feature save never receives a retroactive knock or relocation.
	var old: Dictionary=g.save_data();old.events.erase("arrival_check");old.events.erase("front_checked");old.events.erase("front_ajar");old.doors.front=false
	g.apply_save(old);await wait(.1)
	check("legacy save retains its position",g.player.position.distance_to(Vector3(old.pos[0],old.pos[1],old.pos[2]))<.2)
	await use("front");await wait(.3)
	check("legacy door opens on first press",g.doors.front.opened and absf(g.doors.front.pivot.rotation.y)>1.4)
	await finish_arrival()

func finish_arrival() -> void:
	var failed:=0
	for entry in checks:
		if not entry.passed:failed+=1
	var file=FileAccess.open(output.path_join("repair_report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"elapsed_seconds":seconds()},"\t"));file.close()
	print("ARRIVAL_QA_COMPLETE passed=",checks.size()-failed," failed=",failed)
	get_tree().quit(0 if failed==0 else 1)

