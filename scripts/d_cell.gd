extends RefCounted
# Original unbranded work-torch cell. Metres: max D envelope 34.2 x 61.5 mm.
# Reference dimensions: https://data.energizer.com/pdfs/en95.pdf
# Axis Z; positive terminal faces into the torch (-Z).
static func make(game: Node3D) -> Node3D:
	var root:=Node3D.new();root.name="WorkCell"
	part(game,root,"Jacket",.0170,.0545,0,Color("555c4c"))
	part(game,root,"NegativeRim",.0171,.0025,.028,Color("9b9d8e"))
	part(game,root,"PositiveShoulder",.0167,.0025,-.028,Color("9b9d8e"))
	part(game,root,"Insulator",.010,.001,-.0295,Color("252a25"))
	part(game,root,"PositiveContact",.0045,.0015,-.030,Color("aaa58a"))
	part(game,root,"NegativeContact",.011,.001,.02975,Color("aaa58a"))
	for z in [-.021,.021]:part(game,root,"PrintedBand",.01705,.002,z,Color("c4b990"))
	var label:=Label3D.new();root.add_child(label);label.text="D\n1.5V";label.font_size=28;label.pixel_size=.00035;label.position=Vector3(0,0,.0);label.position.y=-.0172;label.rotation.x=PI/2;label.modulate=Color("c4b990");label.outline_size=0;label.no_depth_test=false
	return root
static func part(game: Node3D,root: Node3D,id: String,radius: float,length: float,z: float,color: Color) -> void:
	var mesh:=MeshInstance3D.new();mesh.name=id;var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius;shape.height=length;shape.radial_segments=20;mesh.mesh=shape;mesh.material_override=game.mat(color);root.add_child(mesh);mesh.rotation.x=PI/2;mesh.position.z=z
