extends "res://scripts/recording_repair_qa.gd"
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec()
	output=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--presence-output="):output=arg.trim_prefix("--presence-output=")
	assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path=output.path_join("fixture_checkpoint.json")
	await exact_resolution()
	g.new_game();g.presentation.clear_transients();g.events.chair=true;g.threat.enabled=false
	g.horror.set_process(false);g.horror.set_physics_process(false)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--static-study="):
			await static_review(arg.trim_prefix("--static-study="));return
	var actor: Node3D=g.surveyor_actor
	var old: Node3D=actor.figure
	old.get_parent().remove_child(old);old.queue_free()
	var path: String="res://assets/original/surveyor_continuation.glb" if "--presence-before" in OS.get_cmdline_user_args() else g.surveyor_model_path()
	var external:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--presence-model="):external=arg.trim_prefix("--presence-model=")
	if external!="":
		var document:=GLTFDocument.new();var state:=GLTFState.new()
		var imported: int=document.append_from_file(external,state)
		if imported!=OK:
			push_error("External art study import failed: "+str(imported));await g.qa_exit(1);return
		actor.figure=document.generate_scene(state);path=external
	else:actor.figure=load(path).instantiate()
	g.presence.add_child(actor.figure)
	actor.figure.scale=Vector3.ONE*1.05;actor.figure.rotation.y=PI;actor._ready()
	g.presence.position=Vector3(0,0.04,-6.2);g.presence.visible=true
	await wait(3.2)
	for spec in [["front",Vector3(0,0.04,-3.4)],["close",Vector3(0,0.04,-5.15)],["side",Vector3(1.1,0.04,-5.3)]]:
		g.player.position=spec[1];g.player.rotation=Vector3.ZERO
		g.player.camera.look_at(Vector3(0,1.65,-6.2));g.presence.look_at(Vector3(0,0.04,-3.5))
		actor.set_mode("watch");g.player.torch.visible=true
		await wait(.65);g.presentation.clear_transients();g.subtitle.text=""
		await wait(.15);await shot(spec[0])
	check("preserved skeleton has 65 bones",actor.skeleton.get_bone_count()==65)
	check("all seven source animation clips preserved",actor.animator.get_animation_list().size()>=7)
	var file:=FileAccess.open(output.path_join("fixture.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"model":path,"checks":checks,"scope":"Actual in-engine camera fixtures; not movement or artistic approval"},"\t"));file.close()
	await g.qa_exit(0)

func static_review(path: String) -> void:
	# Construction gate only: never binds an unapproved mesh to the active rig.
	g.presence.position=Vector3(0,.04,-6.2);g.presence.look_at(Vector3(0,.04,-3.4));g.presence.visible=true
	g.surveyor_actor.attention_override=Vector3(0,1.5,-3.4)
	var doc:=GLTFDocument.new();var state:=GLTFState.new()
	var imported: int=doc.append_from_file(path,state)
	if imported!=OK:
		push_error("Static art study import failed: "+str(imported));await g.qa_exit(1);return
	var study: Node3D=doc.generate_scene(state);g.add_child(study)
	check("external study contains actual rendered meshes",not study.find_children("*","MeshInstance3D",true,false).is_empty())
	study.position=Vector3(0,.04,-6.2);study.rotation.y=0;study.scale=Vector3.ONE*1.05;study.visible=false
	for mode in ["current","rejected_static"]:
		g.presence.visible=mode=="current";study.visible=mode!="current"
		for spec in [["front",Vector3(0,.04,-3.4)],["side",Vector3(1.1,.04,-6.2)],["rear",Vector3(0,.04,-8.9)],["distance",Vector3(0,.04,.4)],["face",Vector3(0,.04,-5.4)]]:
			g.player.position=spec[1];g.player.camera.look_at(Vector3(0,1.65 if spec[0]=="face" else 1.1,-6.2))
			await wait(.4);await shot(mode+"_"+spec[0])
	check("active model path remains preserved",g.surveyor_model_path()=="res://assets/original/surveyor_presence.glb")
	var report=FileAccess.open(output.path_join("static_review.json"),FileAccess.WRITE)
	var matched: bool="--matched-static" in OS.get_cmdline_user_args()
	report.store_string(JSON.stringify({"status":"NOT PROMOTED / matched-source construction foundation" if matched else "REJECTED at static construction gate","reason":"Construction is improved; distinctive Surveyor identity and material/face art are not achieved. No rig or gameplay promotion." if matched else "Garment/body intersections, unfinished footwear and unconvincing hood silhouette. No rig, animation or gameplay promotion.","scope":"Actual Windows current-model and external static-study views; not movement acceptance or human approval.","checks":checks},"\t"));report.close()
	await g.qa_exit(0)
