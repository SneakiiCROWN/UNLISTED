extends RefCounted
# Non-colliding finish work around existing supports. No doors, route nodes,
# puzzle flags, light levels or room-memory layers are replaced here.
var g: Node3D
var repair: RefCounted
const STEEL="res://assets/dusk/psx_house_steel_01.png"
const WOOD="res://assets/dusk/psx_house_old_wood_01.png"
const STONE="res://assets/exterior/Concrete019_1K-JPG_Color.jpg"

func piece(parent: Node3D,id: String,pos: Vector3,size_: Vector3,texture: String,tint: Color) -> MeshInstance3D:
	var mesh: MeshInstance3D=g.box(parent,pos,size_,tint)
	mesh.name=id;mesh.material_override=g.texture_mat(texture,tint)
	return mesh

func build(game: Node3D) -> void:
	g=game;repair=load("res://scripts/environment_repair.gd").new();repair.g=g
	office();kitchen();lounge();utility();cellar();shed()

func office() -> void:
	var deck: Node3D=g.get_node("ArchiveTransport")
	# Deck underside is y=.81, desk top .80; rubber feet span the gap.
	for x in [-.24,.24]:
		for z in [-.14,.14]:piece(deck,"RecorderFoot",Vector3(x,-.055,z),Vector3(.06,.01,.05),STEEL,Color("252a25"))
	# The historical reel rests beside the mechanism, not on an unsupported wing.
	piece(deck,"ReelSideTray",Vector3(-.34,.027,-.04),Vector3(.24,.05,.26),STEEL,Color("434a40"))
	for z in [-.13,.06]:piece(deck,"TrayFoot",Vector3(-.40,-.029,z),Vector3(.055,.062,.05),STEEL,Color("252a25"))
	for x in [-.455,-.225]:piece(deck,"TrayRolledEdge",Vector3(x,.057,-.04),Vector3(.009,.010,.26),STEEL,Color("626756"))
	# Reinforce the sheet board against the real wall; clips stay on its face.
	for x in [4.83,5.57]:
		for y in [1.61,2.08]:piece(g,"SurveyBoardFixing",Vector3(x,y,-9.824),Vector3(.012,.012,.009),STEEL,Color("77745f"))
	# The radio's .81 m base also sits just above the .80 m desk.
	# Tiny feet avoid changing its tuned dial, target or saved pose.
	for x in [4.75,5.01]:piece(g,"ReceiverFoot",Vector3(x,.805,-8.56),Vector3(.045,.01,.12),STEEL,Color("282e26"))
	# The ledgers already stand on the .675 / 1.225 m boards. Support their
	# row ends without adding more books or changing the rack's collision proxy.
	for top in [.675,1.225]:
		for z in [-6.59,-5.09]:
			piece(g,"LedgerBookendFoot",Vector3(6.99,top+.005,z),Vector3(.24,.01,.10),STEEL,Color("464d40"))
			piece(g,"LedgerBookend",Vector3(6.99,top+.11,z),Vector3(.24,.20,.016),STEEL,Color("5b6050"))

func kitchen() -> void:
	# Front glazing is x=-5.59..-4.01, y=1.0..2.4. Keep it open:
	# tile only the two solid piers and the low strip below its sill.
	var material: StandardMaterial3D=g.texture_mat("res://assets/dusk/psx_house_kitchen_tiles_01.png",Color("b5b6a7")).duplicate()
	material.uv1_scale=Vector3.ONE;material.roughness=.86
	for span in [Vector2(-6.30,-5.62),Vector2(-3.98,-3.30)]:
		var width: float=span.y-span.x;var x: float=(span.x+span.y)*.5
		var tiles: MeshInstance3D=piece(g,"KitchenSplashbackPier",Vector3(x,1.16,3.900),Vector3(width,.60,.035),WOOD,Color.WHITE)
		tiles.material_override=material
		piece(g,"SplashbackTopTrim",Vector3(x,1.465,3.88),Vector3(width,.018,.022),STEEL,Color("5a6051"))
	var low: MeshInstance3D=piece(g,"KitchenSillTileBand",Vector3(-4.80,.92,3.900),Vector3(3.0,.12,.035),WOOD,Color.WHITE)
	low.material_override=material

func lounge() -> void:
	var shelf: Node3D=g.get_node("LoungeContents/LoungeWallShelf")
	# Imported bracket rear at z=-2.84; interior wall face is z=-2.91.
	# These packers fill that mounting gap, and travel with the remembered room.
	for x in [5.46,6.54]:
		var backer: MeshInstance3D=piece(g.lounge_contents,"ShelfWallPacker",Vector3(x,1.48,-2.875),Vector3(.09,.60,.07),WOOD,Color("514e3d"))
		backer.set_meta("supported_shelf",shelf.name)
		for y in [1.25,1.72]:piece(g.lounge_contents,"ShelfAnchor",Vector3(x,y,-2.831),Vector3(.014,.014,.014),STEEL,Color("77715c"))

func cellar() -> void:
	# Existing pools of light finally have fixtures at the actual ceiling plane.
	# Keep their established energy/range and every authored blackout untouched.
	for z in [-18,-22]:
		var shade: Node3D=g.model("res://assets/dusk/psx_prop_ceiling_lamp_01.glb",g,Vector3(0,-.40,z),Vector3(.38,.20,.38))
		shade.name="CellarPracticalHousing"
	# Flush corner piers add structural rhythm without changing the walkable shell.
	for x in [-4.87,4.87]:
		for z in [-23.80,-15.22]:piece(g,"CellarWallPier",Vector3(x,-1.60,z),Vector3(.08,2.8,.18),STONE,Color("555b50"))
	# The existing three pipes now meet a common header and floor penetrations.
	repair.tube(Vector3(-2.7,-.60,-23.5),Vector3(4.55,-.60,-23.5),.065,Color("50554a"))
	for x in [-2.7,-1.5,-.3]:
		repair.tube(Vector3(x,-2.99,-23.5),Vector3(x,-2.90,-23.5),.075,Color("50554a"))
		piece(g,"PipeFloorFlange",Vector3(x,-2.984,-23.5),Vector3(.24,.032,.24),STEEL,Color("3d453b"))
		for offset in [-.09,.09]:piece(g,"FlangeBolt",Vector3(x+offset,-2.962,-23.5),Vector3(.018,.014,.018),STEEL,Color("797561"))
	# Cable clips follow the existing overhead service run, not the player's aisle.
	for z in [-17,-19,-21,-23]:
		for x in [-.3,.3]:piece(g,"OverheadCableClip",Vector3(x,-.44,z),Vector3(.075,.035,.06),STEEL,Color("74715e"))
	# Backing spacers join the existing wall box to the west wall lining.
	for z in [-16.90,-16.70]:piece(g,"CellarBoxWallSpacer",Vector3(-4.895,-1.79,z),Vector3(.03,.32,.035),STEEL,Color("424b40"))

func utility() -> void:
	# The cable coils already exist. Short hooks join them to their peg rail.
	for z in [-7.3,-6.8,-6.3]:
		repair.tube(Vector3(-7.28,1.58,z),Vector3(-7.23,1.53,z),.009,Color("72715f"))

func shed() -> void:
	var box_: Node3D=g.model("res://assets/machinery/circuit_breaker.glb",g,Vector3(-19.82,1.25,-12.35),Vector3(.26,.38,.12),PI/2)
	box_.name="ShedGeneratorServiceBox"
	for mesh in g.all_meshes(box_):mesh.material_override=g.texture_mat(STEEL,Color("545b4d"))
	for y in [1.31,1.56]:piece(g,"ShedBoxMount",Vector3(-19.895,y,-12.35),Vector3(.03,.05,.19),STEEL,Color("424b40"))
	# Short conduit meets the generator flank; the upper branch follows the wall.
	repair.tube(Vector3(-19.80,1.25,-12.35),Vector3(-19.80,.95,-12.35),.012,Color("30392f"))
	repair.tube(Vector3(-19.80,1.63,-12.35),Vector3(-19.80,2.55,-12.35),.015,Color("555b4b"))
	repair.tube(Vector3(-19.80,2.55,-12.35),Vector3(-19.80,2.55,-15.95),.015,Color("555b4b"))
	for z in [-12.35,-14.0,-15.95]:piece(g,"ShedConduitClip",Vector3(-19.86,2.55,z),Vector3(.10,.04,.05),STEEL,Color("72715c"))
	# Terminate on the bench's existing work-light circuit rather than in empty air.
	repair.tube(Vector3(-19.80,2.55,-15.95),Vector3(-18,2.55,-15.95),.012,Color("30392f"))
	repair.tube(Vector3(-18,2.55,-15.95),Vector3(-18,2.55,-14),.012,Color("30392f"))
	repair.tube(Vector3(-18,2.55,-14),Vector3(-17,2.55,-14),.012,Color("30392f"))
	repair.tube(Vector3(-17,2.55,-14),Vector3(-17,2.64,-14),.012,Color("30392f"))
