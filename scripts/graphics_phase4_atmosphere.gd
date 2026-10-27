extends "res://scripts/property_finish.gd"
# Refines the preserved landscape only when the explicit Phase4 QA flag is used.
var replaced:=0
var solid_replacements:=0
func conifers() -> void:
 var terrain_policy=load("res://scripts/graphics_phase3_property.gd").new();terrain_policy.site=site
 # Keep every established tree location/scale. Replace solid tiered crowns with
 # the existing connected branch/leaf meshes; do not scatter another forest.
 for node in site.get_children():
  if node is MultiMeshInstance3D and (String(node.name).begins_with("Woodland_PineTree_")):node.visible=false
  if node is StaticBody3D and String(node.name).begins_with("Grounded_PineTree_"):
   node.collision_layer=0;node.queue_free()
 for key in site.batches:
  var data: Dictionary=site.batches[key]
  if not data.id in ["PineTree_1","PineTree_3"]:continue
  section="BrokenCanopy_"+str(key).replace("/","_")
  for entry in data.items:
   var xf: Transform3D=entry.transform
   xf.origin.y+=terrain_policy.relief(xf.origin.x,xf.origin.z)
   var id: String=["Willow_Dead_3","BirchTree_Dead_1","CommonTree_1"][replaced%3]
   for i in site.prototype(id).size():
    var part: Dictionary=site.prototype(id)[i];var batch_id:=section+"/"+id+str(i)
    if not batches.has(batch_id):batches[batch_id]={"mesh":part.mesh,"items":[]}
    batches[batch_id].items.append(xf*part.transform)
   if absf(xf.origin.x)<34 and xf.origin.z>-38 and xf.origin.z<34:
    site.grounded_model_collision(id,xf);solid_replacements+=1
   replaced+=1

func rock_surfaces() -> int:
 var count:=0
 # Retain all rock geometry and collision. Replace the flat cyan palette with
 # the already licensed grain texture, so wet stone belongs to the same soil.
 var material: StandardMaterial3D=g.texture_mat(EXTERIOR+"Concrete019_1K-JPG_Color.jpg",Color("5b574c")).duplicate()
 material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
 material.uv1_triplanar=true;material.uv1_world_triplanar=true;material.uv1_scale=Vector3.ONE*1.8
 material.roughness=.91;material.metallic_specular=.14
 for node in site.find_children("*","MultiMeshInstance3D",true,false):
  if "Rock_" in String(node.name):node.material_override=material;count+=1
 return count

func apply(game: Node3D,id: String) -> Dictionary:
 prepare(game.get_node("BriarLaneExterior"),"Phase4FinalAtmosphere")
 conifers();finish()
 # Unlike small fixtures in property_finish, full-height replacement trees
 # retain the original woodland's cast shadows. No extra light/shadow atlas.
 for node in root.get_children():
  if node is MultiMeshInstance3D:node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
 var rocks:=rock_surfaces()
 if id in ["balanced","enhanced"]:
  for mesh in g.find_children("*","MeshInstance3D",true,false):
   if mesh.material_override is ShaderMaterial:
    var mat: ShaderMaterial=mesh.material_override
    if mat.shader.resource_path=="res://shaders/phase2_timber.gdshader":mat.set_shader_parameter("diffuse_lift",1.32)
    elif mat.shader.resource_path=="res://shaders/phase2_ground.gdshader":mat.set_shader_parameter("surface_restraint",1.0)
  var moon: DirectionalLight3D=site.get_node("CloudedMoonlight");moon.light_energy=.34
  for child in g.get_children():
   if child is OmniLight3D and child.position.distance_to(Vector3(0,2.5,5))<.15:child.light_energy=.96
 return {"scope":"Opt-in Phase4: existing placements and collision footprint retained; no new lights or story state","replaced_conifers":replaced,"matched_near_colliders":solid_replacements,"rock_render_batches":rocks,"added_render_batches":batches.size(),"timber_lift":1.32 if id in ["balanced","enhanced"] else 1.0,"puddle_roughness":.32 if id in ["balanced","enhanced"] else null,"reflection_fallback":"Phase3 clear glass; no static room return or ReflectionProbe"}
