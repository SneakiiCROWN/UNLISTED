extends Node3D
# Imported skeletal animation, with a separate post-animation gaze modifier.
var game: Node3D
var figure: Node3D
var animator: AnimationPlayer
var skeleton: Skeleton3D
var gaze: SkeletonModifier3D
var mode := "listen"
var speed := 0.0
var clips := {}
var capture_amount:=0.0
var capture_phase:=0.0
var capture_diagnostics: Dictionary={}
var tailored_presence:=false
var reborn_presence:=false
var motion_rate:=1.0
var motion_target:=1.0
var attention_override: Variant=null

func _ready() -> void:
	for mesh in figure.find_children("*","MeshInstance3D",true,false):
		if mesh.name.begins_with("Reborn"):reborn_presence=true
		if mesh.name.begins_with("Continuous tailored"):tailored_presence=true
		for i in mesh.mesh.get_surface_count():
			var material: Material=mesh.get_active_material(i)
			if material is BaseMaterial3D:
				material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
				if material.resource_name in ["Saturated umber service canvas","Ashen tissue - recessed healed orbits","Clotted wet hair","Cracked gloves and work boots"]:
					material.vertex_color_use_as_albedo=true
	skeleton = figure.find_children("*","Skeleton3D",true,false)[0]
	animator = figure.find_children("*","AnimationPlayer",true,false)[0]
	var prefixes := {"listen":"Idle_","watch":"Idle_","walk":"Walk_Formal_","run":"Jog_Fwd_","attack":"Interact_","capture":"Idle_","react":"Hit_Head_"}
	var library := AnimationLibrary.new()
	for id in prefixes:
		for name_ in animator.get_animation_list():
			if name_.begins_with(prefixes[id]):
				var a := animator.get_animation(name_).duplicate() as Animation
				a.loop_mode = Animation.LOOP_NONE if id in ["attack","capture","react"] else Animation.LOOP_LINEAR
				library.add_animation(id,a)
				clips[id] = "surveyor/"+id
				break
	animator.add_animation_library("surveyor",library)
	gaze = load("res://scripts/surveyor_gaze.gd").new()
	gaze.actor = self
	skeleton.add_child(gaze)
	animator.play(clips.listen)

func set_mode(value: String) -> void:
	if not clips.has(value):return
	if mode == value and animator.is_playing():return
	mode = value
	animator.speed_scale = 1.0
	animator.play(clips[mode],0.36 if mode in ["listen","watch","walk"] else 0.2)

func locomotion(distance_per_second: float, running := false) -> void:
	speed = distance_per_second
	if speed < 0.06:set_mode("watch");return
	# Walk through corners and doorways even when the AI is pursuing. A slowed
	# capsule must not keep playing a jogging clip while barely moving.
	var jog: bool=running and speed>(1.65 if mode=="run" else 1.9)
	set_mode("run" if jog else "walk")
	motion_target=clampf(speed/(2.581*1.05 if jog else 1.018*1.05),0.18,2.3)
	if not reborn_presence:animator.speed_scale=motion_target

func _process(delta: float) -> void:
	if mode in ["listen","watch"]:animator.speed_scale = .62 if reborn_presence else .72
	elif reborn_presence and mode in ["walk","run"]:
		# Visual rate follows measured body travel, easing between rates without
		# changing AI acceleration, pursuit speed or attack timing.
		motion_rate=lerpf(motion_rate,motion_target,1-exp(-delta*10))
		animator.speed_scale=motion_rate
