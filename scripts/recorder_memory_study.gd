extends Node3D
# Saved production response plus the retained, explicitly armed title-only preview.
# A short mechanical reversal follows the stopped historical recording.
@export var enable_preview:=false
var game: Node3D
var needle: Node3D
var original_angle:=0.0
var reels: Array=[]
var sources: Array[AudioStreamPlayer3D]=[]
var running:=false

func _ready() -> void:
	set_process(false)
	set_physics_process(runtime)

func _process(_delta: float) -> void:
	# Only the explicitly armed preview processes. Abort if someone starts a
	# real case or leaves the title while it runs; ordinary gameplay never loads it.
	if not runtime and running and (not is_instance_valid(game) or game.started or game.presentation.section!="title"):finish_preview()

func start_preview(current: Node3D) -> bool:
	if not is_instance_valid(current) or not enable_preview or running or has_node("ReturnTimeline") or not current.dev_mode or current.started or current.presentation.section!="title":return false
	var deck: Node3D=current.get_node("ArchiveTransport")
	needle=deck.get_node_or_null("ReturnMeterNeedle")
	if not is_instance_valid(needle):return false
	game=current;original_angle=needle.rotation.y;running=true
	var player:=AnimationPlayer.new();player.name="ReturnTimeline";add_child(player)
	var animation:=Animation.new();animation.length=11.0
	var needle_track:=animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(needle_track,NodePath(str(needle.get_path())+":rotation:y"))
	for key in [[0.0,original_angle],[3.15,original_angle],[3.26,.24],[3.55,original_angle],[4.12,original_angle],[4.23,.09],[4.52,original_angle],[5.02,original_angle],[5.13,-.05],[5.46,original_angle],[11.0,original_angle]]:
		animation.track_insert_key(needle_track,key[0],key[1])
	# A barely perceptible backward creep follows the final needle movement.
	# Snapshot every touched reel, then restore on completion, skip or removal.
	for reel in game.get_tree().get_nodes_in_group("archive_reels"):
		if not deck.is_ancestor_of(reel):continue
		if game.presentation.prefs.data.reduced_motion:continue
		reels.append({"node":reel,"angle":reel.rotation.y})
		var track:=animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track,NodePath(str(reel.get_path())+":rotation:y"))
		for key in [[0.0,reel.rotation.y],[5.50,reel.rotation.y],[6.3,reel.rotation.y-.045],[8.0,reel.rotation.y-.045],[9.0,reel.rotation.y],[11.0,reel.rotation.y]]:
			animation.track_insert_key(track,key[0],key[1])
	var cues:=animation.add_track(Animation.TYPE_METHOD);animation.track_set_path(cues,NodePath("."))
	for at in [3.16,4.13,5.03]:animation.track_insert_key(cues,at,{"method":"tick","args":[]})
	var library:=AnimationLibrary.new();library.add_animation("late_return",animation);player.add_animation_library("",library)
	player.animation_finished.connect(func(_id):finish_preview())
	set_meta("development_status","UNTESTED / inactive recorder-memory timing study; no saved-case integration")
	set_meta("review_eye",Vector3(3.30,1.30,-7.70));set_meta("review_target",Vector3(3.30,.92,-8.52))
	set_process(true);player.play("late_return")
	return true

func tick() -> void:
	if not running:return
	var sound:=AudioStreamPlayer3D.new();sound.stream=load("res://assets/audio/latch.wav")
	sound.bus="SFX";sound.volume_db=-36;sound.max_distance=5;sound.unit_size=.7
	add_child(sound);sound.global_position=game.get_node("ArchiveTransport").global_position+Vector3(0,.10,0)
	sources.append(sound);sound.play()

func finish_preview() -> void:
	if not running:return
	running=false
	set_process(false)
	if is_instance_valid(needle):needle.rotation.y=original_angle
	for entry in reels:
		if is_instance_valid(entry.node):entry.node.rotation.y=entry.angle
	reels.clear()
	for sound in sources:
		if is_instance_valid(sound):sound.stop();sound.queue_free()
	sources.clear()
	var timeline=get_node_or_null("ReturnTimeline")
	if is_instance_valid(timeline):timeline.stop();timeline.queue_free()

func _exit_tree() -> void:finish_preview()

# Production uses this same recorder, with a short saved mechanical response.
# The historical FIELD reel and tonight's A/B experiment retain their own owners.
var runtime:=false
var timeline: AnimationPlayer
var quiet:=0.0
var bases: Array=[]
var history: Array=[]
var click_count:=0

func equipment_still() -> bool:
	return not game.field_tape.playing and game.horror.audition=="" and game.horror.echo_index<0 and game.dead_line.sequence.is_empty() and game.events.get("line_feed_off",false)

func cleanup_runtime() -> void:
	running=false;quiet=0
	if is_instance_valid(timeline):timeline.pause();timeline.queue_free()
	timeline=null
	for source in sources:
		if is_instance_valid(source):source.stop();source.queue_free()
	sources.clear()

func restore() -> void:
	cleanup_runtime()
	var state: Dictionary=game.events.get("recorder_answer",{})
	var nodes: Array=get_tree().get_nodes_in_group("archive_reels")
	var angles: Array=state.get("angles",[])
	for i in nodes.size():nodes[i].rotation.y=float(angles[i]) if i<angles.size() else 0.0
	if state.get("phase","")=="running":
		if equipment_still() and not game.ambient_director.response_blocked():start_runtime(true)
		else:
			state.phase="spent";game.events.recorder_answer=state

func snapshot() -> void:
	if not runtime:return
	var state: Dictionary=game.events.get("recorder_answer",{})
	if state.is_empty():return
	state.angles=[]
	for reel in get_tree().get_nodes_in_group("archive_reels"):state.angles.append(reel.rotation.y)
	if running and is_instance_valid(timeline):state.clock=timeline.current_animation_position
	game.events.recorder_answer=state

func start_runtime(resuming:=false) -> void:
	var deck: Node3D=game.get_node("ArchiveTransport")
	var nodes: Array=get_tree().get_nodes_in_group("archive_reels")
	var state: Dictionary=game.events.get("recorder_answer",{})
	bases=state.get("bases",[]) if resuming else []
	if bases.size()!=nodes.size():
		bases=[]
		for reel in nodes:bases.append(reel.rotation.y)
	var reduced: bool=bool(state.get("reduced",game.presentation.prefs.data.reduced_motion)) if resuming else game.presentation.prefs.data.reduced_motion
	# Enabling reduced motion during recovery always takes precedence.
	reduced=reduced or game.presentation.prefs.data.reduced_motion
	var at: float=float(state.get("clock",0)) if resuming else 0.0
	timeline=AnimationPlayer.new();timeline.name="QuietTransportAnswer";add_child(timeline)
	var clip:=Animation.new();clip.length=2.4
	if not reduced:
		for i in nodes.size():
			var track:=clip.add_track(Animation.TYPE_VALUE);clip.track_set_path(track,NodePath(str(nodes[i].get_path())+":rotation:y"))
			for key in [[0.0,bases[i]],[.18,bases[i]],[1.25,float(bases[i])-.72],[2.4,float(bases[i])-.72]]:clip.track_insert_key(track,key[0],key[1])
	var library:=AnimationLibrary.new();library.add_animation("answer",clip);timeline.add_animation_library("",library)
	timeline.animation_finished.connect(func(_name):finish_runtime("completed"))
	running=true;game.events.recorder_answer={"phase":"running","clock":at,"bases":bases.duplicate(),"reduced":reduced}
	timeline.play("answer");timeline.seek(clampf(at,0,2.39),true)
	if not resuming:
		var cue: AudioStreamPlayer3D=game.sound("transport_click",deck.global_position+Vector3.UP*.1,-28)
		cue.unit_size=.9;cue.max_distance=7;sources.append(cue);click_count+=1
		game.sound_caption("A relay clicks.",2.0,"TAPE RECORDER",cue)
		history.append({"event":"started","time":game.time_in_game})
	else:history.append({"event":"resumed_without_replaying_click","time":game.time_in_game})
	snapshot();game.save_game(true)

func finish_runtime(reason: String) -> void:
	if not running:return
	snapshot();game.events.recorder_answer.phase="spent"
	# Leave the reels at their actual stopped angles; no visible reset or rewind.
	cleanup_runtime();history.append({"event":reason,"time":game.time_in_game});game.save_game(true)

func _physics_process(delta: float) -> void:
	if not runtime or not game.started or game.menu_open or game.ended:return
	if running:
		if not equipment_still() or game.ambient_director.response_blocked():finish_runtime("interrupted")
		return
	if game.events.get("house_answers",0)!=1 or game.events.has("recorder_answer") or not game.events.get("test_reel_heard",false):return
	if not equipment_still() or game.ambient_director.response_blocked() or game.player.position.distance_to(game.field_tape.DECK)>4.8:
		quiet=0;return
	quiet+=delta
	if quiet>=3.2:start_runtime()
