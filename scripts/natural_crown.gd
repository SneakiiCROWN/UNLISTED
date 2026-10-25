extends RefCounted
# Original tapered winter-tree mesh. Existing placement/grade owns the tree;
# exterior_world derives its collision from this same rendered geometry.
var surface: SurfaceTool
var rng:=RandomNumberGenerator.new()

func limb(points: Array,radii: Array) -> void:
	for j in range(points.size()-1):
		var a: Vector3=points[j];var b: Vector3=points[j+1]
		var axis: Vector3=(b-a).normalized()
		var side:=axis.cross(Vector3.FORWARD).normalized()
		if side.length()<.1:side=axis.cross(Vector3.RIGHT).normalized()
		var other:=axis.cross(side).normalized()
		for i in 7:
			var t:=TAU*i/7.0;var u:=TAU*(i+1)/7.0
			var p:=side*cos(t)+other*sin(t);var q:=side*cos(u)+other*sin(u)
			for v in [a+p*radii[j],b+p*radii[j+1],a+q*radii[j],a+q*radii[j],b+p*radii[j+1],b+q*radii[j+1]]:surface.add_vertex(v)

func build(id: String) -> Array:
	rng.seed=abs(id.hash())+170105
	surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunk: Array=[];var radii: Array=[]
	var lean:=Vector3(rng.randf_range(-.10,.10),0,rng.randf_range(-.08,.08))
	for i in 7:
		var y:=i/6.0
		trunk.append(Vector3(lean.x*y*y+.018*sin(y*9),y,lean.z*y*y+.012*sin(y*7)))
		radii.append(lerpf(.038,.0015,pow(y,.65)))
	limb(trunk,radii)
	for i in 9:
		var y: float=.25+i*.066
		var yaw: float=i*2.39+rng.randf_range(-.25,.25)
		var reach: float=lerpf(.30,.13,(y-.25)/.6)*rng.randf_range(.8,1.15)
		var radial:=Vector3(cos(yaw),0,sin(yaw))
		var root:=Vector3(lean.x*y*y,y,lean.z*y*y)
		var elbow:=root+radial*reach*.55+Vector3.UP*.09
		var tip:=root+radial*reach+Vector3.UP*rng.randf_range(.17,.27)
		limb([root,elbow,tip],[.014*(1-y*.6),.006,.0007])
		for k in 3:
			var fork: Vector3=elbow.lerp(tip,.15+k*.27)
			var direction:=radial.rotated(Vector3.UP,(-1 if k%2==0 else 1)*.68)
			var end:=fork+direction*rng.randf_range(.06,.12)+Vector3.UP*rng.randf_range(.08,.15)
			limb([fork,end],[.0032,.00035])
			limb([end.lerp(fork,.35),end+radial.rotated(Vector3.UP,1.1)*.045+Vector3.UP*.04],[.0012,.0002])
	surface.generate_normals();var mesh:=surface.commit()
	var material:=ShaderMaterial.new();material.shader=load("res://shaders/winter_bark.gdshader")
	mesh.surface_set_material(0,material)
	return [{"mesh":mesh,"transform":Transform3D.IDENTITY}]
