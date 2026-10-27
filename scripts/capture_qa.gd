extends "res://scripts/recording_repair_qa.gd"
func until(value: String,limit: float) -> bool:
	var before:=seconds()
	while seconds()-before<limit:
		if g.threat.state==value:return true
		await wait(0.05)
	return false
func setup(yaw: float) -> void:
	g.new_game();g.presentation.clear_transients();g.subtitle.text=""
	g.events.chair=true;g.player.position=Vector3(0,0.04,-4)
	g.player.rotation.y=yaw;g.player.camera.rotation=Vector3.ZERO
	g.threat.arm()
func run(game: Node) -> void:
	g=game
	output=ProjectSettings.globalize_path("res://qa/capture_native") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA/capture_native")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system();recording=true
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
	var angles: Array=[PI] if "--capture-quick" in OS.get_cmdline_user_args() else [PI,0.0,PI/2]
	for yaw in angles:
		phase="normal contact / player yaw "+str(yaw)
		setup(yaw)
		check("normal AI reaches capture yaw "+str(yaw),await until("capture",18))
		if not g.capture_director.active:continue
		var original: Vector3=g.player.position
		var checkpoint_before:=FileAccess.get_sha256(g.checkpoint_path)
		await wait(1.0)
		await shot("capture_inspection_"+str(roundi(rad_to_deg(yaw))))
		print("CAPTURE_ARMS ",JSON.stringify(g.surveyor_actor.capture_diagnostics))
		check("physical separation yaw "+str(yaw),g.player.position.distance_to(g.presence.position)>0.64)
		check("capture keeps player body yaw "+str(yaw),g.player.position==original and not g.player.active)
		g.save_game()
		check("capture cannot overwrite checkpoint yaw "+str(yaw),FileAccess.get_sha256(g.checkpoint_path)==checkpoint_before)
		if is_equal_approx(yaw,PI):
			await action("ui_cancel")
			var capture_clock: float=g.capture_director.clock
			await wait(0.7)
			check("capture pause freezes timeline",get_tree().paused and is_equal_approx(g.capture_director.clock,capture_clock))
			g.presentation.buttons.Resume.pressed.emit()
			await wait(0.1)
			check("capture resume keeps controls suspended",g.presentation.section=="capture" and not g.player.active and not get_tree().paused)
		await wait(1.1)
		await shot("capture_contact_"+str(roundi(rad_to_deg(yaw))))
		var errors: Dictionary=g.surveyor_actor.capture_diagnostics
		print("CAPTURE_CONTACT_ARMS ",JSON.stringify(errors))
		check("hands reach contact with human arm lengths yaw "+str(yaw),errors.has("l") and errors.has("r") and errors.l.error<0.12 and errors.r.error<0.12)
		await wait(0.6)
		await shot("capture_cover_"+str(roundi(rad_to_deg(yaw))))
		check("directed capture reaches death yaw "+str(yaw),await until("dead",5))
		await wait(0.5)
		check("death is paused with retry yaw "+str(yaw),get_tree().paused and g.presentation.buttons.has("Retry Checkpoint"))
		g.presentation.buttons["Retry Checkpoint"].pressed.emit();await wait(0.2)
		check("retry restores camera and input yaw "+str(yaw),g.player.active and not get_tree().paused and is_equal_approx(g.player.camera.fov,77) and not g.capture_director.active)
		if is_equal_approx(yaw,PI/2):
			check("repeat encounter reaches capture",await until("capture",18))
			check("repeat inspection is shorter",is_equal_approx(g.capture_director.duration,2.7))
			var retry_bytes:=FileAccess.get_sha256(g.checkpoint_path)
			await wait(0.8);await action("ui_cancel")
			g.presentation.buttons["Main Menu"].pressed.emit();await wait(0.2)
			check("interrupted capture returns cleanly to title",not g.capture_director.active and g.presentation.section=="title" and not g.player.active and get_tree().paused)
			check("interruption preserves checkpoint and camera",FileAccess.get_sha256(g.checkpoint_path)==retry_bytes and is_equal_approx(g.player.camera.fov,77))
	if "--capture-quick" in OS.get_cmdline_user_args():await finish_report();return
	# Reduced-motion inspection is tested independently, with the same real AI.
	phase="reduced motion"
	g.presentation.prefs.data.reduced_motion=true;setup(0)
	check("reduced motion reaches capture",await until("capture",18))
	var fov: float=g.player.camera.fov
	await wait(1.5)
	check("reduced motion avoids zoom",is_equal_approx(g.player.camera.fov,fov))
	await shot("capture_reduced_motion")
	check("reduced motion reaches safe death",await until("dead",5))
	phase="story survival"
	g.presentation.prefs.data.story_mode=true;setup(PI)
	check("story mode reaches warned attack",await until("attack",18))
	await wait(1.2)
	check("story mode preserves survival alternative",g.threat.state=="recovery" and not g.capture_director.active and g.presentation.section=="game")
	g.presentation.prefs.data.story_mode=false
	await finish_report()

func finish_report() -> void:
	recorder.set_recording_active(false)
	var audio:=recorder.get_recording()
	var non_silent:=false
	for value in audio.data:
		if value!=0:non_silent=true;break
	check("native game bus contains audio",non_silent)
	audio.save_to_wav(output.path_join("game_bus.wav"))
	recording=false;await wait(0.2)
	var failed:=0
	for item in checks:
		if not item.passed:failed+=1
	for item in [["input_trace.json",trace],["frames.json",frames],["repair_report.json",{"passed":checks.size()-failed,"failed":failed,"checks":checks,"duration_seconds":seconds(),"started_unix_seconds":started_unix_seconds,"capture":"Native timed, automated real-AI contact scenarios. Explicit fresh fixture placement per angle, no human playtest."}]]:
		var file:=FileAccess.open(output.path_join(item[0]),FileAccess.WRITE);file.store_string(JSON.stringify(item[1],"\t"));file.close()
	print("CAPTURE_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
