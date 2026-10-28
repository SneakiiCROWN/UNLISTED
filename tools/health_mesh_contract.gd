extends SceneTree
func _initialize() -> void:
 var world=load("res://scripts/world.gd").new()
 var holder:=Node3D.new();root.add_child(holder)
 var a: MeshInstance3D=world.box(holder,Vector3.ZERO,Vector3(.123,.456,.789),Color.WHITE)
 var b: MeshInstance3D=world.box(holder,Vector3.ONE,Vector3(.123,.456,.789),Color.BLACK)
 print("MESH_CONTRACT ",is_instance_valid(a)," ",is_instance_valid(b)," shared=",a.mesh==b.mesh," material=",a.material_override!=b.material_override," position=",a.position!=b.position," size=",a.mesh.size," expected=",Vector3(.123,.456,.789))
 var okay: bool=a.mesh==b.mesh and a.material_override!=b.material_override and a.position!=b.position and a.mesh.size.is_equal_approx(Vector3(.123,.456,.789))
 holder.free();world.free();quit(0 if okay else 1)
