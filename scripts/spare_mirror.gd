extends Node3D
# Planar inspection glass. The returned cloth layer contradicts the physical cot.
var game: Node3D
var feed: SubViewport
var camera: Camera3D
var glass: MeshInstance3D
var returned: MeshInstance3D
var clock:=0.0
var center:=Vector3.ZERO
var size_:=Vector2(.5,.7)
const REAL_CLOTH:=1<<13
const RETURN_CLOTH:=1<<14
const GLASS:=1<<15
func _ready() -> void:
	name="UtilityInspectionGlass"
	var frame: Node3D=game.model("res://assets/interiors/bathroomMirror.glb",self,Vector3(-7.37,.95,-4.45),Vector3(.58,.80,.065),PI/2,false)
	var bounds:=AABB();var first:=true
	for mesh in game.all_meshes(frame):
		for i in mesh.mesh.get_surface_count():
			var material: Material=mesh.get_active_material(i)
			if material!=null and material.resource_name.to_lower()=="metal":
				var arrays: Array=mesh.mesh.surface_get_arrays(i)
				for v in arrays[Mesh.ARRAY_VERTEX]:
					var point: Vector3=mesh.global_transform*v
					if first:bounds=AABB(point,Vector3.ZERO);first=false
					else:bounds=bounds.expand(point)
				var hidden:=StandardMaterial3D.new();hidden.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;hidden.albedo_color=Color(0,0,0,0);mesh.set_surface_override_material(i,hidden)
			else:mesh.set_surface_override_material(i,game.texture_mat("res://assets/dusk/psx_house_old_wood_01.png",Color("635b4e")))
	assert(not first,"Approved mirror glass surface missing")
	center=bounds.get_center();center.x=bounds.end.x+.003;size_=Vector2(bounds.size.z,bounds.size.y)
	feed=SubViewport.new();feed.size=Vector2i(roundi(512.0*size_.x/size_.y),512);feed.world_3d=game.get_world_3d();feed.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(feed)
	camera=Camera3D.new();feed.add_child(camera);camera.current=true;camera.cull_mask=1|8|RETURN_CLOTH
	glass=MeshInstance3D.new();var plane:=QuadMesh.new();plane.size=size_;glass.mesh=plane;glass.layers=GLASS;glass.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glass);glass.global_position=center;glass.rotation.y=PI/2
	var reflective:=StandardMaterial3D.new();reflective.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;reflective.albedo_texture=feed.get_texture();reflective.uv1_scale.x=-1;reflective.uv1_offset.x=1;glass.material_override=reflective
	game.player.camera.cull_mask|=REAL_CLOTH|GLASS;game.player.torch.light_cull_mask|=REAL_CLOTH
	game.spare_place.cloth.layers=REAL_CLOTH
	returned=MeshInstance3D.new();add_child(returned);returned.global_position=game.spare_place.cloth.global_position;returned.material_override=game.spare_place.cloth.material_override;returned.layers=RETURN_CLOTH;returned.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	game.collision(self,center,Vector3(.025,size_.y,size_.x),"spare_mirror")
func visible_glass() -> bool:
	var view: Camera3D=game.player.camera
	if view.is_position_behind(center) or not game.get_viewport().get_visible_rect().has_point(view.unproject_position(center)):return false
	var q:=PhysicsRayQueryParameters3D.create(view.global_position,center,1)
	var hit:=get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or is_ancestor_of(hit.collider) or hit.position.distance_to(center)<.10
func touch() -> void:
	game.sound("prop_impact",center,-37)
	if not game.events.get("spare_uncovered",false):return
	game.events.spare_glass_seen=true;game.events.notes=game.events.get("notes",{})
	game.events.notes["THE UTILITY GLASS"]=game.NOTES.SPARE_GLASS_NOTE
	game.save_game(true)
func _process(delta: float) -> void:
	if not game.started or game.menu_open:return
	clock+=delta
	if clock<.125:return
	clock=0
	var eye: Vector3=game.player.camera.global_position
	if eye.x<center.x+.25 or eye.distance_to(center)>4.5 or not visible_glass():return
	var distance_: float=eye.x-center.x
	camera.global_position=Vector3(center.x-distance_,eye.y,eye.z)
	camera.look_at(camera.global_position+Vector3.RIGHT,Vector3.UP)
	# Fixed glass plane with off-axis projection; near clipping excludes its backing wall.
	camera.set_frustum(size_.y,Vector2(center.z-eye.z,center.y-eye.y),distance_+.02,36)
	returned.visible=game.events.get("spare_offered",false)
	if returned.visible:returned.mesh=game.spare_place.cover_mesh(true)
	feed.render_target_update_mode=SubViewport.UPDATE_ONCE
