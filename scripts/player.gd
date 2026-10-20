extends CharacterBody3D

var game: Node
var camera: Camera3D
var torch: SpotLight3D
var sensitivity := 0.0022
var step_clock := 0.0
var active := false
var invert_y := false
var moved_distance := 0.0
var viewmodel: Node3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1|16|32
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.26
	capsule.height = 1.72
	shape.shape = capsule
	shape.position.y = 0.86
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.62
	camera.fov = 77
	camera.cull_mask = 1|2|8
	camera.near = 0.06
	add_child(camera)
	torch = SpotLight3D.new()
	# The beam must not light its own hand/barrel from behind the lens.
	torch.light_cull_mask = 1|8
	torch.light_color = Color(0.82, 0.88, 1.0)
	torch.light_energy = 1.10
	torch.spot_range = 17
	torch.spot_angle = 38
	torch.spot_attenuation = 0.7
	torch.shadow_enabled = true
	torch.position = Vector3(0.15, -0.12, -0.1)
	camera.add_child(torch)
	viewmodel = Node3D.new()
	viewmodel.set_script(load("res://scripts/flashlight_viewmodel.gd"))
	viewmodel.player = self
	camera.add_child(viewmodel)

func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and game.physical.held:
		game.physical.release(true)
		return
	if event is InputEventMouseMotion and game.physical.held and Input.is_physical_key_pressed(KEY_R):
		game.physical.rotate_held(event.relative)
		return
	if event is InputEventMouseMotion and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or (game.automated_qa and event.get_meta("unlisted_qa_input",false))):
		rotate_y(-event.relative.x * sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity * (-1 if invert_y else 1), -1.4, 1.4)
	if event.is_action_pressed("journal"):game.open_casebook();return
	if event.is_action_pressed("hint"):game.request_hint();return
	if event.is_action_pressed("flashlight"):
		torch.visible = not torch.visible
	if event.is_action_pressed("interact"):
		if game.physical.use():return
		game.try_interact()

func _physics_process(delta: float) -> void:
	if not active: return
	var input := Input.get_vector("left", "right", "forward", "back")
	var direction := global_basis * Vector3(input.x, 0, input.y)
	var speed := 2.15
	if Input.is_action_pressed("sprint"): speed = 3.65
	if Input.is_action_pressed("crouch"): speed = 1.15
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 12)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 12)
	if not is_on_floor(): velocity.y -= 20 * delta
	else: velocity.y = -0.1
	var before := position
	move_and_slide()
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var body := collision.get_collider()
		if body is RigidBody3D and not body.freeze:
			body.apply_central_impulse(Vector3(velocity.x,0,velocity.z)*minf(body.mass,1.0)*delta*2)
	var walked := Vector2(position.x - before.x, position.z - before.z).length()
	moved_distance += walked
	step_clock += walked
	if step_clock > 1.25 and is_on_floor():
		step_clock = 0
		var audio = game.sound("step", position, -29 if Input.is_action_pressed("crouch") else (-23 if speed < 3 else -20))
		audio.pitch_scale = 0.94 if position.y < -1 else 1.0
		if is_instance_valid(game.threat):game.threat.hear(position,2.4 if Input.is_action_pressed("crouch") else (8.5 if speed < 3 else 13.0))
		if is_instance_valid(game.horror):game.horror.record_step(position,audio.get_meta("sample"),audio.pitch_scale)
	var eye := 1.12 if Input.is_action_pressed("crouch") else 1.62
	camera.position.y = lerpf(camera.position.y, eye, delta * 10)

func target() -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * 2.6)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)
