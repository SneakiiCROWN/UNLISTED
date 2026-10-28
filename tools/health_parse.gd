extends SceneTree
func _initialize() -> void:
 var failed:=false
 var count:=0
 for file in DirAccess.get_files_at("res://scripts"):
  if not file.ends_with(".gd"):continue
  var script=load("res://scripts/"+file)
  var valid: bool=script!=null and script.can_instantiate()
  count+=1
  print("HEALTH_PARSE ",file," ",valid)
  if not valid:failed=true
 print("HEALTH_PARSE_TOTAL ",count)
 quit(1 if failed else 0)
