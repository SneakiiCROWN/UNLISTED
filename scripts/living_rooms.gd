extends Node3D
# Render-only room finishes. Existing furniture bodies and investigation targets
# remain authoritative; the lounge owns its dressing during the room-memory swap.
var game: Node3D
var cloth: ShaderMaterial
var response := 0.0
var curtain_tween: Tween
var curtain_panels: Array=[]
var curtain_control: StaticBody3D

func build(g: Node3D) -> void:
	game=g;name="LivingRoomFinishes"
	var b=load("res://scripts/interior_finish.gd").new();b.g=g
	for spec in [["paint","788077"],["trim","4c5147"],["metal","383e39"],["paper","9b967e"]]:
		var material: StandardMaterial3D=g.mat(Color(spec[1])).duplicate()
		material.roughness=.96;b.materials[spec[0]]=material
	var paint:=ShaderMaterial.new();paint.shader=load("res://shaders/aged_room_paint.gdshader")
	paint.set_shader_parameter("paper",load("res://assets/original/aged_paper.png"));b.materials.paint=paint
	b.begin(g.lounge_contents,"DomesticWallFinish")
	# Lower wall paint and timber rails are fitted to the interior faces, below
	# windows and clear of the hall doorway. They do not add collision thickness.
	b.piece("South lower paint",Vector3(4.5,.47,-2.893),Vector3(5.77,.86,.008),"paint")
	b.piece("East lower paint",Vector3(7.389,.47,.5),Vector3(.008,.86,6.77),"paint")
	for y in [.09,.92]:
		b.piece("South timber rail",Vector3(4.5,y,-2.881),Vector3(5.77,.055,.024),"trim")
		b.piece("East timber rail",Vector3(7.377,y,.5),Vector3(.024,.055,6.77),"trim")
	b.tube("Curtain pole",Vector3(7.12,2.55,.98),Vector3(7.12,2.55,3.02),.018,"metal")
	for z in [1.05,2.95]:b.tube("Wall bracket",Vector3(7.39,2.55,z),Vector3(7.12,2.55,z),.012,"metal")
	b.finish()
	cloth=ShaderMaterial.new();cloth.shader=load("res://shaders/curtain_canvas.gdshader")
	cloth.set_shader_parameter("canvas",load("res://assets/original/work_canvas.png"))
	for z in [1.04,2.70]:curtain(g.lounge_contents,z)
	# The cloth hangs from sewn tabs over the existing pole. A short real pull
	# gives the player agency over the later off-screen change.
	b.begin(g.lounge_contents,"CurtainPull")
	b.tube("Pull cord",Vector3(7.12,2.55,1.00),Vector3(6.99,1.40,1.00),.003,"trim")
	b.piece("Pull grip",Vector3(6.99,1.38,1.00),Vector3(.022,.07,.022),"trim")
	b.finish()
	curtain_control=g.collision(g.lounge_contents,Vector3(6.99,1.55,1.00),Vector3(.16,.40,.20),"lounge_curtains")
	curtain_control.collision_layer=4
	var sofa: Node3D=g.get_node("LoungeContents/LoungeSofa/CorrectedSofaVisual")
	for mesh in g.all_meshes(sofa):
		var fabric: StandardMaterial3D=g.texture_mat("res://assets/original/work_canvas.png",Color("666958")).duplicate()
		fabric.roughness=1.0;fabric.uv1_scale=Vector3(1.5,1.5,1.5)
		mesh.material_override=fabric
	b.begin(self,"RecordsRoomFinish")
	b.piece("Office lower paint",Vector3(4.5,.46,-9.884),Vector3(5.76,.84,.008),"paint")
	for y in [.08,.91]:b.piece("Office rail",Vector3(4.5,y,-9.868),Vector3(5.76,.045,.022),"trim")
	# A small physical circuit diagram belongs to the equipment, not the HUD.
	b.piece("Comparison input plate",Vector3(6.72,1.78,-9.855),Vector3(.53,.43,.016),"metal")
	b.piece("Etched diagram",Vector3(6.72,1.78,-9.843),Vector3(.49,.39,.007),"paper")
	for x in [6.57,6.87]:
		b.tube("Input trace",Vector3(x,1.84,-9.836),Vector3(x,1.70,-9.836),.0025,"metal")
		b.tube("Comparison trace",Vector3(x,1.70,-9.836),Vector3(6.72,1.70,-9.836),.0025,"metal")
	b.finish()
	for item in [["A / HALL MIC",Vector3(6.58,1.91,-9.83)],["B / ROOM RETURN",Vector3(6.85,1.84,-9.83)],["COMPARE",Vector3(6.72,1.64,-9.83)]]:
		var label: Label3D=g.label3(self,item[0],item[1],0,12,Color("252c26"))
		label.pixel_size=.0015;label.shaded=true
	# Floor finish lies flush on the existing slab, behind the walking/puzzle area.
	b.begin(self,"CellarDrainApron")
	b.piece("Manifold drip apron",Vector3(-1.5,-2.998,-22.85),Vector3(4.1,.003,1.25),"trim")
	for x in [-3.54,.54]:b.piece("Apron edge",Vector3(x,-2.995,-22.85),Vector3(.018,.003,1.25),"metal")
	b.finish()

func curtain(parent: Node3D,z: float) -> void:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices: Array[Vector3]=[]
	for row in 9:
		for col in 13:
			var u:=col/12.0;var v:=row/8.0
			var y:=2.48-v*2.02
			# Window mullions reach x=7.18 and its deep sill reaches x=6.995.
			# Cloth hangs inside the frame and folds over the sill, not through it.
			var drape: float=(1.0-smoothstep(.95,1.22,y))*.18
			vertices.append(Vector3(7.10+.024*cos(u*PI*8)-drape,y,z+u*.28))
	for row in 8:
		for col in 12:
			var i:=row*13+col
			for index in [i,i+1,i+13,i+1,i+14,i+13]:
				surface.set_uv(Vector2((index%13)/12.0,(index/13)/8.0));surface.add_vertex(vertices[index])
	surface.generate_normals()
	# Tabs use the same UV displacement as the main panel, so they stay attached
	# while it is drawn. The previous 7 cm unsupported gap is now bridged.
	for col in [0,3,6,9,12]:
		var u: float=col/12.0;var at: Vector3=vertices[col]
		for point in [at+Vector3(0,0,-.008),at+Vector3(0,0,.008),at+Vector3(.02,.078,-.008),at+Vector3(0,0,.008),at+Vector3(.02,.078,.008),at+Vector3(.02,.078,-.008)]:
			surface.set_uv(Vector2(u+(point.z-at.z)/.28,0));surface.add_vertex(point)
	surface.generate_normals()
	var mesh:=MeshInstance3D.new();mesh.name="FittedWindowCurtainLeft" if z<2 else "FittedWindowCurtainRight";mesh.mesh=surface.commit();mesh.material_override=cloth;mesh.extra_cull_margin=.95;parent.add_child(mesh)
	curtain_panels.append({"node":mesh,"vertices":vertices,"left":z<2})

func curtains_closed() -> bool:
	return bool(game.events.get("curtains_manual",int(game.events.get("atmosphere",{}).get("used",{}).get("curtains_drawn",0))>0))

func use_curtains() -> void:
	if not game.lounge_contents.is_visible_in_tree():return
	var close_:=not curtains_closed()
	game.events.curtains_manual=close_
	if is_instance_valid(curtain_tween):curtain_tween.kill()
	if game.presentation.prefs.data.reduced_motion:cloth.set_shader_parameter("drawn",1.0 if close_ else 0.0)
	else:
		curtain_tween=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		curtain_tween.tween_method(func(v:float):cloth.set_shader_parameter("drawn",v),float(cloth.get_shader_parameter("drawn")),1.0 if close_ else 0.0,.75)
	var cue: AudioStreamPlayer3D=game.sound("cloth_handling",Vector3(7.1,2.45,2),-30)
	game.sound_caption("Curtains rustle.",1.8,"LOUNGE WINDOW",cue)
	game.save_game(true)

func blocks_sight(from: Vector3,to: Vector3) -> bool:
	# Intersect the actual shader-deformed panels, including the real centre gap.
	# No invisible wall, player collision or change to the enemy's hearing/path.
	if not game.lounge_contents.is_visible_in_tree():return false
	# The impossible room turns the actual parent. Query in that parent's
	# coordinates so cover cannot remain at an empty old world position.
	var local_from: Vector3=game.lounge_contents.to_local(from)
	var local_to: Vector3=game.lounge_contents.to_local(to)
	if not AABB(Vector3(6.85,.44,1.02),Vector3(.30,2.06,1.99)).intersects_segment(local_from,local_to):return false
	var amount: float=cloth.get_shader_parameter("drawn")
	var ripple: float=cloth.get_shader_parameter("response")
	for panel in curtain_panels:
		var deformed:=PackedVector3Array()
		for i in panel.vertices.size():
			var p: Vector3=panel.vertices[i];var u: float=(i%13)/12.0;var v: float=(i/13)/8.0
			p.z=lerpf(p.z,(1.04+u*.92) if panel.left else (2.04+u*.94),amount);p.x+=ripple*v*v
			deformed.append(panel.node.transform*p)
		for row in 8:
			for col in 12:
				var i:=row*13+col
				if Geometry3D.segment_intersects_triangle(local_from,local_to,deformed[i],deformed[i+1],deformed[i+13])!=null or Geometry3D.segment_intersects_triangle(local_from,local_to,deformed[i+1],deformed[i+14],deformed[i+13])!=null:return true
	return false

func respond_window() -> void:
	if not game.presentation.prefs.data.reduced_motion:response=2.4

func reset_response() -> void:
	response=0
	if is_instance_valid(curtain_tween):curtain_tween.kill()
	if cloth:
		cloth.set_shader_parameter("response",0.0)
		cloth.set_shader_parameter("drawn",1.0 if curtains_closed() else 0.0)

func draw_curtains() -> void:
	# A persistent off-screen dressing change, not an animation exemption.
	# Reduced motion sees the same completed state; nothing slides on camera.
	if is_instance_valid(curtain_tween):curtain_tween.kill()
	game.events.curtains_manual=true
	cloth.set_shader_parameter("drawn",1.0)

func _process(delta: float) -> void:
	if not is_instance_valid(game):return
	curtain_control.collision_layer=4 if game.started and game.lounge_contents.is_visible_in_tree() else 0
	if not game.started or game.ended:reset_response();return
	if game.menu_open:return
	response=maxf(0,response-delta)
	cloth.set_shader_parameter("response",sin((2.4-response)*4.0)*smoothstep(0,.5,response)*.014 if response>0 and not game.presentation.prefs.data.reduced_motion else 0.0)
