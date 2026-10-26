extends "res://scripts/recording_repair_qa.gd"
# Explicit native regression for demonstrated save/capture defects. No ordinary
# menu-stability claim: input and writes are isolated in the existing QA viewport.
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path=output.path_join("checkpoint.json")
	g.presentation.prefs.path=output.path_join("settings.cfg")
	await exact_resolution()
	if "--forensic-missing-recorder" in OS.get_cmdline_user_args():
		# The exact failure contract which previously reached a native null call.
		recorder=null;await finish_run();return
	var weather: Node=g.get_node("BriarLaneExterior/BriarLaneWeather")
	await wait(.5)
	check("title audio remains playing",g.presentation.ambience.playing and g.presentation.menu_drone.playing and weather.outside.playing and weather.sheltered.playing)
	check("title settled gain is retained",is_equal_approx(g.presentation.ambience.volume_db,-17) and is_equal_approx(g.presentation.menu_drone.volume_db,-33))
	g.presentation.begin_new_game()
	var until:=seconds()+25
	while g.presentation.section!="game" and seconds()<until:await get_tree().process_frame
	check("original car arrival restores control",g.player.active and g.presentation.section=="game")
	await wait(2.2)
	check("menu audio still fades out in gameplay",is_equal_approx(g.presentation.ambience.volume_db,-80) and is_equal_approx(g.presentation.menu_drone.volume_db,-80))
	var valid: Dictionary=g.save_data().duplicate(true)
	check("new save validates",g.checkpoint_usable(valid))
	check("legacy core schema remains accepted",g.checkpoint_usable({"schema":1,"pos":[0,.1,9]}))
	var invalid: Array=[null,[],{"schema":1,"pos":7},{"schema":1,"pos":[0]},{"schema":1,"pos":[0,"bad",0]},{"schema":1,"pos":[0,0,0],"events":null},{"schema":1,"pos":[0,0,0],"events":{"notes":[]}},{"schema":1,"pos":[0,0,0],"doors":[]},{"schema":1,"pos":[0,0,0],"valves":[4]},{"schema":1,"pos":[0,0,0],"fuse":"false"}]
	var index:=0
	for data in invalid:
		var f:=FileAccess.open(g.checkpoint_path,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
		var before:=FileAccess.get_sha256(g.checkpoint_path)
		var position_: Vector3=g.player.position;var stage_: int=g.stage
		check("invalid checkpoint unavailable "+str(index),not g.presentation.has_checkpoint())
		g.load_game()
		check("invalid checkpoint preserved without partial load "+str(index),before==FileAccess.get_sha256(g.checkpoint_path) and g.player.position==position_ and g.stage==stage_)
		index+=1
	var f:=FileAccess.open(g.checkpoint_path,FileAccess.WRITE);f.store_string(JSON.stringify(valid));f.close()
	check("valid checkpoint remains available",g.presentation.has_checkpoint())
	g.load_game();await wait(.3)
	check("valid save restores active controls",g.player.active and g.presentation.section=="game")
	g.player.position=Vector3(0,.04,1);await wait(1.5)
	check("weather shelter fade retained",weather.mix_level>.99 and is_equal_approx(weather.outside.volume_db,-65) and is_equal_approx(weather.sheltered.volume_db,-40))
	g.presentation.show_menu(false);await wait(.1)
	check("pause suspends gameplay",g.menu_open and not g.player.active and get_tree().paused)
	g.presentation.buttons.Resume.pressed.emit();await wait(.2)
	check("Resume callback restores control",g.player.active and not g.menu_open)
	# The retained title fade rises from -80 to -17 at 8 dB/s (7.875 s).
	# An earlier two-second assertion tested an unfinished fade, not a defect.
	g.presentation.return_to_title();await wait(8.3)
	check("title sound and menu return intact",g.presentation.section=="title" and is_equal_approx(g.presentation.ambience.volume_db,-17) and is_equal_approx(g.presentation.menu_drone.volume_db,-33))
	await shot("Q01_recovered_title")
	var failed:=checks.filter(func(item):return not item.passed).size()
	f=FileAccess.open(output.path_join("forensic_report.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Focused exported QA/save and audio transitions, isolated inputs/private data. Not ordinary owner idle or a fresh full route."},"\t"));f.close()
	await g.qa_exit(0 if failed==0 else 1,true)
