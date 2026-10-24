extends Node3D
# INACTIVE UNTESTED sequence study. No ordinary-world/F1 registration or event
# flags. A remembered mechanical rhythm returns after the transport is still.
@export var enable_preview:=false
var game: Node3D
var needle: Node3D
var original_angle:=0.0
var reels: Array=[]
var sources: Array[AudioStreamPlayer3D]=[]
var running:=false

func _ready() -> void:set_process(false)

func _process(_delta: float) -> void:
	# Only the explicitly armed preview processes. Abort if someone starts a
	# real case or leaves the title while it runs; ordinary gameplay never loads it.
	if running and (not is_instance_valid(game) or game.started or game.presentation.section!="title"):finish_preview()

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
