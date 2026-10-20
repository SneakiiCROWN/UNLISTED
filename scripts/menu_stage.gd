extends Node3D

var game: Node3D
var camera: Camera3D
var shadow: Node3D
var clock := 0.0
var active := true
var reduce_motion := true
var reduce_flash := true
var trees: Array[Node] = []
var porch: OmniLight3D
var facade_fill: OmniLight3D
var mist: GPUParticles3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	camera = Camera3D.new()
	camera.name = "TitleCamera"
	camera.fov = 49
	camera.cull_mask = 1|8
	camera.near = 0.1
	add_child(camera)
	camera.position = Vector3(-10.5,2.1,15.3)
	camera.look_at(Vector3(-0.1,1.8,3.6))
	for x in [-4.8,4.8]:
		var glass: MeshInstance3D=game.box(self,Vector3(x,1.70,4.115),Vector3(1.55,1.35,0.05),Color.WHITE)
		glass.material_override=game.window_glass_material()
		for edge in [-0.82,0,0.82]:game.box(self,Vector3(x+edge,1.70,4.17),Vector3(0.065,1.5,0.13),Color(0.16,0.18,0.17))
		for y in [1.0,1.7,2.4]:game.box(self,Vector3(x,y,4.17),Vector3(1.7,0.065,0.13),Color(0.16,0.18,0.17))
		game.box(self,Vector3(x,0.99,4.22),Vector3(1.85,0.10,0.3),Color(0.20,0.21,0.19))
	shadow = game.model("res://assets/original/surveyor_v03.glb",self,Vector3(-4.75,1.07,3.72),Vector3(0.36,1.26,0.03),PI)
	for mesh in game.all_meshes(shadow):mesh.material_override = game.mat(Color(0.008,0.014,0.016))
	shadow.visible = false
	porch = game.lamp(Vector3(0,2.4,5.8),Color(0.76,0.59,0.38),0.9,4.6)
	facade_fill = game.lamp(Vector3(-4,3.8,8),Color(0.32,0.45,0.55),0.38,13)
	trees = get_tree().get_nodes_in_group("bare_trees")
	create_mist()

func create_mist() -> void:
	mist = GPUParticles3D.new()
	mist.name = "GroundMist"
	mist.amount = 18
	mist.lifetime = 24
	mist.preprocess = 24
	mist.visibility_aabb = AABB(Vector3(-30,-2,-30),Vector3(60,6,60))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(18,0.22,14)
	process.direction = Vector3(1,0,0.2)
	process.spread = 8
	process.initial_velocity_min = 0.08
	process.initial_velocity_max = 0.18
	process.gravity = Vector3.ZERO
	process.scale_min = 0.8
	process.scale_max = 2.3
	mist.process_material = process
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.46,0.48,0.5,0.014),Color(0.46,0.48,0.5,0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1,0.5)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_texture = texture
	material.no_depth_test = false
	material.disable_fog = true
	var quad := QuadMesh.new()
	quad.size = Vector2(4,0.65)
	quad.material = material
	mist.draw_pass_1 = quad
	add_child(mist)
	mist.position = Vector3(-3,0.25,8)

func set_active(value: bool) -> void:
	active = value
	porch.visible = value
	facade_fill.visible = value
	mist.visible = value
	camera.current = value
	if not value:shadow.visible = false

func _process(delta: float) -> void:
	if not active: return
	clock += delta
	shadow.visible = fmod(clock,47.0) > 31.0 and fmod(clock,47.0) < 34.0
	porch.light_energy = 0.9 if reduce_flash else 0.9-0.18*pow(maxf(sin(clock*0.37),0),18)
	if not reduce_motion:
		camera.position.x = -10.5+sin(clock*0.055)*0.14
		camera.look_at(Vector3(-0.1,1.8,3.6))
	for i in range(trees.size()):trees[i].rotation.z = sin(clock*0.3+float(i))*0.002
