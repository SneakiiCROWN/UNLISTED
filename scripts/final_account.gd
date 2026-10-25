extends Node3D
# A physical close-out on the existing porch, followed by Eli's actual parked car.
# Only a newly made decision opts in; older pending/finished saves keep their exit.
var game: Node3D
var receipt: Node3D
var receipt_ink: Label3D
var tray_ink: Label3D
var tag_card: Node3D
var car: Node3D
var cabin: OmniLight3D
var packet: Node3D
var elapsed:=0.0
var engine_started:=false
var sources: Array[AudioStreamPlayer3D]=[]
func _ready() -> void:
	name="TheFinalAccount"
	# Extend the existing clipboard support, not a second interactive register.
	var backing: MeshInstance3D=game.box(self,Vector3(-1.30,1.39,4.100),Vector3(.50,.89,.024),Color("494d40"))
	backing.material_override=game.texture_mat("res://assets/dusk/psx_house_old_wood_01.png",Color("665e49"))
	receipt=Node3D.new();add_child(receipt);receipt.position=Vector3(-1.30,1.125,4.15)
	paper(receipt,Vector3.ZERO,Vector3(.31,.16,.003))
	game.box(receipt,Vector3(0,.065,.009),Vector3(.13,.016,.018),Color("777968"))
	receipt_ink=game.label3(receipt,"",Vector3(0,-.005,.004),0,14,Color("282e27"));receipt_ink.pixel_size=.0015
	game.collision(receipt,Vector3(0,-.005,.01),Vector3(.32,.155,.025),"account_receipt")
	# The label can be set beside an existing dated record, on the measured desk.
	var tray:=Node3D.new();tray.name="UndatedEquipmentExhibit";add_child(tray);tray.position=Vector3(5.05,.810,-8.34)
	game.box(tray,Vector3(0,-.004,0),Vector3(.20,.014,.13),Color("4f5546"))
	var record:=paper(tray,Vector3(-.035,.005,0),Vector3(.10,.002,.108))
	var legend: Label3D=game.label3(record,"JOB FILE\nS. WARD\n1998",Vector3(0,.002,0),0,14,Color("30372b"));legend.rotation.x=-PI/2;legend.pixel_size=.0009
	tag_card=paper(tray,Vector3(.057,.008,.0),Vector3(.08,.003,.102))
	tray_ink=game.label3(tag_card,"STOCK\n2018\nUSE DATE ?",Vector3(0,.003,0),0,12,Color("30372b"));tray_ink.rotation.x=-PI/2;tray_ink.pixel_size=.0008
	game.collision(tray,Vector3(0,.025,0),Vector3(.20,.06,.13),"account_compare")
	car=game.get_node("BriarLaneExterior/EliArrivalCar")
	var handle: StaticBody3D=game.collision(car,Vector3(.88,.88,.10),Vector3(.10,.18,.34),"account_car")
	handle.name="DepartureDriverHandle"
	cabin=OmniLight3D.new();car.add_child(cabin);cabin.position=Vector3(0,1.18,0);cabin.light_color=Color("c2b997");cabin.light_energy=0;cabin.omni_range=1.4;cabin.shadow_enabled=false
	packet=Node3D.new();car.add_child(packet);packet.position=Vector3(-.39,.68,.05)
	game.box(packet,Vector3.ZERO,Vector3(.29,.015,.23),Color("6d6851"))
	paper(packet,Vector3(0,.009,0),Vector3(.24,.002,.18))
	restore()
func paper(parent: Node3D,pos: Vector3,size_: Vector3) -> MeshInstance3D:
	var mesh: MeshInstance3D=game.box(parent,pos,size_,Color("c0b58e"))
	mesh.material_override=game.texture_mat("res://assets/original/aged_paper.png",Color("c0b58e"));return mesh
func state() -> Dictionary:return game.events.get("final_account",{})
func pending() -> bool:return not str(game.events.get("departure_pending","")).is_empty() and not state().is_empty()
func phase() -> String:return str(state().get("phase",""))
func cleanup() -> void:
	for audio in sources:
		if is_instance_valid(audio):audio.stop();audio.queue_free()
	sources.clear()
func restore() -> void:
	cleanup();elapsed=0;engine_started=false
	game.presentation.fade.color.a=0
	# Recover interrupted boarding with the receipt retained and full control.
	if phase()=="boarding":
		game.events.final_account.phase="ready"
		game.presentation.fade.color.a=0
	sync()
func sync() -> void:
	var waiting: bool=pending() and phase()=="receipt"
	receipt.visible=waiting;game.targets.account_receipt.collision_layer=1 if waiting else 0
	var witness: bool=str(game.events.get("departure_pending",""))=="on_record"
	receipt_ink.text="E. WARD / WITNESS\nFAULT OPEN / COPY" if witness else "S. WARD / PRESENT 1998\nTONIGHT'S CALL CLOSED"
	game.targets.account_car.collision_layer=1 if pending() else 0
	tag_card.visible=game.events.get("equipment_date_compared",false)
	game.targets.account_compare.collision_layer=1 if game.stage>=3 and game.report_read and tag_known() and not tag_card.visible else 0
	cabin.light_energy=.12 if pending() and phase() in ["ready","boarding"] else 0
	packet.visible=(phase()=="boarding" and elapsed>=.70) or (game.ended and not state().is_empty())
func tag_known() -> bool:
	return game.equipment.data.get("uv",false) and game.events.get("notes",{}).has("INSPECTION KIT")
func begin(outcome: String) -> bool:
	if phase() in ["ready","boarding"]:return false
	game.events.final_account={"version":1,"phase":"receipt","outcome":outcome,"gate_echo":false}
	game.events.departure_pending=outcome;sync()
	var cue: AudioStreamPlayer3D=game.sound("transport_click",receipt.global_position,-29);sources.append(cue)
	return true
func use(id: String) -> void:
	if id=="account_compare":
		if game.stage<3 or not game.report_read or not tag_known() or game.events.get("equipment_date_compared",false):return
		game.events.equipment_date_compared=true;sync()
		game.sound("radio_switch",tag_card.global_position,-36)
		game.message("Dad's file is from 1998. This label isn't. I'm keeping them separate.",4)
		if game.events.get("notes",{}).has("INSPECTION KIT"):game.events.notes["INSPECTION KIT"]=game.NOTES.INSPECTION_KIT+"\n\nI set the 2018 stock label beside the dated job file. It cannot tell me when the head was used, or who left it. I kept it separate from Dad's records."
		game.save_game(true);return
	if id=="account_receipt" and phase()=="receipt":
		if game.threat.active():return
		game.events.final_account.phase="ready";sync();game.recount.update_sheet()
		game.sound("radio_switch",receipt.global_position,-35);game.save_game(true);return
	if id!="account_car" or not pending():return
	if phase()=="receipt":
		game.message("My receipt is still in the clip on the porch.",3);return
	if phase()!="ready" or game.threat.active() or game.player.position.z<18.5:return
	game.events.final_account.phase="boarding";elapsed=0;engine_started=false;sync();game.save_game(true)
	game.physical.release(false);game.player.velocity=Vector3.ZERO;game.player.active=false
	play("door_open",-27)
func play(id: String,db: float) -> void:
	var cue:=AudioStreamPlayer3D.new();cue.stream=load("res://assets/audio/arrival/"+id+".ogg");cue.bus="SFX";cue.volume_db=db;cue.unit_size=1;cue.max_distance=6;add_child(cue);cue.global_position=game.targets.account_car.global_position;cue.finished.connect(cue.queue_free);sources.append(cue);cue.play()
func _process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	sync()
	if not pending():return
	if phase()=="boarding":
		game.player.active=false
		elapsed+=delta;game.presentation.fade.color.a=clampf(elapsed/.65,0,1)
		if elapsed>=.70 and not engine_started:engine_started=true;play("door_close",-28);play("engine_idle",-31)
		if elapsed>=1.65:
			var outcome: String=game.events.departure_pending
			game.events.final_account.phase="departed";game.events.departure_pending="";game.events.ending=outcome
			cleanup();game.presentation.fade.color.a=0;game.finish_game();sync()
		return
	# A repeat from the empty hall, after Eli is physically beyond the gate.
	# No spawned figure, enforced camera turn, return trip or new revelation.
	if phase()=="ready" and not state().get("gate_echo",false) and game.player.position.z>18.7 and absf(game.player.position.x)<8:
		game.events.final_account.gate_echo=true
		var foot: AudioStreamPlayer3D=game.sound("step",Vector3(0,.03,3.2),-23);sources.append(foot)
		game.sound_caption("A footstep inside the house.",2.5,"FRONT HALL",foot)
		game.recount.update_sheet();game.save_game(true)

func _exit_tree() -> void:cleanup()
