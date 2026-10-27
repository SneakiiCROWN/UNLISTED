extends SceneTree
func _initialize() -> void:
 var failed:=false
 for path in ["res://scripts/graphics_study.gd","res://scripts/graphics_phase3_property.gd","res://scripts/graphics_phase3_route.gd","res://shaders/phase2_ground.gdshader"]:
  var r=load(path)
  if r==null or (r is GDScript and not r.can_instantiate()):failed=true
 print("PHASE3_TARGETED_PARSE ",not failed)
 quit(1 if failed else 0)
