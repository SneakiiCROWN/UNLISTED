extends Node3D
# Retained title-only preview plus the saved, optional environmental response.
@export var enable_preview:=false
var game: Node3D
var built:=false

func prepare_preview(current: Node3D) -> bool:
	# Explicit opt-in, title-only development preview; never hijack a live case.
	if not is_instance_valid(current) or not enable_preview or not current.dev_mode or current.started or current.presentation.section!="title":return false
	if built:return false
	game=current;built=true
	var outdoor: Node3D=game.get_node("BriarLaneExterior")
	var marks:=Node3D.new();marks.name="UnreturnedSteps";add_child(marks);marks.visible=false
	var mud:=ShaderMaterial.new();mud.shader=load("res://shaders/property_bootprint.gdshader")
	mud.set_shader_parameter("mud_color",load("res://assets/exterior/Ground067_1K-JPG_Color.jpg"))
	var sole:=QuadMesh.new();sole.size=Vector2(.15,.31);sole.material=mud
	var a:=Vector2(-21.60,-15.45);var b:=Vector2(-20.65,-12.43)
	var direction: Vector2=(b-a).normalized();var right:=Vector2(direction.y,-direction.x)
	# Seven alternating work-boot impressions end at the existing wall-feed job.
	# They do not name Simon, depict a second visitor or unlock any discovery.
	for i in 7:
		var p:=a.lerp(b,float(i)/6)+right*(.105 if i%2==0 else -.105)
		var print_:=MeshInstance3D.new();print_.mesh=sole;print_.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		marks.add_child(print_);print_.position=Vector3(p.x,outdoor.ground_height(p.x,p.y)+.004,p.y)
		print_.rotation=Vector3(-PI/2,0,atan2(direction.x,-direction.y))
	var player:=AnimationPlayer.new();player.name="StudyReveal";add_child(player)
	var animation:=Animation.new();animation.length=.25
	var track:=animation.add_track(Animation.TYPE_VALUE);animation.track_set_path(track,NodePath("UnreturnedSteps:visible"))
	animation.value_track_set_update_mode(track,Animation.UPDATE_DISCRETE)
	animation.track_insert_key(track,0.0,false);animation.track_insert_key(track,.20,true)
	var library:=AnimationLibrary.new();library.add_animation("reveal",animation);player.add_animation_library("",library)
	set_meta("development_status","UNTESTED / inactive environmental-memory candidate; no case/save integration")
	set_meta("review_eye",Vector3(-23.0,1.65,-14.7))
	set_meta("review_target",Vector3(-20.4,.25,-13.3))
	return true

func reveal_preview() -> void:
	if not built or not enable_preview or not is_instance_valid(game) or not game.dev_mode or game.started or game.presentation.section!="title":return
	$StudyReveal.play("reveal")

var runtime:=false
var marks: Node3D
var sample_points: Array[Vector3]=[]
var quiet:=0.0
var probe_clock:=0.0
var observed:=true
var history: Array=[]

func _ready() -> void:
	set_physics_process(false)
	if is_instance_valid(game):
		runtime=true
		call_deferred("build_runtime")

func build_runtime() -> void:
	await get_tree().physics_frame
	marks=Node3D.new();marks.name="UnreturnedSteps";add_child(marks)
	var site: Node3D=game.get_node("BriarLaneExterior")
	var mud:=ShaderMaterial.new();mud.shader=load("res://shaders/property_bootprint.gdshader")
	mud.set_shader_parameter("mud_color",load("res://assets/exterior/Ground067_1K-JPG_Color.jpg"));mud.set_shader_parameter("opacity",.78)
	var a:=Vector2(-21.60,-15.45);var b:=Vector2(-20.65,-12.43)
	var forward: Vector2=(b-a).normalized();var right:=Vector2(-forward.y,forward.x)
	for i in 7:
		var centre:=a.lerp(b,float(i)/6)+right*(.105 if i%2==0 else -.105)
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var corners: Array[Vector3]=[]
		for uv in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
			var q: Vector2=centre+right*((uv.x-.5)*.18)+forward*((.5-uv.y)*.33)
			var y: float=site.ground_height(q.x,q.y)
			var ray:=PhysicsRayQueryParameters3D.create(Vector3(q.x,1,q.y),Vector3(q.x,-1,q.y),1)
			var hit:=game.get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty() and hit.normal.y>.8 and hit.position.y<.4:y=hit.position.y
			corners.append(Vector3(q.x,y+.009,q.y))
		var uvs:=[Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]
		for index in [0,1,2,0,2,3]:st.set_uv(uvs[index]);st.add_vertex(corners[index])
		st.generate_normals();var print_:=MeshInstance3D.new();print_.mesh=st.commit();print_.material_override=mud
		print_.name="MuddySole"+str(i);print_.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;marks.add_child(print_)
		for corner in corners:sample_points.append(corner+Vector3.UP*.012)
		sample_points.append(corners[0].lerp(corners[2],.5)+Vector3.UP*.012)
	# A removed cover rests at the existing wall feed. No new machine or clue text.
	var cover: MeshInstance3D=game.box(self,Vector3(-20.30,.12,-12.05),Vector3(.014,.22,.18),Color("626352"))
	cover.name="RemovedFeedCover";cover.rotation.z=-.30;cover.material_override=game.texture_mat("res://assets/dusk/psx_house_steel_01.png",Color("626352"))
	restore();set_physics_process(true)

func restore() -> void:
	quiet=0;probe_clock=0;observed=true
	if is_instance_valid(marks):marks.visible=game.events.get("unreturned_steps",false)

func visible_creation() -> bool:
	var camera: Camera3D=game.player.camera
	for point in sample_points:
		if game.chapter.point_visible(point):return true
		# Movement toward the trail cannot expose creation between visibility probes.
		if game.player.velocity.length()>.1:
			var q:=PhysicsRayQueryParameters3D.create(camera.global_position+game.player.velocity*.45,point,1)
			q.exclude=[game.player.get_rid(),game.presence.get_rid()]
			if game.get_world_3d().direct_space_state.intersect_ray(q).is_empty():return true
	return false

func eligible() -> bool:
	return game.events.get("house_answers",0)==1 and not game.events.get("unreturned_steps",false) and game.shed_read and (game.events.get("field_return_read",false) or game.events.get("exit_catch_free",false))

func _physics_process(delta: float) -> void:
	if not runtime or not is_instance_valid(marks) or not eligible():return
	var distance: float=game.player.position.distance_to(Vector3(-21,.0,-14))
	if game.ambient_director.response_blocked() or distance<3.2 or distance>22:
		quiet=0;return
	probe_clock-=delta
	if probe_clock<=0:observed=visible_creation();probe_clock=.12
	if observed:quiet=0;return
	quiet+=delta
	if quiet<1.1 or visible_creation():return
	game.events.unreturned_steps=true;marks.visible=true
	history.append({"event":"revealed_unobserved","time":game.time_in_game,"player":game.player.position})
	game.save_game(true)
