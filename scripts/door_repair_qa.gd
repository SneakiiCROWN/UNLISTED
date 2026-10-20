extends "res://scripts/recording_repair_qa.gd"
# Separate, explicitly placed doorway scenarios in the actual exported game.
func run(game: Node) -> void:
	g = game
	await exact_resolution()
	output = ProjectSettings.globalize_path("res://qa/repair_doors") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA/repair_doors")
	DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path = output.path_join("checkpoint.json")
	g.new_game();g.presentation.clear_transients();g.events.chair = true
	await wait(2)
	started_at = Time.get_ticks_usec();started_unix_seconds = Time.get_unix_time_from_system();recording = true
	recorder = AudioEffectRecord.new();recorder.format = AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
	for id in ["lounge","service"]:
		var door: Node3D = g.doors[id];door.locked = false
		for partial in [false,true]:
			for side in [-1,1]:
				for offset in [-0.3,0.0,0.3]:
					door.set_open(false,0.01)
					var start := Vector3(1.5+side*1.3,0.04,1+offset) if id=="lounge" else Vector3(-4.5+offset,0.04,-10.2+side*0.65)
					var destination := Vector2(1.5-side*1.3,1+offset) if id=="lounge" else Vector2(-4.5+offset,-10.2-side*0.65)
					g.player.position = start;g.player.velocity = Vector3.ZERO
					await wait(0.15)
					door.use();await wait(0.15 if partial else 1)
					await travel(destination,"%s %s side=%d offset=%.1f"%[id,"opening" if partial else "open",side,offset])
		await shot("D_"+id+"_clearance")
	var saved_angle: float = g.doors.service.open_angle
	g.save_game();g.load_game();await wait(0.25)
	check("swing direction survives save load",is_equal_approx(saved_angle,g.doors.service.open_angle))
	g.player.position = Vector3(-4.5,0.03,-10.2);g.player.velocity = Vector3.ZERO
	await wait(0.15);g.doors.service.use()
	check("occupied threshold prevents door closing through body",g.doors.service.opened)
	# The throwable is supported by the existing first-person visual language.
	g.player.position = Vector3(-17.25,0.03,-15.2);g.player.velocity = Vector3.ZERO
	g.player.rotation = Vector3.ZERO;g.player.camera.look_at(g.physical.props.spare.global_position)
	await wait(0.2);await action("interact");await wait(1)
	check("scrap pickup",g.physical.held==g.physical.props.spare)
	check("support hand follows held object",g.physical.support.visible and g.physical.support.global_position.distance_to(g.physical.held.global_position)<0.2)
	await shot("D_supported_scrap")
	g.physical.release(false);await wait(1.5)
	check("scrap release settles above floor",g.physical.props.spare.position.y>0 and g.physical.props.spare.position.y<1.5)
	recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"))
	recording = false;await wait(0.2)
	var failed := 0
	for item in checks:if not item.passed:failed += 1
	for spec in [["input_trace.json",trace],["frames.json",frames],["repair_report.json",{"passed":checks.size()-failed,"failed":failed,"checks":checks,"started_unix_seconds":started_unix_seconds,"duration_seconds":seconds(),"capture":"Native input-backed doorway scenarios; initial player placement between cases is explicit."}]]:
		var file := FileAccess.open(output.path_join(spec[0]),FileAccess.WRITE);file.store_string(JSON.stringify(spec[1],"\t"));file.close()
	print("DOOR_REPAIR_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	get_tree().paused = false;await g.qa_exit(0 if failed==0 else 1)
