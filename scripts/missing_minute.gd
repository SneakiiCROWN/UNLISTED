extends Node3D
# A second investigation chapter. All progress is optional schema-1 event data.
var game: Node3D
var room: Node3D
var radio: Node3D
var cabinet: Node3D
var drawer: Node3D
var drawer_open:=false
var active:=false
var quiet:=0.0
var room_lamp: OmniLight3D
var page: MeshInstance3D
var return_clock:=-1.0
var return_cue:=0
var door_clock:=-1.0
var watch_clock:=-1.0
var unseen:=0.0
var watch_seen:=false
var watch_walk:=0.0
const LAST_PAGE:="23:18 / Simon Ward\n\nThat is Eli's drawing on the cupboard. BACK FOR TEA. He put it in my toolbox this morning.\n\nHe is not here. I rang home. He answered and asked when I was coming back.\n\nThe radio in the office is playing the same station we leave on in the kitchen. Through the other door I can hear someone getting out of his bed.\n\nThey want an empty-house return. I won't sign it. There is someone still inside, even if it isn't my son.\n\nIf this gets home: Eli, I didn't leave you. I was trying to make sure nobody got left here.\n\nThe rest of the page is blank."
func _ready() -> void:
	name="TheMissingMinute"
	build_work_surface();build_room();restore()
	# Outdoor confrontation reuses the same physical AI and front-door portal.
	# Nothing is connected across the solid east house wall.
	var chain: Array[int]=[]
	for point in [Vector3(9.15,0,2),Vector3(9.15,0,6),Vector3(5,0,8),Vector3(0,0,7)]:
		var id: int=game.threat.graph.get_point_count();game.threat.graph.add_point(id,point);chain.append(id)
	for i in range(chain.size()-1):game.threat.graph.connect_points(chain[i],chain[i+1])
	game.threat.graph.connect_points(chain[-1],9)
func model(name_: String,pos: Vector3,size_: Vector3,angle:=0.0,solid:=true) -> Node3D:
	var result: Node3D=game.model("res://assets/interiors/"+name_+".glb",room,pos,size_,angle,solid)
	finish_materials(result)
	return result
func finish_materials(root: Node3D) -> void:
	for mesh in game.all_meshes(root):
		for i in mesh.mesh.get_surface_count():
			var source: Material=mesh.get_active_material(i)
			var kind: String=source.resource_name.to_lower() if source else "wood"
			var texture:="res://assets/dusk/psx_house_old_wood_01.png";var tint:=Color("60584b")
			if "metal" in kind:texture="res://assets/dusk/psx_house_steel_01.png";tint=Color("4c514a")
			elif "carpet" in kind or "plant" in kind:texture="res://assets/original/work_canvas.png";tint=Color("8e978a") if "white" in kind else Color("4f675c")
			elif "lamp" in kind:texture="res://assets/original/work_canvas.png";tint=Color("c2b995")
			mesh.set_surface_override_material(i,game.texture_mat(texture,tint))
func build_work_surface() -> void:
	radio=game.model("res://assets/interiors/radio.glb",self,Vector3(4.88,.81,-8.56),Vector3(.36,.25,.20))
	radio.name="ArchiveReturnReceiver";finish_materials(radio)
	game.collision(self,Vector3(4.88,.95,-8.55),Vector3(.38,.26,.22),"return_receiver")
	var mat: MeshInstance3D=game.box(self,Vector3(6.27,.809,-8.56),Vector3(.38,.012,.36),Color("3b3d34"));mat.name="CarbonWritingMat"
	game.box(self,Vector3(6.27,.819,-8.56),Vector3(.30,.004,.31),Color("aaa18a"))
	game.collision(self,Vector3(6.27,.827,-8.56),Vector3(.36,.025,.34),"carbon_return")
	var pencil: MeshInstance3D=game.box(self,Vector3(6.50,.821,-8.55),Vector3(.012,.012,.24),Color("8e7650"));pencil.rotation.y=.15
func build_room() -> void:
	room=Node3D.new();room.name="RememberedBedroom";add_child(room)
	var bed=model("bedSingle",Vector3(6.3,0,1.0),Vector3(1.20,.72,2.25))
	bed.name="ChildhoodBed"
	# Keep the licensed fabric readable as cloth, instead of recolouring it as wood.
	for mesh in game.all_meshes(bed):
		if mesh.name.to_lower().contains("cover") or mesh.name.to_lower().contains("pillow"):
			mesh.material_override=game.texture_mat("res://assets/original/work_canvas.png",Color("6b7368"))
	cabinet=model("cabinetBedDrawer",Vector3(4.95,0,1.85),Vector3(.65,.64,.55))
	cabinet.name="MemoryBedsideCabinet"
	var found=cabinet.find_children("*drawer*","Node3D",true,false)
	if not found.is_empty():drawer=found[0]
	if is_instance_valid(drawer):
		drawer.set_meta("rest_z",drawer.position.z)
		if drawer is MeshInstance3D:
			var bounds: AABB=drawer.get_aabb()
			game.collision(drawer,Vector3(bounds.get_center().x,bounds.get_center().y,bounds.end.z-.008),Vector3(bounds.size.x,bounds.size.y,.016),"memory_drawer")
			game.collision(drawer,Vector3(bounds.get_center().x,bounds.position.y+.006,bounds.get_center().z),Vector3(bounds.size.x,.012,bounds.size.z))
			var paper_pos:=Vector3(bounds.get_center().x,bounds.position.y+.018,bounds.get_center().z)
			page=game.box(drawer,paper_pos,Vector3(bounds.size.x*.70,.003,bounds.size.z*.65),Color("a49b82"))
			page.material_override=game.texture_mat("res://assets/original/aged_paper.png",Color("b0a68c"))
			game.collision(drawer,paper_pos+Vector3.UP*.01,Vector3(bounds.size.x*.70,.02,bounds.size.z*.65),"memory_page")
	# The whole cabinet bounds remain solid: the storage interaction never clips a player inside it.
	game.collision(room,Vector3(4.95,.43,2.15),Vector3(.54,.28,.12),"memory_drawer")
	model("lampRoundTable",Vector3(4.97,.65,1.88),Vector3(.25,.34,.25),0,false)
	model("books",Vector3(4.95,.65,1.66),Vector3(.27,.12,.15),0,false)
	var shelf=model("bookcaseClosedDoors",Vector3(6.3,0,-2.48),Vector3(1.25,1.85,.56))
	shelf.name="RememberedStorage"
	room_lamp=OmniLight3D.new();room.add_child(room_lamp);room_lamp.position=Vector3(4.97,.95,1.88)
	room_lamp.light_color=Color(.83,.68,.43);room_lamp.light_energy=.55;room_lamp.omni_range=4;room_lamp.shadow_enabled=true
	# The same childhood plan is remembered here, without inventing a new photograph.
	var paper: MeshInstance3D=game.box(room,Vector3(6.28,1.22,-2.188),Vector3(.29,.33,.006),Color("9b947a"))
	var ink: Label3D=game.label3(room,"FOR DAD\nBACK FOR TEA\n\nELI / 7",Vector3(6.28,1.22,-2.18),0,14,Color("303730"));ink.pixel_size=.0022
	room.visible=false;set_collisions(room,false)
func set_collisions(root: Node,on: bool) -> void:
	for body in root.find_children("*","CollisionObject3D",true,false):
		if not body.has_meta("chapter_layer"):body.set_meta("chapter_layer",body.collision_layer)
		body.collision_layer=int(body.get_meta("chapter_layer")) if on else 0
func set_room(on: bool) -> void:
	active=on;room.visible=on;set_collisions(room,on)
	game.lounge_contents.visible=not on;set_collisions(game.lounge_contents,not on)
	room_lamp.visible=on
	if game.roomtone:game.roomtone.volume_db=-80 if on else (-65 if game.isolated else -28)
func restore() -> void:
	set_room(game.events.get("memory_bedroom_active",false))
	drawer_open=game.events.get("memory_drawer_open",false)
	return_clock=-1;door_clock=-1;quiet=0;watch_clock=-1
	if game.events.get("memory_watch_started",false) and not game.events.get("memory_watch_done",false):game.events.memory_watch_pending=true
	if is_instance_valid(drawer):drawer.position.z=float(drawer.get_meta("rest_z",drawer.position.z))+(.22 if drawer_open else 0)
	sync_page()
func sync_page() -> void:
	if not is_instance_valid(page):return
	page.visible=not game.events.get("last_page_read",false)
	game.targets.memory_page.collision_layer=1 if active and drawer_open and page.visible else 0
func open_carbon() -> void:
	if not game.events.get("field_return_read",false):
		game.inspect_text("WRITING MAT","A soft pencil and a sheet of tracing paper. The mat is marked with old graphite.");return
	var p=game.presentation;p.pause_world();p.clear_transients();p.clear_card();p.section="document"
	p.label(p.card_body,"ORIGINAL RETURN / PRESSURE MARKS",15,"Meta")
	p.label(p.card_body,"THE TORN PAGE",30,"Title")
	p.label(p.card_body,"Drag the pencil across the backing sheet to bring out the impressions.",18)
	var rubbing=load("res://scripts/carbon_rubbing.gd").new();rubbing.game=game;p.card_body.add_child(rubbing)
	p.add_button("Complete rubbing / motor assistance",rubbing.complete_accessibly,true,p.card_body)
	p.add_button("Keep sheet",func():game.save_game();p.resume_game(),true,p.card_body)
	p.entrance_animation(p.card)
func complete_rubbing() -> void:
	game.events.carbon_read=true
	game.events.notes=game.events.get("notes",{})
	game.events.notes["TORN PAGE / IMPRESSIONS"]="104.6 / HOME\nELI IS AT HOME. I RANG.\nTHE DOOR WAS SHUT WHEN IT CHANGED.\n\nDad's pencil pressed through the missing page onto its backing sheet."
	game.save_game()
func open_receiver() -> void:
	if game.stage<3:game.message("The receiver is silent. Its supply light is out.",3);return
	if game.threat.active():game.message("I can't listen with him this close.",3);return
	var p=game.presentation;p.pause_world();p.clear_transients();p.clear_card();p.section="document"
	p.label(p.card_body,"ARCHIVE / RETURN RECEIVER",15,"Meta")
	var widget=load("res://scripts/return_receiver.gd").new();widget.game=game;p.card_body.add_child(widget)
	p.add_button("Leave receiver",func():game.save_game();p.resume_game(),true,p.card_body)
	p.entrance_animation(p.card)
func receive_return() -> void:
	# Knowing the frequency is enough. Never require a journal flag as a magic key.
	if not game.isolated:return
	if not game.events.get("receiver_found",false):
		game.events.receiver_found=true;return_clock=0;return_cue=0;game.save_game()
func use_drawer() -> void:
	if not active:return
	drawer_open=not drawer_open;game.events.memory_drawer_open=drawer_open
	if is_instance_valid(drawer):
		if not drawer.has_meta("rest_z"):drawer.set_meta("rest_z",drawer.position.z)
		create_tween().tween_property(drawer,"position:z",float(drawer.get_meta("rest_z"))+(.22 if drawer_open else 0),.45)
	game.sound("door",Vector3(4.95,.4,1.85),-34)
	sync_page();game.save_game()
func take_page() -> void:
	if not active or not drawer_open or game.events.get("last_page_read",false):return
	game.events.last_page_read=true;sync_page()
	game.inspect_text("SIMON / THE MISSING PAGE",LAST_PAGE)
	game.events.memory_watch_pending=true
	game.save_game();door_clock=0
func point_visible(point: Vector3) -> bool:
	if game.player.camera.is_position_behind(point):return false
	if not game.get_viewport().get_visible_rect().has_point(game.player.camera.unproject_position(point)):return false
	var q:=PhysicsRayQueryParameters3D.create(game.player.camera.global_position,point,1)
	q.exclude=game.impossible_room.sight_exclusions.duplicate();q.exclude.append(game.presence.get_rid())
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()
func watcher_process(delta: float) -> void:
	if game.threat.active() or game.horror.beat!="":return
	if game.events.get("memory_watch_pending",false) and watch_clock<0 and not game.events.get("memory_watch_done",false):
		var position_:=Vector3(9.15,0,2.0)
		position_.y=game.get_node("BriarLaneExterior").ground_height(position_.x,position_.z)
		if point_visible(position_+Vector3.UP*1.65) or not game.impossible_room.inside(game.player.position):return
		game.presence.position=position_+Vector3.UP*.035;game.presence.visible=true;game.threat.set_collision(true)
		game.presence.look_at(Vector3(game.player.position.x,game.presence.position.y,game.player.position.z))
		game.surveyor_actor.set_mode("watch");watch_clock=0;unseen=0;watch_seen=false;watch_walk=0
		game.events.memory_watch_pending=false;game.events.memory_watch_started=true
	if watch_clock<0:return
	watch_clock+=delta
	if game.player.position.x>7.75 and game.player.position.distance_to(game.presence.position)<2.8:
		# Approaching the staged figure is a real confrontation, never an intangible prop.
		var pose: Vector3=game.presence.position
		game.events.memory_watch_done=true;game.events.memory_watch_pending=false
		game.events.threat_origin="window";game.events.threat_spawn=[pose.x,pose.y,pose.z]
		game.events.threat_pending=true;game.events.threat_resolved=false
		watch_clock=-1;game.save_game();game.threat.begin(false,pose);return
	var seen:=point_visible(game.presence.position+Vector3.UP*1.65)
	watch_seen=watch_seen or seen;unseen=0.0 if seen else unseen+delta
	if watch_seen and watch_clock>3 and watch_walk<1.2:
		var body: CharacterBody3D=game.presence;var before:=body.position
		body.rotation.y=lerp_angle(body.rotation.y,-PI/2,1-exp(-delta*1.7))
		body.velocity=Vector3(.42,body.velocity.y-20*delta,0);body.move_and_slide()
		watch_walk+=body.position.distance_to(before);game.surveyor_actor.locomotion(.42)
	else:game.surveyor_actor.set_mode("watch")
	if watch_clock>3 and unseen>.7 and (watch_seen or not game.impossible_room.inside(game.player.position)):
		game.presence.visible=false;game.threat.set_collision(false);game.presence.velocity=Vector3.ZERO
		watch_clock=-1;game.events.memory_watch_done=true;game.save_game()
func room_observed() -> bool:
	if not active:return game.impossible_room.can_see_changed_room()
	for point in [Vector3(6.3,.55,1),Vector3(4.95,.55,1.85),Vector3(6.3,1.4,-2.4),Vector3(4,.15,1)]:
		if game.player.camera.is_position_behind(point):continue
		if not game.get_viewport().get_visible_rect().has_point(game.player.camera.unproject_position(point)):continue
		var q:=PhysicsRayQueryParameters3D.create(game.player.camera.global_position,point,1);q.exclude=game.impossible_room.sight_exclusions
		var hit=get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty() or room.is_ancestor_of(hit.collider):return true
	return false
func can_change() -> bool:
	return game.impossible_room.closed() and not game.impossible_room.inside(game.player.position,.65) and not room_observed() and not game.threat.active() and not game.physical.held
func _process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	sync_page()
	if return_clock>=0:
		return_clock+=delta
		if return_cue<3 and return_clock>.6+return_cue*.9:
			game.sound("prop_impact",Vector3(3.2,1,-1.8),-30-return_cue*2).pitch_scale=.75+return_cue*.12;return_cue+=1
		if return_cue>=3:return_clock=-1
	if not game.events.get("case_v3",false):return
	watcher_process(delta)
	if not active and game.events.get("receiver_found",false) and not game.events.get("bedroom_left",false):
		if can_change():
			quiet+=delta
			if quiet>1.0:
				game.impossible_room.reset();game.events.impossible_room_active=false
				set_room(true);game.events.memory_bedroom_active=true
				game.sound("latch",game.doors.lounge.position,-32);game.save_game()
		else:quiet=0
	if active and game.events.get("last_page_read",false):
		if not game.impossible_room.inside(game.player.position,.4):
			game.events.bedroom_left=true
		if game.events.get("bedroom_left",false) and can_change():
			set_room(false);game.events.memory_bedroom_active=false;game.save_game()
	if door_clock>=0:
		door_clock+=delta
		if door_clock>1.8:
			# The source is beyond the door, never a text-only explanation or a forced grab.
			game.sound("door",Vector3(.8,1.1,1),-29);game.sound("step",Vector3(0,0,-1),-29)
			door_clock=-1
