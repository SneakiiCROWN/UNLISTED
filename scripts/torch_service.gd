extends Node3D
# A captive rear cap and supported pack exchange. Inventory commits once in equipment.
var player: CharacterBody3D
var geometry: Node3D
var animation: AnimationPlayer
var hinge: Node3D
var hand: Node3D
var sleeve: Node3D
var old_pack: Node3D
var new_pack: Node3D
var running:=false
const PACK_HOME:=Vector3(0,.012,.030)
const PALM:=Vector3(-.005,-.035,.136)
func _ready() -> void:
	name="TorchServicePose";geometry.reparent(self);geometry.name="TorchGeometry"
	hinge=Node3D.new();hinge.name="CapHinge";geometry.add_child(hinge);hinge.position=Vector3(-.028,.012,.064)
	var cap: MeshInstance3D
	for mesh in player.game.all_meshes(geometry):
		if mesh.name.replace("_"," ").to_lower()=="tail cap":cap=mesh
	assert(cap!=null,"The actual rear cap must remain separate")
	cap.reparent(hinge,true)
	var pin:=MeshInstance3D.new();var cylinder:=CylinderMesh.new();cylinder.top_radius=.004;cylinder.bottom_radius=.004;cylinder.height=.033;cylinder.radial_segments=12;pin.mesh=cylinder;pin.material_override=player.game.mat(Color("575d55"));geometry.add_child(pin);pin.position=hinge.position
	old_pack=pack("OldPack");new_pack=pack("NewPack")
	hand=preload("res://assets/first_person/support_hand.glb").instantiate();hand.name="ServiceHand";add_child(hand)
	sleeve=preload("res://assets/first_person/support_sleeve.glb").instantiate();sleeve.name="ServiceSleeve";add_child(sleeve)
	player.viewmodel.prepare_meshes(self)
	animation=AnimationPlayer.new();animation.name="PackAnimation";add_child(animation)
	var library:=AnimationLibrary.new();var full:=make_animation();library.add_animation("exchange",full)
	var reduced: Animation=full.duplicate(true);reduced.remove_track(reduced.find_track(NodePath(".:rotation"),Animation.TYPE_VALUE));library.add_animation("exchange_reduced",reduced);animation.add_animation_library("",library)
	animation.animation_finished.connect(func(_name):finish())
	finish(false)
func pack(id: String) -> Node3D:
	var root:=Node3D.new();root.name=id;geometry.add_child(root);root.position=PACK_HOME
	root.add_child(preload("res://scripts/d_cell.gd").make(player.game))
	return root
func track(anim: Animation,path: String,times: Array,values: Array,discrete:=false) -> void:
	var id:=anim.add_track(Animation.TYPE_VALUE);anim.track_set_path(id,NodePath(path))
	if discrete:anim.value_track_set_update_mode(id,Animation.UPDATE_DISCRETE)
	for i in times.size():anim.track_insert_key(id,float(times[i]),values[i])
func make_animation() -> Animation:
	var anim:=Animation.new();anim.length=1.50
	track(anim,".:position",[0,.18,1.30,1.50],[Vector3.ZERO,Vector3(-.12,.035,.035),Vector3(-.12,.035,.035),Vector3.ZERO])
	track(anim,".:rotation",[0,.18,1.30,1.50],[Vector3.ZERO,Vector3(0,0,-.14),Vector3(0,0,-.14),Vector3.ZERO])
	track(anim,"TorchGeometry/CapHinge:rotation",[0,.28,.46,1.13,1.30,1.50],[Vector3.ZERO,Vector3.ZERO,Vector3(0,-2.2,0),Vector3(0,-2.2,0),Vector3.ZERO,Vector3.ZERO])
	track(anim,"TorchGeometry/OldPack:visible",[0,.43,.80],[false,true,false],true)
	track(anim,"TorchGeometry/OldPack:position",[0,.46,.67,.80],[PACK_HOME,PACK_HOME,PACK_HOME+Vector3(0,0,.07),PACK_HOME+Vector3(-.15,-.30,.07)])
	track(anim,"TorchGeometry/NewPack:visible",[0,.80,1.10],[false,true,false],true)
	track(anim,"TorchGeometry/NewPack:position",[0,.80,.96,1.10],[PACK_HOME+Vector3(-.15,-.30,.07),PACK_HOME+Vector3(-.15,-.30,.07),PACK_HOME+Vector3(0,0,.07),PACK_HOME])
	track(anim,"ServiceHand:visible",[0,.12,1.42],[false,true,false],true)
	track(anim,"ServiceHand:position",[0,.28,.46,.67,.80,.96,1.10,1.30,1.42],[PALM+Vector3(-.15,-.30,.07),PALM+Vector3(0,0,.02),PALM,PALM+Vector3(0,0,.07),PALM+Vector3(-.15,-.30,.07),PALM+Vector3(0,0,.07),PALM,PALM+Vector3(0,0,.02),PALM+Vector3(-.15,-.30,.07)])
	return anim
func start() -> void:
	if running:return
	running=true;rotation=Vector3.ZERO
	for key in get_meta_list():
		if str(key).begins_with("cue_"):remove_meta(key)
	animation.speed_scale=1.0;animation.play("exchange_reduced" if player.game.presentation.prefs.data.reduced_motion else "exchange")
func finish(update_light:=true) -> void:
	running=false
	if is_instance_valid(animation):animation.stop()
	position=Vector3.ZERO;rotation=Vector3.ZERO
	if is_instance_valid(hinge):hinge.rotation=Vector3.ZERO
	for node in [hand,sleeve,old_pack,new_pack]:
		if is_instance_valid(node):node.visible=false
	if update_light and is_instance_valid(player.game.equipment):player.game.equipment.apply_light()
func sound_cue(pitch: float) -> void:
	var cue=player.game.sound("latch",player.camera.global_position,-35);cue.pitch_scale=pitch
func _process(_delta: float) -> void:
	if not running:return
	if not player.active or is_instance_valid(player.game.physical.held):finish();return
	if player.game.presentation.prefs.data.reduced_motion:rotation=Vector3.ZERO
	var t: float=animation.current_animation_position
	# Quiet mechanical cues follow the real animation, including pause-safe timing.
	for pair in [[.30,.90],[1.13,1.12]]:
		var key: String="cue_"+str(roundi(float(pair[0])*100))
		if t<float(pair[0]):
			if has_meta(key):remove_meta(key)
		elif not has_meta(key):set_meta(key,true);sound_cue(pair[1])
	sleeve.visible=hand.visible
	if hand.visible:
		var camera: Camera3D=player.camera
		var wrist: Vector3=hand.global_position-camera.global_basis.y*.035
		var start_: Vector3=camera.to_global(Vector3(-.36,-.59,-.08))
		var sleeve_basis:=Basis(Quaternion(Vector3.UP,(wrist-start_).normalized()));sleeve_basis.y*=wrist.distance_to(start_)
		sleeve.global_transform=Transform3D(sleeve_basis,start_)
