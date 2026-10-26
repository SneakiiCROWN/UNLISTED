extends SceneTree
# Isolated editor/headless resource parsing only. Never instantiates game scenes
# or writes owner settings. Shader loads here are not GPU compilation evidence.
var out:=""
var rows: Array=[]
var failed:=false
var version: Dictionary
func _initialize() -> void:call_deferred("run")
func walk(dir: String) -> void:
	for name in DirAccess.get_files_at(dir):
		var path:=dir.path_join(name)
		if path.get_extension() not in ["gd","tscn","tres","gdshader"]:continue
		# Never recompile the currently executing audit script or force-reload
		# shared script bases under live bytecode. Load each dependency normally.
		if path==get_script().resource_path:continue
		print("FORENSIC_PARSE_FILE ",path)
		var resource=ResourceLoader.load(path)
		var ok:=resource!=null
		if resource is GDScript:ok=resource.can_instantiate()
		rows.append({"file":path,"loaded":ok,"class":resource.get_class() if resource else "null"})
		if not ok:failed=true
		flush_report()
	for name in DirAccess.get_directories_at(dir):walk(dir.path_join(name))
func run() -> void:
	version=Engine.get_version_info()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):out=arg.trim_prefix("--output=")
	assert(not out.is_empty())
	for folder in ["scripts","scenes","themes","shaders","tools"]:walk("res://"+folder)
	flush_report()
	print("FORENSIC_PARSE files=",rows.size()," failed=",failed)
	quit(1 if failed else 0)
func flush_report() -> void:
	var file:=FileAccess.open(out,FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"Local GDScript/scene/theme/shader resource parsing without scene instantiation. Audit runner excluded. No native GPU/shader or ordinary gameplay proof.","rows":rows,"failed":failed,"version":version},"\t"));file.close()
