extends RefCounted
# Original low-poly leaf sprays on connected branches. No alpha-card overdraw,
# displaced terrain, placement reseeding or invisible legacy crown collision.
var rng:=RandomNumberGenerator.new()
var wood: SurfaceTool
var foliage: SurfaceTool

func twig(a: Vector3,b: Vector3,radius: float) -> void:
	var generator=load("res://scripts/natural_crown.gd").new()
	generator.surface=wood;generator.limb([a,b],[radius,.0003])

func leaf(root: Vector3,direction: Vector3,length_: float) -> void:
	var forward:=direction.normalized()
	var side:=forward.cross(Vector3.UP).normalized()
	if side.length()<.1:side=Vector3.RIGHT
	var middle:=root+forward*length_*.48
	var points: Array=[root,middle+side*length_*.26+Vector3.UP*.002,root+forward*length_,middle-side*length_*.26+Vector3.UP*.002]
	var tone:=rng.randf_range(.72,1.15)
	for index in [0,1,2,0,2,3]:
		foliage.set_color(Color(tone,tone,tone));foliage.add_vertex(points[index])

func build(id: String) -> Array:
	rng.seed=abs(id.hash())+170106
	wood=SurfaceTool.new();wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	foliage=SurfaceTool.new();foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var willow:=id.begins_with("Willow")
	var birch:=id.begins_with("Birch")
	var lean:=Vector3(.04,0,-.015)
	var generator=load("res://scripts/natural_crown.gd").new();generator.surface=wood
	generator.limb([Vector3.ZERO,Vector3(0,.35,0),lean*.7+Vector3.UP*.68,lean+Vector3.UP*.96],[.036,.021,.012,.001])
	# Offset rising tiers retain sky gaps; each terminal spray has real twigs.
	for i in 12:
		var y:=.34+i*.041
		var angle:=i*2.399+rng.randf_range(-.3,.3)
		var radial:=Vector3(cos(angle),0,sin(angle))
		var reach: float=(.24 if birch else .34)*sin((y-.20)*PI)*rng.randf_range(.8,1.1)
		var root:=lean*y+Vector3.UP*y
		var elbow:=root+radial*reach*.6+Vector3.UP*.07
		var tip:=root+radial*reach+Vector3.UP*(.035 if willow else .13)
		generator.limb([root,elbow,tip],[.009,.004,.0005])
		for j in 6:
			var begin:=elbow.lerp(tip,.12+j*.15)
			var tangent:=radial.rotated(Vector3.UP,(-1 if j%2==0 else 1)*1.0)
			var end:=begin+tangent*rng.randf_range(.035,.09)+Vector3.UP*(rng.randf_range(-.16,-.07) if willow else rng.randf_range(.025,.10))
			twig(begin,end,.0018)
			for k in 7:
				var attachment:=begin.lerp(end,.18+k*.12)
				var direction:=tangent.rotated(Vector3.UP,(-1 if k%2==0 else 1)*.85)+Vector3.UP*(-.6 if willow else rng.randf_range(-.15,.5))
				leaf(attachment,direction,rng.randf_range(.018,.038) if birch else rng.randf_range(.025,.050))
	wood.generate_normals();foliage.generate_normals()
	var bark:=ShaderMaterial.new();bark.shader=load("res://shaders/winter_bark.gdshader")
	var leaves:=ShaderMaterial.new();leaves.shader=load("res://shaders/leaf_spray.gdshader")
	leaves.set_shader_parameter("tint",Color("394732") if not birch else Color("48513b"))
	var a:=wood.commit();a.surface_set_material(0,bark)
	var b:=foliage.commit();b.surface_set_material(0,leaves)
	return [{"mesh":a,"transform":Transform3D.IDENTITY},{"mesh":b,"transform":Transform3D.IDENTITY}]
