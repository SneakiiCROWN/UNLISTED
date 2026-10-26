extends SceneTree
# Structural/import validation, not an artistic or ordinary gameplay review.
var out:=""
var rows: Array=[]
var faults: Array=[]
func _initialize() -> void:call_deferred("run")
func inspect_node(node: Node,errors: Array,stats: Dictionary) -> void:
	if node is Skeleton3D:
		stats.bones+=node.get_bone_count()
		for i in node.get_bone_count():
			if not node.get_bone_rest(i).is_finite():errors.append("nonfinite bone rest "+node.get_bone_name(i))
	if node is MeshInstance3D and node.mesh:
		stats.meshes+=1
		if not node.mesh.get_aabb().position.is_finite() or not node.mesh.get_aabb().size.is_finite():errors.append("nonfinite mesh AABB")
	if node is AnimationPlayer:
		var root=node.get_node_or_null(node.root_node)
		for name_ in node.get_animation_list():
			var anim: Animation=node.get_animation(name_)
			stats.animations+=1
			for i in anim.get_track_count():
				var path: NodePath=anim.track_get_path(i)
				var names:=str(path).get_slice(":",0)
				var target=root.get_node_or_null(NodePath(names)) if root else null
				if target==null:errors.append("animation target missing: "+str(name_)+" / "+str(path))
				elif target is Skeleton3D and path.get_subname_count()>0 and target.find_bone(str(path.get_subname(0)))<0:errors.append("animation bone missing: "+str(path))
	for child in node.get_children():inspect_node(child,errors,stats)
func walk(dir: String) -> void:
	for name_ in DirAccess.get_files_at(dir):
		var path:=dir.path_join(name_)
		if not FileAccess.file_exists(path+".import"):continue
		print("FORENSIC_ASSET ",path)
		var resource=load(path)
		var errors: Array=[]
		var stats:={"meshes":0,"bones":0,"animations":0}
		if resource==null:errors.append("resource failed to load")
		elif resource is PackedScene:
			var root=resource.instantiate()
			if root:inspect_node(root,errors,stats);root.free()
			else:errors.append("scene could not instantiate")
		elif resource is AudioStream:
			var seconds_: float=resource.get_length()
			stats["seconds"]=seconds_
			if not is_finite(seconds_) or seconds_<=0:errors.append("invalid audio duration")
		elif resource is Texture2D:
			stats["width"]=resource.get_width();stats["height"]=resource.get_height()
			if resource.get_width()<=0 or resource.get_height()<=0:errors.append("empty texture")
		var dependencies: Array=[]
		for entry in ResourceLoader.get_dependencies(path):dependencies.append(str(entry))
		rows.append({"file":path,"class":resource.get_class() if resource else "null","errors":errors,"statistics":stats,"dependencies":dependencies})
		if not errors.is_empty():faults.append({"file":path,"errors":errors})
	for name_ in DirAccess.get_directories_at(dir):walk(dir.path_join(name_))
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):out=arg.trim_prefix("--output=")
	assert(not out.is_empty());walk("res://assets")
	var file:=FileAccess.open(out,FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"All imported assets loaded; model hierarchy, skeleton rest transforms and animation node/bone paths inspected outside scene tree; no artistic approval or gameplay test.","rows":rows,"faults":faults},"\t"));file.close()
	print("FORENSIC_ASSETS resources=",rows.size()," faults=",faults.size())
	quit(1 if not faults.is_empty() else 0)
