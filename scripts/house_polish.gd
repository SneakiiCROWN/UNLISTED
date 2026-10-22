extends RefCounted
var g: Node3D
var repair: RefCounted

func surface(pos: Vector3,size_: Vector3,tint: Color,texture := "res://assets/original/peeling_plaster.png") -> MeshInstance3D:
	var node: MeshInstance3D = g.box(g,pos,size_,tint)
	node.material_override = g.texture_mat(texture,tint)
	return node

func book(pos: Vector3,width: float,height: float,color: Color,lean := 0.0) -> Node3D:
	var root := Node3D.new();g.add_child(root);root.position = pos;root.rotation.z = lean
	if pos.x>6:root.rotation.y = PI/2
	g.box(root,Vector3(0,height/2,0),Vector3(width,height,0.22),color)
	g.box(root,Vector3(0,height/2,-0.005),Vector3(width*0.78,height*0.93,0.205),Color("857e68"))
	for y in [0.05,height-0.05]:g.box(root,Vector3(0,y,0.114),Vector3(width*0.65,0.012,0.008),Color("726c52"))

	return root

func build(game: Node3D) -> void:
	g = game
	repair = load("res://scripts/environment_repair.gd").new();repair.g = g
	# Room-specific damaged plaster accents sit flush against real walls.
	surface(Vector3(4.5,1.5,-9.895),Vector3(5.85,2.5,0.008),Color(0.42,0.46,0.41))
	# The former full-width accent bridged the actual service doorway. Keep
	# plaster only on the two real wall piers; the structural lintel is already lined.
	for x in [-6.3375,-2.6625]:
		var patch:=surface(Vector3(x,1.48,-9.895),Vector3(2.175,2.45,0.008),Color(0.36,0.40,0.37))
		patch.name="UtilityPlasterPier"
		# Match the neighboring paper's physical repeat rather than stretching one
		# square texture across the old six-metre wall and doorway.
		var material: StandardMaterial3D=patch.material_override.duplicate()
		material.uv1_scale=Vector3(2.175/1.5,2.45/1.5,1)
		patch.material_override=material
	surface(Vector3(-7.39,0.52,1.3),Vector3(0.012,0.72,4.5),Color(0.43,0.44,0.34))
	# Office shelves hold property ledgers rather than repeated kitchen bottles.
	for i in 10:
		book(Vector3(6.99,0.675+float(i%2)*0.55,-6.45+floorf(i/2.0)*0.31),0.15,0.36+0.035*(i%3),[Color("3f4b43"),Color("4d3c32"),Color("565346")][i%3],0.04 if i==7 else 0)
	# A pinned survey has a physical board, folded sheet, pencil plan and thumbtacks.
	surface(Vector3(5.2,1.85,-9.868),Vector3(1.2,0.72,0.055),Color("5d5240"),"res://assets/dusk/psx_house_old_wood_01.png")
	g.box(g,Vector3(5.2,1.85,-9.84),Vector3(1.08,0.61,0.006),Color("88816a"))
	for x in [4.83,5.24,5.60]:g.box(g,Vector3(x,1.85,-9.835),Vector3(0.008,0.46,0.003),Color("3d4942"))
	for y in [1.68,1.91,2.02]:g.box(g,Vector3(5.2,y,-9.832),Vector3(0.85,0.008,0.003),Color("3d4942"))
	var label: Label3D = g.label3(g,"17 BRIAR / SERVICE SURVEY",Vector3(5.2,2.09,-9.828),0,15,Color("333b34"));label.pixel_size = 0.0018
	# Evidence transport fits on the clear left portion of the original office desk.
	var transport := Node3D.new();transport.name = "ArchiveTransport";g.add_child(transport);transport.position = Vector3(3.3,0.86,-8.52)
	g.box(transport,Vector3.ZERO,Vector3(0.62,0.10,0.41),Color("29312e"))
	for x in [-0.18,0.18]:
		var reel := MeshInstance3D.new();var mesh := TorusMesh.new();mesh.inner_radius = 0.06;mesh.outer_radius = 0.095;mesh.rings = 16;mesh.ring_segments = 8;reel.mesh = mesh;reel.material_override = g.mat(Color("696851"));transport.add_child(reel);reel.position = Vector3(x,0.065,-0.04);reel.add_to_group("archive_reels")
	for i in 3:
		var x := -0.22+0.22*i
		g.box(transport,Vector3(x,0.07,0.13),Vector3(0.12,0.035,0.09),Color("56594b"))
		var id: String = ["audition_source","audition_return","exclude_return"][i]
		g.collision(g,transport.position+Vector3(x,0.1,0.13),Vector3(0.17,0.12,0.13),id)
		var tag: Label3D = g.label3(transport,["A","B","EXCLUDE"][i],Vector3(x,0.092,0.14),0,15,Color("b0ab91"));tag.rotation.x = -PI/2;tag.pixel_size = 0.001
	var receipt := Node3D.new();receipt.name = "TransportReceipt";transport.add_child(receipt);receipt.position = Vector3(0,0.025,0.21);receipt.visible = false;g.memory_receipt = receipt
	g.box(receipt,Vector3(0,0,0.08),Vector3(0.24,0.003,0.16),Color("9e967d"))
	var tail: MeshInstance3D = g.box(receipt,Vector3(0,-0.025,0.235),Vector3(0.24,0.003,0.16),Color("9e967d"));tail.rotation.x = 0.32
	var ink: Label3D = g.label3(receipt,"COMPARISON SAVED\nTONIGHT\nFAULT DISPUTED",Vector3(0,0.004,0.07),0,16,Color("303b33"));ink.rotation.x = -PI/2;ink.pixel_size = 0.0011
	var source_copy: StaticBody3D=g.collision(g,transport.position+Vector3(0,.032,.29),Vector3(.25,.035,.13),"source_copy")
	source_copy.name="ReadableTransportCopy";source_copy.collision_layer=0
	# Warm desk pool and cold perimeter give the room depth, with real shade/arm supports.
	repair.tube(Vector3(6.4,0.82,-8.96),Vector3(6.4,1.33,-8.96),0.016)
	g.box(g,Vector3(6.4,1.32,-8.87),Vector3(0.22,0.055,0.24),Color("37423a"))
	var task: OmniLight3D = g.lamp(Vector3(6.4,1.22,-8.84),Color(0.91,0.70,0.43),0.48,2.0);task.shadow_enabled = true
	# Kitchen: used place setting, worn runner and a second tucked-in chair.
	g.model("res://assets/dusk/psx_prop_kitchen_chair_01.glb",g,Vector3(-6.4,0,-1.4),Vector3(0.5,0.9,0.52),0,true)
	g.model("res://assets/dusk/psx_prop_newspapers_01.glb",g,Vector3(-6.05,0.815,-0.78),Vector3(0.36,0.025,0.26))
	surface(Vector3(-5.8,0.013,1.95),Vector3(1.2,0.013,0.64),Color("4a5144"),"res://assets/original/work_canvas.png")
	# Utility work corner: supported peg rail, cable coils and a wash pan.
	repair.tube(Vector3(-7.28,1.58,-7.6),Vector3(-7.28,1.58,-6.0),0.024)
	for z in [-7.4,-6.2]:g.box(g,Vector3(-7.34,1.58,z),Vector3(0.13,0.045,0.06),Color("3c443d"))
	for z in [-7.3,-6.8,-6.3]:
		var ring := MeshInstance3D.new();var torus := TorusMesh.new();torus.inner_radius = 0.11;torus.outer_radius = 0.145;torus.rings = 16;torus.ring_segments = 6;ring.mesh = torus;ring.material_override = g.mat(Color("333b33"));g.add_child(ring);ring.position = Vector3(-7.25,1.40,z);ring.rotation.z = PI/2
	g.model("res://assets/dusk/psx_prop_cooking_pot_01.glb",g,Vector3(-5.3,0,-9.35),Vector3(0.42,0.22,0.40))
	# Lounge: frayed runner and neglected reading corner, away from collision routes.
	var lounge_before: Array=g.get_children()
	surface(Vector3(4.8,0.012,0.35),Vector3(2.6,0.012,2.0),Color("3b4038"),"res://assets/original/work_canvas.png")
	# The licensed wall shelf has one board. Remove the old unsupported lower row.
	for piece in g.get_children():
		if not lounge_before.has(piece):piece.reparent(g.lounge_contents)
	# Low wall-side plumbing/weathering also anchors the shed exterior.
	repair.tube(Vector3(-19.85,0.05,-16.5),Vector3(-19.85,2.8,-16.5),0.055)
	for y in [0.5,1.6,2.4]:g.box(g,Vector3(-19.89,y,-16.5),Vector3(0.10,0.05,0.14),Color("42483d"))
	surface(Vector3(-19.905,1.2,-14),Vector3(0.008,2.1,5.7),Color("40483c"))
