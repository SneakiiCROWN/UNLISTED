extends SceneTree
# Compile dynamically loaded scripts before spending time on a native route.
func _initialize() -> void:
	var failed:=0;var checked:=0
	for file in DirAccess.get_files_at("res://scripts"):
		if not file.ends_with(".gd"):continue
		checked+=1
		var resource=load("res://scripts/"+file)
		if resource==null or not resource.can_instantiate():failed+=1;printerr("PREFLIGHT FAILED ",file)
	print("SCRIPT_PREFLIGHT checked=",checked," failed=",failed)
	quit(0 if failed==0 else 1)
