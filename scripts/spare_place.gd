extends Node3D
# A false domestic memory and a physical search, using the existing rest corner.
var game: Node3D
var cloth: MeshInstance3D
var card: Node3D
var lid: Node3D
var clock:=0.0
var uncover:=0.0
var quiet:=0.0
var hunt_resume:=false
var hunt_running:=false
var heard:=false
const COT:=Vector3(-6.8,.53,-5.35)
func _ready() -> void:
	name="TheSparePlace";build();restore()
	var id: int=game.threat.graph.get_point_count()
	game.threat.graph.add_point(id,Vector3(-4.9,0,-5.8));game.threat.graph.connect_points(id,12);game.threat.graph.connect_points(id,13)
func build() -> void:
	# Replace only the existing folded cover, retaining the approved cot/frame/collision.
	game.get_node("FoldedRestBlanket").visible=false
	cloth=MeshInstance3D.new();add_child(cloth);cloth.position=COT;cloth.name="RestCotCover"
	var material:=ShaderMaterial.new();material.shader=load("res://shaders/memory_wool.gdshader")
	material.set_shader_parameter("weave",load("res://assets/original/work_canvas.png"));cloth.material_override=material
	game.collision(self,Vector3(-6.8,.69,-5.25),Vector3(.65,.17,.9),"spare_cover")
	card=Node3D.new();add_child(card);card.position=Vector3(-6.80,.55,-5.35)
	# A folded card occupies real cot fabric, with no floating world label.
	var paper: StandardMaterial3D=game.texture_mat("res://assets/original/aged_paper.png",Color("c1ae88"))
	var back: MeshInstance3D=game.box(card,Vector3.ZERO,Vector3(.26,.004,.21),Color.WHITE);back.material_override=paper
	lid=Node3D.new();card.add_child(lid);lid.position=Vector3(-.13,.005,0)
	var front: MeshInstance3D=game.box(lid,Vector3(.13,0,0),Vector3(.26,.003,.21),Color.WHITE);front.material_override=paper
	var ink: Label3D=game.label3(lid,"ELI\n8\n1999",Vector3(.13,.008,0),0,28,Color("534a38"));ink.rotation.x=-PI/2;ink.rotation.y=PI;ink.pixel_size=.0018;ink.shaded=false;ink.font=load("res://assets/fonts/Kalam-Regular.ttf")
	var signature: Label3D=game.label3(card,"Back for tea.\nDad",Vector3(0,.004,0),0,24,Color("494738"));signature.rotation.x=-PI/2;signature.rotation.y=PI;signature.pixel_size=.0018;signature.shaded=false;signature.font=ink.font
	game.collision(self,Vector3(-6.8,.57,-5.35),Vector3(.28,.07,.25),"spare_card")
	# Small personal traces sit on existing backing: no new obstruction or room shell.
	for y in [1.05,1.13,1.21]:
		var mark: MeshInstance3D=game.box(self,Vector3(-7.382,y,-5.45),Vector3(.003,.009,.12),Color("726953"));mark.name="CopiedHeightMark"
	var tag: Label3D=game.label3(self,"ELI / 1999",Vector3(-7.375,1.25,-5.45),PI/2,20,Color("746f56"));tag.pixel_size=.0014;tag.shaded=true
func cover_mesh() -> void:
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3]=[]
	for z in 21:
		for x in 13:
			var xx: float=-.48+float(x)*.08;var zz: float=-.88+float(z)*.088
			var breathing: float=.0
			if game.events.get("spare_offered",false) and not game.events.get("spare_uncovered",false):breathing=(.19+.018*sin(clock*1.35))*exp(-pow(xx/.27,4))*exp(-pow((zz+.07)/.62,4))
			var hem: float=-.14 if x in [0,12] else .0
			var height: float=hem+.012*sin(x*1.8+z*.7)+breathing*(1-uncover)
			points.append(Vector3(xx,height,lerpf(zz,.65+zz*.16,uncover)))
	for z in 20:
		for x in 12:
			var i:=z*13+x
			for index in [i,i+13,i+1,i+1,i+13,i+14]:
				tool.set_uv(Vector2(float(index%13)/12,float(index/13)/20));tool.add_vertex(points[index])
	tool.generate_normals();cloth.mesh=tool.commit()
func observed() -> bool:
	var camera: Camera3D=game.player.camera
	for point in [COT+Vector3.UP*.25,COT+Vector3(0,.2,.7),Vector3(-7.375,1.15,-5.45)]:
		if camera.is_position_behind(point):continue
		if not game.get_viewport().get_visible_rect().has_point(camera.unproject_position(point)):continue
		var query:=PhysicsRayQueryParameters3D.create(camera.global_position,point,1)
		var hit:=get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or is_ancestor_of(hit.collider) or hit.position.distance_to(point)<.18:return true
	return false
func restore() -> void:
	clock=0;quiet=0;heard=false;hunt_running=false
	hunt_resume=game.events.get("spare_hunt_started",false) and not game.events.get("spare_hunt_done",false)
	uncover=1 if game.events.get("spare_uncovered",false) else 0
	lid.rotation.z=2.0 if game.events.get("spare_card_read",false) else 0
	sync();cover_mesh()
func sync() -> void:
	var offered: bool=game.events.get("spare_offered",false)
	card.visible=offered and uncover>.92
	game.targets.spare_card.collision_layer=1 if card.visible else 0
	game.targets.spare_cover.collision_layer=1 if offered and uncover<.1 else 0
	for node in get_children():
		if node is Label3D or str(node.name).begins_with("CopiedHeightMark"):node.visible=offered
func use(id: String) -> void:
	if not game.events.get("spare_offered",false):return
	if id=="spare_cover":
		if game.threat.active():return
		game.events.spare_uncovered=true;game.sound("capture_contact",COT,-34)
		game.save_game(true)
	elif id=="spare_card" and card.visible:
		if not game.events.get("spare_card_read",false):
			game.events.spare_card_read=true
			game.events.notes=game.events.get("notes",{})
			game.events.notes["THE SPARE PLACE"]="An eighth-birthday card on the work cot. Dad's name, 1999. He disappeared the year before. He never came to that birthday.\n\nThe shape beneath the blanket was empty. The house has my name and the date. That doesn't make this a memory."
			game.save_game(true)
		lid.rotation.z=0.0 if lid.rotation.z>1 else 2.0
func start_search() -> bool:
	if game.threat.active() or game.horror.beat!="" or game.horror.audition!="" or game.chapter.active:return false
	var spawn:=Vector3(0,.04,-4.0)
	if game.player.position.distance_to(spawn)<5:return false
	if game.chapter.point_visible(spawn+Vector3.UP*1.6):return false
	if not game.events.get("spare_hunt_started",false):
		game.events.spare_prior_resolved=game.events.get("threat_resolved",false)
		game.events.spare_prior_pending=game.events.get("threat_pending",false)
		game.events.spare_prior_origin=game.events.get("threat_origin","")
	game.events.spare_hunt_started=true;hunt_running=true;hunt_resume=false
	game.threat.begin(false,spawn);game.threat.last_known=Vector3(-4.9,0,-5.8)
	game.save_game(true);return true
func _physics_process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	clock+=delta
	if not game.events.get("spare_offered",false):
		if game.events.get("line_strip_read",false) and not observed() and not game.threat.active() and not game.chapter.active:
			quiet+=delta
			if quiet>.7:
				game.events.spare_offered=true;sync();game.sound("door",COT,-34).pitch_scale=.75;game.save_game(true)
		else:quiet=0
	var old_uncover: float=uncover
	if game.events.get("spare_uncovered",false):uncover=move_toward(uncover,1,delta*.8)
	sync()
	if int(clock*12)!=int((clock-delta)*12) and ((game.events.get("spare_offered",false) and not game.events.get("spare_uncovered",false)) or old_uncover<uncover):cover_mesh()
	if old_uncover<1 and uncover==1:cover_mesh()
	if game.events.get("spare_offered",false) and not heard and not game.events.get("spare_uncovered",false) and game.player.position.distance_to(COT)<5:
		heard=true;game.sound("capture_contact",COT,-37)
	if game.events.get("spare_card_read",false) and not game.events.get("spare_hunt_done",false):
		if not game.events.get("spare_hunt_started",false) or hunt_resume:
			if not game.events.get("threat_pending",false) or game.events.get("threat_resolved",false):start_search()
	if hunt_running and game.threat.state=="observe" and not game.threat.can_see_player():
		game.threat.change("investigate");game.threat.last_known=Vector3(-4.9,0,-5.8);game.threat.plan(game.threat.last_known)
	if hunt_running and game.threat.state=="complete":
		hunt_running=false;game.events.spare_hunt_done=true
		game.events.threat_resolved=game.events.get("spare_prior_resolved",false)
		game.events.threat_pending=game.events.get("spare_prior_pending",false)
		game.events.threat_origin=game.events.get("spare_prior_origin","")
		game.save_game(true)
