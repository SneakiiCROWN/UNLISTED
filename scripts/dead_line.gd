extends Node3D
# Optional causal investigation: distinguish a working circuit from a witnessed return.
# No door locking, room teleportation, ending gate or additional enemy is introduced.
var game: Node3D
var panel: Node3D
var feed_handle: Node3D
var plug: Node3D
var pilot: MeshInstance3D
var strip: Node3D
var strip_ink: Label3D
var return_cable: MeshInstance3D
var motor: AudioStreamPlayer3D
var sources: Array[AudioStreamPlayer3D]=[]
var sequence: Array=[]
var clock:=0.0
var quiet:=0.0
var cooldown:=0.0
const PANEL:=Vector3(4.8,1.28,-3.20)
const NOTE=preload("res://scripts/case_notes.gd").CONTINUITY_TEST
func _ready() -> void:
	name="DeadLineInvestigation";build()
	motor=game.sound("hum",PANEL,-35,true);motor.max_distance=5;motor.unit_size=1.25
	restore()
func plate(pos: Vector3,size_: Vector3,color: Color) -> MeshInstance3D:
	var mesh: MeshInstance3D=game.box(panel,pos,size_,color)
	mesh.material_override=game.texture_mat("res://assets/dusk/psx_house_steel_01.png",color)
	return mesh
func tag(text: String,pos: Vector3,size_:=18) -> Label3D:
	var label: Label3D=game.label3(panel,text,pos,0,size_,Color("c1b995"))
	label.pixel_size=.0022;label.shaded=true;return label
func build() -> void:
	panel=Node3D.new();add_child(panel);panel.position=PANEL;panel.rotation.y=PI
	# A shallow, wall-mounted inspection station, clear of the desk, chair and aisle.
	var repair=load("res://scripts/environment_repair.gd").new();repair.g=game
	var housing: Node3D=game.model("res://assets/machinery/circuit_breaker.glb",panel,Vector3(0,-.24,-.075),Vector3(.58,.48,.15))
	housing.name="ContinuityHousing"
	for mesh in game.all_meshes(housing):mesh.material_override=game.texture_mat("res://assets/dusk/psx_house_steel_01.png",Color("4b5146"))
	plate(Vector3(0,0,.022),Vector3(.56,.48,.035),Color("53594c"))
	for x in [-.24,.24]:
		for y in [-.20,.20]:plate(Vector3(x,y,.046),Vector3(.014,.014,.012),Color("88846a"))
	tag("LINE TEST / 1998",Vector3(0,.17,.046))
	feed_handle=Node3D.new();panel.add_child(feed_handle);feed_handle.position=Vector3(-.17,.035,.055)
	var lever: MeshInstance3D=game.box(feed_handle,Vector3(0,.035,.015),Vector3(.025,.085,.035),Color("8f8d72"))
	game.collision(panel,Vector3(-.17,.035,.073),Vector3(.105,.13,.10),"line_feed")
	tag("FEED",Vector3(-.17,-.085,.05),14)
	# A real socket and short captive cable; it cannot be lost as a loose puzzle item.
	plate(Vector3(.16,.035,.052),Vector3(.082,.082,.025),Color("212923"))
	plug=Node3D.new();panel.add_child(plug);plug.position=Vector3(.16,.035,.073)
	game.box(plug,Vector3.ZERO,Vector3(.050,.045,.055),Color("3c3a30"))
	return_cable=repair.tube(Vector3(.16,-.005,.083),Vector3(.22,-.17,.09),.009,Color("292d28"),panel)
	repair.tube(Vector3(.30,-.17,.09),Vector3(.30,-.40,.04),.009,Color("292d28"),panel)
	game.collision(panel,Vector3(.16,.035,.11),Vector3(.11,.13,.14),"line_return")
	tag("RETURN",Vector3(.16,-.085,.05),14)
	plate(Vector3(0,.005,.055),Vector3(.055,.055,.030),Color("a19876"))
	game.collision(panel,Vector3(0,.005,.08),Vector3(.07,.08,.08),"line_strike")
	tag("STRIKER",Vector3(0,-.085,.05),12)
	pilot=game.box(panel,Vector3(0,.115,.056),Vector3(.025,.015,.008),Color("a4a16b"),false,true)
	# Supply/return lines follow the wall to the existing underfloor terminal.
	for x in [-.23,.23]:repair.tube(Vector3(x,.24,-.035),Vector3(x,1.48,-.035),.013,Color("57594a"),panel)
	game.collision(panel,Vector3(0,-.36,.07),Vector3(.43,.16,.08),"line_note")
	var note: MeshInstance3D=game.box(panel,Vector3(0,-.36,.039),Vector3(.43,.16,.004),Color("b4ad8d"))
	note.material_override=game.texture_mat("res://assets/original/aged_paper.png",Color("b4ad8d"))
	var ink: Label3D=tag("S. WARD / CONTINUITY TEST\nFEED OFF + RETURN REMOVED",Vector3(0,-.36,.044),10);ink.modulate=Color("44493a")
	strip=Node3D.new();panel.add_child(strip);strip.position=Vector3(0,-.57,.055)
	var paper: MeshInstance3D=game.box(strip,Vector3.ZERO,Vector3(.21,.27,.004),Color("b7b08c"))
	paper.material_override=game.texture_mat("res://assets/original/aged_paper.png",Color("b7b08c"))
	strip_ink=game.label3(strip,"",Vector3(0,0,.005),0,11,Color("313c31"));strip_ink.pixel_size=.0014;strip_ink.shaded=true
	game.collision(panel,Vector3(0,-.57,.075),Vector3(.23,.28,.05),"line_strip")
	# The paper's path is visible and mounted, not a floating description panel.
	plate(Vector3(0,-.435,.05),Vector3(.24,.025,.045),Color("282f29"))
func isolated() -> bool:
	return game.events.get("line_feed_off",false) and game.events.get("line_return_out",false)
func available() -> bool:
	return game.stage>=3 and game.events.get("underfloor_read",false) and int(game.events.get("underfloor_taps",0))>=3
func stop_sources() -> void:
	for source in sources:
		if is_instance_valid(source):source.stop();source.queue_free()
	sources.clear()
func restore() -> void:
	stop_sources();sequence.clear();clock=0;quiet=0;cooldown=0
	feed_handle.rotation.z=PI/2 if game.events.get("line_feed_off",false) else 0.0
	plug.position.y=-.09 if game.events.get("line_return_out",false) else .035
	plug.position.z=.15 if game.events.get("line_return_out",false) else .073
	var start: Vector3=plug.position+Vector3(0,-.0225,.015)
	var end:=Vector3(.30,-.17,.09)
	return_cable.position=(start+end)*.5;return_cable.mesh.height=start.distance_to(end)
	return_cable.quaternion=Quaternion(Vector3.UP,(end-start).normalized())
	pilot.visible=game.stage>=3 and not game.events.get("line_feed_off",false)
	motor.stream_paused=not (pilot.visible and game.started and not game.ended)
	strip.visible=game.events.get("line_printed",false)
	game.targets.line_strip.collision_layer=1 if strip.visible else 0
	strip_ink.text="17 BRIAR LANE\n\nWARD, ELI\nARRIVED 23:17\n1998\n\nEXIT / --"
	# Resume an interrupted sound test by re-arming, never consuming an unseen clue.
	if game.events.get("line_response_started",false) and not game.events.get("line_response_complete",false):game.events.line_response_started=false
func use(id: String) -> void:
	if game.threat.active():return
	if id=="line_note":game.inspect_text("SIMON / CONTINUITY TEST",NOTE);game.save_game(true);return
	if id=="line_strip":
		if not strip.visible:return
		game.events.line_strip_read=true
		game.inspect_text("UNWITNESSED ARRIVAL",game.NOTES.DEAD_LINE_RESULT)
		game.save_game(true);return
	if id in ["line_feed","line_return"]:
		stop_sources();sequence.clear()
		var key: String="line_feed_off" if id=="line_feed" else "line_return_out"
		game.events[key]=not game.events.get(key,false)
		game.sound("latch",PANEL,-30)
		restore();game.save_game(true);return
	if id!="line_strike" or cooldown>0:return
	cooldown=.3;game.sound("prop_impact",PANEL,-31)
	if not available():return
	if not isolated():
		# Calibration only works through both connected leads; a dead or open circuit cannot answer.
		if game.events.get("line_feed_off",false) or game.events.get("line_return_out",false):return
		game.events.line_calibrated=true;queue_pattern(PANEL,.4,false)
	elif game.events.get("line_calibrated",false):
		game.events.line_test_armed=true
	game.save_game(true)
func queue_pattern(where: Vector3,start: float,house: bool) -> void:
	stop_sources();sequence.clear();clock=0
	var pattern: Array=game.events.get("underfloor_pattern",[0.0,.52,1.36])
	for i in mini(pattern.size(),6):sequence.append({"at":start+float(pattern[i]),"where":where,"house":house})
func station_visible() -> bool:
	var camera: Camera3D=game.player.camera
	var samples: Array[Vector3]=[]
	for x in [-.30,0.0,.30]:
		for y in [-.73,-.45,0.0,.30]:samples.append(Vector3(x,y,0))
	for offset in samples:
		var point: Vector3=PANEL+offset
		if camera.is_position_behind(point):continue
		if not game.get_viewport().get_visible_rect().has_point(camera.unproject_position(point)):continue
		var query:=PhysicsRayQueryParameters3D.create(camera.global_position,point,1)
		var hit:=get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or is_ancestor_of(hit.collider):return true
	return false
func _physics_process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	cooldown=maxf(0,cooldown-delta)
	pilot.visible=game.stage>=3 and not game.events.get("line_feed_off",false)
	motor.stream_paused=not pilot.visible
	if game.threat.active() or game.horror.beat!="" or game.horror.audition!="" or game.chapter.active:
		stop_sources();sequence.clear();quiet=0
		if not game.events.get("line_response_complete",false):game.events.line_response_started=false
		return
	clock+=delta
	for i in range(sequence.size()-1,-1,-1):
		if clock<float(sequence[i].at):continue
		var item: Dictionary=sequence[i];sequence.remove_at(i)
		var cue: AudioStreamPlayer3D=game.sound("prop_impact",item.where,-28 if item.house else -34)
		cue.pitch_scale=.78 if item.house else 1.1;sources.append(cue)
		game.sound_caption("The knock pattern comes from the lounge." if item.house else "The striker answers through the line.",2,"LOUNGE" if item.house else "LINE TEST",cue)
		if sequence.is_empty() and item.house:
			game.events.line_response_complete=true;game.save_game(true)
	if not available() or not isolated() or not game.events.get("line_test_armed",false):return
	if not game.events.get("line_response_complete",false) and not game.events.get("line_response_started",false):
		# The player must leave the working box and face a genuinely closed, empty room.
		var p: Vector3=game.player.position
		if absf(p.x)<1.1 and p.y>-.2 and p.z> -3.8 and p.z< -1.0 and game.impossible_room.closed() and not game.impossible_room.active and not game.impossible_room.inside(p,.5):
			game.events.line_response_started=true
			queue_pattern(Vector3(4.5,1.1,-.8),.35,true)
	if game.events.get("line_response_complete",false) and not game.events.get("line_printed",false):
		# Extrude evidence while the entire station is out of view. Never swap geometry in sight.
		if not station_visible():
			quiet+=delta
			if quiet>.5:
				game.events.line_printed=true;strip.visible=true;game.targets.line_strip.collision_layer=1
				game.save_game(true)
