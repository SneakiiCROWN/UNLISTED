extends SceneTree
func _initialize() -> void:
 var failed:=false
 for path in ["res://scripts/graphics_study.gd","res://scripts/graphics_phase2_profile.gd","res://shaders/phase2_ground.gdshader","res://shaders/phase2_window.gdshader","res://shaders/phase2_rain.gdshader","res://shaders/phase2_low_fog.gdshader","res://shaders/phase2_timber.gdshader"]:
  var resource=load(path)
  if resource==null or (resource is GDScript and not resource.can_instantiate()):failed=true
 print("PHASE2_TARGETED_PARSE ",not failed)
 quit(1 if failed else 0)
