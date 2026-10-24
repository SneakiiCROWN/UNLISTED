extends "res://scripts/recording_repair_qa.gd"
# Matched actual Windows rendering. Deliberate art fixtures, not live navigation.
func execute() -> void:
	g.new_game();g.fuse=true;g.interact("breaker");g.presentation.clear_transients()
	g.events.chair=true;g.threat.enabled=false;g.threat.reset()
	g.horror.set_process(false);g.horror.set_physics_process(false);g.ambient_director.set_process(false)
	g.presence.position=Vector3(0,.04,-6.2);g.presence.visible=true;g.presence.look_at(Vector3(0,.04,-3.5))
	var actor: Node3D=g.surveyor_actor
	var fill:=OmniLight3D.new();fill.position=Vector3(0,2.5,-3.7);fill.light_color=Color(.84,.87,.87);fill.light_energy=.7;fill.omni_range=6;g.add_child(fill)
	await wait(.5)
	g.presentation.clear_transients();g.subtitle.text="";g.caption_until=0
	if "--reborn-components" in OS.get_cmdline_user_args():
		var parts: Array=actor.figure.find_children("*","MeshInstance3D",true,false)
		g.player.position=Vector3(0,.04,-4.3);g.player.camera.look_at(Vector3(0,1.0,-6.2));actor.set_mode("watch")
		for i in parts.size():
			for j in parts.size():parts[j].visible=i==j
			await wait(.3);await shot("C"+str(i)+"_"+str(parts[i].name))
		for part in parts:part.visible=true
		await g.qa_exit(0);return
	for spec in [["N01_front_full",Vector3(0,.04,-2.8),Vector3(0,1.05,-6.2)],
		["N02_face",Vector3(0,.04,-5.25),Vector3(0,1.72,-6.2)],
		["N03_side",Vector3(1.05,.04,-5.9),Vector3(0,1.65,-6.2)],
		["N04_rear",Vector3(0,.04,-9.5),Vector3(0,1.05,-6.2)]]:
		g.player.position=spec[1];g.player.velocity=Vector3.ZERO;g.player.camera.look_at(spec[2]);actor.set_mode("watch")
		await wait(.8);await shot(spec[0])
	fill.visible=false;g.player.position=Vector3(0,.04,-2.8);g.player.camera.look_at(Vector3(0,1.15,-6.2));await wait(.5);await shot("N05_flashlight")
	g.player.torch.visible=false;await wait(.5);await shot("N06_hall_shadow");g.player.torch.visible=true;fill.visible=true
	fill.visible=false;g.player.torch.visible=false;g.player.position=Vector3(0,.04,2.4);g.player.camera.look_at(Vector3(0,1.3,-6.2));await wait(.5);await shot("N07_distant_hall")
	fill.visible=true;g.player.torch.visible=true
	for mode in ["listen","walk","run","attack","capture","react"]:
		g.player.position=Vector3(.9,.04,-3.1);g.player.camera.look_at(Vector3(0,1.05,-6.2))
		actor.set_mode(mode);await wait(.36);await shot("A_"+mode)
	check("existing skeleton retains 65 named bones",actor.skeleton.get_bone_count()==65)
	check("candidate motion branch matches selected model",actor.reborn_presence==("--surveyor-reborn" in OS.get_cmdline_user_args()))
	for name_ in ["listen","watch","walk","run","attack","capture","react"]:check("clip available / "+name_,actor.clips.has(name_))
	check("ordinary model is untouched",g.surveyor_model_path()==("res://assets/original/surveyor_reborn_study.glb" if "--surveyor-reborn" in OS.get_cmdline_user_args() else "res://assets/original/surveyor_presence.glb"))
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"model":g.surveyor_model_path(),"scope":"Matched native art/clip pose fixtures. No locomotion, pursuit or human artistic approval claim."},"\t"));file.close()
	await g.qa_exit(0 if failed==0 else 1)
