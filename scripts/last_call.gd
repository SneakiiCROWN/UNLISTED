extends Node3D
# An investigation through existing evidence, a real stairwell recess and an audible lure.
# Only new cases require its completion. No interpretation identifies the Surveyor.
var game: Node3D
var bay: Node3D
var lightbox: Node3D
var retainer: MeshInstance3D
var jumper: Node3D
var folded_page: Node3D
var bay_light: OmniLight3D
var reply_clock:=-1.0
var reply_index:=0
var cooldown:=0.0
var sources: Array[AudioStreamPlayer3D]=[]
var lamp_levels: Dictionary={}
const BAY:=Vector3(-3.25,-3,-13.85)
const REMOTE:=Vector3(-3.92,-1.65,-13.08)
const SPEAKER:=Vector3(-2.56,-1.62,-13.20)
const SPAWNS:=[Vector3(2.8,-2.99,-18.3),Vector3(0,-2.99,-22)]
const TITLE:="SIMON / AFTER THE LOUNGE"
const PLAN_TITLE:="THE TWO CELLAR PLANS"
const PLAN_NOTE:="The printed sheet is the site-office plan issued in 1998. Dad's tracing was folded into the test-reel sleeve. It's marked 'measured in cellar / after the lounge'.\n\nThe stairs, walls and service line match. His tracing adds a doorway beside the lower landing, on the west side. The printed plan shows solid wall there.\n\nHe either found an alteration they hadn't recorded, or this place showed him a different layout. I can check the wall myself."
const AFTER:="17 BRIAR LANE / S. WARD / 1998\nAfter the lounge inspection\n\nI rang home again. Eli was there. I could hear the kettle behind him.\n\nThen the speaker in this bay played our first call back. Every word. Even the kettle, in the same place. The line to it was already disconnected.\n\nI don't think there was a child in that room. It had my call, his room and the drawing from my toolbox. It was using things I knew.\n\nI nearly left it for the next contractor. Then the recorder started again and the man was at the landing. I played the test reel in the office. He went towards it. I got back into this bay.\n\nI haven't signed the clearance. If anyone comes after me, please check the rooms. Don't follow a voice just because you recognise it.\n\n[The page ends here.]"
const OBSERVATION:="Dad's tracing led to a doorway missing from the printed plan. His toolbox drawing and another page of his report were inside.\n\nHe wrote that he phoned home to check on me. The speaker in this room played that call back to him, even though he'd disconnected it.\n\nI pulled out the metal link connecting the speaker. It still answered the old recording. The switch here can run the office recorder without reconnecting the speaker.\n\nHis page says he used the recorder to draw the man away from the stairs. He was trying to get out. I still don't know what happened after he hid here."
func _ready() -> void:
	name="TheLastCall";build();restore()
	var previous:=24
	for point in [Vector3(-3.25,-3,-15.7),Vector3(-3.25,-3,-14.6),Vector3(-3.25,-3,-13.8)]:
		var id: int=game.threat.graph.get_point_count();game.threat.graph.add_point(id,point);game.threat.graph.connect_points(previous,id);previous=id
func surface(parent: Node3D,pos: Vector3,size_: Vector3,texture: String,tint: Color,solid:=false) -> MeshInstance3D:
	var mesh: MeshInstance3D=game.box(parent,pos,size_,tint,solid);mesh.material_override=game.texture_mat(texture,tint);return mesh
func tag(parent: Node3D,text: String,pos: Vector3,size_:=14) -> Label3D:
	var label: Label3D=game.label3(parent,text,pos,0,size_,Color("c4b99a"));label.pixel_size=.0017;label.shaded=true;return label
func build() -> void:
	var stone:="res://assets/exterior/Concrete019_1K-JPG_Color.jpg"
	var steel:="res://assets/dusk/psx_house_steel_01.png"
	var wood:="res://assets/dusk/psx_house_old_wood_01.png"
	# A backed, roofed 2.1 x 2.1 m inspection recess next to the original lower landing.
	bay=Node3D.new();bay.name="StairwellReturnBay";add_child(bay)
	game.floor_area(-4.30,-2.20,-15,-12.78,-3);game.ceiling(-4.30,-2.20,-15,-12.78,-.2)
	game.wall(Vector3(-4.3,-3,-13.89),2.22,PI/2);game.wall(Vector3(-2.2,-3,-13.89),2.22,PI/2)
	game.wall(Vector3(-3.25,-3,-12.78),2.1)
	var door: Node3D=game.door("call_niche",Vector3(-3.25,-3,-15))
	for mesh in game.all_meshes(door):
		mesh.material_override=game.texture_mat(wood,Color("484d42"))
	# Old lining, a narrow stone reveal and a recessed latch; no literal location sign.
	for x in [-4.16,-2.34]:surface(bay,Vector3(x,-1.65,-14.89),Vector3(.14,2.68,.16),stone,Color("5c6455"))
	var repair=load("res://scripts/environment_repair.gd").new();repair.g=game
	for x in [-4.08,-2.42]:
		repair.tube(Vector3(x,-.35,-12.92),Vector3(x,-2.65,-12.92),.018,Color("4b5143"),bay)
	# Existing approved carpentry and electrical housing; clear central standing/escape aisle.
	var shelf: MeshInstance3D=surface(bay,Vector3(-3.25,-1.93,-13.07),Vector3(1.62,.075,.43),wood,Color("615845"),true)
	shelf.name="ReturnBayWorkShelf"
	for x in [-3.88,-2.62]:surface(bay,Vector3(x,-2.18,-12.98),Vector3(.055,.48,.055),steel,Color("454b41"))
	var monitor: Node3D=game.model("res://assets/interiors/last_call/speakerSmall.glb",bay,Vector3(-2.57,-1.88,-13.08),Vector3(.25,.42,.22),PI,true)
	game.chapter.finish_materials(monitor)
	game.model("res://assets/machinery/circuit_breaker.glb",bay,Vector3(-3.98,-1.91,-13.03),Vector3(.33,.50,.14),PI)
	var board: Node3D=surface(bay,Vector3(-3.25,-1.48,-12.91),Vector3(.74,.72,.025),wood,Color("5a5343"))
	var drawing: MeshInstance3D=surface(board,Vector3(0,.12,-.024),Vector3(.28,.31,.005),"res://assets/original/eli_bedroom_sketch.svg",Color.WHITE)
	drawing.name="ToolboxDrawingInBay"
	# Separate signal bridge and transport-control cable; removing signal never powers the remote.
	var plate: Node3D=surface(bay,Vector3(-3.92,-1.44,-13.12),Vector3(.28,.23,.035),steel,Color("414a3f"))
	plate.rotation.y=PI
	for x in [-.065,.065]:game.box(plate,Vector3(x,-.02,.035),Vector3(.030,.04,.030),Color("a39569"))
	jumper=Node3D.new();plate.add_child(jumper)
	for pair in [[Vector3(-.065,-.02,.045),Vector3(-.065,.055,.055)],[Vector3(-.065,.055,.055),Vector3(.065,.055,.055)],[Vector3(.065,.055,.055),Vector3(.065,-.02,.045)]]:
		repair.tube(pair[0],pair[1],.009,Color("a18b60"),jumper)
	retainer=repair.tube(Vector3(-.12,-.02,.04),Vector3(-.065,.055,.055),.0025,Color("777a65"),plate)
	game.collision(plate,Vector3(0,.015,.058),Vector3(.19,.14,.09),"call_bridge")
	tag(plate,"SPEAKER LINK",Vector3(0,-.085,.025),11)
	var remote: Node3D=surface(bay,REMOTE,Vector3(.24,.13,.09),steel,Color("585746"));remote.rotation.y=PI
	game.box(remote,Vector3(0,0,.065),Vector3(.08,.04,.055),Color("a89a77"))
	game.collision(remote,Vector3(0,0,.07),Vector3(.21,.14,.11),"call_remote")
	tag(remote,"OFFICE REPLAY",Vector3(0,-.05,.050),9)
	for points in [[Vector3(-3.92,-1.65,-12.96),Vector3(-4.08,-1.65,-12.96),Vector3(-4.08,-.45,-12.96),Vector3(-3.25,-.45,-12.96)],[Vector3(-2.57,-1.66,-12.94),Vector3(-2.57,-1.18,-12.94),Vector3(-3.92,-1.18,-12.94),Vector3(-3.92,-1.42,-12.94)]]:
		for i in range(points.size()-1):repair.tube(points[i],points[i+1],.008,Color("272e26"),bay)
	folded_page=surface(bay,Vector3(-3.25,-1.881,-13.08),Vector3(.35,.004,.28),"res://assets/original/aged_paper.png",Color("b8ad8b"))
	var ink: Label3D=tag(folded_page,"1998 / S. Ward\nAfter the lounge\nIt played our call back.",Vector3(0,.007,0),13);ink.rotation.x=-PI/2;ink.rotation.y=PI;ink.font=load("res://assets/fonts/Kalam-Regular.ttf");ink.font_size=22;ink.pixel_size=.0009
	game.collision(bay,Vector3(-3.25,-1.86,-13.08),Vector3(.38,.06,.31),"call_page")
	game.model("res://assets/dusk/psx_prop_ceiling_lamp_01.glb",bay,Vector3(-3.25,-.52,-13.6),Vector3(.30,.20,.30))
	bay_light=game.lamp(Vector3(-3.25,-.68,-13.6),Color("b8ac86"),.38,3)
	# Fold-out tracing cabinet on the office's solid south wall, beside the original test station.
	lightbox=Node3D.new();lightbox.name="OfficeTracingCabinet";add_child(lightbox);lightbox.position=Vector3(2.95,1.35,-3.14);lightbox.rotation.y=PI
	surface(lightbox,Vector3(0,0,-.018),Vector3(.97,.71,.12),wood,Color("4d5349"))
	var glass: MeshInstance3D=game.box(lightbox,Vector3(0,0,.048),Vector3(.87,.61,.015),Color("b7b08a"),false,true)
	glass.material_override.emission_energy_multiplier=.25
	for x in [-.46,.46]:surface(lightbox,Vector3(x,0,.06),Vector3(.035,.70,.04),steel,Color("626253"))
	for y in [-.32,.32]:surface(lightbox,Vector3(0,y,.06),Vector3(.95,.035,.04),steel,Color("626253"))
	tag(lightbox,"No. 17 / SITE PLAN / 1998",Vector3(0,.26,.065),14)
	tag(lightbox,"S. WARD / TRACING",Vector3(0,-.26,.065),12)
	game.collision(lightbox,Vector3(0,0,.06),Vector3(.90,.62,.08),"call_lightbox")
	# Fine plan strokes are printed under the glass, rather than floating explanatory text.
	for x in [-.22,-.04,.04,.22]:game.box(lightbox,Vector3(x,-.015,.061),Vector3(.004,.32,.002),Color("596050"))
	for y in [-.17,.15]:game.box(lightbox,Vector3(0,y,.061),Vector3(.44,.004,.002),Color("596050"))
func plans_available() -> bool:
	return game.report_read and game.events.get("test_reel_found",false)
func align_plans() -> void:
	if not plans_available() or game.events.get("call_plan_aligned",false):return
	game.events.call_plan_aligned=true;game.events.call_plan_placed=true
	game.events.notes[PLAN_TITLE]=PLAN_NOTE
	var paper_audio:=AudioStreamPlayer3D.new();paper_audio.stream=preload("res://assets/audio/foley/paper_handling.ogg");paper_audio.bus="SFX";paper_audio.volume_db=-32;paper_audio.max_distance=4;add_child(paper_audio);paper_audio.global_position=lightbox.global_position;paper_audio.finished.connect(paper_audio.queue_free);paper_audio.play();game.save_game(true)
func open_plans() -> void:
	if game.threat.active():game.presentation.notify("He's too close. I can't stop here.");return
	var p=game.presentation;p.pause_world();p.clear_transients();p.clear_card();p.section="document"
	p.label(p.card_body,"PROPERTY SERVICES / TRACING CABINET",15,"Meta")
	var widget=load("res://scripts/plan_lightbox.gd").new();widget.game=game;p.card_body.add_child(widget)
	var actions:=HBoxContainer.new();p.card_body.add_child(actions)
	p.add_button("Place tracing",widget.place_sheet,plans_available(),actions)
	p.add_button("Turn left",func():widget.turn(deg_to_rad(-5)),plans_available(),actions)
	p.add_button("Turn right",func():widget.turn(deg_to_rad(5)),plans_available(),actions)
	p.add_button("Steady sheets",widget.assist,plans_available(),actions)
	p.add_button("Put down",func():widget.remember();p.resume_game(),true,actions)
	for button in actions.get_children():
		button.custom_minimum_size.x=0;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.add_theme_font_size_override("font_size",18)
	widget.focus_neighbor_bottom=widget.get_path_to(actions.get_child(0))
	actions.get_child(0).focus_neighbor_top=actions.get_child(0).get_path_to(widget)
	var guidance: Label=p.label(p.card_body,"Right stick moves the tracing; D-pad selects buttons. Match the stairs, walls and service line." if game.controller.used else "Drag the tracing; scroll to turn it. Match the stairs, walls and service line.",15,"Meta");guidance.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	widget.grab_focus()
func busy() -> bool:
	return game.events.get("call_test_running",false) or game.events.get("call_search_running",false) or reply_clock>=0
func use(id: String) -> void:
	if id=="call_lightbox":open_plans();return
	if id=="call_niche":
		game.doors.call_niche.use();game.events.call_bay_found=true;game.save_game(true);return
	if id=="call_bridge":
		if game.events.get("call_disconnected",false):return
		game.events.call_disconnected=true;sync();game.sound("latch",jumper.global_position,-30);game.save_game(true);return
	if id=="call_remote":
		if cooldown>0 or game.field_tape.playing:return
		if not game.events.get("test_reel_loaded",false):game.presentation.notify("There's no tape in the office recorder.");return
		if not game.events.get("call_disconnected",false):game.presentation.notify("The speaker is still connected. I need to pull the metal link out before I test it.");return
		cooldown=18
		game.events.call_test_running=not game.events.get("call_test_complete",false)
		game.field_tape.play(true);game.sound("latch",REMOTE,-31);game.save_game(true);return
	if id=="call_page":
		game.events.call_note_read=true
		game.inspect_text(TITLE,AFTER);sync();finish_if_ready();game.save_game(true)
func sync() -> void:
	jumper.position.y=-.20 if game.events.get("call_disconnected",false) else 0
	jumper.rotation.z=.35 if game.events.get("call_disconnected",false) else 0
	var tie: Vector3=jumper.transform*Vector3(-.065,.055,.055);var anchor:=Vector3(-.12,-.02,.04)
	retainer.position=(tie+anchor)*.5;retainer.mesh.height=tie.distance_to(anchor);retainer.quaternion=Quaternion(Vector3.UP,(tie-anchor).normalized())
	# The important test bridge stays captive and visible as physical evidence.
	game.targets.call_bridge.collision_layer=0 if game.events.get("call_disconnected",false) else 1
	folded_page.visible=not game.events.get("call_note_read",false)
	game.targets.call_page.collision_layer=1 if folded_page.visible else 0
func restore() -> void:
	for source in sources:
		if is_instance_valid(source):source.stop();source.queue_free()
	sources.clear();reply_clock=-1;reply_index=0;cooldown=0;lamp_levels.clear()
	game.events.call_test_running=false # Rewind an interrupted test, never award unheard evidence.
	var notes: Dictionary=game.events.get("notes",{})
	for pair in [[TITLE,AFTER],[PLAN_TITLE,PLAN_NOTE],["ELI / THE LAST CALL",OBSERVATION]]:
		if notes.has(pair[0]):notes[pair[0]]=pair[1] # Refresh wording only; never grant evidence on load.

	if game.events.get("call_search_running",false):
		var target_: Array=game.events.get("call_search_target",[-3.25,-3.0,-15.7])
		if target_.size()==3:game.threat.last_known=Vector3(float(target_[0]),float(target_[1]),float(target_[2]))
	bay_light.light_energy=.04 if game.events.get("call_search_running",false) else .38
	sync()
func reel_cue(index: int) -> void:
	if index==9 and game.events.get("call_test_running",false):reply_clock=0;reply_index=0
func safe_to_start() -> bool:
	return not game.threat.active() and not game.presence.visible and game.threat.enabled and not game.recount.active and not (game.chapter.active and game.impossible_room.inside(game.player.position,.5)) and not (game.impossible_room.active and game.impossible_room.inside(game.player.position,.5)) and game.chapter.watch_clock<0 and not game.events.get("exit_blackout_running",false) and not game.events.get("inspection_search_pending",false) and not game.events.get("witness_echo_pending",false)
func start_search() -> bool:
	if not safe_to_start():return false
	var p: Vector3=game.player.position
	if p.y> -2.4 or p.distance_to(BAY)>4.0:return false
	var spawn:=Vector3.ZERO
	for candidate in SPAWNS:
		if p.distance_to(candidate)>5 and not game.chapter.point_visible(candidate+Vector3.UP*1.6):spawn=candidate;break
	if spawn==Vector3.ZERO:return false
	game.events.call_prior_resolved=game.events.get("threat_resolved",false);game.events.call_prior_pending=game.events.get("threat_pending",false)
	game.events.call_prior_origin=game.events.get("threat_origin","");game.events.call_prior_spawn=game.events.get("threat_spawn",[]).duplicate()
	game.events.call_search_pending=false;game.events.call_search_running=true
	game.events.threat_pending=true;game.events.threat_resolved=false;game.events.threat_origin="last_call";game.events.threat_spawn=[spawn.x,spawn.y,spawn.z]
	game.threat.begin(false,spawn);game.threat.last_known=Vector3(-3.25,-3,-15.7);game.events.call_search_target=[-3.25,-3.0,-15.7]
	game.sound("door",Vector3(0,-1.2,-12),-30);game.save_game(true);return true
func finish_search() -> void:
	game.events.call_search_running=false;game.events.call_search_done=true;game.events.call_search_pending=false
	game.events.threat_resolved=game.events.get("call_prior_resolved",false);game.events.threat_pending=game.events.get("call_prior_pending",false)
	game.events.threat_origin=game.events.get("call_prior_origin","");game.events.threat_spawn=game.events.get("call_prior_spawn",[]).duplicate()
	finish_if_ready();game.save_game(true)
func finish_if_ready() -> void:
	if game.events.get("call_test_complete",false) and game.events.get("call_note_read",false) and game.events.get("call_search_done",false):
		game.events.call_complete=true;game.events.notes["ELI / THE LAST CALL"]=OBSERVATION
func hint() -> String:
	if game.events.get("call_search_running",false):return "The recorder is upstairs. This switch can start it from here. If he loses sight of me, he might go towards the sound."
	if game.events.get("call_test_complete",false) and not game.events.get("call_note_read",false):return "There is a folded page beside the drawing in the bay."
	if game.events.get("call_disconnected",false):return "The metal link is out, so the speaker should be silent. The separate switch starts Dad's recording upstairs. I can listen here while it plays."
	if game.events.get("call_plan_aligned",false):return "Dad marked a doorway west of the bottom landing. The issued plan shows wall."
	if not game.events.get("test_reel_found",false):return "Dad kept his test reel and measured tracing in the records store. The access is beside the cellar ramp."
	if not game.events.get("test_reel_loaded",false):return "The reel fits the office recorder. Dad folded a tracing into its sleeve. I can compare it with the plan in the lightbox."
	return "The site plan and Dad's tracing share the same stairs and service line. I can compare them on the office lightbox."
func _physics_process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	cooldown=maxf(0,cooldown-delta)
	if reply_clock>=0:
		reply_clock+=delta
		if reply_index<3 and reply_clock>1.2+reply_index*.65:
			var cue: AudioStreamPlayer3D=game.sound("prop_impact",SPEAKER,-29);cue.pitch_scale=.82;cue.max_distance=7;cue.unit_size=1;sources.append(cue)
			if reply_index==0:game.sound_caption("Taps from the disconnected speaker.",3,"RETURN BAY",cue)
			reply_index+=1
		if reply_index==3:
			reply_clock=-1;game.events.call_test_running=false;game.events.call_test_complete=true
			if not game.events.get("call_search_done",false):game.events.call_search_pending=true
			game.save_game(true)
	if game.events.get("call_search_pending",false):start_search()
	var running: bool=game.events.get("call_search_running",false)
	if running and game.events.get("threat_origin","")=="last_call":
		var target_: Vector3=game.threat.last_known;game.events.call_search_target=[target_.x,target_.y,target_.z]
		if game.threat.state=="observe":game.threat.change("investigate");game.threat.plan(game.threat.last_known)
		if game.threat.state=="complete":finish_search();running=false
		elif game.threat.age>8 and game.player.position.y>-.4 and game.player.position.x>11.9 and game.player.position.z< -6 and game.player.position.z> -10 and not game.threat.can_see_player() and game.threat.state not in ["retreat","dead","capture"]:
			game.threat.change("retreat");game.threat.plan(Vector3(0,0,2.7))
	# One slow blackout, never a strobe; controls, torch and every exit remain live.
	bay_light.light_energy=move_toward(bay_light.light_energy,(.035 if running else .38) if game.stage>=3 else 0.0,delta*.18)
	if running:
		for light in game.lamps:
			if not lamp_levels.has(light):lamp_levels[light]=light.light_energy
			light.light_energy=move_toward(light.light_energy,.035,delta*.25)
	elif not lamp_levels.is_empty():
		var restored:=true
		for light in lamp_levels:
			light.light_energy=move_toward(light.light_energy,float(lamp_levels[light]),delta*.35)
			restored=restored and is_equal_approx(light.light_energy,float(lamp_levels[light]))
		if restored:lamp_levels.clear()
