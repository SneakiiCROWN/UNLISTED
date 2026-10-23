extends Node3D
# Final close-out is experienced in the real hall. No camera lock or new actor.
var game: Node3D
var clock:=0.0
var active:=false
var shutter: MeshInstance3D
var sheet: Label3D
var hall: Array[OmniLight3D]=[]
var sources: Array[AudioStreamPlayer3D]=[]
var cue_index:=0
var was_isolated:=false
var porch: OmniLight3D
var porch_energy:=1.3
var archive: Label3D
var archive_text: String
var archive_font:=15
var archive_pixels:=.005
const TIMES:=[1.2,2.7,4.3,5.9,7.5]
const ZONES:=[-7.0,-4.0,-1.0,2.6]

func _ready() -> void:
	sheet=game.targets.order.get_parent().find_children("*","Label3D",false,false)[0]
	archive=game.targets.security.get_parent().find_children("*","Label3D",false,false)[0]
	archive_text=archive.text;archive_font=archive.font_size;archive_pixels=archive.pixel_size
	for light in game.lamps:
		if absf(light.position.x)<1.2 and light.position.z>-9 and light.position.z<4 and light.position.y>2:hall.append(light)
	for light in game.find_children("*","OmniLight3D",true,false):
		if light.position.distance_to(Vector3(0,2.5,5))<.1:porch=light;porch_energy=light.light_energy
	var cabinet:=Node3D.new();cabinet.name="FieldReturnDrawer";add_child(cabinet)
	cabinet.position=Vector3(3.85,-1.53,-23.84)
	for side in [-1,1]:game.box(cabinet,Vector3(side*.32,0,.075),Vector3(.055,.82,.17),Color("343c38"))
	game.box(cabinet,Vector3(0,-.40,.075),Vector3(.68,.05,.17),Color("343c38"))
	game.box(cabinet,Vector3(0,.75,.10),Vector3(.68,.62,.20),Color("343c38"))
	for x in [-.28,.28]:
		for y in [-.36,.36]:game.box(cabinet,Vector3(x,y,-.02),Vector3(.04,.04,.12),Color("343c38"))
	game.paper(Vector3(3.85,-1.53,-23.73),"relay_record","FIELD RETURN\n1998\n\nS. WARD\nIN / 23:17\nEXIT / --")
	var paper: Node3D=game.targets.relay_record.get_parent()
	paper.name="OriginalRelayReturn";paper.reparent(cabinet)
	var text: Label3D=paper.find_children("*","Label3D",false,false)[0]
	text.font_size=13;text.pixel_size=.0028
	shutter=game.box(cabinet,Vector3(0,0,.15),Vector3(.59,.73,.025),Color("424b45"))
	shutter.name="MechanicalReturnCover"
	shutter.material_override=game.texture_mat("res://assets/dusk/psx_house_steel_01.png",Color(.43,.47,.39))
	restore_state()

func restore_state() -> void:
	for source in sources:
		if is_instance_valid(source):source.stop();source.queue_free()
	sources.clear()
	clock=clampf(float(game.events.get("recount_elapsed",0)),0,8.8)
	active=game.events.get("recount_started",false) and not game.events.get("recount_complete",false)
	cue_index=0
	while cue_index<TIMES.size() and TIMES[cue_index]<=clock:cue_index+=1
	shutter.position.y=.67 if game.isolated else 0.0
	was_isolated=game.isolated
	game.targets.relay_record.collision_layer=1 if game.isolated else 0
	if is_instance_valid(porch):porch.light_energy=porch_energy
	update_sheet()
	update_archive()

func update_archive() -> void:
	var returned: bool=game.events.get("return_request",false)
	archive.text="POWER RESTORED\nWORK ORDER 017\n1998 JOB: NOT CLOSED" if returned else archive_text
	archive.font_size=12 if returned else archive_font
	archive.pixel_size=.0035 if returned else archive_pixels

func update_sheet() -> void:
	var complete: bool=game.events.get("recount_complete",false)
	sheet.text="1998 / TONIGHT\n\nS. WARD / IN\nE. WARD / IN\n\nEXIT / --\nWITNESS / ____" if complete else "NIGHT CALL\n\nE. WARD\n23:17\n\nVACANT"
	sheet.font_size=16 if complete else 17
	sheet.pixel_size=.0035 if complete else .005
	if str(game.events.get("departure_pending",""))!="":
		sheet.text="WITNESSED / E. WARD\n\nS. WARD / IN\n\nRECEIPT RETAINED\nEXIT / PENDING"

func request() -> bool:
	if game.events.get("case_v2",false) and not game.events.get("field_return_read",false):
		game.inspect_text("FIELD RETURN MISSING","I only have the office record. Dad's note says his original report is in the service cabinet downstairs.")
		return false
	if game.events.get("case_v3",false) and not game.events.get("bedroom_left",false):
		game.inspect_text("THE UNFINISHED RETURN",game.NOTES.unfinished_return(game.events))
		return false
	if game.events.get("case_v4",false) and not game.events.get("call_complete",false):
		game.inspect_text("DAD'S LAST TEST","Dad's later notes describe another test. I want to check what happened before I close this job.\n\n"+game.last_call.hint());return false
	if active:return false
	if game.events.get("recount_complete",false):return true
	# A retained room-memory is scenery, not a live encounter. It must never
	# prevent the porch close-out after the player has escaped the Surveyor.
	if game.threat.active() or game.events.get("threat_pending",false):
		game.inspect_text("ATTENDANCE / STILL OPEN","Simon Ward / 1998 / IN\nEli Ward / tonight / IN\n\nNeither of us has been recorded leaving. I can't stop here while he's nearby.")
		return false
	active=true;clock=0;cue_index=0
	game.events.recount_started=true;game.events.recount_elapsed=0.0
	if not game.doors.front.opened:
		game.doors.front.open_away_from(game.player.global_position)
		game.doors.front.set_open(true,1.5)
	game.presentation.clear_transients();game.save_game()
	return false

func _process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	if game.isolated and not was_isolated:
		var catch: AudioStreamPlayer3D=game.sound("latch",shutter.global_position,-24)
		game.sound_caption("A mechanical catch releases.",2,"RELAY CABINET",catch)
	was_isolated=game.isolated
	if game.isolated and not game.events.get("return_request",false) and game.events.get("threat_resolved",false) and not game.threat.active():
		var p: Vector3=game.player.position
		if p.y>-.3 and absf(p.x)<6 and p.z< -4 and p.z> -9:
			game.events.return_request=true
			game.sound("relay",game.targets.security.global_position,-27)
			game.security_light.light_energy=.65
			update_archive()
	shutter.position.y=move_toward(shutter.position.y,.67 if game.isolated else 0.0,delta*.45)
	game.targets.relay_record.collision_layer=1 if game.isolated else 0
	# The isolated plant falls quiet, including when loading an old save.
	for child in game.get_children():
		if child is AudioStreamPlayer3D and child.get_meta("source_slot","")=="hum":
			child.volume_db=move_toward(child.volume_db,-65 if game.isolated else -24,delta*18)
	if not active:return
	# Walking away remains possible. Resume the recount when the listener returns.
	if game.player.global_position.distance_to(game.targets.order.global_position)>8:return
	clock+=delta;game.events.recount_elapsed=clock
	if is_instance_valid(porch):porch.light_energy=lerpf(porch.light_energy,.28 if clock<6 else porch_energy,1-exp(-delta*1.5))
	while cue_index<TIMES.size() and clock>=TIMES[cue_index]:
		if cue_index<4:
			var sound: AudioStreamPlayer3D=game.sound("step",Vector3(.10 if cue_index%2==0 else -.10,0,ZONES[cue_index]),-21)
			sound.pitch_scale=.86;sources.append(sound)
			if cue_index==0:game.sound_caption("Footsteps in the hall.",3,"INSIDE",sound)
		else:
			var sound: AudioStreamPlayer3D=game.sound("latch",game.targets.order.global_position,-24)
			sources.append(sound)
		cue_index+=1
	# Slow practical-light swell rather than strobing or forced camera movement.
	var zone: float=lerpf(-7.0,2.6,clampf((clock-1.0)/5.0,0,1))
	for light in hall:
		var target: float=.15+.65*exp(-pow((light.position.z-zone)/1.8,2))
		if clock>7.5:target=.35
		light.light_energy=lerpf(light.light_energy,target,1-exp(-delta*3))
	if clock>=8.8:
		complete(false)

func complete(skipped: bool) -> void:
	active=false;clock=8.8
	if skipped:
		for source in sources:
			if is_instance_valid(source):source.stop()
	game.events.recount_complete=true;game.events.recount_elapsed=8.8
	game.events.notes=game.events.get("notes",{})
	game.events.notes["TWO ARRIVALS / NO EXIT"]=game.NOTES.RECOUNT
	for light in hall:light.light_energy=.35
	if is_instance_valid(porch):porch.light_energy=porch_energy
	update_sheet();game.save_game()
