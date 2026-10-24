extends Node3D
# Shared New Game cinematic and retained opt-in title-only study.
# The parked car never moves; the existing New Game function owns case creation.
var game: Node3D
var integrated:=false
var running:=false
var headlamps: Array[SpotLight3D]=[]
var cue_log: Array=[]
var engine: AudioStreamPlayer3D
var original_car_transform:=Transform3D.IDENTITY
var previous_camera: Camera3D
var previous_focus: Control
var previous_stage:=false
var hidden_controls: Dictionary={}
var streams: Array[AudioStreamPlayer3D]=[]
var menu_levels: Dictionary={}

func _ready() -> void:
	if integrated:
		start_integrated();return
	if not is_instance_valid(game) or not game.dev_mode or game.started or game.presentation.section!="title":queue_free();return
	var car: Node3D=game.get_node_or_null("BriarLaneExterior/EliArrivalCar")
	if not is_instance_valid(car):queue_free();return
	running=true
	previous_camera=get_viewport().get_camera_3d();previous_focus=get_viewport().gui_get_focus_owner()
	var p=game.presentation;previous_stage=p.stage.active;p.section="arrival_study"
	for audio in [p.ambience,p.menu_drone]:menu_levels[audio]=audio.volume_db
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
	var joy: bool=event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_START]
	if keyboard or joy or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled();finish()
func finish() -> void:
	if integrated:
		finish_integrated();return
	if not running:return
	running=false;$AnimationPlayer.stop()
	for audio in streams:
		if is_instance_valid(audio):audio.stop()
	for control in hidden_controls:
		if is_instance_valid(control):control.visible=hidden_controls[control]
	for audio in menu_levels:
		if is_instance_valid(audio):audio.volume_db=menu_levels[audio]
	if is_instance_valid(game):
		game.presentation.stage.set_active(previous_stage)
		if game.presentation.section=="arrival_study":game.presentation.section="title"
	if is_instance_valid(previous_camera):previous_camera.current=true
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():previous_focus.grab_focus()
	elif is_instance_valid(game) and game.presentation.section=="title":
		var first: Button=game.presentation.buttons.get("New Game")
		if is_instance_valid(first) and first.is_visible_in_tree():first.grab_focus()
	queue_free()

func _exit_tree() -> void:
	# Also restore presentation on explicit removal, not just normal completion.
	if running and integrated:
		running=false
		for audio in streams:
			if is_instance_valid(audio):audio.stop()
		if is_instance_valid(game) and is_instance_valid(game.presentation):
			game.presentation.arrival_sequence=null
			# Recover explicit removal on the next UI frame. Application teardown
			# has no next frame and must never start/save a new case here.
			game.presentation.call_deferred("recover_arrival_removal")
	elif running:finish()

func start_integrated() -> void:
	var car: Node3D=game.get_node_or_null("BriarLaneExterior/EliArrivalCar")
	if not is_instance_valid(car):
		game.presentation.arrival_sequence=null;game.presentation.begin_original_intro();queue_free();return
	running=true;original_car_transform=car.global_transform
	var p=game.presentation
	previous_camera=get_viewport().get_camera_3d();previous_stage=p.stage.active
	p.pause_world();p.section="intro";p.stage.set_active(false);game.player.torch.visible=false
	for control in [p.body,p.status,p.footer,p.shade,p.card,p.toast,p.menu_navigation,p.intro_text]:
		hidden_controls[control]=control.visible;control.visible=false
	p.fade.color.a=0
	$PreviewCamera.current=true;$PreviewCamera.fov=62
	$PreviewOverlay/Skip.theme=p.THEME
	$PreviewOverlay/Skip.text="A / B / START  SKIP" if game.controller.used else "SPACE / E / ESC  SKIP"
	p.anchored($PreviewOverlay/Skip,Control.PRESET_BOTTOM_LEFT,Rect2(32,-38,650,24))
	var text:=VBoxContainer.new();text.name="CaseContext";$PreviewOverlay.add_child(text)
	p.anchored(text,Control.PRESET_CENTER_LEFT,Rect2(48,-60,700,140))
	text.theme=p.THEME
	p.label(text,"ELI WARD / 23:17",16,"Meta")
	p.label(text,"Dad disappeared here in 1998.\nTonight, someone reported a TV playing in the empty house.\nI asked dispatch for the call.",20)
	var title:=VBoxContainer.new();title.name="ArrivalTitle";$PreviewOverlay.add_child(title)
	p.anchored(title,Control.PRESET_CENTER,Rect2(-300,-55,600,110));title.theme=p.THEME
	var name_: Label=p.label(title,"UNLISTED",58,"Title");name_.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var tag: Label=p.label(title,"No Record. No Exit.",18,"Meta");tag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var h: float=car.global_position.y
	var a:=view(Vector3(-1.3,h+1.15,25.7),car.global_position+Vector3(.65,.55,0))
	var b:=view(Vector3(-1.55,h+1.15,25.5),car.global_position+Vector3(.65,.55,0))
	var c:=view(Vector3(-5.1,h+1.66,19.5),Vector3(0,1.65,4.0))
	var d:=view(Vector3(-4.95,h+1.66,19.4),Vector3(0,1.65,4.0))
	var gate:=view(Vector3(0,1.68,19.4),Vector3(0,1.68,3.4))
	if p.prefs.data.reduced_motion:b=a;d=c
	var clip:=Animation.new();clip.length=13.0
	track(clip,"PreviewCamera:transform",[0,4.65,4.66,7.55,7.56,12.0],[a,b,c,d,gate,gate])
	track(clip,"PreviewCamera:fov",[0,7.55,7.56,12.0],[62.0,62.0,77.0,77.0])
	track(clip,"PreviewOverlay/Black:color",[0,.8,4.2,4.55,4.85,5.25,7.15,7.48,7.8,8.15,11.3,12.0],[Color.BLACK,Color(0,0,0,0),Color(0,0,0,0),Color.BLACK,Color.BLACK,Color(0,0,0,0),Color(0,0,0,0),Color.BLACK,Color.BLACK,Color(0,0,0,0),Color(0,0,0,0),Color.BLACK])
	track(clip,"PreviewOverlay/CaseContext:modulate:a",[0,.8,3.9,4.3,12.0],[0.0,1.0,1.0,0.0,0.0])
	track(clip,"PreviewOverlay/ArrivalTitle:modulate:a",[0,8.2,8.9,10.7,11.3,12.0],[0.0,0.0,1.0,1.0,0.0,0.0])
	for x in [-.62,.62]:
		var light:=SpotLight3D.new();light.name="TemporaryArrivalHeadlamp";add_child(light)
		light.global_position=car.to_global(Vector3(x,.62,2.23));light.look_at(light.global_position+car.global_basis.z*12+Vector3(0,-.7,0))
		light.light_color=Color("e1d2aa");light.light_energy=.7;light.spot_range=17;light.spot_angle=34;light.spot_attenuation=.8;light.shadow_enabled=true;headlamps.append(light)
	var method:=clip.add_track(Animation.TYPE_METHOD);clip.track_set_path(method,NodePath("."))
	for cue in [[2.45,"engine_stop"],[4.72,"door_open"],[6.05,"door_close"]]:clip.track_insert_key(method,cue[0],{"method":"integrated_cue","args":[cue[1]]})
	for ti in clip.get_track_count():
		for ki in range(clip.track_get_key_count(ti)-1,-1,-1):
			var at:=clip.track_get_key_time(ti,ki)
			if at>=3.9:clip.track_set_key_time(ti,ki,at+1.0)
	var library:=AnimationLibrary.new();library.add_animation("arrival",clip);$AnimationPlayer.add_animation_library("",library)
	$AnimationPlayer.animation_finished.connect(func(_id):finish())
	play_cue("res://assets/audio/arrival/engine_idle.ogg",car.global_position+Vector3(1,.6,0),-30);engine=streams.back()
	$AnimationPlayer.play("arrival")

func integrated_cue(id: String) -> void:
	if not running:return
	var car: Node3D=game.get_node("BriarLaneExterior/EliArrivalCar")
	cue_log.append({"id":id,"at":$AnimationPlayer.current_animation_position,"position":car.global_position})
	if id=="engine_stop":
		if is_instance_valid(engine):engine.stop()
		play_cue("res://assets/audio/arrival/engine_off.ogg",car.global_position+Vector3(1,.6,0),-25)
		for light in headlamps:create_tween().tween_property(light,"light_energy",0.0,.6)
	elif id=="door_open":play_cue("res://assets/audio/arrival/door_open.ogg",car.global_position+Vector3(0,.8,-.8),-28)
	else:play_cue("res://assets/audio/arrival/door_close.ogg",car.global_position+Vector3(0,.8,-.8),-27)

func finish_integrated() -> void:
	if not running:return
	running=false;$AnimationPlayer.stop()
	for audio in streams:
		if is_instance_valid(audio):audio.stop();audio.queue_free()
	streams.clear()
	for light in headlamps:
		if is_instance_valid(light):light.visible=false;light.queue_free()
	headlamps.clear()
	if not is_instance_valid(game):return
	var p=game.presentation;p.arrival_sequence=null
	for control in hidden_controls:
		if is_instance_valid(control):control.visible=hidden_controls[control]
	p.menu_navigation.visible=false
	game.controller.clear()
	p.complete_intro(true)
	queue_free()
