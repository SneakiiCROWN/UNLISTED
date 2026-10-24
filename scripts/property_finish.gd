extends RefCounted
# UNTESTED property art continuation. Static render geometry only: no collisions,
# physics bodies, interaction targets, lights, save fields or frame callbacks.
var g: Node3D
var site: Node3D
var root: Node3D
var section:="Arrival"
var materials: Dictionary={}
var batches: Dictionary={}
var placements: Array=[]
const EXTERIOR="res://assets/exterior/"
const STEEL="res://assets/dusk/psx_house_steel_01.png"

func reserved_verge(p: Vector3) -> bool:
	# Only suppress existing *visual* random undergrowth in the authored pockets.
	# Called after woodland RNG/collider creation, so old trees/rocks stay exact.
	for pocket in [Rect2(-11.5,2.0,4.2,7.5),Rect2(-6.2,7.8,2.0,1.6),Rect2(4.1,8.2,3.2,6.5),Rect2(14.0,-14.4,2.8,12.0),Rect2(-23.0,-20.4,2.8,2.7),Rect2(-21.6,-16.1,1.3,4.4),Rect2(-10,18.9,8,1.5)]:
		if pocket.has_point(Vector2(p.x,p.z)):return true
	return false

func prepare(outdoor: Node3D,id: String) -> void:
	site=outdoor;g=site.game
	root=Node3D.new();root.name=id;site.add_child(root)
	root.set_meta("development_status","UNTESTED / source-only property overhaul")
	root.set_meta("collision_policy","Decoration only; all existing physical routes retained")
	for spec in [["wood",EXTERIOR+"WoodSiding006_1K-JPG_Color.jpg","58564a"],["iron",STEEL,"454e47"],["rust",STEEL,"5d5141"],["stone",EXTERIOR+"Concrete019_1K-JPG_Color.jpg","61665a"],["rubber",STEEL,"242d29"],["canvas","res://assets/original/work_canvas.png","676454"]]:
		var material: StandardMaterial3D=g.texture_mat(spec[1],Color(spec[2])).duplicate()
		material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		material.roughness=.90;materials[spec[0]]=material

func batch(kind: String,key: String,xf: Transform3D,label_: String) -> void:
	var id:=section+"/"+kind+"/"+key
	if not batches.has(id):
		var mesh: PrimitiveMesh
		if kind=="box":
			var box:=BoxMesh.new();box.size=Vector3.ONE;mesh=box
		else:
			var tube:=CylinderMesh.new();tube.top_radius=1; tube.bottom_radius=1;tube.height=1;tube.radial_segments=8;mesh=tube
		mesh.material=materials[key]
		batches[id]={"mesh":mesh,"items":[]}
	batches[id].items.append(xf)
	placements.append({"part":label_,"region":section,"position":xf.origin,"size":xf.basis.get_scale()})

func piece(label_: String,pos: Vector3,size_: Vector3,key: String,angle:=0.0) -> void:
	batch("box",key,Transform3D(Basis(Vector3.UP,angle).scaled(size_),pos),label_)

func tube(label_: String,a: Vector3,b: Vector3,radius: float,key: String) -> void:
	var basis:=Basis(Quaternion(Vector3.UP,(b-a).normalized())).scaled(Vector3(radius,a.distance_to(b),radius))
	batch("tube",key,Transform3D(basis,(a+b)*.5),label_)

func nature(id: String,p: Vector2,height: float,yaw: float,sink:=.025) -> void:
	# Reuse the exterior's normalized Quaternius meshes and shared materials.
	# Larger additions are outside the existing physical perimeter, never ghost
	# trunks in the playable property. Small verge details do not block walking.
	# Near-route stones are mostly buried texture-scale relief, not knee-high
	# obstacles without matching collision. Larger deadfall stays beyond fences.
	var burial: float=maxf(sink,height*.78) if id.begins_with("Rock") else sink
	var origin:=Vector3(p.x,site.ground_height(p.x,p.y)-burial,p.y)
	var xf:=Transform3D(Basis(Vector3.UP,yaw).scaled(Vector3.ONE*height),origin)
	for i in site.prototype(id).size():
		var part: Dictionary=site.prototype(id)[i]
		var key:=section+"/nature/"+id+str(i)
		if not batches.has(key):batches[key]={"mesh":part.mesh,"items":[]}
		batches[key].items.append(xf*part.transform)
	placements.append({"part":id,"region":section,"position":origin,"height":height})

func finish() -> void:
	# Region/material batches keep little bolts and supports from becoming
	# hundreds of independent render objects. No per-frame decoration logic.
	for key in batches:
		var data: Dictionary=batches[key]
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=data.mesh
		multi.instance_count=data.items.size()
		for i in data.items.size():multi.set_instance_transform(i,data.items[i])
		var node:=MultiMeshInstance3D.new();node.name=String(key).replace("/","_");node.multimesh=multi
		root.add_child(node)
		# Small fixtures, leaves and ground dressing need no extra shadow passes.
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.set_meta("authored_placements",placements)
	root.set_meta("render_batches",batches.size())

func build(outdoor: Node3D) -> void:
	prepare(outdoor,"PropertyFinish")
	arrival();house();woodland();shed();yard()
	finish()

func arrival() -> void:
	section="FrontApproach"
	# Gate posts remain their original colliders. Bolted shoes and end-grain
	# caps fit their existing 16 cm footprint and leave the leaf sweep untouched.
	for x in [-1.46,1.46]:
		piece("Gate post shoe",Vector3(x,.10,17),Vector3(.175,.20,.175),"iron")
		piece("Gate post cap",Vector3(x,1.419,17),Vector3(.185,.018,.185),"iron")
		for z in [16.91,17.09]:piece("Post shoe fixing",Vector3(x,.13,z),Vector3(.027,.027,.014),"rust")
	# Existing gate/fence corners, not additional fence panels or boundary walls.
	for p in [Vector2(-10,17),Vector2(10,17),Vector2(-10,5.5),Vector2(10,5.5)]:
		var y: float=site.ground_height(p.x,p.y)
		piece("Fence foot collar",Vector3(p.x,y+.035,p.y),Vector3(.19,.07,.19),"stone")
	# The car shoulder is deliberately sparse; nothing touches its collision,
	# either door side, the road centre or the gate's 3.1 m clear opening.
	for spec in [["Grass_Short",-9.4,19.5,.19,1.4],["Plant_1",-8.8,19.45,.17,.4],["Bush_2",-2.8,19.6,.30,2.3],["Grass_Short",4.8,19.7,.20,1.2],["Rock_4",10.9,19.5,.16,2.6],["Plant_1",11.3,19.7,.24,.7]]:
		nature(spec[0],Vector2(spec[1],spec[2]),spec[3],spec[4])
	for spec in [["Grass_Short",-2.5,15.4,.19,2.0],["Plant_1",-3.9,12.2,.24,.7],["Bush_1",-5.5,8.5,.39,1.8],["Rock_1",-5.1,8.2,.16,.2],["Plant_1",4.5,14.1,.25,2.9],["Grass_Short",4.9,13.9,.18,1.5],["Bush_2",6.7,9.0,.37,2.2]]:
		nature(spec[0],Vector2(spec[1],spec[2]),spec[3],spec[4])

func house() -> void:
	section="HouseEnvelope"
	# A thin damp-course/cap ties the existing brick foundation to weatherboards.
	# Match its .37 m top; do not cover any front/rear threshold openings.
	for x in [-7.52,7.52]:piece("Foundation weathering cap",Vector3(x,.379,-3),Vector3(.245,.018,14),"stone")
	for span in [Vector2(-7.5,-.85),Vector2(.85,7.5)]:
		piece("Front plinth cap",Vector3((span.x+span.y)*.5,.379,4.01),Vector3(span.y-span.x,.018,.245),"stone")
	for span in [Vector2(-7.5,-5.30),Vector2(-3.70,-.85),Vector2(.85,7.5)]:
		piece("Rear plinth cap",Vector3((span.x+span.y)*.5,.379,-10.01),Vector3(span.y-span.x,.018,.245),"stone")
	# Corner boards and sill flashings sit outside the original wall surface.
	for side in [-1,1]:
		for z in [-10.045,4.045]:piece("Weatherboard corner side",Vector3(side*7.615,1.57,z),Vector3(.060,2.35,.19),"wood")
		for z in [-10.115,4.115]:piece("Weatherboard corner return",Vector3(side*7.51,1.57,z),Vector3(.20,2.35,.055),"wood")
	# The established gutter channels stay in place; add their missing hangers.
	for x in [-7.66,7.66]:
		for z in [-9.6,-7.3,-5.0,-2.7,-.4,1.9,4.0]:
			tube("Gutter hanger",Vector3(signf(x)*7.55,2.78,z),Vector3(x,2.765,z),.009,"iron")
			piece("Gutter strap",Vector3(x,2.769,z),Vector3(.15,.010,.028),"iron")
	# Drain catch pits reuse, rather than duplicate, the existing grates/outlets.
	for x in [-7.66,7.66]:
		for side in [-1,1]:piece("Rainwater catch-pit rim",Vector3(x+side*.174,.009,4.25),Vector3(.044,.018,.43),"stone")
		for z in [4.045,4.455]:piece("Rainwater catch-pit rim",Vector3(x,.009,z),Vector3(.39,.018,.04),"stone")
	# Visible connection at the existing west-wall supply end; no new power gate.
	for z in [-4.13,-3.87]:piece("Supply entry fixing",Vector3(-7.708,2.86,z),Vector3(.014,.045,.025),"rust")
	tube("Supply drip loop",Vector3(-7.71,2.83,-4.02),Vector3(-7.73,2.68,-4.02),.012,"rubber")
	tube("Supply wall entry",Vector3(-7.73,2.68,-4.02),Vector3(-7.55,2.68,-4.02),.012,"rubber")

func woodland() -> void:
	section="WoodlandEdge"
	# Small groups frame landmarks, leaving the long west-side route visible.
	for spec in [["Bush_2",-10.7,7.0,.42,1.1],["Plant_1",-10.55,4.8,.25,2.4],["Rock_4",-10.8,3.1,.22,.8],["Grass_Short",-7.96,.3,.16,1.4],["Plant_1",-7.97,-3.4,.19,2.9],["Grass_Short",-8.0,-6.2,.17,.5],["Bush_1",-21.5,-18.7,.50,1.7],["Rock_1",-21.8,-18.4,.25,2.3],["Bush_2",14.9,-4.4,.46,2.6],["Plant_1",15.2,-4.8,.23,.8],["Grass_Short",14.8,-12.4,.21,1.1],["Bush_1",14.9,-13.2,.42,.3]]:
		nature(spec[0],Vector2(spec[1],spec[2]),spec[3],spec[4])
	# Author deadfall behind the already fenced edge. The supplied log is
	# 3.568 m long per metre of height; scales here intentionally remain small.
	nature("WoodLog",Vector2(-32.0,-19.4),.34,.65,.065)
	nature("WoodLog",Vector2(32.0,-13.4),.31,2.4,.065)
	nature("TreeStump",Vector2(-21.1,-37.9),.48,.8,.055)
	# Distant framing only, beyond the original wire perimeter. No new near-field
	# ghost trunks, procedural tree grid, collision walls or sky/fog replacement.
	for spec in [["Willow_Dead_3",-34.8,-18.5,8.2,.9],["BirchTree_Dead_1",-35.4,-7.3,7.1,2.0],["CommonTree_Dead_3",-33.5,6.0,9.0,1.3],["Willow_Dead_1",33.8,-12.1,8.4,2.3],["BirchTree_Dead_1",33.6,3.7,8.0,.4],["CommonTree_Dead_1",26.2,-40.3,9.4,1.8],["Willow_Dead_3",9.6,-39.5,10.1,2.5],["CommonTree_Dead_3",-11.4,-40.2,8.8,.3]]:
		nature(spec[0],Vector2(spec[1],spec[2]),spec[3],spec[4],.16)

func shed() -> void:
	section="ShedEnvelope"
	# environment_repair already caps the ceiling with a 6.5 m flat roof,
	# y=2.82..3.00. Dress that actual outer edge; never add a second roof.
	for z in [-17.245,-10.755]:piece("Shed roof edge flashing",Vector3(-17,3.006,z),Vector3(6.54,.045,.10),"iron")
	for x in [-20.245,-13.755]:piece("Shed roof edge flashing",Vector3(x,3.006,-14),Vector3(.10,.045,6.52),"iron")
	for z in [-17.045,-10.955]:piece("Shed corner side",Vector3(-20.115,1.52,z),Vector3(.060,2.42,.19),"wood")
	for z in [-17.115,-10.885]:piece("Shed corner return",Vector3(-20.01,1.52,z),Vector3(.20,2.42,.055),"wood")
	for z in [-17.03,-10.97]:piece("Shed plinth cap",Vector3(-17,.259,z),Vector3(6.16,.018,.245),"stone")
	piece("Shed west plinth cap",Vector3(-20.03,.259,-14),Vector3(.245,.018,6.1),"stone")
	# The original door already has complete jambs and a 2.68 m head trim.
	# A weather hood attaches above that trim, clear of the leaf and padlock.
	piece("Shed door head drip",Vector3(-13.80,2.710,-14),Vector3(.27,.045,1.74),"iron")
	piece("Door hood wall upstand",Vector3(-13.91,2.755,-14),Vector3(.02,.10,1.74),"iron")
	piece("Door hood folded edge",Vector3(-13.67,2.692,-14),Vector3(.016,.024,1.74),"iron")
	# One west-eave channel drains to a leader, remote from the shed door.
	# The older pipe at x=-19.85 is inside; it remains a separate service riser.
	piece("Shed west gutter",Vector3(-20.30,2.805,-14),Vector3(.15,.018,6.60),"iron")
	for x in [-20.37,-20.23]:piece("Shed gutter lip",Vector3(x,2.842,-14),Vector3(.012,.075,6.60),"iron")
	for z in [-17.30,-10.70]:piece("Shed gutter end cap",Vector3(-20.30,2.842,z),Vector3(.15,.075,.012),"iron")
	for z in [-16.8,-15.0,-13.2,-11.4]:tube("Shed gutter hanger",Vector3(-20.13,2.80,z),Vector3(-20.36,2.80,z),.009,"iron")
	tube("Shed rain leader",Vector3(-20.32,2.80,-16.55),Vector3(-20.32,.14,-16.55),.035,"iron")
	for y in [.50,1.55,2.50]:tube("Leader stand-off",Vector3(-20.14,y,-16.55),Vector3(-20.32,y,-16.55),.009,"iron")
	tube("Shed drain shoe",Vector3(-20.32,.14,-16.55),Vector3(-20.50,.04,-16.55),.034,"iron")
	for z in [-16.72,-16.38]:piece("Shed soakaway kerb",Vector3(-20.58,.008,z),Vector3(.50,.016,.045),"stone")
	for spec in [[-20.57,-16.62,.065],[-20.70,-16.50,.055],[-20.46,-16.48,.050]]:
		nature("Rock_4",Vector2(spec[0],spec[1]),spec[2],.7,.025)
	# Outside junction aligns with the already-built interior service box. The
	# pipe enters the wall, then the existing indoor riser takes over.
	piece("Generator wall feed junction",Vector3(-20.153,1.44,-12.35),Vector3(.09,.24,.23),"iron")
	for z in [-12.43,-12.27]:piece("Feed junction wall packer",Vector3(-20.10,1.44,z),Vector3(.020,.20,.035),"iron")
	tube("Junction through-wall sleeve",Vector3(-20.19,1.44,-12.35),Vector3(-19.81,1.44,-12.35),.018,"iron")
	tube("Buried service feed riser",Vector3(-20.21,1.32,-12.35),Vector3(-20.21,.04,-12.35),.019,"rubber")
	for y in [.35,.85,1.18]:tube("Feed conduit clip",Vector3(-20.13,y,-12.35),Vector3(-20.21,y,-12.35),.009,"iron")
	# Work already in progress: the existing movable iron fitting lies on a
	# wipe mat, with its loose gasket and fixings contained on the same bench.
	section="ShedWork"
	piece("Fitting work mat",Vector3(-17.24,.8005,-16.0),Vector3(.68,.001,.48),"canvas")
	for x in [-17.54,-16.94]:piece("Mat stitched hem",Vector3(x,.8013,-16),Vector3(.012,.0006,.46),"canvas")
	for z in [-16.18,-15.82]:piece("Mat stitched hem",Vector3(-17.24,.8013,z),Vector3(.60,.0006,.012),"canvas")
	piece("Bench fastener tray",Vector3(-18.70,.813,-16.0),Vector3(.28,.026,.23),"iron")
	for x in [-18.837,-18.563]:piece("Tray rolled edge",Vector3(x,.835,-16),Vector3(.008,.025,.23),"iron")
	for z in [-16.111,-15.889]:piece("Tray rolled edge",Vector3(-18.7,.835,z),Vector3(.28,.025,.008),"iron")
	for p in [Vector2(-18.75,-16.03),Vector2(-18.66,-15.98),Vector2(-18.72,-15.96)]:
		piece("Contained removed fastener",Vector3(p.x,.836,p.y),Vector3(.045,.018,.018),"rust",.45)
	# Backboard and clips follow the real bench/wall, below the existing note.
	piece("Bench cable restraint rail",Vector3(-18.3,1.04,-16.854),Vector3(1.1,.055,.04),"wood")
	for x in [-18.70,-17.90]:tube("Bench cable hook",Vector3(x,1.06,-16.825),Vector3(x,1.02,-16.76),.008,"iron")

func yard() -> void:
	section="ServiceYard"
	# Show where the existing low drain leads. These are flush covers/frames,
	# not new ground collision, raised steps or a pipe laid across the walkway.
	for p in [Vector2(-12.65,-15.04),Vector2(-8.0,-14.72)]:
		piece("Existing service duct cover",Vector3(p.x,.003,p.y),Vector3(.42,.006,.32),"iron")
		for offset in [-.15,.15]:piece("Duct cover fixing",Vector3(p.x+offset,.008,p.y),Vector3(.018,.006,.018),"rust")
	# A grounded masonry heel stops the existing wall-side housings looking like
	# free-standing primitives. Stay against the original fence x=-3.17.
	for z in [-13.4,-12.5]:piece("Yard equipment masonry heel",Vector3(-3.17,.025,z),Vector3(.23,.05,.54),"stone")
	for spec in [["Grass_Short",-12.3,-15.75,.18,.5],["Plant_1",-9.3,-15.78,.23,1.6],["Rock_4",-6.7,-15.85,.16,2.1],["Grass_Short",-5.1,-15.8,.18,1.3],["Plant_1",-21.0,-15.2,.27,.6],["Grass_Short",-21.0,-12.7,.18,2.8]]:
		nature(spec[0],Vector2(spec[1],spec[2]),spec[3],spec[4])

func finish_service_exit(game: Node3D,exit: Node3D) -> void:
	# Called only after the existing real incline has established its height.
	prepare(game.get_node("BriarLaneExterior"),"ServiceExitFinish")
	section="ServiceExit"
	var y: float=exit.exterior_height
	# Coping on the outside faces of the existing retaining cheeks. The clear
	# 1.78 m passage, lid, grille and .62 m landing collider are untouched.
	for z in [-9.24,-7.46]:
		piece("Service cut retaining cap",Vector3(8.72,.027,z),Vector3(5.76,.023,.20),"stone")
		for x in [6.35,8.72,11.20]:piece("Retaining wall vertical joint",Vector3(x,-1.49,z),Vector3(.018,2.90,.145),"rubber")
	# A thin frame dresses the existing landing; nothing rises above its top.
	for z in [-9.32,-7.38]:piece("Service landing edge",Vector3(11.86,y-.018,z),Vector3(.62,.024,.035),"iron")
	# No rail across the mouth, no extra screen hiding its loose-contact clue.
	for x in [11.58,12.06]:
		for z in [-9.20,-7.50]:piece("Landing frame anchor",Vector3(x,y-.003,z),Vector3(.025,.006,.025),"rust")
	finish()
