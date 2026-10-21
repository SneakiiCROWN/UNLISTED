extends RefCounted
# Selective working-room dressing. Paths, puzzle positions and lounge memory stay intact.
const WOOD="res://assets/dusk/psx_house_old_wood_01.png"
const STEEL="res://assets/dusk/psx_house_steel_01.png"
const PAPER="res://assets/original/aged_paper.png"

func finish_model(g: Node3D, root: Node3D, cardboard:=false) -> void:
	for mesh in g.all_meshes(root):
		for i in mesh.mesh.get_surface_count():
			var source: Material=mesh.get_active_material(i)
			var metal: bool=source!=null and "metal" in source.resource_name.to_lower()
			var material: StandardMaterial3D=g.texture_mat(PAPER if cardboard else (STEEL if metal else WOOD),Color("69624c") if cardboard else (Color("3b423c") if metal else Color("60584b"))).duplicate()
			material.uv1_scale=Vector3(1.7,1.7,1.7) if cardboard else Vector3(.8,.8,.8)
			mesh.set_surface_override_material(i,material)

func desk(g: Node3D,pos: Vector3,width: float,depth: float) -> Node3D:
	var result: Node3D=g.model("res://assets/interiors/desk.glb",g,pos,Vector3(width,.8,depth),0,true)
	result.name="ArchiveWorkDesk" if width>1.5 else "TransportWorkDesk"
	finish_model(g,result)
	result.add_to_group("authored_work_desks")
	return result

func build(g: Node3D) -> void:
	var repair=load("res://scripts/environment_repair.gd").new();repair.g=g
	# The existing record is a pinned sheet, never wall-sized text through cabinets.
	var record: Node3D=g.targets.record.get_parent()
	var ink: Label3D=record.find_children("*","Label3D",false,false)[0]
	ink.font_size=12;ink.pixel_size=.0032;ink.shaded=true
	for x in [-.20,.20]:
		for y in [-.25,.25]:g.box(record,Vector3(x,y,.026),Vector3(.014,.014,.01),Color("6b6652"))
	# Archive boxes sit on the actual cabinet top, with upright files inside.
	var box_: Node3D=g.model("res://assets/interiors/cardboardBoxOpen.glb",g,Vector3(2.43,1.24,-9.43),Vector3(.44,.31,.41))
	box_.name="PropertyArchiveBox";finish_model(g,box_,true)
	for i in 4:
		var file: MeshInstance3D=g.box(box_,Vector3(-.13+i*.085,.19,-.015),Vector3(.035,.27,.28),Color("79705a"))
		file.rotation.z=.025*(i-1)
		file.material_override=g.texture_mat(PAPER,Color("756c57"))
	# A continuous signal lead, not another sign, links the two working stations.
	for points in [[Vector3(3.5,.87,-8.69),Vector3(3.58,.79,-8.91),Vector3(3.73,.42,-8.98),Vector3(4.08,.055,-9.0),Vector3(4.80,.055,-9.04),Vector3(5.35,.5,-9.02),Vector3(5.35,1.0,-8.99)]]:
		for i in range(points.size()-1):repair.tube(points[i],points[i+1],.008,Color("252c28"))
	# Physical tape follows guides between the existing reels, behind the controls.
	var transport: Node3D=g.get_node("ArchiveTransport")
	for pair in [[Vector3(-.18,.06,.045),Vector3(-.07,.06,.075)],[Vector3(-.07,.06,.075),Vector3(.07,.06,.075)],[Vector3(.07,.06,.075),Vector3(.18,.06,.045)]]:
		repair.tube(pair[0],pair[1],.0025,Color("251f19"),transport)
	# Give the existing rest mattress a plausible folding cot rather than a floor prop.
	var mattress: Node3D=g.get_node("UtilityRestMattress")
	mattress.position.y=.34
	for x in [-7.01,-6.19]:
		repair.tube(Vector3(x,.32,-6.28),Vector3(x,.32,-4.52),.022)
		for z in [-6.18,-4.62]:repair.tube(Vector3(x,.03,z),Vector3(x,.32,z),.025)
	for z in [-6.28,-4.52]:repair.tube(Vector3(-7.01,.32,z),Vector3(-6.19,.32,z),.022)
	# Worn folded cloth follows the mattress edges; the outer hems hang over it.
	var cloth:=SurfaceTool.new();cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
	var xs:=[-.475,-.41,-.2,.0,.2,.41,.475]
	var points: Array[Vector3]=[]
	for row in 7:
		for col in xs.size():
			var x: float=xs[col];var z: float=-.33+row*.11
			var y: float=-.065 if col in [0,6] else .012+.009*sin(row*1.5+col*.8)
			points.append(Vector3(x,y,z+.009*sin(col*1.3+row)))
	for row in 6:
		for col in 6:
			var i:=row*7+col
			for index in [i,i+7,i+1,i+1,i+7,i+8]:cloth.add_vertex(points[index])
	cloth.generate_normals()
	var blanket:=MeshInstance3D.new();blanket.mesh=cloth.commit();g.add_child(blanket)
	blanket.position=Vector3(-6.6,.52,-4.88);blanket.name="FoldedRestBlanket"
	var canvas: StandardMaterial3D=g.texture_mat("res://assets/original/work_canvas.png",Color(.83,.8,.67)).duplicate()
	canvas.cull_mode=BaseMaterial3D.CULL_DISABLED;blanket.material_override=canvas
