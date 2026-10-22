extends "res://scripts/recording_repair_qa.gd"
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec()
	output=OS.get_executable_path().get_base_dir().path_join("QA/views")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();g.new_game();g.stage=3;g.threat.enabled=false;g.threat.reset()
	g.events.chair=true;g.events["return"]=true;g.events.impossible_room_resolved=true;g.events.threat_resolved=true
	g.presentation.clear_transients()
	for light in g.lamps:light.light_energy=.6
	for door in g.doors.values():door.locked=false;door.set_open(true,.01)
	var views=[
		["V01_porch",Vector3(0,.04,7.2),Vector3(0,1.4,3.7)],
		["V02_lounge",Vector3(2.7,.04,2.6),Vector3(5.5,.9,.2)],
		["V03_kitchen",Vector3(-2.8,.04,-1),Vector3(-5.8,.9,2.5)],
		["V04_office",Vector3(2.8,.04,-5.3),Vector3(5.5,1.1,-8.8)],
		["V05_utility",Vector3(-3.5,.04,-7.2),Vector3(-6.45,.8,-5.4)],
		["V06_shed",Vector3(-15,.04,-14.1),Vector3(-18.1,1,-15)],
		["V07_cellar",Vector3(0,-2.99,-17.2),Vector3(-1.5,-1.5,-23)],
		["V08_lane",Vector3(0,.04,17),Vector3(0,1.5,2)],
		["V09_rear",Vector3(-9,.04,-12.5),Vector3(-15,1.1,-14)]
	]
	for view in views:
		g.player.position=view[1];g.player.velocity=Vector3.ZERO;g.player.restore_stance(false)
		g.player.camera.look_at(view[2]);g.caption_until=0;g.subtitle.text="";await wait(.6);await shot(view[0])
	g.chapter.set_room(true)
	for view in [["V10_bedroom",Vector3(3.9,.04,2),Vector3(5.7,.9,-1.8)],["V11_work_corner",Vector3(5,.04,1.5),Vector3(7.03,.9,.10)],["V12_bedding",Vector3(5.3,.04,-.1),Vector3(6.35,.6,-1.65)]]:
		g.player.position=view[1];g.player.velocity=Vector3.ZERO;g.player.restore_stance(false);g.player.camera.look_at(view[2]);g.caption_until=0;g.subtitle.text="";await wait(.6);await shot(view[0])
	var file=FileAccess.open(output.path_join("VIEW_SCOPE.txt"),FileAccess.WRITE)
	file.store_string("Actual Windows viewport captures at player eye height, using labelled powered visual fixtures. Camera/position placement is deliberate for inspection; these are not movement-route or human quality approval tests.");file.close()
	await g.qa_exit(0)
