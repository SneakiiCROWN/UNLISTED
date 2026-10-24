extends Node3D
# Curated nonessential objects only. Keys, fuse, documents and puzzle valves remain fixed.
var game: Node3D
var props: Dictionary = {}
var homes: Dictionary = {}
var held: RigidBody3D
var last_speed: Dictionary = {}
var impact_cooldown := 0.0
var reminded := false
var support: Node3D
var forearm: Node3D

func _ready() -> void:
	make_prop("cup","mug","res://assets/dusk/psx_prop_mug_01.glb",Vector3(4.6,0.87,0),Vector3(0.12,0.14,0.12),0.24)
	make_prop("spare","iron fitting","res://assets/machinery/pipe_valve.glb",Vector3(-17.25,0.93,-16),Vector3(0.26,0.22,0.26),1.1)
	make_prop("tin","tool tin","res://assets/dusk/psx_prop_single_tin.glb",Vector3(-3.20,.96,-9.4),Vector3(.23,.24,.22),1.05)
	make_prop("kitchen_mug","enamel mug","res://assets/dusk/psx_prop_mug_01.glb",Vector3(-5.6,.87,-.7),Vector3(.12,.14,.12),.25)
	make_prop("pot","cooking pot","res://assets/dusk/psx_prop_cooking_pot_01.glb",Vector3(-7.04,float(game.get_node("KitchenStove").get_meta("cooktop"))+.127,1.45),Vector3(.30,.25,.30),.85)
	make_prop("counter_mug","cup","res://assets/dusk/psx_prop_mug_01.glb",Vector3(-4.8,.936,3.55),Vector3(.14,.15,.14),.24)
	for i in 3:
		make_prop("can"+str(i),"food tin","res://assets/dusk/psx_prop_single_tin.glb",Vector3(-3.6-i*.15,.956,3.32 if i==0 else 3.53),Vector3(.12,.19,.12),.32)
	make_prop("archive_mug","office mug","res://assets/dusk/psx_prop_mug_01.glb",Vector3(3.76,1.32,-9.45),Vector3(.14,.16,.14),.24)
	# Reuse the existing wash-pan asset, away from the service doorway and rack.
	# Legacy saves lack this optional body and fall back to its authored home.
	make_prop("wash_pan","wash pan","res://assets/dusk/psx_prop_cooking_pot_01.glb",Vector3(-5.90,.112,-9.40),Vector3(.42,.22,.40),.60)
	# Curated loose details on existing supports, not new progression items.
	make_prop("water_bottle","empty bottle","res://assets/dusk/psx_prop_single_bottle.glb",Vector3(-6.50,.942,-.99),Vector3(.08,.28,.08),.28)
	make_prop("parts_tin","parts tin","res://assets/dusk/psx_prop_single_tin.glb",Vector3(-4.58,-2.078,-17.88),Vector3(.16,.24,.16),.36)
	# Replace one existing fixed household object, then add two purposeful
	# working-room details on the authored .86 m counter / .80 m benches.
	make_prop("counter_vase","small vase","res://assets/furniture/vase.glb",Vector3(-4.15,1.022,3.55),Vector3(.20,.32,.20),.60)
	make_prop("utility_mug","work mug","res://assets/dusk/psx_prop_mug_01.glb",Vector3(-2.10,.867,-9.15),Vector3(.11,.13,.11),.25)
	make_prop("shed_parts","parts tin","res://assets/dusk/psx_prop_single_tin.glb",Vector3(-17.85,.902,-15.80),Vector3(.18,.20,.18),.40)
	build_support()

func build_support() -> void:
	support = preload("res://assets/first_person/support_hand.glb").instantiate()
	support.name = "LeftCarryHand";add_child(support)
	forearm = preload("res://assets/first_person/support_sleeve.glb").instantiate()
	add_child(forearm)
	game.player.viewmodel.prepare_meshes(support)
	game.player.viewmodel.prepare_meshes(forearm)
	support.visible = false;forearm.visible = false

func _process(_delta: float) -> void:
	var shown: bool = is_instance_valid(held) and game.player.active and game.presentation.prefs.data.viewmodel
	support.visible = shown;forearm.visible = shown
	if not shown:return
	var camera: Camera3D = game.player.camera
	# The palm follows the swept physical object, not an unrelated fixed screen pose.
	support.global_transform = Transform3D(camera.global_basis,held.global_position-camera.global_basis.y*0.11)
	var a: Vector3 = camera.to_global(Vector3(-0.36,-0.64,-0.03))
	var b := support.global_position-camera.global_basis.y*0.035
	forearm.global_position = a
	forearm.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	forearm.scale.y = a.distance_to(b)

func make_prop(id: String,label_: String,path: String,pos: Vector3,size_: Vector3,weight: float) -> void:
	var body := RigidBody3D.new()
	body.set_script(load("res://scripts/loose_body.gd"))
	body.name = "Loose_"+id
	body.mass = weight
	body.collision_layer = 32
	body.collision_mask = 1|2|16|32
	body.continuous_cd = true
	body.contact_monitor = true
	body.max_contacts_reported = 12
	body.linear_damp = 0.35
	body.angular_damp = 0.6
	var material := PhysicsMaterial.new()
	material.friction = 0.7
	material.bounce = 0.08
	body.physics_material_override = material
	body.set_meta("loose_prop",id)
	body.set_meta("prop_label",label_)
	add_child(body)
	body.position = pos
	var shape := CollisionShape3D.new()
	shape.name = "PropShape"
	# The broad, leafy pot needs a stable contact footprint. The cylinder proxy
	# settled through the worktop by 11 mm in the native support capture.
	if id in ["cup","water_bottle","utility_mug"]:
		var cylinder := CylinderShape3D.new()
		cylinder.radius = size_.x/2
		cylinder.height = size_.y
		shape.shape = cylinder
	else:
		var box := BoxShape3D.new()
		box.size = size_
		shape.shape = box
	body.add_child(shape)
	game.model(path,body,Vector3(0,-size_.y/2,0),size_,0,false)
	props[id] = body
	homes[id] = body.transform
	last_speed[id] = 0.0
	body.body_entered.connect(func(_other):impact(body,id))

func impact(body: RigidBody3D,id: String) -> void:
	if not game.started or game.menu_open or held==body or impact_cooldown>0:return
	var strength: float = last_speed.get(id,0.0)
	if strength<0.65:return
	impact_cooldown = 0.16
	var audio = game.sound("prop_impact",body.position,clampf(-34+strength*1.5,-33,-22))
	audio.pitch_scale = 1.25 if id=="cup" else (0.85 if body.position.y < -1 else 1.02)
	game.threat.hear(body.position,minf(14,strength*2.4))

func can_carry(body: RigidBody3D) -> bool:
	return body.global_position.distance_to(game.player.camera.global_position)<=2.0

func use() -> bool:
	if held:release(false);return true
	var hit: Dictionary = game.player.target()
	if hit.is_empty() or not hit.collider.has_meta("loose_prop"):return false
	var body: RigidBody3D = hit.collider
	if not can_carry(body):return false
	held = body
	held.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	held.freeze = true
	held.linear_velocity = Vector3.ZERO
	held.angular_velocity = Vector3.ZERO
	held.add_collision_exception_with(game.player)
	if body==props.spare and not game.events.get("scrap_examined",false):
		game.events.scrap_examined = true
		game.presentation.notify("An old valve fitting. Heavier than it looks.")
	if body==props.cup and not game.events.has("remembered_cup"):
		game.events.remembered_cup = [body.position.x,body.position.y,body.position.z]
	if not reminded and game.presentation.prefs.data.reminders:
		reminded = true
		game.presentation.notify("X RELEASE / RT THROW / HOLD LT + RIGHT STICK TO ROTATE" if game.controller.used else "E RELEASE / LEFT MOUSE THROW / HOLD R TO ROTATE")
	return true

func release(throw_: bool) -> void:
	if not is_instance_valid(held):return
	var body := held
	held = null
	body.freeze = false
	body.sleeping = false
	body.linear_velocity = -game.player.camera.global_basis.z*(minf(6.0,4.5/sqrt(body.mass)) if throw_ else 0.3)
	body.angular_velocity = Vector3(0.5,1.0,0.2) if throw_ else Vector3.ZERO
	# The body remains in front of the capsule; restore ordinary collisions immediately.
	body.remove_collision_exception_with(game.player)

func rotate_held(relative: Vector2) -> void:
	if held:
		var before := held.transform
		held.rotate_y(-relative.x*0.008)
		held.rotate_object_local(Vector3.RIGHT,-relative.y*0.008)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = held.get_node("PropShape").shape
		query.transform = held.global_transform
		# Rotation must respect the Surveyor's body as well as walls/other props,
		# just like the existing swept carry movement does.
		query.collision_mask = 1|16|32
		query.exclude = [held.get_rid(),game.player.get_rid()]
		if not game.get_world_3d().direct_space_state.intersect_shape(query).is_empty():held.transform = before

func snapshot() -> Dictionary:
	var result := {}
	for id in props:
		var body: RigidBody3D = props[id]
		var transform_: Transform3D = homes[id] if body==held else body.transform
		var v := transform_.origin
		var r := transform_.basis.get_euler()
		result[id] = [v.x,v.y,v.z,r.x,r.y,r.z]
	return result

func restore(values := {}) -> void:
	if held:release(false)
	for id in props:
		var b: RigidBody3D = props[id]
		b.freeze = true
		b.transform = homes[id]
		var p: Array = values.get(id,[])
		if p.size()==6:
			var point:=Vector3(p[0],p[1],p[2]);var rotation_:=Vector3(p[3],p[4],p[5])
			# Keep valid placements on the newer raised lane/terrain, while still
			# rejecting out-of-world positions and invalid saved rotations.
			if point.is_finite() and rotation_.is_finite() and point.y>-5 and point.y<40 and absf(point.x)<=128 and absf(point.z)<=128:
				b.position=point;b.rotation=rotation_
		b.linear_velocity = Vector3.ZERO;b.angular_velocity = Vector3.ZERO
		b.call("relocate",b.transform)

func _physics_process(delta: float) -> void:
	if not game.started:return
	impact_cooldown = maxf(0,impact_cooldown-delta)
	for id in props:
		var body: RigidBody3D = props[id]
		last_speed[id] = body.linear_velocity.length()
		# The old 28 m limit predated the connected lane and woodland. Do not
		# snatch an object out of the player's hand inside the current property.
		# Recovery remains beyond the 112 m authored exterior and below the cellar.
		if body.position.y < -7 or absf(body.position.x)>128 or absf(body.position.z)>128:
			if body==held:release(false)
			body.call("relocate",homes[id])
		if body.linear_velocity.length()>8:body.linear_velocity = body.linear_velocity.normalized()*8
	if not held:return
	var camera: Camera3D = game.player.camera
	var desired := camera.to_global(Vector3(-0.22,-0.30,-0.75))
	var motion := desired-held.global_position
	# A quick turn can put the desired grip on the opposite side of the camera.
	# Release only when the object itself falls out of reach, not on that turn.
	if held.global_position.distance_to(camera.global_position)>3.0:release(false);return
	# Frozen kinematic bodies are swept, never teleported through walls or furniture.
	held.move_and_collide(motion.limit_length(delta*5.0))

func repeat_placement() -> bool:
	if not game.events.has("remembered_cup") or game.events.get("cup_repeated",false) or held==props.cup:return false
	var body: RigidBody3D = props.cup
	var camera: Camera3D = game.player.camera
	if not camera.is_position_behind(body.position):
		var screen := camera.unproject_position(body.position)
		if game.get_viewport().get_visible_rect().has_point(screen) and game.threat.clear_line(camera.global_position,body.position):return false
	var p: Array = game.events.remembered_cup
	var destination := Vector3(p[0],p[1]+0.015,p[2])
	if body.position.distance_to(destination)<0.25:return false
	if destination.distance_to(game.player.position)<1.2:return false
	if not camera.is_position_behind(destination) and game.get_viewport().get_visible_rect().has_point(camera.unproject_position(destination)) and game.threat.clear_line(camera.global_position,destination):return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = body.get_node("PropShape").shape
	query.transform = Transform3D(body.basis,destination)
	query.collision_mask = 1|2|16|32
	query.exclude = [body.get_rid()]
	if not game.get_world_3d().direct_space_state.intersect_shape(query).is_empty():return false
	body.call("relocate",Transform3D(body.basis,destination))
	game.events.cup_repeated = true
	return true
