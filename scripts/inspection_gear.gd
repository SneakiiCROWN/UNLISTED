extends Node3D
# One saved power source, no darkness softlock: packs plus a manual backup dynamo.
var game: Node3D
var data: Dictionary={}
var kit: Node3D
var pickups: Dictionary={}
var winding:=0.0
var notified_low:=false
var fault_fade:=0.0
const WHITE_DRAIN:=.28
const UV_DRAIN:=.42
func _ready() -> void:
	name="InspectionEquipment";build();restore()
	var mark=load("res://scripts/inspection_mark.gd").new();mark.game=game;game.add_child(mark)
func new_case() -> void:
	game.events.torch={"version":1,"charge":100.0,"spares":1,"mode":1,"uv":false,"packs":[]}
	restore()
func restore() -> void:
	var legacy: bool=not game.events.has("torch")
	data=game.events.get("torch",{"version":1,"charge":100.0,"spares":1,"mode":1,"uv":legacy and (game.shed_read or game.events.get("carbon_read",false)),"packs":[]})
	if game.events.get("carbon_read",false):data.uv=true
	game.player.viewmodel.cancel_pack_change()
	game.events.torch=data;winding=0;notified_low=false;fault_fade=0
	data.contact_fault=data.get("contact_fault",false);data.contact_count=data.get("contact_count",0);data.contact_wait=data.get("contact_wait",randf_range(240,420))
	kit.visible=not data.uv;game.targets.inspection_kit.collision_layer=1 if kit.visible else 0
	for id in pickups:
		pickups[id].visible=not id in data.packs;game.targets[id].collision_layer=1 if pickups[id].visible else 0
	apply_light()
func apply_light() -> void:
	var torch: SpotLight3D=game.player.torch
	var uv: bool=int(data.get("mode",1))==2 and data.get("uv",false) and float(data.get("charge",100))>0
	torch.visible=int(data.get("mode",1))!=0 and winding<=0 and not game.player.viewmodel.replacing_pack()
	torch.light_color=Color(.48,.29,1.0) if uv else Color(.82,.88,1)
	torch.light_energy=.70 if uv else (.27 if float(data.get("charge",100))<=0 else 1.10)
	if data.get("contact_fault",false):
		torch.light_energy*=fault_fade
	torch.spot_range=8 if float(data.get("charge",100))<=0 else (11 if uv else 17)
func is_uv() -> bool:
	return data.get("uv",false) and int(data.get("mode",1))==2 and float(data.get("charge",0))>0 and winding<=0 and not data.get("contact_fault",false) and not game.player.viewmodel.replacing_pack()
func cycle() -> void:
	data.mode=(int(data.mode)+1)%(3 if data.uv else 2);apply_light()
	game.presentation.notify(["Torch off","White light","Inspection light"][int(data.mode)])
func status() -> void:
	game.presentation.show_battery_status()
	if data.get("contact_fault",false):game.presentation.notify("Loose contact. "+tap_instruction())
func replace_pack() -> void:
	if game.player.viewmodel.replacing_pack():return
	if is_instance_valid(game.physical.held):game.presentation.notify("I need a free hand to change the pack.");return
	if int(data.spares)<=0:
		game.presentation.notify("No spare packs. Hold to wind the backup." if float(data.charge)<20 else "No spare packs. The backup can be wound when charge is low.");return
	if float(data.charge)>95:game.presentation.notify("Battery is still full.");return
	data.spares=int(data.spares)-1;data.charge=100.0;data.contact_fault=false;notified_low=false
	if game.player.active and game.presentation.prefs.data.viewmodel:game.player.viewmodel.start_pack_change()
	else:game.sound("latch",game.player.position,-32)
	apply_light();game.save_game(true);status()
func collect(id: String) -> void:
	if id=="inspection_kit":
		if data.uv:return
		data.uv=true;data.mode=2;kit.visible=false;game.targets.inspection_kit.collision_layer=0
		game.events.notes=game.events.get("notes",{})
		game.events.notes["INSPECTION KIT"]="The case is stamped 2018. The house was taken off the service list in 1999. I don't know who left it here.\n\n365nm head: reveals fluorescent security ink. The spare head fits my work torch. F / RB changes mode. B / D-pad Up checks charge. T / Y changes the battery pack. With no spares, hold it to wind the backup cap.\n\nA label inside the case says the office report sleeves use the same security ink."
		game.presentation.notify("UV head fitted. RB changes light; check report sleeves for fluorescent ink." if game.controller.used else "UV head fitted. F changes light; check report sleeves for fluorescent ink.")
	else:
		if id in data.packs:return
		data.packs.append(id);data.spares=int(data.spares)+1;pickups[id].visible=false;game.targets[id].collision_layer=0
		game.presentation.notify("Battery pack taken / %d spare"%int(data.spares))
	apply_light();game.sound("latch",game.player.position,-32);game.save_game(true)
func _physics_process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	step_contact(delta)
	step_power(delta)
func step_power(delta: float,drain:=true) -> void:
	if winding>0:
		if not Input.is_action_pressed("battery_replace"):winding=0;apply_light();return
		winding+=delta
		if winding>=3.2:
			data.charge=maxf(float(data.charge),25);winding=0;apply_light();game.save_game(true);game.presentation.notify("Backup charged / 25%")
		return
	if Input.is_action_pressed("battery_replace") and int(data.spares)==0 and float(data.charge)<20:
		winding=.001;apply_light();game.presentation.notify("Winding backup... keep holding");return
	if drain and int(data.mode)!=0 and not data.get("contact_fault",false):
		data.charge=maxf(0,float(data.charge)-delta*(UV_DRAIN if is_uv() else WHITE_DRAIN))
		if float(data.charge)<=20 and not notified_low:
			notified_low=true;game.presentation.show_battery_status(5.0);var control: String="Y" if game.controller.used else "T"
			game.presentation.notify("Torch battery low. "+control+" fits a spare pack." if int(data.spares)>0 else "Torch battery low. Hold "+control+" to wind the backup.")
		apply_light()
func tap_instruction() -> String:
	return "D-pad Down taps the torch." if game.controller.used else "V taps the torch."
func safe_contact_window() -> bool:
	return not (is_instance_valid(game.last_call) and game.last_call.busy()) and game.started and not game.menu_open and not game.ended and not game.threat.active() and not game.recount.active and not game.capture_director.active and not game.player.viewmodel.replacing_pack() and game.horror.beat=="" and not game.chapter.active and not (game.impossible_room.active and game.impossible_room.inside(game.player.position)) and not game.events.get("exit_blackout_running",false)
func start_contact_fault() -> bool:
	if not safe_contact_window() or not game.presentation.prefs.data.get("torch_contacts",true) or int(data.mode)!=1 or float(data.charge)<25 or int(data.contact_count)>=2 or data.contact_fault:return false
	data.contact_fault=true;data.contact_count=int(data.contact_count)+1;fault_fade=1
	game.presentation.notify("Loose torch contact. "+tap_instruction())
	game.sound("latch",game.player.position,-36);game.save_game(true);return true
func tap_contact() -> void:
	var failed: bool=data.get("contact_fault",false)
	data.contact_fault=false;data.contact_wait=randf_range(300,480);fault_fade=0
	game.sound("latch",game.player.position,-35)
	if is_instance_valid(game.player.viewmodel):game.player.viewmodel.tap_clock=.32
	apply_light()
	if failed:game.presentation.notify("Light steady.");game.save_game(true)
func step_contact(delta: float) -> void:
	if data.get("contact_fault",false):
		if not game.presentation.prefs.data.get("torch_contacts",true) or game.threat.active() or game.events.get("exit_blackout_running",false):data.contact_fault=false;apply_light();return
		fault_fade=move_toward(fault_fade,0,delta*(2.5 if game.reduced_flash else 7));apply_light();return
	if safe_contact_window() and int(data.mode)==1 and float(data.charge)>=25 and int(data.contact_count)<2 and game.stage>=2:
		data.contact_wait=float(data.contact_wait)-delta
		if float(data.contact_wait)<=0:start_contact_fault()
func build() -> void:
	# Existing bench's measured top is y=.80; critical equipment never becomes a loose prop.
	kit=Node3D.new();add_child(kit);kit.position=Vector3(-18.45,.805,-16.04)
	var shell: Node3D=game.model("res://assets/interiors/cardboardBoxOpen.glb",kit,Vector3.ZERO,Vector3(.38,.14,.28))
	var lens:=MeshInstance3D.new();var shape:=CylinderMesh.new();shape.top_radius=.045;shape.bottom_radius=.045;shape.height=.09;shape.radial_segments=12;lens.mesh=shape;lens.material_override=game.mat(Color("424952"));kit.add_child(lens);lens.position=Vector3(0,.08,0)
	var glass:=MeshInstance3D.new();var disc:=CylinderMesh.new();disc.top_radius=.038;disc.bottom_radius=.038;disc.height=.004;disc.radial_segments=16;glass.mesh=disc;glass.material_override=game.mat(Color("514f74"));kit.add_child(glass);glass.position=Vector3(0,.127,0)
	game.box(kit,Vector3(0,.07,.143),Vector3(.23,.07,.002),Color("aeaf9d"))
	game.collision(kit,Vector3(0,.12,0),Vector3(.40,.25,.28),"inspection_kit")
	var label: Label3D=game.label3(kit,"365nm / 2018",Vector3(0,.07,.146),0,14,Color("343c3b"));label.pixel_size=.0014
	for spec in [["battery_shed",Vector3(-18.75,.805,-16.05)],["battery_office",Vector3(4.82,.80,-8.34)]]:
		var body:=Node3D.new();add_child(body);body.position=spec[1];pickups[spec[0]]=body
		var support: Node3D=game.get_node("ShedEquipmentBench" if spec[0]=="battery_shed" else "ArchiveWorkDesk")
		var top: float=game.surface_height(support,body.position,1.2)
		if is_finite(top):body.position.y=top
		# Four cells in a dark reusable sleeve, not a floating pickup icon.
		game.box(body,Vector3(0,.035,0),Vector3(.10,.07,.075),Color("444d46"))
		for offset in [Vector2(-.011,-.011),Vector2(.011,-.011),Vector2(-.011,.011),Vector2(.011,.011)]:
			var cell:=MeshInstance3D.new();var cylinder:=CylinderMesh.new();cylinder.top_radius=.009;cylinder.bottom_radius=.009;cylinder.height=.068;cylinder.radial_segments=8;cell.mesh=cylinder;cell.material_override=game.mat(Color("8f927b"));body.add_child(cell);cell.position=Vector3(offset.x,.04,offset.y)
		game.collision(body,Vector3(0,.05,0),Vector3(.15,.12,.13),spec[0])
