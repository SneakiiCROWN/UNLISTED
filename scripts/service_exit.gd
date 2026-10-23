extends Node3D
# A real return route and an observable false departure, not another ending gate.
var game: Node3D
var slope: Node3D
var grille: Node3D
var receipt: Node3D
var pilot: OmniLight3D
var length_: float
var rise: float
var angle: float
var exterior_height: float
var elapsed:=0.0
var resumed:=false
var printing:=0.0
var obstruction_announced:=false
const START:=Vector3(5.95,-3,-8.35)
const END_X:=11.50
const SPAWN:=Vector3(2.4,-2.99,-18.3)
const TITLE:="THE OTHER WAY OUT"
const PAPER:="SERVICE EXIT / CONTACT TEST / TONIGHT\nWARD, ELI / OUT\n\nThe grille was open, but I hadn't gone through it. Its contact wire was hanging loose.\n\nI went back down. This was waiting in Dad's terminal box.\n\nIf it can write me out while I'm still inside, his EMPTY entry proves nothing. I'm keeping this with his report."
const EARLY_PAPER:="SERVICE EXIT / CONTACT TEST / TONIGHT\nWARD, ELI / OUT\n\nThe grille was open, but I hadn't gone through it. Its contact wire was hanging loose.\n\nThat strip says I've left. I was still under the house when it printed. The wire isn't even connected. I'm keeping it."
func _ready() -> void:
	name="ServiceExit";build();restore()
	for id in game.physical.props:
		var body: RigidBody3D=game.physical.props[id]
		body.body_entered.connect(func(other):strike(body,id,other))
func surface(parent: Node3D,pos: Vector3,size_: Vector3,texture: String,tint: Color,solid:=false) -> MeshInstance3D:
	var mesh: MeshInstance3D=game.box(parent,pos,size_,tint,solid)
	mesh.material_override=game.texture_mat(texture,tint);return mesh
func build() -> void:
	exterior_height=game.get_node("BriarLaneExterior").ground_height(END_X,-8.35)+.008
	rise=exterior_height-START.y;angle=atan2(rise,END_X-START.x);length_=Vector2(END_X-START.x,rise).length()
	slope=Node3D.new();add_child(slope);slope.position=START;slope.rotation.z=angle
	var stone:="res://assets/exterior/Concrete019_1K-JPG_Color.jpg"
	var steel:="res://assets/dusk/psx_house_steel_01.png"
	# A lined service incline under a low bulkhead, rather than a bare outdoor ramp.
	surface(slope,Vector3(length_*.5,-.09,0),Vector3(length_+.20,.18,1.78),stone,Color("535d58"),true)
	for z in [-.82,.82]:surface(slope,Vector3((length_+.90)*.5,.71,z),Vector3(length_-.72,1.60,.16),stone,Color("666b61"),true)
	for z in [-9.17,-7.53]:surface(self,Vector3(6.40,-2.0,z),Vector3(1.0,2.0,.16),stone,Color("666b61"),true)
	# Trim the sloped lid at the vertical room wall. Its normal otherwise projects
	# 70 cm into the records aisle and silently blocks a standing player's return.
	surface(slope,Vector3((length_+.90)*.5,1.45,0),Vector3(length_-.70,.16,1.94),steel,Color("414b46"),true)
	for x in [.95,1.5,2.8,4.1,5.4,length_-.12]:
		for z in [-.72,.72]:surface(slope,Vector3(x,.71,z),Vector3(.065,1.36,.04),steel,Color("343e36"))
		surface(slope,Vector3(x,1.34,0),Vector3(.065,.05,1.44),steel,Color("343e36"))
	# The threshold meets the surveyed terrain. Side cheeks close the cut soil edges.
	for z in [-9.24,-7.46]:
		surface(self,Vector3(8.72,-1.56,z),Vector3(5.76,3.15,.14),stone,Color("4d584e"),true)
	surface(self,Vector3(11.86,exterior_height-.07,-8.35),Vector3(.62,.14,1.94),stone,Color("535d58"),true)
	# The lower opening is capped at crawl height; there is no invisible upper gap.
	surface(self,Vector3(6.0,-.8,-8.35),Vector3(.20,1.2,1.5),stone,Color("575f54"),true)
	grille=Node3D.new();slope.add_child(grille);grille.position=Vector3(length_+.02,0,-.70)
	for y in [.07,1.27]:surface(grille,Vector3(0,y,.70),Vector3(.07,.09,1.40),steel,Color("555e52"))
	for z in [.04,.35,.70,1.05,1.36]:surface(grille,Vector3(0,.67,z),Vector3(.055,1.25,.045),steel,Color("555e52"))
	game.collision(grille,Vector3(0,.67,.70),Vector3(.08,1.34,1.4),"exit_grille")
	game.collision(grille,Vector3(-.09,.62,1.22),Vector3(.19,.18,.17),"exit_catch")
	surface(grille,Vector3(-.07,.62,1.22),Vector3(.14,.06,.14),steel,Color("8a8064"))
	game.collision(grille,Vector3(.14,.65,1.16),Vector3(.16,.24,.18),"exit_outer_handle")
	surface(grille,Vector3(.10,.65,1.16),Vector3(.12,.18,.04),steel,Color("8a8064"))
	# The severed contact and its conduit are visible at the actual threshold.
	var repair=load("res://scripts/environment_repair.gd").new();repair.g=game
	repair.tube(slope.to_global(Vector3(length_-.12,.93,-.73)),slope.to_global(Vector3(length_-.5,.86,-.73)),.012,Color("8b7655"),self)
	repair.tube(slope.to_global(Vector3(length_-.64,.69,-.73)),slope.to_global(Vector3(1.3,.69,-.73)),.012,Color("8b7655"),self)
	# Reuse the existing underfloor terminal instead of duplicating equipment or
	# making the player move the records rack again to reach another paper.
	repair.tube(slope.to_global(Vector3(1.3,.69,-.73)),Vector3(5.85,-1.65,-9.7),.012,Color("8b7655"),self)
	game.label3(self,"EXIT CONTACT\nRETURN DISCONNECTED",Vector3(5.77,-1.58,-9.7),-PI/2,13,Color("b7b79c")).pixel_size=.0013
	surface(self,Vector3(5.785,-1.58,-9.7),Vector3(.015,.18,.36),steel,Color("343d34"))
	game.collision(self,Vector3(5.765,-1.69,-9.7),Vector3(.045,.22,.38),"exit_terminal")
	receipt=Node3D.new();add_child(receipt);receipt.position=Vector3(5.775,-1.91,-9.7);receipt.rotation.y=-PI/2
	surface(receipt,Vector3.ZERO,Vector3(.22,.30,.006),"res://assets/original/aged_paper.png",Color("c5bea6"))
	game.label3(receipt,"WARD, ELI\nOUT / TONIGHT",Vector3(0,0,.007),0,13,Color("343b30")).pixel_size=.0013
	game.collision(receipt,Vector3.ZERO,Vector3(.24,.32,.025),"exit_receipt")
	pilot=OmniLight3D.new();add_child(pilot);pilot.position=Vector3(6.20,-1.6,-8.35);pilot.light_color=Color("a9b9ad");pilot.light_energy=.30;pilot.omni_range=4;pilot.shadow_enabled=true
func strike(body: RigidBody3D,id: String,other: Node) -> void:
	if not game.started or game.menu_open or game.physical.held==body:return
	if other!=game.targets.exit_catch and other!=game.targets.exit_grille:return
	if body.mass*float(game.physical.last_speed.get(id,0))<1.6:return
	release_catch()
func release_catch() -> void:
	if game.events.get("exit_catch_free",false):return
	game.events.exit_catch_free=true;game.sound("latch",game.targets.exit_catch.global_position,-27);game.save_game(true)
func in_passage(p: Vector3) -> bool:
	var local: Vector3=slope.to_local(p)
	return local.x>-.2 and local.x<length_+.4 and absf(local.z)<.75 and local.y<1.4
func use(id: String) -> void:
	if id=="exit_terminal":
		if game.events.get("exit_false_departure",false) and not game.events.get("exit_receipt_read",false):use("exit_receipt");return
		var text_: String="The cable runs to the grille at the top of the service passage. The return wire is disconnected."
		if game.stage<3:text_+=" There is no supply here."
		elif game.events.get("exit_receipt_read",false):text_+=" It printed my departure before I went through. The strip is in my field notes."
		else:text_+=" The feed is live. This box used to record the exit contact; it shouldn't receive anything with that wire loose."
		game.inspect_text("SERVICE EXIT / CONTACT RECORDER",text_);return
	if id=="exit_receipt":
		if not game.events.get("exit_false_departure",false) or game.events.get("exit_receipt_read",false):return
		game.events.exit_receipt_read=true;game.events.exit_blackout_pending=true
		game.inspect_text(TITLE,PAPER if game.report_read else EARLY_PAPER);game.save_game(true);sync();return
	if id=="exit_outer_handle":release_catch()
	if not game.events.get("exit_catch_free",false):game.message("Rust has bound the catch. It needs a sharp knock.",2.5);return
	obstruction_announced=false
	game.events.exit_open=not game.events.get("exit_open",false)
	game.sound("door",grille.global_position,-28)
	# A falsifiable observation: opening from outside never awards this discovery.
	game.events.exit_test_armed=game.events.exit_open and in_passage(game.player.position) and game.player.position.x<END_X-.5
	game.save_game(true)
func move_grille(next: float) -> void:
	var before: float=grille.rotation.y;grille.rotation.y=next
	var body: StaticBody3D=game.targets.exit_grille
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=body.get_child(0).shape
	query.transform=body.global_transform;query.collision_mask=2|16|32;query.margin=.015
	if not get_world_3d().direct_space_state.intersect_shape(query).is_empty():
		grille.rotation.y=before
		if not obstruction_announced:game.message("Something is catching the grille.",1.8);obstruction_announced=true
func sync() -> void:
	receipt.visible=game.events.get("exit_false_departure",false) and not game.events.get("exit_receipt_read",false)
	receipt.scale.y=maxf(.04,printing)
	game.targets.exit_receipt.collision_layer=1 if receipt.visible and printing>=1 else 0
func restore() -> void:
	grille.rotation.y=float(game.events.get("exit_angle",1.65 if game.events.get("exit_open",false) else 0.0))
	printing=1 if game.events.get("exit_false_departure",false) else 0
	elapsed=0;resumed=game.events.get("exit_blackout_running",false)
	sync()
	# A pre-expansion outdoor save must not place a standing capsule in the bulkhead.
	var p: Vector3=game.player.position
	if not game.events.has("exit_version") and p.x>7.7 and p.x<END_X+.15 and absf(p.z+8.35)<1.15 and p.y>-.20 and p.y<1.7:
		game.player.position.z=-6.95;game.player.velocity=Vector3.ZERO
	game.events.exit_version=1
func blocked() -> bool:
	return game.threat.active() or game.horror.beat!="" or game.horror.audition!="" or game.chapter.active or game.recount.active or not game.dead_line.sequence.is_empty() or game.maintenance.surprise_armed or game.events.get("witness_echo_pending",false)
func start_blackout() -> bool:
	if blocked() or not game.threat.enabled:return false
	if (not resumed and not game.maintenance.inside(game.player.position)) or game.player.position.distance_to(SPAWN)<4:return false
	if game.chapter.point_visible(SPAWN+Vector3.UP*1.6):return false
	if not game.events.get("exit_blackout_running",false):
		game.events.exit_prior_resolved=game.events.get("threat_resolved",false)
		game.events.exit_prior_pending=game.events.get("threat_pending",false)
		game.events.exit_prior_origin=game.events.get("threat_origin","")
		game.events.exit_prior_spawn=game.events.get("threat_spawn",[]).duplicate()
	game.events.exit_blackout_pending=false;game.events.exit_blackout_running=true;elapsed=0;resumed=false
	game.events.threat_pending=true;game.events.threat_resolved=false;game.events.threat_origin="service_exit";game.events.threat_spawn=[SPAWN.x,SPAWN.y,SPAWN.z]
	game.threat.begin(false,SPAWN);game.threat.last_known=Vector3(3.25,-3,-15.7)
	game.sound("latch",game.maintenance.lamp.global_position,-31);game.save_game(true);return true
func finish_blackout() -> void:
	resumed=false
	game.events.exit_blackout_running=false;game.events.exit_blackout_done=true;game.events.exit_blackout_pending=false
	game.events.threat_resolved=game.events.get("exit_prior_resolved",false)
	game.events.threat_pending=game.events.get("exit_prior_pending",false)
	game.events.threat_origin=game.events.get("exit_prior_origin","")
	game.events.threat_spawn=game.events.get("exit_prior_spawn",[]).duplicate()
	game.save_game(true)
func _physics_process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	var target: float=1.65 if game.events.get("exit_open",false) else 0.0
	# Stop on contact rather than sweep a returning player or a dropped object.
	if absf(grille.rotation.y-target)>.001:move_grille(move_toward(grille.rotation.y,target,delta*.85))
	game.events.exit_angle=grille.rotation.y
	if game.stage>=3 and game.events.get("exit_test_armed",false) and grille.rotation.y>.4 and not game.events.get("exit_false_departure",false) and in_passage(game.player.position) and game.player.position.x<END_X-.5:
		game.events.exit_test_armed=false;game.events.exit_false_departure=true;printing=0
		game.sound("foley/archive_rack",Vector3(5.75,-1.8,-9.7),-31);game.save_game(true)
	if game.events.get("exit_false_departure",false):printing=move_toward(printing,1,delta*.65)
	sync()
	var running: bool=game.events.get("exit_blackout_running",false)
	if resumed and running and game.threat.active() and game.events.get("threat_origin","")=="service_exit":resumed=false
	if game.events.get("exit_blackout_pending",false) or resumed:
		start_blackout();running=game.events.get("exit_blackout_running",false)
	if running:
		elapsed+=delta
		if game.threat.state=="observe":
			game.threat.change("investigate");game.threat.last_known=Vector3(3.25,-3,-15.7);game.threat.plan(game.threat.last_known)
		if game.threat.state=="complete":finish_blackout();running=false
	# Only this branch's practicals fade; the player's torch, access doors and input stay live.
	var store_energy: float=0.04 if running else .7
	game.maintenance.lamp.light_energy=move_toward(game.maintenance.lamp.light_energy,store_energy,delta*.45)
	pilot.light_energy=move_toward(pilot.light_energy,.03 if running else .30,delta*.3)
