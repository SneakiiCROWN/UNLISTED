extends SceneTree
func _initialize() -> void:
 var failed:=false
 for path in ["res://scripts/graphics_study.gd","res://scripts/exterior_weather.gd","res://scripts/graphics_phase2_profile.gd","res://scripts/graphics_phase4_atmosphere.gd","res://scripts/graphics_phase4_route.gd","res://shaders/phase2_ground.gdshader","res://shaders/phase2_timber.gdshader"]:
  var r=load(path)
  if r==null or (r is GDScript and not r.can_instantiate()):failed=true
 print("PHASE4_TARGETED_PARSE ",not failed)
 quit(1 if failed else 0)
