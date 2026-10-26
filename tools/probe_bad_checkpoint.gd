extends SceneTree
var output:=""
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	assert(not output.is_empty() and "--visual-probe" in OS.get_cmdline_user_args())
	DirAccess.make_dir_recursive_absolute(output)
	var game=load("res://scenes/main.tscn").instantiate()
	game.checkpoint_path=output.path_join("malformed_checkpoint.json")
	root.add_child(game);current_scene=game
	await process_frame
	var processing: Array=[]
	var audio: Array=[]
	for node in root.find_children("*","",true,false):
		var script=node.get_script()
		if script and node.can_process() and (node.is_processing() or node.is_physics_processing()):processing.append({"node":str(node.get_path()),"script":script.resource_path,"mode":node.process_mode,"process":node.is_processing(),"physics":node.is_physics_processing()})
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D:audio.append({"node":str(node.get_path()),"playing":node.playing,"can_process":node.can_process(),"bus":node.bus,"stream":node.stream.resource_path if node.stream else "null"})
	var f:=FileAccess.open(output.path_join("paused_menu_execution.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"scope":"Headless original world, explicit visual-probe/private data; actual pause inheritance snapshot, not GPU or ordinary owner run.","paused":paused,"processing":processing,"audio":audio},"\t"));f.close()
	f=FileAccess.open(game.checkpoint_path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema":1,"pos":7}));f.close()
	print("FORENSIC_BAD_SAVE before has_checkpoint scalar position")
	var accepted: bool=game.presentation.has_checkpoint()
	print("FORENSIC_BAD_SAVE accepted=",accepted)
	f=FileAccess.open(output.path_join("bad_save_result.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"accepted":accepted,"scope":"Malformed private checkpoint only; log is authoritative for script errors."}));f.close()
	await game.qa_exit(0)
