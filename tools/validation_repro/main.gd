extends Node
class Builder:
 extends Node
 var boxes: Dictionary={}
 func box(parent: Node3D,pos: Vector3,size: Vector3,color: Color) -> MeshInstance3D:
  var node:=MeshInstance3D.new()
  if not boxes.has(size):
   var mesh:=BoxMesh.new();mesh.size=size;boxes[size]=mesh
  node.mesh=boxes[size]
  var material:=StandardMaterial3D.new();material.albedo_color=color;node.material_override=material
  parent.add_child(node);node.position=pos
  return node
func _ready() -> void:
 var builder: Node=Builder.new();add_child(builder)
 var args:=OS.get_cmdline_user_args()
 var mode: String=args[0] if not args.is_empty() else "correct"
 if mode not in ["correct","guarded","original"]:get_tree().quit(64);return
 var holder: Node=self
 if mode=="correct":holder=Node3D.new();add_child(holder)
 var a: MeshInstance3D=builder.box(holder,Vector3.ZERO,Vector3(.123,.456,.789),Color.WHITE)
 var b: MeshInstance3D=builder.box(holder,Vector3.ONE,Vector3(.123,.456,.789),Color.BLACK)
 print("REPRO_MODE ",mode," constructed=",is_instance_valid(a),"/",is_instance_valid(b))
 if mode=="guarded" and (not is_instance_valid(a) or not is_instance_valid(b)):
  print("REPRO_GUARD rejected invalid results");get_tree().quit(12);return
 print("REPRO_SHARED ",a.mesh==b.mesh)
 print("REPRO_SEPARATE ",a.material_override!=b.material_override and a.position!=b.position and a.mesh.size==Vector3(.123,.456,.789))
 print("REPRO_BEFORE_FREE")
 a.queue_free();b.queue_free()
 print("REPRO_AFTER_FREE");get_tree().quit()
