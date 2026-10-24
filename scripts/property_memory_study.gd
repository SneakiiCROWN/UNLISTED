extends Node3D
# INACTIVE UNTESTED art/sequence candidate. No ordinary world/F1 registration.
# Future: one unobserved reveal after the shed discovery and service isolation,
# outside all threat/recount/blackout windows. Case persistence is NOT integrated.
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
