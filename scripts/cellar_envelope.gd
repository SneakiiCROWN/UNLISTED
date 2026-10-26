extends RefCounted
# Wall/ceiling finishes at surveyed coordinates. No new collision, navigation,
# interaction, lights or saved machinery. Existing relay/bench/vent stay clear.
func build(g: Node3D) -> void:
	var b=load("res://scripts/interior_finish.gd").new();b.g=g
	var concrete:=ShaderMaterial.new();concrete.shader=load("res://shaders/cellar_concrete.gdshader")
	concrete.set_shader_parameter("concrete",load("res://assets/exterior/Concrete019_1K-JPG_Color.jpg"))
	for body in g.get_tree().get_nodes_in_group("service_concrete_walls"):
		for mesh in g.all_meshes(body):mesh.material_override=concrete
	b.materials.concrete=concrete
	for spec in [["steel","res://assets/dusk/psx_house_steel_01.png","485048"],["rubber","res://assets/dusk/psx_house_steel_01.png","252d28"]]:
		var mat: StandardMaterial3D=g.texture_mat(spec[1],Color(spec[2])).duplicate();mat.roughness=.88;b.materials[spec[0]]=mat
	var glass: StandardMaterial3D=g.mat(Color("9caa88")).duplicate()
	glass.emission_enabled=true;glass.emission=Color("4a5840");glass.emission_energy_multiplier=.4;b.materials.glass=glass
	b.begin(g,"CellarStructuralFinish")
	for z in [-17.0,-20.0,-23.0]:
		b.piece("Concrete roof rib",Vector3(0,-.33,z),Vector3(9.72,.24,.20),"concrete")
		for x in [-4.86,4.86]:
			b.piece("Wall pilaster",Vector3(x,-1.59,z),Vector3(.075,2.56,.24),"concrete")
	# The actual existing point lights now belong to attached guarded fittings.
	for z in [-18.0,-22.0]:
		b.piece("Luminaire backplate",Vector3(0,-.255,z),Vector3(.68,.07,.25),"steel")
		for x in [-.24,.24]:b.tube("Fixture hanger",Vector3(x,-.20,z),Vector3(x,-.37,z),.011,"steel")
		b.piece("Old frosted diffuser",Vector3(0,-.405,z),Vector3(.58,.07,.19),"glass")
		for x in [-.30,.30]:b.piece("Diffuser end cap",Vector3(x,-.41,z),Vector3(.045,.13,.26),"steel")
		for x in [-.24,0,.24]:b.tube("Lamp guard",Vector3(x,-.48,z-.12),Vector3(x,-.48,z+.12),.005,"steel")
	# Supported cable tray connects entry services to the existing plant side.
	for x in [3.54,3.84]:b.piece("Tray edge",Vector3(x,-.62,-19.45),Vector3(.025,.075,7.5),"steel")
	for i in 31:
		var z: float=-15.8-i*.245
		b.piece("Cable tray rung",Vector3(3.69,-.65,z),Vector3(.31,.014,.025),"steel")
	for x in [3.62,3.70,3.77]:b.tube("Plant feed cable",Vector3(x,-.62,-15.7),Vector3(x,-.62,-23.2),.012,"rubber")
	for z in [-16.2,-18.6,-21.0,-23.1]:
		for x in [3.52,3.87]:b.tube("Tray suspension",Vector3(x,-.22,z),Vector3(x,-.65,z),.008,"steel")
	b.finish();b.root.set_meta("development_status","Cellar envelope; native acceptance in DREAD_WITHIN_VERIFICATION.md")
