extends RefCounted

var g: Node3D
var concrete := "res://assets/architecture/concrete.jpg"
var wood := "res://assets/dusk/psx_house_old_wood_01.png"
var steel := "res://assets/dusk/psx_house_steel_01.png"

func textured_box(pos: Vector3, size: Vector3, texture: String, tint: Color, solid := false, parent: Node3D = null) -> MeshInstance3D:
	var node: MeshInstance3D = g.box(g if parent == null else parent,pos,size,tint,solid)
	node.material_override = g.texture_mat(texture,tint)
	return node

func tube(a: Vector3, b: Vector3, radius := 0.065, color := Color(0.24,0.25,0.22), parent: Node3D = null) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 12
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = g.texture_mat(steel,color)
	(g if parent == null else parent).add_child(node)
	node.position = (a+b)*0.5
	node.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	return node

func plaque(pos: Vector3, text: String, width := 0.9, angle := 0.0, color := Color(0.55,0.57,0.49)) -> Node3D:
	var node := Node3D.new()
	g.add_child(node)
	node.position = pos
	node.rotation.y = angle
	textured_box(Vector3.ZERO,Vector3(width,0.24,0.035),steel,color,false,node)
	var label: Label3D = g.label3(node,text,Vector3(0,0,0.022),0,18,Color(0.035,0.045,0.039))
	label.pixel_size = 0.0034
	for x in [-width/2+0.04,width/2-0.04]: g.box(node,Vector3(x,0,0.024),Vector3(0.015,0.015,0.01),Color(0.12,0.13,0.12))
	return node

func ground(pos: Vector3, size: Vector3) -> void:
	# Soil and yard meet at grade. This removes the former 10 cm
	# vertical lip, without changing the global player controller.
	var old:=textured_box(pos+Vector3(0,0.1,0),size,concrete,Color(0.17,0.19,0.15),true)
	old.add_to_group("legacy_exterior_ground")

func fence(a: Vector2, b: Vector2, height := 1.6, solid := true) -> void:
	var delta := b-a
	var length := delta.length()
	var midpoint := (a+b)*0.5
	var parent := Node3D.new()
	g.add_child(parent)
	parent.position = Vector3(midpoint.x,0,midpoint.y)
	parent.rotation.y = -atan2(delta.y,delta.x)
	var count := int(length/0.25)
	for i in range(count+1):
		var x := -length/2+float(i)*length/maxi(count,1)
		var board: MeshInstance3D = g.box(parent,Vector3(x,height/2,0),Vector3(0.19,height,0.07),Color(0.2,0.21,0.16))
		board.material_override = g.texture_mat(wood,Color(0.28,0.31,0.25))
	for y in [0.32,height-0.28]:
		textured_box(Vector3(0,y,-0.08),Vector3(length,0.1,0.1),wood,Color(0.28,0.28,0.23),false,parent)
	if solid:g.collision(parent,Vector3(0,height/2,0),Vector3(length,height,0.12))

func tree(pos: Vector3, height: float, seed_: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var parent := Node3D.new()
	g.add_child(parent)
	parent.position = pos
	parent.add_to_group("bare_trees")
	var p := Vector3.ZERO
	for i in range(5):
		var next := p+Vector3(rng.randf_range(-0.2,0.2),height/5,rng.randf_range(-0.2,0.2))
		tube(p,next,0.20-float(i)*0.032,Color(0.075,0.07,0.055),parent)
		if i > 1:
			for j in range(2):
				var angle := rng.randf()*TAU
				var tip := p+Vector3(cos(angle)*1.8,1.3,sin(angle)*1.8)
				tube(p,tip,0.055,Color(0.075,0.07,0.055),parent)
				tube(tip,tip+Vector3(cos(angle+0.6)*0.7,0.8,sin(angle+0.6)*0.7),0.025,Color(0.075,0.07,0.055),parent)
		p = next

func backdrop() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.015,0.035,0.065)
	sky_mat.sky_horizon_color = Color(0.07,0.12,0.14)
	sky_mat.ground_horizon_color = Color(0.07,0.12,0.14)
	sky_mat.ground_bottom_color = Color(0.015,0.025,0.025)
	sky_mat.sky_energy_multiplier = 0.6
	var sky := Sky.new()
	sky.sky_material = sky_mat
	for node in g.get_children():
		if node is WorldEnvironment:
			node.environment.background_mode = Environment.BG_SKY
			node.environment.sky = sky
			node.environment.fog_density = 0.017
			node.environment.ambient_light_energy = 0.19
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-36,-28,0)
	moon.light_color = Color(0.37,0.52,0.65)
	moon.light_energy = 0.20
	g.add_child(moon)
	# Continuous ground outside the enclosed basement/ramp footprint.
	ground(Vector3(0,-0.3,17),Vector3(64,0.4,25.6))
	ground(Vector3(-20,-0.3,-10),Vector3(24,0.4,54))
	ground(Vector3(20,-0.3,-10),Vector3(24,0.4,54))
	ground(Vector3(0,-0.3,-27),Vector3(16,0.4,24))
	ground(Vector3(-4.8,-0.3,-12.5),Vector3(6.4,0.4,5))
	ground(Vector3(4.8,-0.3,-12.5),Vector3(6.4,0.4,5))
	for i in range(28):
		var angle := float(i)/28*TAU
		var radius := 21.0+float(i%4)*2.2
		tree(Vector3(cos(angle)*radius-3,0,sin(angle)*radius-3),5.5+float(i%5)*0.6,1700+i)
	for i in range(8):tree(Vector3(-19+float(i)*4.6,0,16+float(i%3)*1.5),5.2+float(i%3),1800+i)
	fence(Vector2(-20.8,-18),Vector2(-5.5,-18),1.8)
	fence(Vector2(-14,-10.6),Vector2(-9.8,-10.6),1.5)
	fence(Vector2(-7.7,-10.6),Vector2(-6.1,-10.6),1.5)
	fence(Vector2(-14,-15.4),Vector2(-13.8,-15.4),1.5)
	fence(Vector2(-12.3,-15.4),Vector2(-6.1,-15.4),1.5)
	# Terrain berms fill the horizon below the tree line.
	for i in range(14):
		var angle := float(i)/14*TAU
		var rock := SphereMesh.new()
		rock.radial_segments = 12
		rock.rings = 5
		var mesh := MeshInstance3D.new()
		mesh.mesh = rock
		mesh.scale = Vector3(17,4+float(i%4),12)
		mesh.material_override = g.texture_mat(concrete,Color(0.07,0.1,0.09))
		g.add_child(mesh)
		mesh.position = Vector3(cos(angle)*48,-0.5,sin(angle)*48)
		mesh.add_to_group("legacy_horizon")

func shell() -> void:
	var roof_mat: StandardMaterial3D = g.texture_mat(steel,Color(0.2,0.23,0.23))
	for side in [-1,1]:
		var roof: MeshInstance3D = g.box(g,Vector3(float(side)*3.8,3.55,-3),Vector3(7.75,0.16,14.8),Color(0.2,0.23,0.23))
		roof.rotation.z = -float(side)*atan2(1.5,7.6)
		roof.material_override = roof_mat
	for z in [-10.2,4.2]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.add_vertex(Vector3(-7.7,2.76,z))
		st.add_vertex(Vector3(0,4.33,z))
		st.add_vertex(Vector3(7.7,2.76,z))
		st.generate_normals()
		var triangle := MeshInstance3D.new()
		triangle.mesh = st.commit()
		var m: StandardMaterial3D = g.texture_mat(concrete,Color(0.36,0.37,0.34)).duplicate()
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		triangle.material_override = m
		g.add_child(triangle)
	textured_box(Vector3(0,2.75,5.1),Vector3(4.1,0.18,2.6),steel,Color(0.17,0.2,0.19))
	for x in [-1.85,1.85]:
		textured_box(Vector3(x,1.35,6.25),Vector3(0.14,2.7,0.14),wood,Color(0.35,0.34,0.28),true)
		textured_box(Vector3(x,0.08,6.25),Vector3(0.28,0.16,0.28),concrete,Color(0.42,0.42,0.38))
	textured_box(Vector3(5,3.7,-5.5),Vector3(0.65,1.7,0.7),concrete,Color(0.31,0.32,0.3))
	for x in [-7.6,7.6]: tube(Vector3(x,2.78,-10.2),Vector3(x,2.78,4.2),0.07)
	# The basement access lives inside a weathered rear service annex. A complete
	# roof and end wall replace the exposed diagonal slab/fin silhouette.
	textured_box(Vector3(0,2.88,-12.6),Vector3(3.65,0.20,5.65),steel,Color(0.24,0.27,0.26))
	textured_box(Vector3(0,1.3,-15.08),Vector3(3.2,3.0,0.18),concrete,Color(0.39,0.41,0.36),true)
	for side in [-1,1]:
		textured_box(Vector3(side*1.61,1.35,-12.5),Vector3(0.08,2.7,5.15),concrete,Color(0.40,0.42,0.37))
		textured_box(Vector3(side*1.66,0.18,-12.5),Vector3(0.10,0.36,5.2),concrete,Color(0.24,0.27,0.25))
		for z in [-10.15,-12.5,-14.85]:textured_box(Vector3(side*1.7,1.4,z),Vector3(0.06,2.8,0.07),steel,Color(0.22,0.25,0.23))
		tube(Vector3(side*1.79,2.78,-10.1),Vector3(side*1.79,2.78,-15.35),0.055)
	tube(Vector3(-1.79,2.78,-15.25),Vector3(-1.79,0.08,-15.25),0.055)
	# Fixed maintenance vent, deliberately no apparent upper walkway/destination.
	textured_box(Vector3(-1.72,1.85,-13.3),Vector3(0.06,0.55,0.85),steel,Color(0.16,0.20,0.18))
	for y in [1.64,1.75,1.86,1.97,2.08]:textured_box(Vector3(-1.76,y,-13.3),Vector3(0.05,0.035,0.76),steel,Color(0.29,0.32,0.28))
	textured_box(Vector3(0,2.77,4.1),Vector3(15.4,0.14,0.18),wood,Color(0.3,0.3,0.25))
	# Shed cornice, roof and weatherproof external base seal all shell edges.
	textured_box(Vector3(-17,2.91,-14),Vector3(6.5,0.18,6.5),steel,Color(0.23,0.27,0.25))
	for z in [-17,-11]:textured_box(Vector3(-17,0.08,z),Vector3(6.2,0.16,0.24),concrete,Color(0.3,0.32,0.29))
	address_sign()

func address_sign() -> void:
	var sign_:=Node3D.new();sign_.name="MountedBriarLaneAddress";g.add_child(sign_)
	# Entire sign is on the solid wall pier, beyond the jamb and door's swing.
	sign_.position=Vector3(1.96,1.61,4.112)
	g.box(sign_,Vector3.ZERO,Vector3(0.66,0.54,0.035),Color("282c29"))
	var face: MeshInstance3D=g.box(sign_,Vector3(0,0,0.021),Vector3(0.614,0.494,0.006),Color("34413e"))
	var enamel: StandardMaterial3D=face.material_override.duplicate();enamel.roughness=0.72;face.material_override=enamel
	var number: Label3D=g.label3(sign_,"17",Vector3(0,0.065,0.026),0,60,Color("c9c5ac"))
	number.font=load("res://assets/fonts/AnalogMono_v1_1.ttf");number.pixel_size=0.0044
	number.shaded=true
	var street: Label3D=g.label3(sign_,"BRIAR LANE",Vector3(0,-0.157,0.026),0,18,Color("b7b69f"))
	street.font=number.font;street.pixel_size=0.0027
	street.shaded=true
	for x in [-0.286,0.286]:
		for y in [-0.224,0.224]:
			var bolt:=CylinderMesh.new();bolt.top_radius=0.009;bolt.bottom_radius=0.009;bolt.height=0.008;bolt.radial_segments=8
			var head:=MeshInstance3D.new();head.mesh=bolt;head.material_override=g.mat(Color("6b6756"))
			sign_.add_child(head);head.position=Vector3(x,y,0.029);head.rotation.x=PI/2
			g.box(sign_,Vector3(x,y,-0.021),Vector3(0.015,0.015,0.010),Color("292c28"))
			g.box(sign_,Vector3(x,y,0.034),Vector3(0.010,0.0018,0.001),Color("282b27"))
	for spec in [[-0.30,0.11,0.008],[-0.16,-0.238,0.015],[0.302,-0.10,0.009],[0.23,0.237,0.012]]:
		g.box(sign_,Vector3(spec[0],spec[1],0.026),Vector3(spec[2],0.004,0.001),Color("68604b"))
	sign_.set_meta("mount_wall","front east pier / z=4.09")

func rack(pos: Vector3, width := 1.7, angle := 0.0) -> void:
	var parent := Node3D.new()
	g.add_child(parent)
	parent.position = pos
	parent.rotation.y = angle
	for x in [-width/2,width/2]:
		for z in [-0.22,0.22]:textured_box(Vector3(x,0.9,z),Vector3(0.045,1.8,0.045),steel,Color(0.28,0.31,0.28),false,parent)
	for y in [0.12,0.65,1.2,1.75]:textured_box(Vector3(0,y,0),Vector3(width,0.05,0.52),wood,Color(0.43,0.4,0.32),false,parent)
	g.collision(parent,Vector3(0,0.9,0),Vector3(width,1.8,0.48))
	if pos.x>6:return # Office shelves are dressed with property ledgers.
	for i in range(3):
		g.model("res://assets/dusk/psx_prop_tins_01.glb",parent,Vector3(-width/2+0.3+float(i)*0.5,0.68,0),Vector3(0.28,0.28,0.2))
		g.model("res://assets/dusk/psx_prop_bottles_01.glb",parent,Vector3(-width/2+0.3+float(i)*0.5,1.23,0),Vector3(0.25,0.34,0.2))

func dressing() -> void:
	# Existing rooms gain specific purposes; central walking/door arcs remain clear.
	rack(Vector3(-6.7,0,-8.9),1.5,PI/2)
	rack(Vector3(-19.5,0,-14.4),2,PI/2)
	rack(Vector3(7.04,0,-5.5),2.5,PI/2)
	for i in range(3):
		var cabinet := textured_box(Vector3(2.4+float(i)*0.68,0.62,-9.45),Vector3(0.62,1.24,0.62),steel,Color(0.37,0.40,0.34),true)
		for j in range(3):
			var y := 0.25+float(j)*0.38
			textured_box(Vector3(2.4+float(i)*0.68,y,-9.12),Vector3(0.55,0.34,0.035),steel,Color(0.33,0.37,0.31))
			g.box(g,Vector3(2.4+float(i)*0.68,y,-9.08),Vector3(0.15,0.025,0.04),Color(0.12,0.14,0.12))
	g.model("res://assets/dusk/psx_prop_newspapers_01.glb",g,Vector3(5.05,0.81,-8.96),Vector3(0.55,0.05,0.35))
	# Keep the actual report-sleeve work surface clear; its mug is a shared loose prop on the archive cabinet.
	# Notice board on utility wall; attached labels and clipped papers.
	textured_box(Vector3(-2.6,1.75,-9.84),Vector3(1.7,0.8,0.06),wood,Color(0.46,0.37,0.25))
	for i in range(3):
		var x := -3.2+float(i)*0.55
		g.box(g,Vector3(x,1.75,-9.79),Vector3(0.42,0.56,0.01),Color(0.57,0.56,0.44))
		g.label3(g,["SERVICE\nCHECKS","SPARE\n13A","KEEP\nCLEAR"][i],Vector3(x,1.76,-9.775),0,15,Color(0.08,0.09,0.07))
	# Practical shaded lamp beside the couch, including stem and cloth shade.
	tube(Vector3(6.7,0,2.95),Vector3(6.7,1.65,2.95),0.025)
	textured_box(Vector3(6.7,0.035,2.95),Vector3(0.35,0.07,0.35),steel,Color(0.18,0.19,0.16))
	var shade := CylinderMesh.new()
	shade.top_radius = 0.17
	shade.bottom_radius = 0.32
	shade.height = 0.38
	var mesh := MeshInstance3D.new()
	mesh.mesh = shade
	mesh.material_override = g.mat(Color(0.49,0.44,0.29))
	g.add_child(mesh)
	mesh.position = Vector3(6.7,1.65,2.95)
	g.lamp(Vector3(6.7,1.45,2.95),Color(0.96,0.71,0.43),0.6,3.5)
	# An entrance mat anchors the house to the approach.
	textured_box(Vector3(0,0.012,4.9),Vector3(1.5,0.025,0.65),wood,Color(0.22,0.26,0.23))

func relay_room() -> void:
	# One coherent feed manifold, with pipes, brackets, turnable wheels and fixed ID plates.
	textured_box(Vector3(-1.5,-1.65,-23.73),Vector3(4.5,2.3,0.12),steel,Color(0.32,0.36,0.32))
	for i in range(3):
		var x := -2.7+float(i)*1.2
		tube(Vector3(x,-2.9,-23.5),Vector3(x,-0.4,-23.5),0.075,Color(0.4,0.43,0.37))
		for y in [-2.65,-0.65]:
			textured_box(Vector3(x,y,-23.51),Vector3(0.32,0.11,0.18),steel,Color(0.27,0.3,0.25))
		var wheel := Node3D.new()
		g.add_child(wheel)
		wheel.position = Vector3(x,-1.65,-23.19)
		var colors := [Color(0.46,0.12,0.07),Color(0.09,0.29,0.43),Color(0.61,0.61,0.51)]
		var mesh := TorusMesh.new()
		mesh.inner_radius = 0.17
		mesh.outer_radius = 0.23
		mesh.rings = 16
		mesh.ring_segments = 8
		var ring := MeshInstance3D.new()
		ring.mesh = mesh
		ring.rotation.x = PI/2
		ring.material_override = g.mat(colors[i])
		wheel.add_child(ring)
		g.box(wheel,Vector3.ZERO,Vector3(0.42,0.045,0.05),colors[i])
		g.box(wheel,Vector3.ZERO,Vector3(0.045,0.42,0.05),colors[i])
		tube(Vector3(0,0,-0.3),Vector3(0,0,0.02),0.06,Color(0.37,0.39,0.33),wheel)
		var id := "valve"+str(i)
		g.valve_visuals[id] = wheel
		g.collision(g,Vector3(x,-1.65,-23.2),Vector3(0.7,0.8,0.55),id)
		var plate:=plaque(Vector3(x+.38,-0.97,-23.635),g.PUZZLES.plate(g.events,i),0.65)
		g.valve_labels[i]=plate.find_children("*","Label3D",true,false)[0]
	# Plates sit on the backboard, beside the pipes, rather than floating out
	# in front of them. The backboard itself is fixed to the structural wall.
	for x in [-3.55,.55]:
		for y in [-2.55,-.70]:textured_box(Vector3(x,y,-23.84),Vector3(.10,.10,.18),steel,Color(.26,.28,.25))
	plaque(Vector3(-1.5,-0.34,-23.88),"OCCUPANCY RELAY / FEED ISOLATION",3.6)
	g.box(g,Vector3(-1.5,-0.37,-22.8),Vector3(2.8,0.07,0.16),Color(0.48,0.58,0.46),false,true)
	for x in [-2.6,-.4]:tube(Vector3(x,-.34,-22.8),Vector3(x,-.19,-22.8),.018)
	g.lamp(Vector3(-1.5,-0.57,-22.4),Color(0.63,0.74,0.62),1.3,4.2)
	var control := Node3D.new()
	g.add_child(control)
	control.position = Vector3(2,-1.9,-23.78)
	g.box(control,Vector3(0,0.45,0),Vector3(0.48,0.68,0.16),Color(0.24,0.28,0.25))
	g.box(control,Vector3(0,0.45,0.09),Vector3(0.39,0.58,0.025),Color(0.35,0.38,0.32))
	g.box(control,Vector3(0,0.43,0.11),Vector3(0.15,0.28,0.02),Color(0.065,0.075,0.067))
	var handle: MeshInstance3D = g.box(control,Vector3(0,0.5,0.16),Vector3(0.20,0.07,0.08),Color(0.31,0.12,0.075))
	handle.name = "IsolationHandle"
	g.collision(control,Vector3(0,0.45,0),Vector3(0.48,0.68,0.23),"isolate")
	plaque(Vector3(2,-0.82,-23.88),"MANUAL / PULL TO ISOLATE",1.7)
	for y in [-1.7,-1.2]:textured_box(Vector3(2,y,-23.87),Vector3(.34,.06,.12),steel,Color(.24,.27,.24))
	textured_box(Vector3(3.85,-2.91,-20.0),Vector3(1.65,0.18,2.5),concrete,Color(0.4,0.42,0.37),true)
	g.model("res://assets/machinery/generator.glb",g,Vector3(3.85,-2.81,-20.0),Vector3(1.25,1.45,2.2),0,true)
	tube(Vector3(4.55,-2.5,-21.2),Vector3(4.55,-0.6,-21.2),0.12)
	tube(Vector3(4.55,-0.6,-21.2),Vector3(4.55,-0.6,-23.5),0.12)
	for x in [-0.3,0.3]:tube(Vector3(x,-0.5,-16),Vector3(x,-0.5,-23.5),0.03,Color(0.13,0.14,0.11))
	for z in [-17,-19,-21,-23]:textured_box(Vector3(0,-0.42,z),Vector3(0.9,0.06,0.12),steel,Color(0.3,0.32,0.27))
	# Wall-side maintenance station: keep the surveyed west pursuit aisle clear.
	# Every loose-looking detail belongs to the bench or the actual wall.
	var bench: Node3D = g.table(Vector3(-4.58,-3,-17.4),1.8,.64)
	bench.name="CellarMaintenanceBench";bench.rotation.y=PI/2
	g.collision(bench,Vector3(0,.4,0),Vector3(1.8,.8,.64))
	g.model("res://assets/dusk/psx_prop_tins_01.glb",bench,Vector3(-.45,.80,0),Vector3(.3,.28,.2))
	g.model("res://assets/machinery/circuit_breaker.glb",g,Vector3(-4.82,-2.02,-16.8),Vector3(.32,.50,.12),PI/2)
	tube(Vector3(-4.81,-1.52,-16.8),Vector3(-4.81,-.45,-16.8),.022)
	tube(Vector3(-4.81,-.45,-16.8),Vector3(-4.81,-.45,-20),.022)
	for z in [-16.8,-18.3,-19.8]:textured_box(Vector3(-4.85,-.45,z),Vector3(.10,.07,.09),steel,Color(.23,.25,.23))
	rack(Vector3(-4.6,-3,-20),2.2,PI/2)

func build(game: Node3D) -> void:
	g = game
	backdrop()
	shell()
	dressing()
	# Bound the useful maintenance yard with joined fencing and a grounded curb.
	fence(Vector2(-6.1,-15.4),Vector2(-3,-15.4),1.5)
	fence(Vector2(-3,-15.4),Vector2(-3,-10.6),1.5)
	# Preserve the existing maintenance gap and walkable circuit around the shed.
	textured_box(Vector3(-11.95,0.07,-10.6),Vector3(4.3,0.14,0.18),concrete,Color(0.32,0.34,0.29),true)
	textured_box(Vector3(-6.8,0.07,-10.6),Vector3(1.8,0.14,0.18),concrete,Color(0.32,0.34,0.29),true)
	# Curbs stop at both sides of the maintenance gap; never put a step across it.
	textured_box(Vector3(-9.1,0.07,-15.4),Vector3(6.4,0.14,0.18),concrete,Color(0.32,0.34,0.29),true)
	textured_box(Vector3(-13.95,0.07,-15.4),Vector3(0.3,0.14,0.18),concrete,Color(0.32,0.34,0.29),true)
	# Clear service route remains wider than 2 m; dressing is fixed to its boundary.
	for z in [-13.4,-12.5]:
		textured_box(Vector3(-3.17,0.55,z),Vector3(0.18,1.1,0.5),steel,Color(0.21,0.25,0.22))
	textured_box(Vector3(-11.7,0.015,-15.05),Vector3(1.1,0.03,0.35),steel,Color(0.19,0.23,0.21))
