extends Node3D
# Cosmetic only. The gameplay SpotLight3D and interaction ray remain owned by player.gd.
var player: CharacterBody3D
var clock := 0.0
var home := Vector3(0.23,-0.205,-0.43)
var obstruction := 0.0
var inspection_rim: MeshInstance3D
var inspection_material: StandardMaterial3D

func prepare_meshes(root: Node) -> void:
	for child in root.get_children():
		if child is GeometryInstance3D:
			child.layers = 2
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		prepare_meshes(child)

func _ready() -> void:
	name = "HandheldTorch"
	position = home
	var model: Node3D = preload("res://assets/first_person/work_torch.glb").instantiate()
	add_child(model)
	prepare_meshes(model)
	for mesh in player.game.all_meshes(model):
		if "Bezel wear" in mesh.name or "Bezel_wear" in mesh.name:inspection_rim=mesh
	inspection_material=StandardMaterial3D.new();inspection_material.albedo_color=Color("62627c");inspection_material.roughness=.65

	# Restrained bounce on the hands only; no extra light reaches the house.
	var bounce := OmniLight3D.new()
	bounce.position = Vector3(-0.08,0.13,-0.15)
	bounce.light_color = Color(0.64,0.69,0.73)
	bounce.light_energy = 0.07
	bounce.omni_range = 1.1
	bounce.light_cull_mask = 2
	bounce.shadow_enabled = false
	add_child(bounce)

func _process(delta: float) -> void:
	if is_instance_valid(inspection_rim) and is_instance_valid(player.game.equipment):inspection_rim.material_override=inspection_material if player.game.equipment.data.get("uv",false) else null
	var prefs: Dictionary = player.game.presentation.prefs.data
	var hit: Dictionary = player.target()
	var clearance := 5.0
	if not hit.is_empty():clearance = player.camera.global_position.distance_to(hit.position)
	# Check the actual barrel's side of the view as well as the centre ray.
	var origin: Vector3 = player.camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin,player.camera.to_global(home+Vector3(0,0,-0.20)),1)
	var barrel_hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not barrel_hit.is_empty():clearance=minf(clearance,origin.distance_to(barrel_hit.position))
	obstruction=lerpf(obstruction,clampf((0.85-clearance)/0.4,0,1),1.0-exp(-delta*18))
	visible = player.active and prefs.get("viewmodel",true) and clearance > 0.36
	var moving := Vector2(player.velocity.x,player.velocity.z).length()
	clock += delta*minf(moving*2.5,8.0)
	var sway := Vector3.ZERO
	if not prefs.reduced_motion:sway = Vector3(sin(clock)*0.006,cos(clock*2)*0.004,0)*minf(moving,1)
	var lowered := Vector3(0,-0.10,0.035) if not player.torch.visible else Vector3.ZERO
	position = position.lerp(home+sway+lowered+Vector3(0,-0.13,0.16)*obstruction,1.0-exp(-delta*15))
