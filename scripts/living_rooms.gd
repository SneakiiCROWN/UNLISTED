extends Node3D
# Render-only room finishes. Existing furniture bodies and investigation targets
# remain authoritative; the lounge owns its dressing during the room-memory swap.
var game: Node3D
var cloth: ShaderMaterial
var response := 0.0

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
	b.tube("Curtain pole",Vector3(7.20,2.55,.98),Vector3(7.20,2.55,3.02),.018,"metal")
	for z in [1.05,2.95]:b.tube("Wall bracket",Vector3(7.39,2.55,z),Vector3(7.20,2.55,z),.012,"metal")
	b.finish()
	cloth=ShaderMaterial.new();cloth.shader=load("res://shaders/curtain_canvas.gdshader")
	cloth.set_shader_parameter("canvas",load("res://assets/original/work_canvas.png"))
	for z in [1.04,2.70]:curtain(g.lounge_contents,z)
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
			vertices.append(Vector3(7.18+.024*cos(u*PI*8),2.48-v*2.02,z+u*.28))
	for row in 8:
		for col in 12:
			var i:=row*13+col
			for index in [i,i+1,i+13,i+1,i+14,i+13]:
				surface.set_uv(Vector2((index%13)/12.0,(index/13)/8.0));surface.add_vertex(vertices[index])
	surface.generate_normals()
	var mesh:=MeshInstance3D.new();mesh.name="FittedWindowCurtainLeft" if z<2 else "FittedWindowCurtainRight";mesh.mesh=surface.commit();mesh.material_override=cloth;mesh.extra_cull_margin=.95;parent.add_child(mesh)

func respond_window() -> void:
	if not game.presentation.prefs.data.reduced_motion:response=2.4

func reset_response() -> void:
	response=0
	if cloth:
		cloth.set_shader_parameter("response",0.0)
		cloth.set_shader_parameter("drawn",1.0 if int(game.events.get("atmosphere",{}).get("used",{}).get("curtains_drawn",0))>0 else 0.0)

func draw_curtains() -> void:
	# A persistent off-screen dressing change, not an animation exemption.
	# Reduced motion sees the same completed state; nothing slides on camera.
	cloth.set_shader_parameter("drawn",1.0)

func _process(delta: float) -> void:
	if not is_instance_valid(game):return
	if not game.started or game.ended:reset_response();return
	if game.menu_open:return
	response=maxf(0,response-delta)
	cloth.set_shader_parameter("response",sin((2.4-response)*4.0)*smoothstep(0,.5,response)*.014 if response>0 and not game.presentation.prefs.data.reduced_motion else 0.0)
