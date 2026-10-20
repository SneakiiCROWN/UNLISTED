extends "res://scripts/presentation_qa.gd"
func run(game: Node) -> void:
	g=game;p=g.presentation
	output=ProjectSettings.globalize_path("res://qa/captions") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA/captions")
	DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path=output.path_join("checkpoint.json")
	g.new_game();p.clear_transients();g.player.active=false
	g.events.chair=true
	g.player.position=Vector3(-4.2,0.04,-8.15);g.player.look_at(Vector3(-4.5,0.04,-10))
	g.doors.service.locked=false;g.doors.service.use()
	await wait(1)
	p.prefs.data.subtitles=false;p.prefs.data.sound_captions=true;p.prefs.data.observations=true
	g.message("The carrier is empty. A 13A cartridge belongs here.",8)
	await wait(0.1)
	check("observation identity",g.subtitle.text.begins_with("OBSERVATION\n"))
	check("observations independent of speech setting",g.subtitle.visible)
	var count: int=g.message_history.size()
	g.sound_caption("Must never be shown",3,"MISSING",null)
	check("no sound caption without playback",g.message_history.size()==count)
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		await render_size(size_)
		g.player.camera.current=true
		p.prefs.data.subtitle_scale=1.4;p.apply_preferences(false)
		g.message("The carrier is empty. A 13A cartridge belongs here.",8)
		await wait(0.15)
		await capture("C_observation_%d"%size_.x)
		var step=g.sound("step",Vector3(-4.5,1,-9.5),-23)
		g.sound_caption("One footstep behind the door.",8,"SERVICE DOOR",step)
		check("sound tied to playing stream %d"%size_.x,g.message_info.audio_playing_at_trigger and g.message_info.audio!="" and g.message_info.category=="sound")
		await wait(0.15)
		await capture("C_sound_%d"%size_.x)
		check("caption clears prompt %d"%size_.x,g.subtitle.get_global_rect().end.y<=p.prompt.get_global_rect().position.y)
		p.show_settings("pause");p.fill_settings("Captions")
		await wait(0.2)
		await capture("C_settings_%d"%size_.x)
		check("caption controls inside card %d"%size_.x,p.card.get_global_rect().encloses(p.controls.caption_backing.get_global_rect()))
		p.resume_game();await wait(0.1);g.player.active=false
	p.prefs.data.sound_captions=false
	var noise=g.sound("step",g.player.position,-23)
	g.sound_caption("A footstep.",3,"HALL",noise)
	await wait(0.1)
	check("sound captions independently hidden",not g.subtitle.visible)
	p.prefs.data.observations=true;g.message("The supply indicator is dark.",3)
	await wait(0.1)
	check("observations remain enabled",g.subtitle.visible)
	var preferences=load("res://scripts/preferences.gd").new()
	preferences.path=output.path_join("caption_settings.cfg")
	preferences.data=p.prefs.data.duplicate(true)
	check("caption settings save",preferences.save_file()==OK)
	var reloaded=load("res://scripts/preferences.gd").new();reloaded.path=preferences.path;reloaded.load_file()
	check("caption settings persist",not reloaded.data.sound_captions and reloaded.data.subtitle_scale==1.4 and reloaded.data.caption_backing)
	var failed:=0
	for result in checks:
		if not result.passed:failed+=1
	var file:=FileAccess.open(output.path_join("caption_report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failed,"events":g.message_history},"\t"));file.close()
	print("CAPTION_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
