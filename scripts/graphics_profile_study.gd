extends RefCounted
# Runtime integration permits only the two reviewed profiles, at startup.
var runtime := false
var probes: Array[ReflectionProbe]=[]
var changes: Array=[]
func apply(g: Node3D,id: String) -> Dictionary:
 assert((runtime and id in ["balanced","enhanced"]) or (g.qa_mode and "--graphics-study-qa" in OS.get_cmdline_user_args()))
 var env: Environment
 for child in g.get_children():
  if child is WorldEnvironment:env=child.environment
 assert(env!=null)
 var wet:=id in ["wet","balanced","enhanced","ssr"]
 var lights:=id in ["balanced","enhanced","lights"]
 var reflection:=id=="probe" # Kept as a separate rejected-for-now teardown study.
 var glass:=id in ["balanced","enhanced","glass"]
 if wet:
  for mesh in [g.get_node("BriarLaneExterior/ContinuousWoodlandTerrain"),g.get_node("ServiceHardstanding")]:
   var material: ShaderMaterial=mesh.material_override.duplicate()
   material.shader=load("res://shaders/study_property_ground.gdshader");mesh.material_override=material
  changes.append("Existing terrain materials: three irregular bounded wet pools; dry porch retained; no geometry/collision")
 if lights:
  for child in g.get_children():
   if not child is OmniLight3D:continue
   if child.position.distance_to(Vector3(0,2.5,5))<.15:
    child.light_energy=1.05;child.omni_range=7.2;child.omni_attenuation=1.15
    child.shadow_bias=.025;child.shadow_normal_bias=.6;child.light_size=.10
    changes.append("Existing porch practical redistributed, contact bias reduced")
   elif child.position.y<0 and child.position.z< -17:
    child.shadow_bias=.03;child.shadow_normal_bias=.55;child.light_size=.075
    if not runtime:child.light_energy=1.0 if child.position.z> -20 else 1.15
    # Powered gameplay lamps retain their narrative-controlled energy.
    changes.append("Existing cellar practical falloff/contact, no extra lamps")
 if reflection:
  for spec in [["PorchStudyProbe",Vector3(0,1.7,9),Vector3(21,7,24),false],["LoungeStudyProbe",Vector3(5,1.4,1),Vector3(6,3,6),true]]:
   var probe:=ReflectionProbe.new();probe.name=spec[0];probe.size=spec[2];probe.interior=spec[3]
   probe.box_projection=true;probe.ambient_mode=ReflectionProbe.AMBIENT_DISABLED
   probe.cull_mask=1;probe.enable_shadows=true;probe.intensity=.7
   probe.update_mode=ReflectionProbe.UPDATE_ONCE;g.add_child(probe);probe.position=spec[1];probes.append(probe)
  changes.append("Two bounded static probes, no live reflection cameras or added ambient")
 if glass:
  var count:=0
  var original: Material=g.materials.get("closed_window_glass")
  for mesh in g.find_children("*","MeshInstance3D",true,false):
   if original!=null and mesh.material_override==original:
    var material:=ShaderMaterial.new();material.shader=load("res://shaders/study_window.gdshader")
    mesh.material_override=material;count+=1
  changes.append("Existing window surfaces: edge grime/thin rain trails, alpha centre .055; narrative mirror untouched; count="+str(count))
 if id in ["enhanced","ssr"]:
  env.ssr_enabled=true;env.ssr_max_steps=48;env.ssr_depth_tolerance=.15
 if id in ["enhanced","ao"]:
  env.ssao_enabled=true;env.ssao_radius=.38;env.ssao_intensity=.65;env.ssao_power=1.1;env.ssao_light_affect=.15
 if id=="ssil":
  env.ssil_enabled=true;env.ssil_radius=2.0;env.ssil_intensity=.25
 return {"profile":id,"changes":changes,"ssr":env.ssr_enabled,"ssao":env.ssao_enabled,"ssil":env.ssil_enabled,"ambient_energy":env.ambient_light_energy,"fog_density":env.fog_density,"tonemap":env.tonemap_mode}
