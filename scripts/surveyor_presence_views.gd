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
	var actor: Node3D=g.surveyor_actor
	var old: Node3D=actor.figure
	old.get_parent().remove_child(old);old.queue_free()
	var path:="res://assets/original/surveyor_continuation.glb" if "--presence-before" in OS.get_cmdline_user_args() else "res://assets/original/surveyor_presence.glb"
	actor.figure=load(path).instantiate();g.presence.add_child(actor.figure)
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
