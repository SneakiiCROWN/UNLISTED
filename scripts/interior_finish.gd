extends RefCounted
# UNTESTED house art pass. Only static render geometry/materials. Room-owned
# groups follow the existing lounge/bedroom transformation without new flags.
var g: Node3D
var root: Node3D
var batches: Dictionary={}
var materials: Dictionary={}
var placements: Array=[]
const STEEL="res://assets/dusk/psx_house_steel_01.png"
const WOOD="res://assets/dusk/psx_house_old_wood_01.png"
const CANVAS="res://assets/original/work_canvas.png"
const PAPER="res://assets/original/aged_paper.png"

func build(game: Node3D) -> void:
	g=game
	for spec in [["iron",STEEL,"41483f"],["rubber",STEEL,"242c27"],["wood",WOOD,"645847"],["paper",PAPER,"b5ab91"],["cloth",CANVAS,"747465"],["brass",STEEL,"8c8063"]]:
		var mat: StandardMaterial3D=g.texture_mat(spec[1],Color(spec[2])).duplicate()
		mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS;mat.roughness=.94
		materials[spec[0]]=mat
	lounge();office();recorder();utility();cellar();underfloor();bedroom()

func begin(parent: Node3D,id: String) -> void:
	root=Node3D.new();root.name=id;parent.add_child(root)
	root.set_meta("development_status","UNTESTED interior art / no gameplay or collision changes")
	batches={};placements=[]

func piece(id: String,pos: Vector3,size_: Vector3,material: String,angle:=0.0) -> void:
	var key:="box/"+material
	if not batches.has(key):
		var mesh:=BoxMesh.new();mesh.size=Vector3.ONE;mesh.material=materials[material]
		batches[key]={"mesh":mesh,"items":[]}
	batches[key].items.append(Transform3D(Basis(Vector3.UP,angle).scaled(size_),pos))
	placements.append({"part":id,"position":pos,"size":size_})

func tube(id: String,a: Vector3,b: Vector3,radius: float,material: String) -> void:
	var key:="tube/"+material
	if not batches.has(key):
		var mesh:=CylinderMesh.new();mesh.top_radius=1;mesh.bottom_radius=1;mesh.height=1;mesh.radial_segments=8;mesh.material=materials[material]
		batches[key]={"mesh":mesh,"items":[]}
	var basis:=Basis(Quaternion(Vector3.UP,(b-a).normalized())).scaled(Vector3(radius,a.distance_to(b),radius))
	batches[key].items.append(Transform3D(basis,(a+b)*.5))
	placements.append({"part":id,"from":a,"to":b,"radius":radius})

func finish() -> void:
	for key in batches:
		var data: Dictionary=batches[key]
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=data.mesh
		multi.instance_count=data.items.size()
		for i in data.items.size():multi.set_instance_transform(i,data.items[i])
		var node:=MultiMeshInstance3D.new();root.add_child(node);node.name=String(key).replace("/","_");node.multimesh=multi
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.set_meta("authored_placements",placements);root.set_meta("render_batches",batches.size())

func cable(points: Array,radius:=.006) -> void:
	for i in range(points.size()-1):tube("Supported equipment cable",points[i],points[i+1],radius,"rubber")

func lounge() -> void:
	begin(g.lounge_contents,"LoungeInteriorFinish")
	# A readable domestic shelf rather than another bottle row. The exact board
	# height comes from its imported triangles, not the shelf wrapper's centre.
	var shelf: Node3D=g.get_node("LoungeContents/LoungeWallShelf")
	var point:=Vector3(6.43,0,-2.70);var top: float=g.surface_height(shelf,point)
	if is_finite(top):
		var books: Node3D=g.model("res://assets/interiors/home/books.glb",root,Vector3(point.x,top+.001,point.z),Vector3(.26,.11,.18),PI/2,false)
		books.name="LoungeShelfReading";load("res://scripts/interior_life.gd").new().finish_model(g,books)
	# TV back, desk edge and wall socket describe a continuous power lead. All
	# geometry stays behind the existing table, clear of chair/door circulation.
	piece("TV wall socket",Vector3(3.53,.25,-2.896),Vector3(.11,.15,.030),"iron")
	piece("TV plug",Vector3(3.53,.25,-2.865),Vector3(.048,.055,.032),"rubber")
	cable([Vector3(3.53,.99,-2.155),Vector3(3.53,.70,-2.23),Vector3(3.53,.08,-2.79),Vector3(3.53,.25,-2.84)])
	# Reading-lamp cord follows its real base, behind the conversation furniture.
	piece("Reading lamp wall socket",Vector3(7.396,.26,3.30),Vector3(.028,.15,.11),"iron")
	cable([Vector3(6.70,.06,2.95),Vector3(6.96,.024,3.17),Vector3(7.30,.024,3.30),Vector3(7.365,.26,3.30)])
	# Table runner is already present; a closed folded envelope beside the real
	# newspaper suggests interrupted ordinary use, without inventing a new clue.
	piece("Unwritten lounge envelope",Vector3(3.94,.8015,.52),Vector3(.23,.003,.12),"paper",-.08)
	lounge_throw()
	finish()

func lounge_throw() -> void:
	# Fit a worn throw to actual sofa triangles. The normalized sofa's .95 m
	# bounding height is NOT its seat height; that shortcut produces floating cloth.
	var sofa: Node3D=g.get_node("LoungeContents/LoungeSofa/CorrectedSofaVisual")
	var xs:=[5.91,5.98,6.08,6.20,6.34,6.48,6.60]
	var zs:=[1.34,1.38,1.42,1.46,1.50,1.54]
	var points: Array[Vector3]=[]
	for z in zs:
		for x in xs:
			var y: float=g.surface_height(sofa,Vector3(maxf(x,5.97),0,z))
			if not is_finite(y):return
			if x<5.95:y-=.18
			points.append(Vector3(x,y+.008+.003*sin(x*27+z*19),z))
	var cloth:=SurfaceTool.new();cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in zs.size()-1:
		for col in xs.size()-1:
			var i:=row*xs.size()+col
			for index in [i,i+xs.size(),i+1,i+1,i+xs.size(),i+xs.size()+1]:
				cloth.set_uv(Vector2(float(index%xs.size())/(xs.size()-1),float(index/xs.size())/(zs.size()-1)))
				cloth.add_vertex(points[index])
	cloth.generate_normals()
	var mesh:=MeshInstance3D.new();mesh.name="FittedLoungeThrow";mesh.mesh=cloth.commit();root.add_child(mesh)
	var material: StandardMaterial3D=g.texture_mat(CANVAS,Color("887b60")).duplicate()
	material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.roughness=.99;mesh.material_override=material

func office() -> void:
	begin(g,"OfficeInteriorFinish")
	# Current desk tops are .80 m. Keep the active carbon mat at x=6.27 and all
	# recorder buttons/reel tray clear. Thin desk pads meet, not replace, supports.
	piece("Recorder desk blotter",Vector3(3.30,.8005,-8.53),Vector3(.91,.001,.60),"cloth")
	for x in [2.86,3.74]:piece("Blotter bound edge",Vector3(x,.8012,-8.53),Vector3(.008,.0004,.58),"cloth")
	# A pencil rests in a proper shallow tray away from the UV report sleeve.
	piece("Office pencil tray",Vector3(2.84,.807,-8.285),Vector3(.28,.014,.070),"wood")
	tube("Used pencil",Vector3(2.73,.819,-8.285),Vector3(2.95,.819,-8.285),.0035,"brass")
	# Cable loops exit through the back of each desk rather than dangling into
	# the player's knees. Existing signal/microphone cables are not duplicated.
	for p in [Vector3(4.15,2.35,-9.855)]:
		piece("Existing signal lead restraint",p,Vector3(.028,.045,.025),"iron")
	# Folded shade sides turn the existing task-light lid into a believable hood.
	for x in [6.296,6.504]:piece("Task-light folded shade",Vector3(x,1.27,-8.87),Vector3(.012,.06,.24),"iron")
	tube("Task-light hinge",Vector3(6.375,1.32,-8.96),Vector3(6.425,1.32,-8.96),.022,"brass")
	# A small closed file on the actual archive top, next to the already opened
	# box; it never covers the occupancy record or portable mug.
	piece("Pending archive folder",Vector3(3.10,1.243,-9.47),Vector3(.36,.006,.25),"paper",.04)
	for x in [2.42,3.10,3.78]:
		for z in [-9.16,-9.74]:piece("Archive cabinet floor shoe",Vector3(x,.012,z),Vector3(.52,.024,.045),"iron")
	finish()

func recorder() -> void:
	var deck: Node3D=g.get_node("ArchiveTransport")
	begin(deck,"RecorderInstrumentFinish")
	# A restrained physical VU window fits between the existing 20 cm reels.
	# The existing stopped-transport anomaly owns the brief mechanical response.
	piece("VU bezel",Vector3(0,.054,-.09),Vector3(.105,.008,.074),"iron")
	piece("VU scale backing",Vector3(0,.0585,-.09),Vector3(.089,.001,.058),"paper")
	for x in [-.032,-.016,0,.016,.032]:piece("VU scale tick",Vector3(x,.0594,-.111),Vector3(.0015,.0008,.009),"rubber")
	var needle:=Node3D.new();needle.name="ReturnMeterNeedle";deck.add_child(needle);needle.position=Vector3(0,.060,-.068)
	var pointer: MeshInstance3D=g.box(needle,Vector3(0,0,-.024),Vector3(.0018,.001,.046),Color("383e34"))
	pointer.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;needle.rotation.y=-.55
	needle.set_meta("rest_angle",-.55)
	# Capstan/pinch guide meets the existing tape path at z=.075. No new
	# button, legend or interaction zone is added to this already busy deck.
	tube("Tape guide spindle",Vector3(-.07,.052,.075),Vector3(-.07,.069,.075),.005,"brass")
	tube("Tape guide spindle",Vector3(.07,.052,.075),Vector3(.07,.069,.075),.005,"brass")
	for x in [-.28,.28]:
		for z in [-.17,.18]:piece("Recorder case fastener",Vector3(x,.052,z),Vector3(.008,.003,.008),"brass")
	finish()

func utility() -> void:
	begin(g,"UtilityInteriorFinish")
	# Existing cot rails are y=.32, mattress .34..52. Webbing stays below the
	# mattress and follows its real 1.9 m length, without changing cover/card rays.
	for z in [-6.12,-5.76,-5.40,-5.04,-4.68]:piece("Cot support webbing",Vector3(-6.8,.328,z),Vector3(.80,.012,.075),"cloth")
	for x in [-7.21,-6.39]:
		for z in [-6.18,-4.62]:piece("Cot rubber foot",Vector3(x,.015,z),Vector3(.075,.030,.075),"rubber")
	# The glass frame is only 7.5 mm off the real wall. Discreet stand-offs fill
	# that mounting gap, while the existing reflective surface/layers stay clear.
	for y in [.78,1.48]:
		for z in [-5.64,-5.06]:piece("Mirror wall stand-off",Vector3(-7.405,y,z),Vector3(.012,.065,.055),"iron")
	# Protect the wall where the existing tool loops actually rub; keep birthday
	# marks, glass, fuse, rest cot and rear door free of new papers and clutter.
	# Native review showed the continuous board visually absorbing the existing
	# ELI/1999 height marks. Keep a bare-wall gap around that evidence instead.
	piece("Utility tool-rail backing",Vector3(-7.395,1.40,-7.10),Vector3(.014,.49,.80),"wood")
	piece("Utility end-hook backing",Vector3(-7.395,1.40,-6.26),Vector3(.014,.49,.24),"wood")
	for z in [-7.30,-6.80,-6.30]:piece("Tool backing fixing",Vector3(-7.384,1.58,z),Vector3(.008,.018,.018),"brass")
	finish()

func cellar() -> void:
	begin(g,"CellarInteriorFinish")
	# The established generator bottom is -2.81, plinth top -2.82. Ten-mm
	# vibration pads bridge that exact gap; none enter the table/escape aisle.
	for x in [3.35,4.35]:
		for z in [-20.85,-19.15]:piece("Generator vibration pad",Vector3(x,-2.815,z),Vector3(.14,.010,.16),"rubber")
	# Retain all valve wheels and their readable clues. Common header already
	# exists; these mount it to the back wall instead of adding another pipe.
	for x in [-2.70,-1.50,-.30]:
		tube("Header wall stand-off",Vector3(x,-.60,-23.91),Vector3(x,-.60,-23.55),.016,"iron")
		piece("Header clamp plate",Vector3(x,-.60,-23.905),Vector3(.15,.16,.022),"iron")
	# Cable terminates at the existing control's solid upper face, never across
	# the valve labels or a route. Cleats sit immediately under the ceiling.
	cable([Vector3(.30,-.50,-22.8),Vector3(1.75,-.50,-22.8),Vector3(2.0,-.50,-23.69),Vector3(2.0,-1.11,-23.69)],.008)
	for z in [-17.0,-19.0,-21.0]:
		for x in [-.30,.30]:piece("Cable ceiling drop hanger",Vector3(x,-.31,z),Vector3(.018,.22,.035),"iron")
	finish()
	# Apply restrained damp/mineral wear only to tagged pre-existing concrete
	# wall meshes. No new wall, floor, light, collider or displacement shader.
	var damp:=ShaderMaterial.new();damp.shader=load("res://shaders/service_concrete.gdshader")
	damp.set_shader_parameter("concrete",load("res://assets/exterior/Concrete019_1K-JPG_Color.jpg"))
	damp.set_shader_parameter("roughness_map",load("res://assets/exterior/Concrete019_1K-JPG_Roughness.jpg"))
	for wall in g.get_tree().get_nodes_in_group("service_concrete_walls"):
		for mesh in g.all_meshes(wall):mesh.material_override=damp

func underfloor() -> void:
	begin(g.maintenance,"UnderfloorInteriorFinish")
	# The two existing service pipes hang 13.5 cm below the crawl roof. Join
	# them to it without lowering their already established crouch clearance.
	for z in [-14.5,-12.7,-10.9]:
		for x in [2.60,2.73]:
			tube("Crawl pipe suspension",Vector3(x,-1.895,z),Vector3(x,-1.76,z),.006,"iron")
			piece("Crawl hanger fixing",Vector3(x,-1.768,z),Vector3(.085,.016,.065),"iron")
	for y in [-1.26,-.92,-.65]:piece("Terminal conduit wall spacer",Vector3(5.893,y,-9.70),Vector3(.038,.055,.045),"iron")
	# Keep the rack travel and paper reveal entirely open. Wall-side mechanical
	# fixings are visible landmarks; there is no loose debris in the tracks.
	for x in [2.34,5.74]:
		for z in [-7.38,-6.98]:piece("Rail end-stop anchor",Vector3(x,-2.902,z),Vector3(.018,.006,.030),"brass")
	finish()

func bedroom() -> void:
	begin(g.chapter.room,"BedroomInteriorFinish")
	# A quiet reconstruction error: a repaired wallpaper strip repeats the same
	# print with its register shifted. No new name/date/photo or evidence flag.
	var original: MeshInstance3D=g.chapter.room.get_node("MemoryWallpaper")
	var strip: MeshInstance3D=g.box(root,Vector3(5.85,1.39,-2.8985),Vector3(.19,2.58,.001),Color.WHITE)
	strip.name="MisregisteredWallpaperRepair"
	var paper: StandardMaterial3D=original.material_override.duplicate();paper.uv1_offset+=Vector3(.23,0,0);strip.material_override=paper
	# The bed's outer height includes a headboard, so never use its AABB top
	# as mattress height. Dress the actual rug surface instead of floating trim.
	var rug: Node3D=g.chapter.room.get_node("RememberedRug")
	var top: float=g.surface_height(rug,Vector3(4.98,0,-.02))
	if is_finite(top):
		piece("Remembered rug repair",Vector3(4.98,top+.0006,-.02),Vector3(.12,.0012,.16),"cloth")
		for z in [-.09,.05]:piece("Repair stitch",Vector3(4.98,top+.0013,z),Vector3(.10,.0004,.002),"paper")
	# The known lamp begins .65 m above the .64 m bedside cabinet. Its pad
	# closes that measured gap without moving the drawer, evidence or light.
	piece("Bedside lamp base pad",Vector3(5.12,.645,-2.29),Vector3(.18,.010,.18),"rubber")
	piece("Remembered lamp wall socket",Vector3(5.12,.25,-2.892),Vector3(.10,.13,.022),"iron")
	cable([Vector3(5.12,.655,-2.40),Vector3(5.12,.10,-2.78),Vector3(5.12,.25,-2.866)])
	finish()
