extends "res://scripts/graphics_profile_study.gd"
func apply(g: Node3D,id: String) -> Dictionary:
 var result: Dictionary=super.apply(g,id)
 if id=="original" or id=="probe":return result
 if id in ["balanced","enhanced","wet","ssr"]:
  for mesh in [g.get_node("BriarLaneExterior/ContinuousWoodlandTerrain"),g.get_node("ServiceHardstanding")]:
   var material: ShaderMaterial=mesh.material_override.duplicate();material.shader=load("res://shaders/phase2_ground.gdshader");mesh.material_override=material
  changes.append("Phase2 irregular wet unions, restored side/rear response, sheltered porch exclusion")
 if id in ["balanced","enhanced"]:
  for mesh in g.find_children("*","MeshInstance3D",true,false):
   var source: Material=mesh.material_override
   if source is ShaderMaterial and source.shader.resource_path=="res://shaders/damp_timber.gdshader":
    var damp: ShaderMaterial=source.duplicate();damp.shader=load("res://shaders/phase2_timber.gdshader");mesh.material_override=damp
   elif source is StandardMaterial3D and source.albedo_texture!=null and "Bricks097" in source.albedo_texture.resource_path:
    var brick: StandardMaterial3D=source.duplicate();brick.roughness=.76;brick.metallic_specular=.22;mesh.material_override=brick
  changes.append("Existing exposed timber and brick roughness; sheltered porch posts retained")
 if id in ["balanced","enhanced","glass"]:
  var cube_path:="res://assets/studies_phase2/lounge_return.res"
  for mesh in g.find_children("*","MeshInstance3D",true,false):
   var source: Material=mesh.material_override
   if source is ShaderMaterial and source.shader.resource_path=="res://shaders/study_window.gdshader":
    var mat:=ShaderMaterial.new();mat.shader=load("res://shaders/phase2_window.gdshader")
    mat.set_shader_parameter("motion",0.0 if g.presentation.prefs.data.reduced_motion else 1.0)
    if not runtime and ResourceLoader.exists(cube_path):mat.set_shader_parameter("room_return",load(cube_path))
    else:mat.set_shader_parameter("reflection_strength",0.0)
    if "--phase2-no-reflection" in OS.get_cmdline_user_args():mat.set_shader_parameter("reflection_strength",0.0)
    mesh.material_override=mat
  changes.append("Lower-haze glass and actual precomputed static room sampling; outside return suppressed")
 if id in ["balanced","enhanced"]:
  var weather: Node=g.get_node("BriarLaneExterior/BriarLaneWeather")
  for rain in weather.find_children("*","GPUParticles3D",true,false):
   if rain.name not in ["WindDrivenDrizzle","ForegroundRain"]:continue
   if runtime:continue # Configured before add_child in exterior_weather.
   if rain.draw_pass_1.material.shader.resource_path=="res://shaders/phase2_rain.gdshader":continue
   var quad: QuadMesh=rain.draw_pass_1.duplicate();var mat: ShaderMaterial=quad.material.duplicate()
   mat.shader=load("res://shaders/phase2_rain.gdshader");quad.material=mat;rain.draw_pass_1=quad
  changes.append("Existing roof-colliding rain receives actual scene lights; soft tapered sides")
 if id=="enhanced" and not "--phase2-no-fog" in OS.get_cmdline_user_args():
  for child in g.get_children():
   if child is WorldEnvironment:
    child.environment.volumetric_fog_enabled=true;child.environment.volumetric_fog_density=0.0
  var volume:=FogVolume.new();volume.name="Phase2OutsideGroundHaze";volume.size=Vector3(7,1.4,12)
  var material:=ShaderMaterial.new();material.shader=load("res://shaders/phase2_low_fog.gdshader");volume.material=material
  g.add_child(volume);volume.position=Vector3(0,.7,12.8)
  g.get_node("BriarLaneExterior/BriarLaneWeather/LowDriftingMist").visible=false
  changes.append("Feathered exterior-only volumetric haze; existing mist sprites disabled for comparison")
 result.changes=changes;result.generation=2;result.reflection_bake_present=ResourceLoader.exists("res://assets/studies_phase2/lounge_return.res")
 return result
