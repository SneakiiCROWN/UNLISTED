extends "res://scripts/property_finish.gd"
# Opt-in Phase3 property composition. Normal startup never constructs this.
func views() -> Array:
 return [
  ["E01_gate_arrival",Vector3(0,.04,19.4),Vector3(0,1.8,3.5)],
  ["E02_porch_outward",Vector3(1.2,.04,6.4),Vector3(-2,2.4,23)],
  ["E03_kitchen_woodland",Vector3(-6.35,.04,1),Vector3(-17,2.4,1)],
  ["E04_office_woodland",Vector3(5.8,.04,-8.6),Vector3(18,2.0,-8.5)],
  ["E05_rear_exit",Vector3(-5.2,.04,-12.2),Vector3(-4.5,1.7,-9.7)],
  ["E06_yard_shed",Vector3(-11,.04,-12.5),Vector3(-17,1.6,-14)],
  ["E07_shed_perimeter",Vector3(-21,.04,-17.8),Vector3(-16,1.8,-14)],
  ["E08_rear_woodland",Vector3(-12,.04,-17.8),Vector3(-12,3.8,-29)],
  ["E09_east_foundation",Vector3(10,.04,0),Vector3(7,1.7,-4)],
  ["E10_car_departure",Vector3(-2.8,.04,19.5),Vector3(-6,1.25,21.5)]
 ]
func relief(x: float,z: float) -> float:
 # Exact route planes and service openings retain their grade. Low garden beds
 # and woodland undulations are real mesh/collision, not a displacement shader.
 var lane_clear: float=lerpf(smoothstep(4.7,6.2,absf(z-site.lane_z(x))),1.0,smoothstep(76,84,absf(x)))
 var garden:=0.0
 if z>7.5 and z<16.4:
  garden=.17*exp(-pow((absf(x)-5.6)/1.8,4)-pow((z-11.6)/4.1,4))
 var edge: float=maxf(absf(x),absf(z+3))
 var outer: float=smoothstep(25,44,edge)*(.25+.45*site.terrain_noise.get_noise_2d(x*2.3+95,z*2.3))
 # Remove the old steep square bowl rim beyond the fence. A broad rolling
 # woodland floor extends to 256 m instead; the clouded horizon stays open.
 var distant: float=4.0+site.terrain_noise.get_noise_2d(x*1.4+310,z*1.4-91)*3.0+sin(x*.041+z*.023)*.9
 outer=lerpf(outer,distant-site.ground_height(x,z),smoothstep(42,74,edge))
 var fence_clear: float=lerpf(smoothstep(.5,3.5,minf(absf(absf(x)-31.2),absf(z+36.5))),1.0,smoothstep(38,44,edge))
 if edge<38 and site.protected_property(Vector2(x,z)):outer=0.0
 return (garden+outer*fence_clear)*lane_clear

func height(x: float,z: float) -> float:
 return site.ground_height(x,z)+relief(x,z)

func terrain() -> void:
 var xs: Array[float]=[];var zs: Array[float]=[]
 for i in range(-64,65):xs.append(float(i)*2);zs.append(float(i)*2)
 for i in range(-33,34,2):xs.append(float(i));zs.append(float(i))
 xs.append_array([-256.0,-224.0,-192.0,-160.0,160.0,192.0,224.0,256.0]);zs.append_array([-256.0,-224.0,-192.0,-160.0,160.0,192.0,224.0,256.0])
 xs.append_array([-1.6,1.6,5.8,11.66]);zs.append_array([-15.1,-9.32,-7.38]);xs.sort();zs.sort()
 var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for ix in xs.size()-1:
  for iz in zs.size()-1:
   var x: float=(xs[ix]+xs[ix+1])*.5;var z: float=(zs[iz]+zs[iz+1])*.5
   if x>-1.6 and x<1.6 and z>-15.1 and z<-10:continue
   if x>5.8 and x<11.66 and z>-9.32 and z<-7.38:continue
   var points: Array[Vector3]=[]
   for pair in [Vector2(xs[ix],zs[iz]),Vector2(xs[ix],zs[iz+1]),Vector2(xs[ix+1],zs[iz+1]),Vector2(xs[ix+1],zs[iz])]:
    points.append(Vector3(pair.x,height(pair.x,pair.y),pair.y))
   for index in [0,2,1,0,3,2]:st.set_uv(Vector2(points[index].x,points[index].z)/2.8);st.add_vertex(points[index])
 st.generate_normals();st.index()
 var mesh: MeshInstance3D=site.get_node("ContinuousWoodlandTerrain");mesh.mesh=st.commit()
 for child in mesh.get_children():
  if child is StaticBody3D:child.collision_layer=0;child.queue_free()
 mesh.create_trimesh_collision()
 # Existing woodland parts and matching physical trunks move by the same grade.
 for node in site.find_children("*","MultiMeshInstance3D",true,false):
  var mm: MultiMesh=node.multimesh.duplicate();node.multimesh=mm
  for i in mm.instance_count:
   var xf:=mm.get_instance_transform(i);xf.origin.y+=relief(xf.origin.x,xf.origin.z);mm.set_instance_transform(i,xf)
 for node in site.get_children():
  if node is StaticBody3D and String(node.name).begins_with("Grounded_"):node.position.y+=relief(node.position.x,node.position.z)

func grounded_nature(id: String,p: Vector2,h: float,yaw: float) -> void:
 # Authored additions remain low and permeable inside the garden; full trunks
 # only beyond the existing boundary, where the player cannot enter.
 var xf:=Transform3D(Basis(Vector3.UP,yaw).scaled(Vector3.ONE*h),Vector3(p.x,height(p.x,p.y)-.035,p.y))
 if h>2.0:site.grounded_model_collision(id,xf)
 for i in site.prototype(id).size():
  var part: Dictionary=site.prototype(id)[i];var key:=section+"/nature/"+id+str(i)
  if not batches.has(key):batches[key]={"mesh":part.mesh,"items":[]}
  batches[key].items.append(xf*part.transform)
 placements.append({"part":id,"region":section,"position":xf.origin,"height":h})

func plant_edges() -> void:
 # Replace coarse cyan block crowns with connected twig/leaf sprays already
 # used by the approved woodland. No change to any physical tree or obstacle.
 for node in site.find_children("*","MultiMeshInstance3D",true,false):
  if "Bush_" in String(node.name):node.visible=false
 section="GardenBeds"
 var rng:=RandomNumberGenerator.new();rng.seed=170327
 for side in [-1,1]:
  for i in 12:
   var z: float=8.1+i*.65;var x: float=side*(5.5+sin(i*1.83)*1.1)
   var p:=Vector2(x,z)
   grounded_nature("CommonTree_1" if i%3 else "BirchTree_3",p,rng.randf_range(.48,.95),rng.randf()*TAU)
   for k in 4:
    var q:=p+Vector2(rng.randf_range(-.55,.55),rng.randf_range(-.35,.35))
    grounded_nature("Grass_Short",q,rng.randf_range(.15,.30),rng.randf()*TAU)
 section="WoodlandMiddleLayer"
 for spec in [[-15,7,3.2],[-16,12,4.1],[-12,18,2.8],[15,13,3.4],[17,5,3.8],[19,-3,4.6],[-26,-21,3.9],[-25,-4,3.6],[-17,-27,3.6],[-6,-27,4.3],[6,-29,3.1],[23,-24,4.1]]:
  # Slim multi-stem saplings with no new trunk across the established routes.
  var p:=Vector2(spec[0],spec[1]);grounded_nature("BirchTree_3",p,spec[2],rng.randf()*TAU)
  # Tiny vegetation stays outside circulation; no chest-high ghost obstruction.
  for k in 5:grounded_nature("Grass_Short",p+Vector2(rng.randf_range(-.6,.6),rng.randf_range(-.6,.6)),rng.randf_range(.2,.36),rng.randf()*TAU)
 section="DistantBrokenCanopy"
 for spec in [[-38,18,11],[-42,4,12],[-40,-10,9],[-34,-30,10],[-22,-43,12],[-7,-46,10],[12,-43,13],[29,-41,11],[39,-24,12],[42,-8,10],[38,10,12]]:
  grounded_nature("CommonTree_Dead_3" if int(spec[0])%2 else "Willow_Dead_3",Vector2(spec[0],spec[1]),spec[2],rng.randf()*TAU)

func building_contacts() -> void:
 section="FoundationDrainage"
 # Low, buried aggregate follows existing downpipe outlets and exposed plinths,
 # not a continuous decorative kerb or another slab around the property.
 var rng:=RandomNumberGenerator.new();rng.seed=170328
 for side in [-1,1]:
  for i in 27:
   var z: float=-9.5+i*.50;var x: float=side*(7.80+rng.randf_range(-.03,.10))
   nature("Rock_4",Vector2(x,z),rng.randf_range(.04,.075),rng.randf()*TAU,.04)
 for i in 18:
  nature("Rock_4",Vector2(-20.23+rng.randf_range(-.04,.03),-16.8+i*.32),rng.randf_range(.04,.065),rng.randf()*TAU,.03)
 # Interrupted maintenance: a supported pair of offcuts at the closed west
 # fence, beside the existing supply pole; no new objective or fake evidence.
 for i in 2:piece("Stored weathered fence offcut",Vector3(-10.30,.04+i*.055,6.2),Vector3(.13,.065,1.5),"wood",.18+i*.05)

func apply(game: Node3D) -> Dictionary:
 prepare(game.get_node("BriarLaneExterior"),"Phase3LivingProperty")
 terrain();plant_edges();building_contacts();finish()
 for mesh in [site.get_node("ContinuousWoodlandTerrain"),g.get_node("ServiceHardstanding")]:
  if mesh.material_override is ShaderMaterial and mesh.material_override.shader.resource_path=="res://shaders/phase2_ground.gdshader":mesh.material_override.set_shader_parameter("property_detail",true)
 # A baked room can lie about changed power/furniture. Until production state
 # gating is reviewed, Phase3 keeps clear glass but suppresses its static return.
 for mesh in g.find_children("*","MeshInstance3D",true,false):
  if mesh.material_override is ShaderMaterial and mesh.material_override.shader.resource_path=="res://shaders/phase2_window.gdshader":mesh.material_override.set_shader_parameter("reflection_strength",0.0)
 return {"scope":"Opt-in property composition, real terrain/collision and unchanged protected-route grade","render_batches":batches.size(),"placements":placements.size(),"static_room_return":"disabled to avoid misleading changed-room imagery","new_trunks":"matched mesh collisions outside established routes"}
