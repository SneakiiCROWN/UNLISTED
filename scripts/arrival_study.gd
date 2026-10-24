extends Node3D
# Opt-in title-only staging study. Never starts a case, drives the parked body,
# saves, changes progression, or replaces the ordinary New Game introduction.
var game: Node3D
var running:=false
var previous_camera: Camera3D
var previous_focus: Control
var previous_stage:=false
var hidden_controls: Dictionary={}
var streams: Array[AudioStreamPlayer3D]=[]

func _ready() -> void:
	if not is_instance_valid(game) or not game.dev_mode or game.started or game.presentation.section!="title":queue_free();return
	var car: Node3D=game.get_node_or_null("BriarLaneExterior/EliArrivalCar")
	if not is_instance_valid(car):queue_free();return
	running=true
	previous_camera=get_viewport().get_camera_3d();previous_focus=get_viewport().gui_get_focus_owner()
	var p=game.presentation;previous_stage=p.stage.active;p.section="arrival_study"
	for control in [p.body,p.status,p.footer,p.shade,p.card,p.toast,p.menu_navigation]:
		hidden_controls[control]=control.visible;control.visible=false
	p.stage.set_active(false)
	$PreviewCamera.current=true
	# Keep the actual car fixed. The view introduces its place on the lane,
	# then cuts to the gate/house. No unapproved interior or driving animation.
	var h: float=car.global_position.y
	var car_a:=view(Vector3(-8.8,h+1.65,25.5),car.global_position+Vector3(0,.8,0))
	var car_b:=view(Vector3(-8.45,h+1.65,25.1),car.global_position+Vector3(0,.8,0))
	var gate_a:=view(Vector3(-1.9,h+1.65,20.0),Vector3(0,1.8,4.0))
	var gate_b:=view(Vector3(-1.75,h+1.65,19.8),Vector3(0,1.8,4.0))
	if p.prefs.data.reduced_motion:car_b=car_a;gate_b=gate_a
	var animation:=Animation.new();animation.length=8.4
	track(animation,"PreviewCamera:transform",[0,3.40,3.41,8.4],[car_a,car_b,gate_a,gate_b])
	track(animation,"PreviewOverlay/Black:color",[0,.65,2.95,3.25,3.55,4.05,7.6,8.4],[Color.BLACK,Color(0,0,0,0),Color(0,0,0,0),Color.BLACK,Color.BLACK,Color(0,0,0,0),Color(0,0,0,0),Color.BLACK])
	# The second cue uses the same AnimationPlayer timeline as both camera shots.
	var method:=animation.add_track(Animation.TYPE_METHOD);animation.track_set_path(method,NodePath("."))
	animation.track_insert_key(method,2.7,{"method":"door_cue","args":[]})
	var library:=AnimationLibrary.new();library.add_animation("arrival",animation)
	$AnimationPlayer.add_animation_library("",library)
	$AnimationPlayer.animation_finished.connect(func(_id):finish())
	$AnimationPlayer.play("arrival")
	# Audio is replaceable study media, not new canon dialogue or a final mix.
	play_cue("res://assets/audio/arrival/engine_off.ogg",car.global_position+Vector3(0,.7,0),-26)

func view(position_: Vector3,target: Vector3) -> Transform3D:
	return Transform3D(Basis.IDENTITY,position_).looking_at(target,Vector3.UP)
func track(animation: Animation,path: String,times: Array,values: Array) -> void:
	var id:=animation.add_track(Animation.TYPE_VALUE);animation.track_set_path(id,NodePath(path))
	for i in times.size():animation.track_insert_key(id,float(times[i]),values[i])
func play_cue(path: String,where: Vector3,db: float) -> void:
	var audio:=AudioStreamPlayer3D.new();audio.stream=load(path);audio.bus="SFX";audio.volume_db=db;audio.max_distance=18;audio.unit_size=2
	add_child(audio);audio.global_position=where;streams.append(audio);audio.play()
func door_cue() -> void:
	var car: Node3D=game.get_node_or_null("BriarLaneExterior/EliArrivalCar")
	if is_instance_valid(car):play_cue("res://assets/audio/arrival/door_close.ogg",car.global_position+Vector3(0,.8,0),-29)
func _input(event: InputEvent) -> void:
	if not running:return
	var keyboard: bool=event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ESCAPE,KEY_SPACE,KEY_E,KEY_F1]
	if keyboard or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled();finish()
func finish() -> void:
	if not running:return
	running=false;$AnimationPlayer.stop()
	for audio in streams:
		if is_instance_valid(audio):audio.stop()
	for control in hidden_controls:
		if is_instance_valid(control):control.visible=hidden_controls[control]
	if is_instance_valid(game):
		game.presentation.stage.set_active(previous_stage)
		if game.presentation.section=="arrival_study":game.presentation.section="title"
	if is_instance_valid(previous_camera):previous_camera.current=true
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():previous_focus.grab_focus()
	queue_free()

func _exit_tree() -> void:
	# Also restore presentation on explicit removal, not just normal completion.
	if running:finish()
