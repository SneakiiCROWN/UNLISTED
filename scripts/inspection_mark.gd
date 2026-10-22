extends MeshInstance3D
# Fluorescent inspection seal. Beam-local shader plus conservative real occlusion.
var game: Node3D
var ink:=ShaderMaterial.new()
func _ready() -> void:
	name="ReportSleeveInspectionSeal"
	var plane:=PlaneMesh.new();plane.size=Vector2(.16,.12);mesh=plane
	position=Vector3(6.27,.8223,-8.56);cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ink.shader=load("res://shaders/inspection_ink.gdshader");ink.set_shader_parameter("ink_texture",load("res://assets/original/inspection_seal.svg"));material_override=ink
func _process(_delta: float) -> void:
	var on: bool=is_instance_valid(game.equipment) and game.started and game.events.get("field_return_read",false) and game.equipment.is_uv()
	if on:
		var light: SpotLight3D=game.player.torch
		var query:=PhysicsRayQueryParameters3D.create(light.global_position,global_position+Vector3.UP*.004,1)
		query.exclude=[game.player.get_rid(),game.targets.carbon_return.get_rid()]
		on=get_world_3d().direct_space_state.intersect_ray(query).is_empty()
		ink.set_shader_parameter("beam_origin",light.global_position);ink.set_shader_parameter("beam_forward",-light.global_basis.z)
	ink.set_shader_parameter("beam_active",1.0 if on else 0.0)
