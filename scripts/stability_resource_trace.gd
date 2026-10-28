extends Node
# Explicit QA-only observer. No resource setters, extra render passes, effects,
# save writes or rendering defaults. Stream evidence survives an abrupt process loss.
var game: Node3D
var output: String
var clock:=0.0
var samples: FileAccess
var lifecycle: FileAccess
var paths: Dictionary={}
func _ready() -> void:
	assert((game.automated_qa or not game.native_capture_directory.is_empty()) and output.is_absolute_path())
	DirAccess.make_dir_recursive_absolute(output)
	samples=FileAccess.open(output.path_join("resource_samples.jsonl"),FileAccess.WRITE)
	lifecycle=FileAccess.open(output.path_join("resource_lifecycle.jsonl"),FileAccess.WRITE)
	var catalog: Array=[]
	for node in game.find_children("*","VisualInstance3D",true,false):
		paths[node.get_instance_id()]=str(node.get_path())
		catalog.append(describe(node))
	var file:=FileAccess.open(output.path_join("resource_catalog.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"Application-visible instance/base RIDs, not certification of native renderer ownership","instances":catalog},"\t"));file.close()
	get_tree().node_added.connect(added);get_tree().node_removed.connect(removed)
	snapshot()
func describe(node: VisualInstance3D) -> Dictionary:
	return {"object_id":node.get_instance_id(),"path":paths.get(node.get_instance_id(),str(node.name)),"class":node.get_class(),"base":str(node.get_base()),"base_id":node.get_base().get_id(),"instance":str(node.get_instance()),"instance_id":node.get_instance().get_id()}
func observed(node: Node) -> bool:
	return node is GPUParticles3D or node is CPUParticles3D or node is GPUParticlesCollisionHeightField3D
func added(node: Node) -> void:
	if not observed(node):return
	paths[node.get_instance_id()]=str(node.get_path());lifecycle.store_line(JSON.stringify({"event":"added","ticks_usec":Time.get_ticks_usec(),"node":describe(node)}));lifecycle.flush()
func removed(node: Node) -> void:
	if not observed(node):return
	lifecycle.store_line(JSON.stringify({"event":"removed_from_tree","ticks_usec":Time.get_ticks_usec(),"node":describe(node)}));lifecycle.flush()
func snapshot() -> void:
	var particles: Array=[]
	for type_ in ["GPUParticles3D","CPUParticles3D","GPUParticlesCollisionHeightField3D"]:
		for node in game.find_children("*",type_,true,false):
			var item: Dictionary=describe(node);item.visible=node.is_visible_in_tree();item.queued=node.is_queued_for_deletion();item.position=str(node.global_position)
			if node is GPUParticles3D or node is CPUParticles3D:item.emitting=node.emitting
			particles.append(item)
	var view: Viewport=game.get_viewport();var camera: Camera3D=view.get_camera_3d()
	var item: Dictionary={"ticks_usec":Time.get_ticks_usec(),"section":game.presentation.section,"started":game.started,"ended":game.ended,"paused":get_tree().paused,"viewport":view.get_instance_id(),"world":str(game.get_world_3d().scenario),"camera":str(camera.get_path()) if camera else "none","player":str(game.player.position),"enemy_state":game.threat.state,"impossible_room":game.impossible_room.active,"particles":particles}
	samples.store_line(JSON.stringify(item));samples.flush()
func _process(delta: float) -> void:
	clock+=delta
	if clock<.5:return
	clock=0;snapshot()
func _exit_tree() -> void:
	var tree:=get_tree()
	if tree.node_added.is_connected(added):tree.node_added.disconnect(added)
	if tree.node_removed.is_connected(removed):tree.node_removed.disconnect(removed)
	if samples:samples.flush();samples.close()
	if lifecycle:lifecycle.flush();lifecycle.close()
