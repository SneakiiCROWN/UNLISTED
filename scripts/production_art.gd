extends RefCounted

func cylinder(g: Node, parent: Node3D, pos: Vector3, radius: float, length_: float, color: Color, horizontal := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = length_
	shape.radial_segments = 12
	mesh.mesh = shape
	mesh.material_override = g.mat(color)
	parent.add_child(mesh)
	mesh.position = pos
	if horizontal:mesh.rotation.z = PI/2
	return mesh

func fuse(g: Node) -> Node3D:
	var tray: MeshInstance3D = g.box(g,Vector3(-3.5,0.815,-8.8),Vector3(0.32,0.025,0.22),Color(0.15,0.17,0.16))
	tray.name = "FusePartsTray"
	var part := Node3D.new()
	g.add_child(part)
	part.name = "Ceramic13AFuse"
	part.position = Vector3(-3.5,0.847,-8.8)
	cylinder(g,part,Vector3.ZERO,0.018,0.11,Color(0.74,0.72,0.60),true)
	for x in [-0.05,0.05]:cylinder(g,part,Vector3(x,0,0),0.0195,0.021,Color(0.43,0.42,0.34),true)
	cylinder(g,part,Vector3(0.013,0,0),0.0184,0.012,Color(0.30,0.08,0.055),true)
	var legend: Label3D = g.label3(part,"13A",Vector3(-0.013,0.019,0),0,24,Color(0.12,0.10,0.08))
	legend.rotation.x = -PI/2
	legend.pixel_size = 0.00075
	# The inventory hit area is deliberately more generous than this small physical part.
	g.collision(g,Vector3(-3.5,0.89,-8.8),Vector3(0.44,0.17,0.33),"fuse")
	g.box(g,Vector3(-3.5,0.76,-8.40),Vector3(0.42,0.11,0.018),Color(0.44,0.41,0.31))
	var tag: Label3D = g.label3(g,"SPARE / 13A",Vector3(-3.5,0.76,-8.387),0,18,Color(0.10,0.12,0.11))
	tag.pixel_size = 0.002
	return part

func panel(g: Node) -> void:
	var root := Node3D.new()
	g.add_child(root)
	root.name = "KitchenSupplyPanel"
	root.position = Vector3(-2.65,1.38,3.68)
	g.box(root,Vector3.ZERO,Vector3(0.43,0.58,0.14),Color(0.22,0.25,0.24))
	g.box(root,Vector3(0,0.0,-0.078),Vector3(0.37,0.51,0.025),Color(0.31,0.33,0.29))
	g.box(root,Vector3(0,-0.06,-0.10),Vector3(0.16,0.12,0.025),Color(0.045,0.055,0.05))
	g.box(root,Vector3(0,-0.06,-0.12),Vector3(0.11,0.065,0.025),Color(0.14,0.12,0.09))
	g.box(root,Vector3(0,-0.20,-0.11),Vector3(0.13,0.035,0.045),Color(0.10,0.12,0.11))
	g.box(root,Vector3(0,0.13,-0.10),Vector3(0.25,0.13,0.014),Color(0.59,0.58,0.47))
	for x in [-0.165,0.165]:
		for y in [-0.22,0.22]:
			var screw := cylinder(g,root,Vector3(x,y,-0.102),0.012,0.009,Color(0.41,0.40,0.33))
			screw.rotation.x = PI/2
	var tag: Label3D = g.label3(root,"MAIN SUPPLY\n13A / ISOLATE",Vector3(0,0.13,-0.110),PI,18,Color(0.08,0.10,0.09))
	tag.pixel_size = 0.0018
	g.collision(root,Vector3.ZERO,Vector3(0.45,0.60,0.18),"breaker")
	# The installation has supported conduit and a non-emissive painted face.
	for y in [1.94,2.2]:g.box(g,Vector3(-2.65,y,3.75),Vector3(0.035,0.27,0.035),Color(0.26,0.28,0.25))

func details(g: Node) -> void:
	# Opaque exterior glass corresponds to the existing room windows, with grounded frames/sills.
	for spec in [[Vector3(-7.61,1.70,1),-PI/2],[Vector3(7.61,1.70,2),PI/2]]:
		var frame := Node3D.new()
		g.add_child(frame)
		frame.position = spec[0]
		frame.rotation.y = spec[1]
		var glass: MeshInstance3D=g.box(frame,Vector3.ZERO,Vector3(1.25,1.25,0.035),Color.WHITE)
		glass.material_override=g.window_glass_material()
		for x in [-0.67,0.0,0.67]:g.box(frame,Vector3(x,0,0.05),Vector3(0.065,1.44,0.12),Color(0.17,0.20,0.18))
		for y in [-0.7,0,0.7]:g.box(frame,Vector3(0,y,0.05),Vector3(1.42,0.065,0.12),Color(0.17,0.20,0.18))
		g.box(frame,Vector3(0,-0.74,0.13),Vector3(1.58,0.09,0.31),Color(0.24,0.26,0.22))
	for record in [["report_read",Vector3(6.20,0.89,-8.57),true],["shed_read",Vector3(-17.82,1.5,-16.86),false]]:
		var key := Node3D.new()
		g.add_child(key)
		key.position = record[1]
		key.add_to_group("record_keys")
		key.set_meta("record_flag",record[0])
		var ring := MeshInstance3D.new()
		var shape := TorusMesh.new()
		shape.inner_radius = 0.017
		shape.outer_radius = 0.025
		shape.rings = 12
		shape.ring_segments = 6
		ring.mesh = shape
		ring.material_override = g.mat(Color(0.43,0.32,0.14))
		key.add_child(ring)
		if not record[2]:ring.rotation.x = PI/2
		g.box(key,Vector3(0,-0.04 if not record[2] else 0,0.04 if record[2] else 0),Vector3(0.012,0.01 if record[2] else 0.065,0.065 if record[2] else 0.01),Color(0.43,0.32,0.14))
	# Clips join the stock sheets to the existing backing board.
	for x in [-3.2,-2.65,-2.10]:g.box(g,Vector3(x,2.02,-9.79),Vector3(0.07,0.045,0.05),Color(0.30,0.31,0.27))
	# The child's plan is a physical clue underneath the impossible television feed.
	var drawing_before: Array=g.get_children()
	g.box(g,Vector3(3.58,0.814,-1.63),Vector3(0.25,0.008,0.23),Color(0.57,0.55,0.43))
	for x in [-0.06,0.06]:g.box(g,Vector3(3.58+x,0.82,-1.63),Vector3(0.003,0.002,0.17),Color(0.19,0.23,0.20))
	for z in [-0.05,0.04]:g.box(g,Vector3(3.58,0.82,-1.63+z),Vector3(0.22,0.002,0.003),Color(0.19,0.23,0.20))
	# A small chair is drawn against the top of the room, not its floor.
	# This physical clue precedes the later room-memory; no extra popup or sign.
	for spec in [Vector4(3.535,-1.68,3.535,-1.64),Vector4(3.575,-1.68,3.575,-1.64),Vector4(3.535,-1.64,3.585,-1.64),Vector4(3.585,-1.64,3.585,-1.608)]:
		var a:=Vector3(spec.x,.8215,spec.y);var b:=Vector3(spec.z,.8215,spec.w)
		var stroke: MeshInstance3D=g.box(g,(a+b)*.5,Vector3(.0018,.001,a.distance_to(b)),Color(.15,.18,.16))
		stroke.look_at(b,Vector3.UP)
	var drawing: Label3D = g.label3(g,"ELI / AGE 7",Vector3(3.58,0.824,-1.54),0,16,Color(0.18,0.20,0.16))
	drawing.rotation.x = -PI/2
	drawing.pixel_size = 0.0014
	# The same drawing belongs to the table when the remembered room turns over.
	for piece in g.get_children():
		if not drawing_before.has(piece):
			piece.reparent(g.lounge_contents)
			piece.position.x+=.22
	# Make the work-order fault physically inspectable: a real loose lead and
	# three-pin plug behind the humming set, separated from its wall socket.
	var lead:=Node3D.new();lead.name="UnpluggedTelevisionLead";g.lounge_contents.add_child(lead)
	var points: Array[Vector3]=[Vector3(3.0,1.02,-2.16),Vector3(3.05,.83,-2.30),Vector3(3.18,.35,-2.32),Vector3(3.27,.032,-2.35),Vector3(3.55,.027,-2.40),Vector3(3.84,.035,-2.34)]
	for i in range(points.size()-1):
		var a:=points[i];var b:=points[i+1]
		var cord:=cylinder(g,lead,(a+b)*.5,.006,a.distance_to(b),Color(.035,.04,.036))
		cord.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	g.box(lead,Vector3(3.86,.035,-2.33),Vector3(.046,.028,.054),Color(.13,.135,.12))
	for pin in [Vector3(0,.020,-.016),Vector3(-.014,.020,.009),Vector3(.014,.020,.009)]:
		g.box(lead,Vector3(3.86,.035,-2.33)+pin,Vector3(.004,.015,.004),Color(.40,.32,.15))
	g.box(g,Vector3(3.85,.28,-2.892),Vector3(.085,.13,.026),Color(.43,.42,.34))
	for pin in [Vector3(0,.027,0),Vector3(-.016,0,0),Vector3(.016,0,0)]:
		g.box(g,Vector3(3.85,.28,-2.876)+pin,Vector3(.005,.014,.003),Color(.07,.075,.065))
	# Useful, sparse maintenance records sit on the existing office desk.
	g.box(g,Vector3(3.08,1.2625,-9.45),Vector3(0.35,0.045,0.27),Color(0.34,0.30,0.21))
	g.box(g,Vector3(3.08,1.294,-9.45),Vector3(0.31,0.018,0.23),Color(0.61,0.58,0.45))
	var tag: Label3D = g.label3(g,"WARD / 1998",Vector3(3.08,1.307,-9.45),0,17,Color(0.15,0.16,0.14))
	tag.rotation.x = -PI/2
	tag.pixel_size = 0.002
	# Ground the table and wall junctions without adding obstacles to circulation routes.
	for node in g.doors.values():
		g.box(node,Vector3(0,0.008,0),Vector3(1.23,0.016,0.22),Color(0.24,0.23,0.19))
	# Exterior practical lighting is supported by a timber post and metal arm.
	for light in g.get_children():
		if light is OmniLight3D and light.position.distance_to(Vector3(-9,2,-12.5)) < 0.1:light.position = Vector3(-9,2.42,-14.78);light.light_energy = 0.72
	g.box(g,Vector3(-9,1.4,-15.10),Vector3(0.13,2.8,0.13),Color(0.19,0.22,0.19))
	g.box(g,Vector3(-9,2.61,-14.93),Vector3(0.10,0.08,0.40),Color(0.17,0.20,0.19))
	g.box(g,Vector3(-9,2.54,-14.76),Vector3(0.25,0.12,0.23),Color(0.23,0.26,0.23))
	g.box(g,Vector3(-9,2.47,-14.76),Vector3(0.17,0.025,0.16),Color(0.38,0.44,0.38),false,true)
	# The task light was almost a metre from its backing panel. Give it real brackets.
	for x in [-2.65,-0.35]:g.box(g,Vector3(x,-0.37,-23.23),Vector3(0.045,0.045,0.92),Color(0.21,0.25,0.22))
	# The exterior now supplies grounded property fencing instead of slab barriers.
