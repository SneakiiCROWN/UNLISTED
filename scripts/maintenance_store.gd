extends Node3D
# An underfloor route, optional historical evidence, and a physical sound experiment.
var game: Node3D
var rack: Node3D
var lamp: OmniLight3D
var moving:=false
var goal:=4.95
var tap_clock:=0.0
var answers: Array=[]
var surprise_armed:=false
var surprise_clock:=0.0
const TEST_NOTE:="Site 17 / underfloor inspection / S. Ward, 1998\n\nThe little passage runs beside the cellar ramp, under the records office. Dry storage at the far end. Someone has moved the shelving across the old inspection bay. The rails are still free.\n\nI disconnected the return at the terminal box. The motor stopped. I could still hear two sets of feet upstairs. One of them was mine. I hadn't left this room.\n\nI tapped a floor joist. Once, then twice. Something answered from the passage. The third time I stopped. It kept going.\n\nI'm leaving the test sheet here. Don't trust the sound of someone coming back. Check the doors. Check that you can actually see them.\n\nThe original call is still in my notebook. I haven't signed the empty-house certificate."
func _ready() -> void:
	name="UnderfloorRecordsStore";build();restore()
	var id:=game.threat.graph.get_point_count()
	game.threat.graph.add_point(id,Vector3(3.25,-3,-15.7));game.threat.graph.connect_points(id,25)
func surface(pos: Vector3,size_: Vector3,texture: String,tint: Color,solid:=false) -> MeshInstance3D:
	var result: MeshInstance3D=game.box(self,pos,size_,tint,solid)
	result.material_override=game.texture_mat(texture,tint)
	return result
func build() -> void:
	var stone:="res://assets/exterior/Concrete019_1K-JPG_Color.jpg"
	var steel:="res://assets/dusk/psx_house_steel_01.png"
	var wood:="res://assets/dusk/psx_house_old_wood_01.png"
	# One 4.7 m crawl, 1.24 m clear height, beside the existing ramp. No teleports.
	surface(Vector3(3.25,-3.09,-12.7),Vector3(1.62,.18,5.0),stone,Color("66685b"),true)
	for x in [2.44,4.06]:surface(Vector3(x,-2.34,-12.7),Vector3(.14,1.32,5),stone,Color("666a60"),true)
	surface(Vector3(3.25,-1.68,-12.7),Vector3(1.76,.16,5),stone,Color("555b52"),true)
	for z in [-14.9,-13.3,-11.7]:
		for x in [2.54,3.96]:surface(Vector3(x,-2.35,z),Vector3(.045,1.28,.08),steel,Color("484e42"))
		surface(Vector3(3.25,-1.80,z),Vector3(1.44,.05,.08),steel,Color("484e42"))
	var repair=load("res://scripts/environment_repair.gd").new();repair.g=game
	for x in [2.60,2.73]:repair.tube(Vector3(x,-1.92,-15),Vector3(x,-1.92,-10.4),.025,Color("45493d"),self)
	# Below the existing office, entirely inside the property's footprint.
	game.floor_area(2.1,6.0,-10.4,-6.3,-3)
	game.ceiling(2.1,6.0,-10.4,-6.3,-.2)
	for x in [2.1,6.0]:game.wall(Vector3(x,-3,-8.35),4.1,PI/2)
	game.wall(Vector3(4.05,-3,-6.3),3.9)
	game.wall(Vector3(2.275,-3,-10.4),.35)
	game.wall(Vector3(5.025,-3,-10.4),1.95)
	surface(Vector3(3.25,-.95,-10.4),Vector3(1.6,1.5,.18),stone,Color("606457"),true)
	for z in [-9.8,-8.65,-7.5,-6.5]:surface(Vector3(4.05,-.43,z),Vector3(3.72,.25,.13),wood,Color("6b6250"),true)
	# Rails have end stops and a grounded wheeled carriage, not a floating cabinet.
	for z in [-7.38,-6.98]:
		surface(Vector3(4.04,-2.984,z),Vector3(3.46,.032,.05),steel,Color("56594b"))
		for x in [2.34,5.74]:surface(Vector3(x,-2.95,z),Vector3(.06,.09,.10),steel,Color("444b40"))
	rack=game.model("res://assets/furniture/shelf.glb",self,Vector3(4.95,-2.91,-7.18),Vector3(1.35,1.65,.50),PI,true)
	rack.name="RollingRecordsRack"
	for x in [-.5,.5]:
		for z in [-.19,.19]:
			var wheel:=CylinderMesh.new();wheel.top_radius=.045;wheel.bottom_radius=.045;wheel.height=.025;wheel.radial_segments=10
			var mesh:=MeshInstance3D.new();mesh.mesh=wheel;mesh.material_override=game.texture_mat(steel,Color("464b41"));rack.add_child(mesh);mesh.position=Vector3(x,-.045,z);mesh.rotation.z=PI/2
	for i in 3:
		game.model("res://assets/interiors/cardboardBoxOpen.glb",rack,Vector3(-.43+i*.41,.68,0),Vector3(.34,.24,.34),0,false)
	game.model("res://assets/interiors/home/books.glb",rack,Vector3(.23,1.19,0),Vector3(.56,.25,.27))
	game.collision(rack,Vector3(0,.85,.32),Vector3(.82,.3,.1),"archive_rack")
	# The inspection sheet is pinned behind the rack, not duplicated attendance UI.
	surface(Vector3(4.95,-1.6,-6.44),Vector3(.55,.72,.018),wood,Color("635b47"))
	var page=surface(Vector3(4.95,-1.59,-6.456),Vector3(.38,.54,.004),"res://assets/original/aged_paper.png",Color("bcb294"))
	game.collision(self,Vector3(4.95,-1.59,-6.47),Vector3(.4,.56,.04),"underfloor_sheet")
	var ink=game.label3(self,"S. WARD\n\nRETURN TEST\n1998",Vector3(4.95,-1.59,-6.462),PI,14,Color("313b31"));ink.shaded=true;ink.pixel_size=.0026
	# A capped terminal box and the disconnected return lead substantiate the test note.
	game.model("res://assets/machinery/circuit_breaker.glb",self,Vector3(5.86,-1.86,-8.8),Vector3(.40,.52,.14),-PI/2)
	repair.tube(Vector3(5.85,-1.37,-8.8),Vector3(5.85,-.63,-8.8),.024,Color("5b594b"),self)
	repair.tube(Vector3(5.85,-.63,-8.8),Vector3(2.7,-.63,-8.8),.024,Color("5b594b"),self)
	game.collision(self,Vector3(3.85,-.57,-8.65),Vector3(.5,.24,.2),"test_joist")
	for x in [3.74,3.82,3.90]:surface(Vector3(x,-.56,-8.718),Vector3(.025,.035,.002),wood,Color("a39b7b"))
	game.model("res://assets/dusk/psx_prop_ceiling_lamp_01.glb",self,Vector3(4.5,-.65,-8.5),Vector3(.38,.25,.38))
	lamp=OmniLight3D.new();add_child(lamp);lamp.position=Vector3(4.5,-.8,-8.5);lamp.omni_range=5;lamp.light_color=Color("baae89");lamp.light_energy=.7;lamp.shadow_enabled=true
	# Empty storage space is a working aisle and a place to break sight, not a prop dump.
	var box_=game.model("res://assets/interiors/cardboardBoxOpen.glb",self,Vector3(2.48,-3,-8.1),Vector3(.48,.4,.48),0,true)
	load("res://scripts/interior_life.gd").new().finish_model(game,box_,true)
func inside(point: Vector3) -> bool:
	return point.y<-.8 and point.x>2.18 and point.x<5.9 and point.z>-15.2 and point.z<-6.4
func occupied(a: float,b: float) -> bool:
	var shape:=BoxShape3D.new();shape.size=Vector3(absf(a-b)+1.42,1.8,.64)
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=2|16|32
	query.transform=Transform3D(Basis.IDENTITY,Vector3((a+b)*.5,-2.05,-7.18))
	return not get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func push_rack() -> void:
	if moving:return
	goal=4.95 if game.events.get("archive_rack_open",false) else 3.15
	if occupied(rack.position.x,goal):game.message("Something is in the track.",2);return
	game.events.archive_rack_open=goal<4;moving=true
	game.sound("door",rack.position,-31).pitch_scale=.65
	game.save_game()
func read_sheet() -> void:
	if moving or not game.events.get("archive_rack_open",false):return
	game.events.underfloor_read=true
	game.inspect_text("SIMON / UNDERFLOOR TEST",TEST_NOTE);game.save_game()
func tap_joist() -> void:
	if tap_clock<.28:return
	tap_clock=0
	var cue=game.sound("prop_impact",Vector3(3.85,-.48,-8.65),-30);cue.pitch_scale=.8
	game.threat.hear(Vector3(3.85,-3,-8.65),8)
	var count:=int(game.events.get("underfloor_taps",0))+1;game.events.underfloor_taps=count
	if count<=3:
		answers.append({"left":.75 if count==1 else (.48 if count==2 else .18),"position":Vector3(3.25,-1.9,-12.8),"extra":count==3})
		if count==3:surprise_armed=true
	game.save_game()
func restore() -> void:
	goal=3.15 if game.events.get("archive_rack_open",false) else 4.95
	rack.position.x=goal;moving=false;tap_clock=1;answers.clear();surprise_armed=false;surprise_clock=0
	if game.events.get("underfloor_taps",0)>=3 and not game.events.get("underfloor_echo_complete",false):surprise_armed=true
	lamp.light_color=Color("93a8a3") if game.events.get("underfloor_echo_complete",false) else Color("baae89")
func _physics_process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	tap_clock+=delta
	game.targets.underfloor_sheet.collision_layer=1 if game.events.get("archive_rack_open",false) and not moving else 0
	if moving:
		var next:=move_toward(rack.position.x,goal,delta*.45)
		if not occupied(rack.position.x,next):rack.position.x=next
		if is_equal_approx(rack.position.x,goal):moving=false
	for i in range(answers.size()-1,-1,-1):
		answers[i].left-=delta
		if answers[i].left<=0:
			var cue=game.sound("prop_impact",answers[i].position,-33);cue.pitch_scale=.73
			game.sound_caption("A knock answers from the passage.",2,"SERVICE VOID",cue)
			if answers[i].extra:answers.append({"left":1.1,"position":Vector3(4.8,-.3,-7.6),"extra":false})
			answers.remove_at(i)
	if surprise_armed and game.events.get("underfloor_read",false) and inside(game.player.position) and not game.threat.active():
		surprise_clock+=delta
		if surprise_clock>2 and not moving:
			var center: Vector3=rack.position+Vector3.UP
			if not game.chapter.point_visible(center) and not occupied(rack.position.x,4.95):
				surprise_armed=false;game.events.underfloor_echo_complete=true
				game.events.archive_rack_open=false;goal=4.95;moving=true;lamp.light_color=Color("93a8a3")
				game.sound("door",rack.position,-32).pitch_scale=.61;game.sound("step",Vector3(4.2,-.15,-8.5),-29)
				game.save_game()
	if inside(game.player.position) and not game.events.get("service_void_visited",false):
		game.events.service_void_visited=true;game.save_game()
