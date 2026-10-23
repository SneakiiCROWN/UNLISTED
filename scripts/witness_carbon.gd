extends Node3D
# Optional physical evidence, no new ending gate and no replacement hostile actor.
var game: Node3D
var cover: Node3D
var fasteners: Array[Node3D]=[]
var paper: Node3D
var last_position:=Vector3.ZERO
var still:=0.0
var emitted: Array[Vector3]=[]
var sources: Array[AudioStreamPlayer3D]=[]
func _ready() -> void:
	name="ReturnInspectionBox";position=Vector3(3.98,-2.45,-12.6);rotation.y=-PI/2
	var steel:="res://assets/dusk/psx_house_steel_01.png"
	game.model("res://assets/machinery/circuit_breaker.glb",self,Vector3(0,-.28,-.015),Vector3(.68,.56,.10))
	# Flush wall-mounted inspection tray, with a cover sliding along captive rails.
	for y in [-.28,.28]:
		var rail: MeshInstance3D=game.box(self,Vector3(-.36,y,.075),Vector3(1.40,.025,.05),Color("555a50"))
		rail.material_override=game.texture_mat(steel,Color("646659"))
	game.box(self,Vector3(0,0,.065),Vector3(.60,.49,.025),Color("272f2a"))
	cover=Node3D.new();add_child(cover)
	var lid: MeshInstance3D=game.box(cover,Vector3(0,0,.115),Vector3(.62,.51,.025),Color("52594d"))
	lid.material_override=game.texture_mat(steel,Color("747b67"))
	game.collision(cover,Vector3(0,0,.127),Vector3(.62,.51,.025),"witness_cover")
	for i in 2:
		var catch:=Node3D.new();cover.add_child(catch);catch.position=Vector3(.24,.17 if i==0 else -.17,.151);fasteners.append(catch)
		game.box(catch,Vector3.ZERO,Vector3(.055,.055,.016),Color("838779"))
		game.box(catch,Vector3(0,0,.01),Vector3(.007,.033,.004),Color("242a23"))
		game.collision(catch,Vector3(0,0,.012),Vector3(.10,.10,.025),"witness_fastener"+str(i))
	var label: Label3D=game.label3(cover,"RETURN / INSPECTION\nRELEASE  < >",Vector3(-.05,0,.132),0,13,Color("c0c0a4"));label.pixel_size=.0015
	paper=Node3D.new();add_child(paper)
	var sheet: MeshInstance3D=game.box(paper,Vector3(0,0,.089),Vector3(.40,.37,.004),Color("bbb49a"))
	sheet.material_override=game.texture_mat("res://assets/original/aged_paper.png",Color("c1b79c"))
	var ink: Label3D=game.label3(paper,"1998 / CLEARANCE\n\nEMPTY / 23:18\nWITNESS: ______\n\nS.W. / NOT SIGNED",Vector3(0,0,.094),0,15,Color("333b31"));ink.pixel_size=.00115
	game.collision(paper,Vector3(0,0,.098),Vector3(.40,.37,.012),"witness_carbon")
	restore()
func restore() -> void:
	for source in sources:
		if is_instance_valid(source):source.stop();source.queue_free()
	sources.clear();emitted.clear();still=0;last_position=game.player.position
	cover.position.x=float(game.events.get("witness_slide",-.72 if game.events.get("witness_open",false) else 0.0))
	var clips: Array=game.events.get("witness_fasteners",[false,false])
	for i in 2:fasteners[i].rotation.z=PI/2 if clips[i] else 0.0
	sync()
func sync() -> void:
	var opened: bool=cover.position.x<-.66
	paper.visible=not game.events.get("witness_carbon_read",false)
	game.targets.witness_carbon.collision_layer=1 if opened and paper.visible else 0
	for i in 2:game.targets["witness_fastener"+str(i)].collision_layer=0 if opened else 1
func use(id: String) -> void:
	if id=="witness_carbon":
		if cover.position.x>-.66 or game.events.get("witness_carbon_read",false):return
		game.events.witness_carbon_read=true;game.events.witness_echo_pending=true
		game.events.witness_steps=0;game.events.witness_distance=0.0
		last_position=game.player.position;paper.visible=false
		game.inspect_text(game.NOTES.WITNESS_TITLE,game.NOTES.WITNESS_CARBON);game.save_game(true);sync();return
	if id.begins_with("witness_fastener"):
		if absf(cover.position.x)>.01:return
		var index:=int(id.right(1));var clips: Array=game.events.get("witness_fasteners",[false,false]).duplicate()
		clips[index]=not clips[index];game.events.witness_fasteners=clips
		fasteners[index].rotation.z=PI/2 if clips[index] else 0.0
		game.sound("latch",fasteners[index].global_position,-34);game.save_game(true);return
	var clips: Array=game.events.get("witness_fasteners",[false,false])
	if not clips[0] or not clips[1]:game.message("The cover is still held by its fasteners.",2);return
	game.events.witness_open=not game.events.get("witness_open",false)
	game.sound("latch",global_position,-32);game.save_game(true)
func cue(point: Vector3) -> void:
	var source: AudioStreamPlayer3D=game.sound("step",point,-30);source.pitch_scale=.88
	sources.append(source);emitted.append(point)
	game.sound_caption("A footstep overhead.",2,"ABOVE THE PASSAGE",source)
func cover_in_frame() -> bool:
	var camera: Camera3D=game.player.camera
	for x in [-1.05,-.35,.35]:
		for y in [-.3,.3]:
			var point: Vector3=to_global(Vector3(x,y,.15))
			if not camera.is_position_behind(point) and game.get_viewport().get_visible_rect().has_point(camera.unproject_position(point)):return true
	return false
func _physics_process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	cover.position.x=move_toward(cover.position.x,-.72 if game.events.get("witness_open",false) else 0.0,delta*.55)
	game.events.witness_slide=cover.position.x;sync()
	var p: Vector3=game.player.position
	var movement: float=Vector2(p.x-last_position.x,p.z-last_position.z).length();last_position=p
	# The reversed lounge can remain active until it is revisited. It is scenery,
	# not a running sequence elsewhere in the property; only defer in that room.
	var room_overlap: bool=game.impossible_room.active and game.impossible_room.inside(p,.65)
	if game.threat.active() or game.horror.beat!="" or game.horror.audition!="" or game.chapter.active or room_overlap or game.recount.active or not game.dead_line.sequence.is_empty() or game.maintenance.surprise_armed:return
	if game.events.get("witness_close_pending",false) and not cover_in_frame():
		game.events.witness_close_pending=false;game.events.witness_open=false;game.sound("latch",global_position,-32);game.save_game(true)
	if not game.events.get("witness_echo_pending",false):return
	if p.y> -2.5 or p.z< -15.35 or p.z> -10.1:
		game.events.witness_echo_pending=false;game.events.witness_echo_done=true;game.events.witness_close_pending=true;game.save_game(true);return
	if movement>.3:return # Save/load or development relocation is not a footstep.
	var steps: int=int(game.events.get("witness_steps",0))
	game.events.witness_distance=float(game.events.get("witness_distance",0.0))+movement
	still=still+delta if movement<.003 else 0.0
	if steps<3 and float(game.events.witness_distance)>.85:
		game.events.witness_distance=0.0;game.events.witness_steps=steps+1;cue(Vector3(p.x,-.05,p.z));game.save_game(true)
	elif steps>=3 and still>1.4:
		cue(Vector3(3.25,-.05,clampf(p.z-1.4,-15.5,-10.2)))
		game.events.witness_echo_pending=false;game.events.witness_echo_done=true;game.events.witness_close_pending=true;game.save_game(true)
