extends Node3D
# One shared outdoor world: continuous terrain, grounded woodland and a clouded sky.
var game: Node3D
var terrain_noise:=FastNoiseLite.new()
var sky_material: ShaderMaterial
var clock:=0.0
var sky_tick:=0.0
var prototypes: Dictionary={}
var woodland_materials: Dictionary={}
var batches: Dictionary={}
var instance_count:=0
var collision_prototypes: Dictionary={}
const ROOT="res://assets/exterior/"
const TREES=["Willow_Dead_1","Willow_Dead_3","CommonTree_Dead_1","CommonTree_Dead_3","BirchTree_Dead_1","PineTree_1","PineTree_3","CommonTree_1","BirchTree_3","Willow_1"]

func _ready() -> void:
	name="BriarLaneExterior"
	process_mode=Node.PROCESS_MODE_ALWAYS
	terrain_noise.seed=17017;terrain_noise.frequency=0.026
	for group in ["legacy_exterior_ground","legacy_boundary_visuals","duplicate_yard_tiles"]:
		for node in get_tree().get_nodes_in_group(group):node.visible=false
	for node in get_tree().get_nodes_in_group("bare_trees"):
		node.remove_from_group("bare_trees");node.queue_free()
	for node in get_tree().get_nodes_in_group("legacy_horizon"):node.queue_free()
	build_sky()
	build_terrain()
	cladding()
	build_woodland()
	infrastructure()
	property_fence()
	front_approach()
	arrival_car()
	load("res://scripts/property_finish.gd").new().build(self)
	var weather=load("res://scripts/exterior_weather.gd").new()
	weather.game=game;add_child(weather)
	set_meta("forest_instances",instance_count)
	set_meta("route_policy","Existing house/yard/shed grade and collisions retained; terrain excludes service descent")

func build_sky() -> void:
	for child in game.get_children():
		if child is DirectionalLight3D:child.queue_free()
	var moon:=DirectionalLight3D.new();moon.name="CloudedMoonlight"
	moon.rotation_degrees=Vector3(-36,-32,0)
	moon.light_color=Color(0.51,0.61,0.73);moon.light_energy=0.30
	moon.shadow_enabled=true;moon.directional_shadow_max_distance=55
	moon.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(moon)
	sky_material=ShaderMaterial.new();sky_material.shader=load("res://shaders/night_sky.gdshader")
	var noise:=FastNoiseLite.new();noise.seed=170001;noise.frequency=0.014
	noise.fractal_octaves=4;noise.fractal_gain=0.5
	var clouds:=NoiseTexture2D.new();clouds.width=512;clouds.height=512
	clouds.noise=noise;clouds.seamless=true;clouds.generate_mipmaps=true
	sky_material.set_shader_parameter("cloud_map",clouds)
	sky_material.set_shader_parameter("moon_direction",moon.global_basis.z)
	var sky:=Sky.new();sky.sky_material=sky_material;sky.radiance_size=Sky.RADIANCE_SIZE_64
	for child in game.get_children():
		if child is WorldEnvironment:
			var env: Environment=child.environment
			env.background_mode=Environment.BG_SKY;env.sky=sky
			env.ambient_light_color=Color(0.37,0.43,0.50);env.ambient_light_energy=0.22
			env.fog_light_color=Color(0.075,0.090,0.11);env.fog_density=0.010
			env.fog_aerial_perspective=0.25;env.fog_sky_affect=0.55

func ground_height(x: float,z: float) -> float:
	var edge:=maxf(absf(x+3)/1.1,absf(z+4)/1.05)
	var noise:=terrain_noise.get_noise_2d(x,z)
	var irregular:=terrain_noise.get_noise_2d(x+417,z-192)*4.5
	var bank:=smoothstep(23,43,edge+irregular)*(1.5+noise*0.8)
	var distant:=smoothstep(32,100,edge+irregular)*(7.0+noise*5.0)
	var micro:=0.0 if protected_property(Vector2(x,z)) else (0.10+noise*0.10)*smoothstep(7,16,edge)
	var lane_cut:=(1.0-smoothstep(2.7,5.0,absf(z-lane_z(x))))*(1.0-smoothstep(65,82,absf(x)))
	var lane_grade:=smoothstep(22,65,absf(x))*2.5
	return lerpf(-0.003+bank+distant+micro,lane_grade-0.003,lane_cut)+pow(maxf(edge-92,0),2)*0.025

func ground_material(hardstanding:=false) -> ShaderMaterial:
	var mat:=ShaderMaterial.new();mat.shader=load("res://shaders/property_ground.gdshader")
	mat.set_shader_parameter("soil_color",load(ROOT+"Ground067_1K-JPG_Color.jpg"))
	mat.set_shader_parameter("soil_normal",load(ROOT+"Ground067_1K-JPG_NormalGL.jpg"))
	mat.set_shader_parameter("concrete_color",load(ROOT+"Concrete019_1K-JPG_Color.jpg"))
	mat.set_shader_parameter("concrete_normal",load(ROOT+"Concrete019_1K-JPG_NormalGL.jpg"))
	mat.set_shader_parameter("soil_roughness",load(ROOT+"Ground067_1K-JPG_Roughness.jpg"))
	mat.set_shader_parameter("concrete_roughness",load(ROOT+"Concrete019_1K-JPG_Roughness.jpg"))
	mat.set_shader_parameter("hardstanding",hardstanding)
	return mat

func build_terrain() -> void:
	var xs: Array[float]=[];var zs: Array[float]=[]
	for i in range(-64,65):xs.append(float(i)*2);zs.append(float(i)*2)
	xs.append_array([-1.6,1.6,5.8,11.66]);zs.append_array([-15.1,-9.32,-7.38]);xs.sort();zs.sort()
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ix in xs.size()-1:
		for iz in zs.size()-1:
			var x0:=xs[ix];var x1:=xs[ix+1];var z0:=zs[iz];var z1:=zs[iz+1]
			# Exact hole through the enclosed access: no hidden plane across the ramp.
			if (x0+x1)*0.5>-1.6 and (x0+x1)*0.5<1.6 and (z0+z1)*0.5>-15.1 and (z0+z1)*0.5< -10:continue
			if (x0+x1)*.5>5.8 and (x0+x1)*.5<11.66 and (z0+z1)*.5>-9.32 and (z0+z1)*.5<-7.38:continue
			var points:=[Vector3(x0,ground_height(x0,z0),z0),Vector3(x0,ground_height(x0,z1),z1),Vector3(x1,ground_height(x1,z1),z1),Vector3(x1,ground_height(x1,z0),z0)]
			for index in [0,2,1,0,3,2]:st.set_uv(Vector2(points[index].x,points[index].z)/2.8);st.add_vertex(points[index])
	st.generate_normals();st.index()
	var mesh:=MeshInstance3D.new();mesh.name="ContinuousWoodlandTerrain";mesh.mesh=st.commit()
	mesh.material_override=ground_material();add_child(mesh)
	mesh.create_trimesh_collision()
	set_meta("terrain_bounds",256);set_meta("service_ramp_hole",Rect2(-1.6,-15.1,3.2,5.1))
	var pad: MeshInstance3D=game.get_node("ServiceHardstanding")
	pad.material_override=ground_material(true)

func cladding() -> void:
	var boards: StandardMaterial3D=game.texture_mat(ROOT+"WoodSiding006_1K-JPG_Color.jpg",Color(0.54,0.59,0.57))
	boards.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	boards.uv1_scale=Vector3.ONE*0.55;boards.roughness=0.94
	boards.normal_enabled=true;boards.normal_texture=load(ROOT+"WoodSiding006_1K-JPG_NormalGL.jpg");boards.normal_scale=0.25
	boards.roughness_texture=load(ROOT+"WoodSiding006_1K-JPG_Roughness.jpg")
	for child in game.get_children():
		if child.get_meta("exterior_wall",false):
			for mesh in game.all_meshes(child):mesh.material_override=boards
	var bricks: StandardMaterial3D=game.texture_mat(ROOT+"Bricks097_1K-JPG_Color.jpg",Color(0.48,0.50,0.46))
	bricks.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	bricks.uv1_scale=Vector3.ONE*0.65
	bricks.normal_enabled=true;bricks.normal_texture=load(ROOT+"Bricks097_1K-JPG_NormalGL.jpg");bricks.normal_scale=0.35
	bricks.roughness_texture=load(ROOT+"Bricks097_1K-JPG_Roughness.jpg")
	for x in [-7.52,7.52]:foundation(Vector3(x,0.16,-3),Vector3(0.22,0.42,14),bricks)
	for pair in [[-7.5,-0.85],[0.85,7.5]]:foundation(Vector3((pair[0]+pair[1])/2,0.16,4.01),Vector3(pair[1]-pair[0],0.42,0.22),bricks)
	for pair in [[-7.5,-5.30],[-3.70,-0.85],[0.85,7.5]]:foundation(Vector3((pair[0]+pair[1])/2,0.16,-10.01),Vector3(pair[1]-pair[0],0.42,0.22),bricks)
	for z in [-17.03,-10.97]:foundation(Vector3(-17,0.10,z),Vector3(6.16,0.30,0.22),bricks)
	foundation(Vector3(-20.03,0.10,-14),Vector3(0.22,0.30,6.1),bricks)
	for pair in [[-17,-14.85],[-13.15,-11]]:foundation(Vector3(-13.97,0.10,(pair[0]+pair[1])/2),Vector3(0.22,0.30,pair[1]-pair[0]),bricks)

func foundation(pos: Vector3,size_: Vector3,mat: Material) -> void:
	var mesh: MeshInstance3D=game.box(self,pos,size_,Color.WHITE)
	mesh.name="GroundedFoundationCourse";mesh.material_override=mat

func parts(node: Node,transform_: Transform3D,result: Array) -> void:
	var xf:=transform_
	if node is Node3D:xf=transform_*node.transform
	if node is MeshInstance3D:result.append({"mesh":node.mesh,"transform":xf})
	for child in node.get_children():parts(child,xf,result)

func prototype(id: String) -> Array:
	if prototypes.has(id):return prototypes[id]
	var scene: Node3D=load(ROOT+id+".glb").instantiate()
	var result: Array=[];parts(scene,Transform3D.IDENTITY,result);scene.free()
	for item in result:
		var mesh: ArrayMesh=item.mesh.duplicate()
		for i in mesh.get_surface_count():
			var old: Material=mesh.surface_get_material(i)
			var tint:=Color(0.17,0.135,0.105)
			if old is BaseMaterial3D:tint=old.albedo_color
			var key:=tint.to_html()+str(id.begins_with("Rock") or id in ["WoodLog","TreeStump"])
			if not woodland_materials.has(key):
				var mat:=ShaderMaterial.new();mat.shader=load("res://shaders/woodland.gdshader")
				mat.set_shader_parameter("tint",tint)
				mat.set_shader_parameter("sway",0.0 if id.begins_with("Rock") or id in ["WoodLog","TreeStump"] else 1.0)
				woodland_materials[key]=mat
			mesh.surface_set_material(i,woodland_materials[key])
		item.mesh=mesh
	prototypes[id]=result
	return result

func place(id: String,pos: Vector3,height: float,yaw: float,rng: RandomNumberGenerator) -> void:
	var key:=id+"/"+str(floori(pos.x/64))+"/"+str(floori(pos.z/64))
	if not batches.has(key):batches[key]={"id":id,"items":[]}
	var tree:=id in TREES
	var xf:=Transform3D(Basis(Vector3.UP,yaw).scaled(Vector3(height*0.70,height,height*0.70) if tree else Vector3.ONE*height),pos)
	batches[key].items.append({"transform":xf,"color":Color.WHITE*(rng.randf_range(0.86,1.10))})
	instance_count+=1
	if absf(pos.x)<34 and pos.z>-38 and pos.z<34 and (tree or id.begins_with("Rock") or id in ["WoodLog","TreeStump"]):
		grounded_model_collision(id,xf)

func protected_property(p: Vector2) -> bool:
	if p.x>5.7 and p.x<12.7 and p.y>-10 and p.y<-6.5:return true
	if p.x>-8.1 and p.x<8.1 and p.y>-10.6 and p.y<4.8:return true
	if p.x>-22.0 and p.x< -2.5 and p.y>-19.0 and p.y< -9.5:return true
	if absf(p.x)<3.2 and p.y>3.8 and p.y<24:return true
	if absf(p.y-lane_z(p.x))<4.7:return true
	return false

func build_woodland() -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=1701998
	for x in range(-17,18):
		for z in range(-17,18):
			var p:=Vector2(x*6+rng.randf_range(-2,2),z*6+rng.randf_range(-2,2))
			if protected_property(p) or maxf(absf(p.x+3)/1.1,absf(p.y+4)/1.05)<22 or p.length()>112 or rng.randf()<0.32:continue
			var id: String=TREES[rng.randi_range(0,TREES.size()-1)]
			if rng.randf()<0.45:id=TREES[rng.randi_range(7,9)]
			if id.begins_with("Pine") and p.length()<48:id=TREES[rng.randi_range(0,4)]
			place(id,Vector3(p.x,ground_height(p.x,p.y)-0.12,p.y),rng.randf_range(7.5,14.5),rng.randf()*TAU,rng)
	for spec in [[-11,7,9.0],[-13,3,10.5],[11,6,9.5],[12,-5,11.0],[-23,-20,9.3],[-24,-9,9.5],[-6,-25,10.2],[-25,1,9.5]]:
		var p:=Vector2(spec[0],spec[1]);var id: String=TREES[rng.randi_range(0,4)]
		if p.x==-13 or p.x==12 or p.x==-23:id="CommonTree_1"
		place(id,Vector3(p.x,ground_height(p.x,p.y)-0.07,p.y),spec[2],rng.randf()*TAU,rng)
	for i in 460:
		var p:=Vector2(rng.randf_range(-32,27),rng.randf_range(-31,23))
		if protected_property(p):continue
		var id: String=["Grass_Short","Bush_1","Bush_2","Plant_1"][i%4]
		place(id,Vector3(p.x,ground_height(p.x,p.y)-0.035,p.y),rng.randf_range(0.15,0.35) if i%4 in [0,3] else rng.randf_range(0.3,0.65),rng.randf()*TAU,rng)
	for spec in [[-24,-22,1.8],[-23,-8,1.2],[13,8,1.4],[-9,13,1.1],[18,-8,2.0],[-5,-28,1.6]]:
		place("Rock_1" if rng.randf()<0.5 else "Rock_4",Vector3(spec[0],ground_height(spec[0],spec[1])-0.18,spec[1]),spec[2],rng.randf()*TAU,rng)
	place("WoodLog",Vector3(-23,ground_height(-23,-4)-0.07,-4),0.5,0.7,rng)
	place("TreeStump",Vector3(-10,ground_height(-10,10)-0.04,10),0.55,1.2,rng)
	# Cull only decorative random grass/bushes inside the new authored pockets.
	# Keep all RNG consumption, tree/rock placements and collision creation above
	# unchanged. A source-only art pass must not silently reseed physical terrain.
	var detail=load("res://scripts/property_finish.gd").new()
	for key in batches:
		var batch: Dictionary=batches[key]
		var visible_items: Array=batch.items
		if batch.id in ["Grass_Short","Bush_1","Bush_2","Plant_1"]:
			visible_items=visible_items.filter(func(entry):return not detail.reserved_verge(entry.transform.origin))
		for item in prototype(batch.id):
			var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_colors=true;multi.mesh=item.mesh
			multi.instance_count=visible_items.size()
			for i in visible_items.size():
				multi.set_instance_transform(i,visible_items[i].transform*item.transform)
				multi.set_instance_color(i,visible_items[i].color)
			var visible_batch:=MultiMeshInstance3D.new();visible_batch.multimesh=multi;visible_batch.name="Woodland_"+batch.id
			visible_batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			add_child(visible_batch)
	set_meta("forest_batches",batches.size())

func tube(a: Vector3,b: Vector3,radius: float,mat: Material) -> void:
	var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=a.distance_to(b);mesh.radial_segments=8
	var node:=MeshInstance3D.new();node.mesh=mesh;node.material_override=mat;add_child(node)
	node.position=(a+b)*0.5;node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())

func infrastructure() -> void:
	var metal: StandardMaterial3D=game.mat(Color("303b3c"))
	for x in [-7.66,7.66]:
		tube(Vector3(x,2.76,4.15),Vector3(x,0.10,4.15),0.045,metal)
		game.box(self,Vector3(x,0.006,4.25),Vector3(0.30,0.012,0.35),Color("242c2b"))
		# Complete the existing downpipes. Open channels follow the actual
		# pitched-roof eaves, rather than leaving pipes ending in mid-air.
		var bottom: MeshInstance3D=game.box(self,Vector3(x,2.775,-3),Vector3(.14,.018,14.8),Color.WHITE)
		bottom.name="RoofRainwaterChannel";bottom.material_override=metal
		for edge in [-.065,.065]:
			var lip: MeshInstance3D=game.box(self,Vector3(x+edge,2.811,-3),Vector3(.012,.065,14.8),Color.WHITE)
			lip.material_override=metal
		for z in [-10.4,4.4]:
			var cap: MeshInstance3D=game.box(self,Vector3(x,2.811,z),Vector3(.14,.065,.012),Color.WHITE);cap.material_override=metal
		for y in [.60,1.60,2.50]:
			var anchor:=Vector3(signf(x)*7.56,y,4.105)
			game.box(self,anchor,Vector3(.10,.05,.035),Color("3d4540"))
			tube(anchor,Vector3(x,y,4.15),.008,metal)
		tube(Vector3(x,.10,4.15),Vector3(x,.045,4.25),.04,metal)
		for i in 5:game.box(self,Vector3(x-.115+i*.0575,.015,4.25),Vector3(.018,.009,.29),Color("545d52"))
	var wood: StandardMaterial3D=game.texture_mat(ROOT+"WoodSiding006_1K-JPG_Color.jpg",Color("555047"))
	tube(Vector3(-12,-0.10,5.5),Vector3(-12,6.3,5.5),0.115,wood)
	game.box(self,Vector3(-12,5.95,5.5),Vector3(1.2,0.12,0.14),Color("3b3b33"))
	for offset in [-0.42,0.42]:
		tube(Vector3(-12+offset,5.99,5.5),Vector3(-12+offset,6.15,5.5),0.05,metal)
		var a:=Vector3(-12+offset,6.15,5.5);var b:=Vector3(-7.64,2.91,-4.0+offset*0.25)
		for i in 10:
			var t0:=float(i)/10;var t1:=float(i+1)/10
			tube(a.lerp(b,t0)-Vector3.UP*sin(t0*PI)*0.6,a.lerp(b,t1)-Vector3.UP*sin(t1*PI)*0.6,0.012,game.mat(Color("171d1c")))
	game.box(self,Vector3(-7.64,2.86,-4),Vector3(0.12,0.2,0.45),Color("343d3b"))
	# Ground-level drain at the low side of the maintained service pad.
	for i in 9:game.box(self,Vector3(-11.6+float(i)*0.10,0.009,-15.05),Vector3(0.035,0.018,0.28),Color("3b4240"))

func property_fence() -> void:
	var wood: StandardMaterial3D=game.texture_mat(ROOT+"WoodSiding006_1K-JPG_Color.jpg",Color("343b35"))
	var wire:=ImmediateMesh.new();wire.surface_begin(Mesh.PRIMITIVE_LINES)
	for ends in [[Vector2(-31.2,-36.5),Vector2(-31.2,28.5)],[Vector2(31.2,-36.5),Vector2(31.2,28.5)],[Vector2(-31.2,-36.5),Vector2(31.2,-36.5)]]:
		var a: Vector2=ends[0];var b: Vector2=ends[1]
		var count:=ceili(a.distance_to(b)/3.0)
		for i in range(count+1):
			var p:=a.lerp(b,float(i)/count);var h:=ground_height(p.x,p.y)
			if absf(p.y-lane_z(p.x))>=4.7:tube(Vector3(p.x,h-0.10,p.y),Vector3(p.x,h+1.65,p.y),0.045,wood)
			if i==count:continue
			var q:=a.lerp(b,float(i+1)/count);var hq:=ground_height(q.x,q.y)
			if absf(((p+q)*0.5).y-lane_z(((p+q)*0.5).x))<4.7:continue
			for height in [0.35,0.72,1.08,1.46]:
				wire.surface_add_vertex(Vector3(p.x,h+height,p.y));wire.surface_add_vertex(Vector3(q.x,hq+height,q.y))
			var delta:=q-p
			var body: StaticBody3D=game.collision(self,Vector3((p.x+q.x)/2,(h+hq)/2+0.8,(p.y+q.y)/2),Vector3(delta.length()+0.02,1.6+absf(h-hq),0.04))
			body.rotation.y=-atan2(delta.y,delta.x);body.name="PropertyWireFence"
	wire.surface_end()
	var node:=MeshInstance3D.new();node.mesh=wire;node.material_override=game.mat(Color("444d49"));add_child(node)
	node.name="VisiblePropertyWire"

func _process(delta: float) -> void:
	if not is_instance_valid(game.presentation):return
	if game.menu_open and game.started and game.presentation.section not in ["title","ending","intro"]:return
	clock+=delta;sky_tick+=delta
	if sky_tick>1.5:
		sky_tick=0;sky_material.set_shader_parameter("cloud_drift",Vector2(clock*0.0015,clock*0.0005))

func lane_z(x: float) -> float:
	return 23.0+0.006*x*x

func grounded_model_collision(id: String,xf: Transform3D) -> void:
	# Static surface geometry follows the actual model, including leaning trunks.
	# No oversized invisible convex hull around empty branches or beside a rock.
	if not collision_prototypes.has(id):
		var faces:=PackedVector3Array()
		for item in prototype(id):
			for vertex in item.mesh.get_faces():faces.append(item.transform*vertex)
		var shape:=ConcavePolygonShape3D.new();shape.set_faces(faces)
		collision_prototypes[id]=shape
	var body:=StaticBody3D.new();body.name="Grounded_"+id
	var collision:=CollisionShape3D.new();collision.shape=collision_prototypes[id]
	body.add_child(collision);add_child(body);body.transform=xf

func approach_fence(a: Vector2,b: Vector2) -> void:
	var count:=ceili(a.distance_to(b)/1.8)
	var wood: Material=game.texture_mat(ROOT+"WoodSiding006_1K-JPG_Color.jpg",Color("55544a"))
	for i in range(count+1):
		var p:=a.lerp(b,float(i)/count);var h:=ground_height(p.x,p.y)
		var post: MeshInstance3D=game.box(self,Vector3(p.x,h+0.63,p.y),Vector3(0.11,1.38,0.11),Color.WHITE,true)
		post.material_override=wood;post.name="GardenFencePost"
		if i==count:continue
		var q:=a.lerp(b,float(i+1)/count);var hq:=ground_height(q.x,q.y)
		var delta:=q-p
		for level in [0.38,0.94]:
			var rail: MeshInstance3D=game.box(self,Vector3((p.x+q.x)/2,(h+hq)/2+level,(p.y+q.y)/2),Vector3(delta.length()+0.04,0.105,0.065),Color.WHITE)
			rail.material_override=wood;rail.rotation.y=-atan2(delta.y,delta.x)
		var body: StaticBody3D=game.collision(self,Vector3((p.x+q.x)/2,(h+hq)/2+0.55,(p.y+q.y)/2),Vector3(delta.length(),1.1,0.07))
		body.rotation.y=-atan2(delta.y,delta.x);body.name="VisibleGardenFence"

func front_approach() -> void:
	# A small front garden connects the short porch to a real, curving country lane.
	# There is no closed invisible barrier at the old spawn point.
	approach_fence(Vector2(-10,5.5),Vector2(-10,17))
	approach_fence(Vector2(10,5.5),Vector2(10,17))
	approach_fence(Vector2(-10,17),Vector2(-1.48,17))
	approach_fence(Vector2(1.48,17),Vector2(10,17))
	var gate:=Node3D.new();gate.set_script(game.DOOR);gate.name="FrontGardenGate"
	gate.game=game;gate.door_id="front_gate";gate.clear_half_width=1.55
	add_child(gate);gate.position=Vector3(0,0,17)
	var wood: Material=game.texture_mat(ROOT+"WoodSiding006_1K-JPG_Color.jpg",Color("686459"))
	for x in [-1.46,1.46]:
		var post: MeshInstance3D=game.box(gate,Vector3(x,0.67,0),Vector3(0.16,1.48,0.16),Color.WHITE,true)
		post.material_override=wood
	gate.pivot=Node3D.new();gate.add_child(gate.pivot);gate.pivot.position.x=-1.35
	for x in [0.07,0.71,1.35,1.99,2.63]:
		var slat: MeshInstance3D=game.box(gate.pivot,Vector3(x,0.66,0),Vector3(0.105,1.13,0.065),Color.WHITE)
		slat.material_override=wood
	for y in [0.30,0.99]:
		var rail: MeshInstance3D=game.box(gate.pivot,Vector3(1.35,y,0),Vector3(2.70,0.12,0.085),Color.WHITE)
		rail.material_override=wood
	var brace: MeshInstance3D=game.box(gate.pivot,Vector3(1.35,0.65,-0.06),Vector3(2.62,0.075,0.055),Color.WHITE)
	brace.rotation.z=0.27;brace.material_override=wood
	for y in [0.30,0.99]:game.box(gate.pivot,Vector3(0.13,y,0.065),Vector3(0.28,0.055,0.018),Color("343938"))
	game.box(gate.pivot,Vector3(2.61,0.99,0.085),Vector3(0.20,0.045,0.07),Color("343938"))
	var leaf: StaticBody3D=game.collision(gate.pivot,Vector3(1.35,0.65,0),Vector3(2.70,1.18,0.10),"front_gate")
	leaf.name="GardenGateLeaf";game.doors.front_gate=gate
	# Low verge posts communicate the lane edge without an artificial wall.
	for x in [-26,-18,-10,10,18,26]:
		var z:=lane_z(x)+2.7;var h:=ground_height(x,z)
		var post: MeshInstance3D=game.box(self,Vector3(x,h+0.35,z),Vector3(0.10,0.75,0.10),Color("55584e"),true)
		post.rotation.z=0.05 if x<0 else -0.03
	set_meta("front_approach","Openable saved garden gate; continuous footpath and curved lane; no spawn backstop")

func arrival_car() -> void:
	# Eli parked along the near verge, leaving the gate and both lane directions open.
	var car: Node3D=load("res://assets/exterior/arrival/eli_station_wagon.glb" if "--original-wagon" in OS.get_cmdline_user_args() and game.qa_mode else "res://assets/production_20261025/eli_sedan.glb").instantiate()
	car.name="EliArrivalCar";add_child(car)
	car.position=Vector3(-5.6,ground_height(-5.6,21.6)-.015,21.6)
	car.rotation.y=PI/2-.067
	car.set_meta("usable_interior",not ("--original-wagon" in OS.get_cmdline_user_args() and game.qa_mode))
	var headlight_materials: Array=[]
	var faces:=PackedVector3Array()
	for mesh in game.all_meshes(car):
		for v in mesh.mesh.get_faces():faces.append(car.global_transform.affine_inverse()*mesh.global_transform*v)
		for i in mesh.mesh.get_surface_count():
			var source: Material=mesh.get_active_material(i)
			if source is StandardMaterial3D:
				var wet: StandardMaterial3D=source.duplicate();wet.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;wet.roughness=.43;wet.metallic=.12
				if wet.emission_enabled:headlight_materials.append(wet);wet.emission_enabled=false
				mesh.set_surface_override_material(i,wet)
	var body:=StaticBody3D.new();body.name="FittedBodyCollision";car.add_child(body)
	var shape:=ConcavePolygonShape3D.new();shape.set_faces(faces)
	var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
	car.set_meta("headlight_materials",headlight_materials)
	car.set_meta("purpose","Eli's parked arrival vehicle; no new quest or departure condition")
