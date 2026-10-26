extends Node3D
# Events are recorded in the existing schema-1 events map. Active staging is transient.
var game: Node3D
var actor: Node3D
var rng := RandomNumberGenerator.new()
var beat := ""
var elapsed := 0.0
var hold := 2.8
var hidden_for := 0.0
var retreat := Vector3.ZERO
var walk_distance := 0.0
var step_distance := 0.0
var screen_mesh: MeshInstance3D
var feed: SubViewport
var feed_clock := 0.0
var feed_ghost: Node3D
var cue_played := false
var variant := 0
var echo_clock := 0.0
var echo_index := -1
var echo_trace: Array = []
var archive_clock := 0.0
var echo_hall: Array = []
var audition := ""
var audition_clock := 0.0
var audition_index := 0
var audition_tail := false
var audition_players: Array[AudioStreamPlayer3D] = []
var vent_owned:=false
var vent_hidden:=0.0
var vent_steps:=0.0
var vent_history: Array=[]
const VENT_START:=Vector3(-.9,-2.99,-17.2)
const VENT_END:=Vector3(-4.5,.02,-8.8)

func _ready() -> void:
	build_feed()

func reset() -> void:
	vent_owned=false;vent_hidden=0;vent_steps=0
	if is_instance_valid(actor):actor.attention_override=null
	stop_audition()
	beat = ""
	echo_index = -1
	echo_clock = 0
	archive_clock = 0
	echo_trace = game.events.get("memory_trace",[]).duplicate(true)
	echo_hall = game.events.get("memory_hall",[]).duplicate(true)
	elapsed = 0
	game.presence.visible = false
	if actor:actor.set_mode("listen")
	if game.events.has("horror_seed"):rng.seed = int(game.events.horror_seed)
	else:
		rng.randomize()
		game.events.horror_seed = rng.randi_range(1,2000000000)
		game.events.horror_variant = rng.randi_range(0,1)
	variant = int(game.events.get("horror_variant",0))
	if game.stage >= 3:game.events.house_responds = true
	cue_played = false
	if feed_ghost:feed_ghost.visible = false
	update_screen()

func begin(id: String) -> void:
	if vent_owned:return
	if game.threat.active():return
	stop_audition()
	beat = id
	elapsed = 0
	hidden_for = 0
	walk_distance = 0
	step_distance = 0
	hold = rng.randf_range(2.3,3.6)
	game.presence.visible = true
	# Every physically present figure has body separation, including staged sightings.
	game.threat.set_collision(true)
	actor.set_mode("listen")
	if id == "watcher":
		# Beyond the yard fence, away from the player's circulation route.
		game.presence.position = Vector3(-7.8 if variant == 0 else -9.5,0,-15.9)
		retreat = Vector3(-1,0,0)
		game.sound("breath",game.presence.position,-29)
	else:
		# A knock comes from the hall ahead; the figure is on the side of the relay room.
		game.presence.position = Vector3(-3.8 if variant == 0 else 3.8,-3,-16.0)
		retreat = Vector3(-1 if variant == 0 else 1,0,0)
		game.sound("door",Vector3(0,0,-7),-27)
		game.sound("step",Vector3(0,-0.5,-12),-26)
	game.presence.look_at(Vector3(game.player.position.x,game.presence.position.y,game.player.position.z))

func visible_to_player() -> bool:
	# A visible head over the fence still counts as direct sight.
	for offset in [Vector3(0,1.95,0),Vector3(-0.19,1.62,0),Vector3(0.19,1.62,0),Vector3(0,1.15,0)]:
		var point: Vector3 = game.presence.global_position+offset
		if game.player.camera.is_position_behind(point):continue
		var screen_pos: Vector2 = game.player.camera.unproject_position(point)
		if not game.get_viewport().get_visible_rect().has_point(screen_pos):continue
		var query := PhysicsRayQueryParameters3D.create(game.player.camera.global_position,point,1)
		query.exclude = [game.player.get_rid(),game.presence.get_rid()]
		if game.get_world_3d().direct_space_state.intersect_ray(query).is_empty():return true
	return false

func vent_protected() -> bool:
	var p: Vector3=game.player.position
	return p.y< -2.6 and p.x>2.48 and p.x<4.0 and p.z> -15.5 and p.z< -10.0

func vent_visible_from(position_: Vector3,eye: Vector3) -> bool:
	# Frustum independent: turning the camera cannot expose a newly spawned or
	# just removed actor. Sample the capsule envelope, not only its head centre.
	for x in [-.38,0.0,.38]:
		for z in [-.32,0.0,.32]:
			for y in [.08,.65,1.3,2.05]:
				var q:=PhysicsRayQueryParameters3D.create(eye,position_+Vector3(x,y,z),1)
				q.exclude=[game.player.get_rid(),game.presence.get_rid()]
				if game.get_world_3d().direct_space_state.intersect_ray(q).is_empty():return true
	return false

func vent_hide_safe() -> bool:
	var eyes: Array[Vector3]=[game.player.camera.global_position,game.player.camera.global_position+game.player.velocity*.45,
		Vector3(3.25,-2.06,-15.0),Vector3(3.25,-1.38,-16.2),Vector3(3.25,-1.38,-9.8),
		Vector3(2.8,-2.06,-13.5),Vector3(3.7,-2.06,-13.5)]
	for eye in eyes:
		if vent_visible_from(game.presence.position,eye):return false
	return true

func vent_blocked() -> bool:
	return game.threat.active() or game.events.get("threat_pending",false) or game.presence.visible or beat!="" or audition!="" or echo_index>=0 or game.chapter.active or game.chapter.return_clock>=0 or game.chapter.watch_clock>=0 or game.impossible_room.active or game.recount.active or game.last_call.busy() or not game.dead_line.sequence.is_empty() or game.maintenance.surprise_armed or game.spare_place.hunt_running

func snapshot_vent() -> void:
	if not vent_owned:return
	game.events.vent_pass_snapshot={"pos":[game.presence.position.x,game.presence.position.y,game.presence.position.z],"yaw":game.presence.rotation.y,"mode":actor.mode,"clip":actor.animator.current_animation_position}

func restore_vent() -> void:
	if str(game.events.get("vent_first_pass",""))!="walking":return
	var saved: Dictionary=game.events.get("vent_pass_snapshot",{})
	var pos_: Array=saved.get("pos",[])
	if pos_.size()!=3 or game.threat.active() or game.events.get("threat_pending",false):
		game.events.vent_first_pass="spent";return
	# Applied before the loaded world is rendered. This is its saved physical
	# body, not a new staged spawn or a repeat of the first crossing.
	game.presence.position=Vector3(pos_[0],pos_[1],pos_[2]);game.presence.rotation.y=float(saved.get("yaw",0))
	vent_owned=true;beat="vent_pass";game.presence.visible=true;game.threat.set_collision(true)
	game.threat.plan(VENT_END);game.threat.stuck=0;game.threat.door_wait=0;vent_hidden=0;vent_steps=0
	actor.set_mode(str(saved.get("mode","walk")));actor.animator.seek(float(saved.get("clip",0)),true)
	vent_history.append({"event":"restored","position":game.presence.position})

func release_vent(hide_body: bool) -> void:
	vent_owned=false;vent_hidden=0;game.events.vent_first_pass="spent";game.events.erase("vent_pass_snapshot")
	if beat=="vent_pass":beat=""
	actor.attention_override=null
	game.threat.route.clear()
	if hide_body:
		game.presence.visible=false;game.presence.velocity=Vector3.ZERO;game.threat.set_collision(false);actor.set_mode("listen")
	vent_history.append({"event":"retired" if hide_body else "handed_over","position":game.presence.position})
	game.save_game(true)

func _physics_process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	var phase_: String=str(game.events.get("vent_first_pass",""))
	var p: Vector3=game.player.position
	if not vent_owned:
		if phase_=="armed" and vent_protected() and p.z< -14.5:
			game.events.vent_first_pass="approach";game.save_game(true);phase_="approach"
		if phase_!="approach":return
		if p.z> -11.3:
			game.events.vent_first_pass="spent";game.save_game(true);return
		if not vent_protected() or p.z< -13.8 or p.z> -12.0:return
		# A closed/locked final portal or another actor owner is a reason to skip,
		# not to spawn through a wall, delay a pursuit, or repeat on a later visit.
		if vent_blocked() or game.doors.utility.locked or not game.doors.utility.opened:return
		if vent_visible_from(VENT_START,game.player.camera.global_position):return
		game.presence.position=VENT_START;game.presence.rotation.y=0;game.presence.velocity=Vector3.ZERO
		game.threat.plan(VENT_END)
		if game.threat.route.is_empty():return
		vent_owned=true;beat="vent_pass";vent_hidden=0;vent_steps=0
		game.threat.stuck=0;game.threat.door_wait=0;game.threat.set_collision(true);game.presence.visible=true
		game.events.vent_first_pass="walking";actor.set_mode("walk")
		vent_history.append({"event":"started_hidden","position":VENT_START});game.save_game(true)
		return
	if game.threat.active():
		release_vent(false);return # An existing owner retains this exact body.
	if game.threat.enabled and not vent_protected() and p.distance_to(game.presence.position)<2.4:
		var where: Vector3=game.presence.position;var facing: float=game.presence.rotation.y
		release_vent(false)
		game.events.threat_origin="vent_follow";game.events.threat_spawn=[where.x,where.y,where.z];game.events.threat_pending=true
		game.threat.begin(false,where);game.presence.rotation.y=facing;game.save_game(true);return
	actor.attention_override=game.presence.position-game.presence.global_basis.z*3+Vector3.UP*1.45
	# Reuse the real capsule, doors, floor gravity, corner recovery and animation
	# rate. This staging owns no separate enemy or navigation implementation.
	game.threat.move_route(delta,1.42,true)
	var at_end:=Vector2(game.presence.position.x-VENT_END.x,game.presence.position.z-VENT_END.z).length()<.35
	if game.threat.route.is_empty() and not at_end and game.threat.stuck<2:game.threat.plan(VENT_END)
	if at_end or game.threat.stuck>=2:
		vent_hidden=vent_hidden+delta if vent_hide_safe() else 0.0
		if vent_hidden>.35:release_vent(true)

func house_responds() -> void:
	game.events["house_responds"] = true
	game.sound("relay",Vector3(3.2,1.1,-1.85),-27)
	update_screen()
	# A door returns towards its frame only when nobody occupies its sweep.
	if game.player.position.distance_to(game.doors.lounge.position) > 1.6:
		game.doors.lounge.set_open(false,2.2)

func record_step(point: Vector3,sample := "step",pitch := 1.0) -> void:
	if game.stage >= 3 and game.events.get("memory_echo",false) and game.events.get("memory_trace",[]).size()>=4:return
	var trace: Array = game.events.get("memory_trace",[])
	trace.append([snappedf(point.x,0.01),snappedf(point.y,0.01),snappedf(point.z,0.01),game.time_in_game,sample,pitch])
	while trace.size()>8:trace.pop_front()
	game.events.memory_trace = trace
	if absf(point.x)<1.05 and point.y>-0.2 and point.z>-8 and point.z<3:
		var hall: Array = game.events.get("memory_hall",[])
		hall.append([point.x,point.y,point.z,game.time_in_game])
		while hall.size()>8:hall.pop_front()
		game.events.memory_hall = hall

func memory_process(delta: float) -> void:
	if audition=="FIELD":return # Historical playback owns its short listening window.
	process_audition(delta)
	if game.events.get("memory_reviewed",false) and not game.impossible_room.active:game.physical.repeat_placement()
	archive_clock += delta
	if not game.events.get("memory_echo",false) and game.stage>=3 and game.events.get("memory_trace",[]).size()>=4 and game.player.velocity.length()<0.2 and not game.report_read:
		echo_clock += delta
		if echo_clock>1.3:
			game.events.memory_echo = true
			echo_trace = game.events.memory_trace.duplicate(true)
			echo_hall = game.events.get("memory_hall",[]).duplicate(true)
			echo_index = 0
			echo_clock = -0.4
			game.events.memory_cadence = []
	elif not game.events.get("memory_echo",false):echo_clock = 0
	if echo_index>=0:
		echo_clock += delta
		if echo_clock>=0:
			var p: Array = echo_trace[echo_index]
			game.sound(str(p[4]) if p.size()>4 else "step",Vector3(p[0],p[1],p[2]),-25).pitch_scale = float(p[5]) if p.size()>5 else 1.0
			game.events.memory_cadence.append(p[3])
			echo_index += 1
			if echo_index>=echo_trace.size():echo_index = -1
			else:echo_clock = -clampf(float(echo_trace[echo_index][3])-float(p[3]),0.28,1.4)
	# Only the archive feed repeats the stored route. The real actor remains physical.
	if feed_ghost and game.events.get("memory_echo",false) and echo_hall.size()>1 and not game.events.get("memory_confirmed",false):
		var t := fmod(archive_clock*0.7,float(echo_hall.size()-1))
		var i := int(t)
		var a: Array = echo_hall[i]
		var b: Array = echo_hall[i+1]
		var from := Vector3(a[0],a[1],a[2])
		var to := Vector3(b[0],b[1],b[2])
		feed_ghost.position = from.lerp(to,t-i)
		if from.distance_to(to)>0.1:
			feed_ghost.rotation.y = lerp_angle(feed_ghost.rotation.y,atan2(-(to.x-from.x),-(to.z-from.z)),delta*3)
		var playback: AnimationPlayer = feed_ghost.find_children("*","AnimationPlayer",true,false)[0]
		if playback.current_animation!="Walk_001":playback.play("Walk_001",0.4)
		playback.speed_scale = clampf(from.distance_to(to)*0.7/1.07,0.2,1.0)
	if game.events.get("memory_confirmed",false) and feed_ghost:
		# The repeated worker finally notices the archive camera, not the real player.
		feed_ghost.look_at(Vector3(0,0,3.2))
		var playback: AnimationPlayer = feed_ghost.find_children("*","AnimationPlayer",true,false)[0]
		if playback.current_animation!="Idle_001":playback.play("Idle_001",0.5)

func stop_audition() -> void:
	audition = ""
	if is_instance_valid(game.recorder_memory):game.recorder_memory.transport_channel("")
	for player_ in audition_players:
		if is_instance_valid(player_):player_.stop();player_.queue_free()
	audition_players.clear()

func audition_channel(channel: String) -> void:
	if game.stage<3:game.message("The tape recorder has no power.",3);return
	if game.threat.active():game.message("Not while he's this close.",3);return
	if game.events.get("memory_trace",[]).size()<4:
		game.inspect_text("TRANSPORT / LEADER",game.NOTES.TRANSPORT_LEADER)
		return
	stop_audition()
	echo_trace = game.events.memory_trace.duplicate(true)
	game.events.memory_echo = true
	echo_hall = game.events.get("memory_hall",[]).duplicate(true)
	echo_index = -1
	audition = channel
	audition_clock = -0.4
	audition_index = 0
	audition_tail = false
	game.recorder_memory.transport_channel(channel)
	var motor=game.sound("latch",Vector3(3.3,1,-8.52),-29)
	game.sound_caption("The tape recorder starts.",2,"RECORDER "+channel,motor)

func process_audition(delta: float) -> void:
	if audition=="" or audition=="FIELD":return
	if not audition_tail:
		for reel in get_tree().get_nodes_in_group("archive_reels"):reel.rotation.y += delta*1.8
	audition_clock += delta
	if audition_clock<0:return
	if audition_index<echo_trace.size():
		var p: Array = echo_trace[audition_index]
		var player_ = game.sound(str(p[4]) if p.size()>4 else "step",Vector3(3.3,1,-8.52),-23)
		player_.pitch_scale = float(p[5]) if p.size()>5 else 1.0
		audition_players.append(player_)
		game.recorder_memory.transport_pulse(.85)
		audition_index += 1
		if audition_index==1:game.sound_caption("Footsteps on the tape.",3,"RECORDER "+audition,player_,true)
		audition_clock = -0.6 if audition_index>=echo_trace.size() else -clampf(float(echo_trace[audition_index][3])-float(p[3]),0.28,1.4)
	elif audition=="B" and not audition_tail:
		audition_tail = true
		audition_clock = -1.7
		game.recorder_memory.transport_channel("")
		var stop_click=game.sound("transport_click",Vector3(3.3,.95,-8.52),-27)
		game.sound_caption("The recorder stops.",1.4,"TAPE RECORDER",stop_click)
		# Reels and meter now stop before the step at the actual doorway. That
		# distinction is physical; the impossible step never drives the deck meter.
	elif audition=="B" and audition_tail:
		var answer=game.sound("step",Vector3(1.7,0,-7),-23)
		answer.pitch_scale = 0.79
		game.sound_caption("One heavier footstep.",3,"OFFICE DOORWAY",answer)
		game.events.audition_B = true
		audition = ""
	else:
		# Playback has ended. Let the silence carry the comparison.
		game.events.audition_A = true
		audition = ""
		game.recorder_memory.transport_channel("")

func exclude_channel(channel: String) -> void:
	if not game.events.get("audition_A",false) or not game.events.get("audition_B",false):return
	if channel=="A":
		game.presentation.resume_game()
		game.sound("relay",Vector3(3.3,1,-8.52),-28)
		game.message("The tape had stopped before that last step. I should listen once more.",4)
		return
	game.events.memory_confirmed = true
	stop_audition()
	game.inspect_text(game.NOTES.COMPARISON_TITLE,game.NOTES.SOURCE_COPY)
	game.save_game()

func build_feed() -> void:
	screen_mesh = game.find_child("TelevisionScreen",true,false)
	if screen_mesh == null:return
	feed = SubViewport.new()
	feed.name = "ImpossibleArchiveFeed"
	feed.size = Vector2i(240,180)
	feed.world_3d = game.get_world_3d()
	feed.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(feed)
	var camera := Camera3D.new()
	feed.add_child(camera)
	camera.position = Vector3(0,2.0,3.2)
	camera.look_at(Vector3(0,1.3,-7.5))
	camera.fov = 68
	camera.cull_mask = 1|4
	camera.current = true
	feed_ghost = load(game.surveyor_model_path()).instantiate()
	game.add_child(feed_ghost)
	feed_ghost.position = Vector3(0.85,0,-6.2)
	feed_ghost.scale = Vector3.ONE*1.05
	feed_ghost.rotation.y = PI
	var playback: AnimationPlayer = feed_ghost.find_children("*","AnimationPlayer",true,false)[0]
	playback.play("Idle_001")
	feed_ghost.name = "ArchiveOnlyOccupant"
	for mesh in game.all_meshes(feed_ghost):
		mesh.layers = 4
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	feed_ghost.visible = false
	var m := StandardMaterial3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.73,0.49)
	screen_mesh.mesh = quad
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = feed.get_texture()
	m.albedo_color = Color(0.52,0.68,0.59)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	screen_mesh.material_override = m

func update_screen() -> void:
	if feed == null:return
	feed_ghost.visible = game.events.has("house_responds")
	feed.render_target_update_mode = SubViewport.UPDATE_ONCE
	var legend := game.find_child("TelevisionLegend",true,false)
	if legend:legend.text = "CAM 02 / HALL\n23:17:08" if game.events.has("house_responds") else "NO SIGNAL"

func _process(delta: float) -> void:
	if not game.started or game.menu_open:return
	memory_process(delta)
	# Make room for concrete sounds; silence follows the electrical change.
	var score_target := -42.0 if game.events.has("house_responds") and not game.report_read else -35.0
	if beat != "" or audition!="" or game.threat.active() or game.impossible_room.active:score_target = -48.0
	if is_instance_valid(game.recorder_memory) and game.recorder_memory.running:score_target=-48.0
	if is_instance_valid(game.recount) and game.recount.active:score_target=-65.0
	if is_instance_valid(game.dead_line) and not game.dead_line.sequence.is_empty():score_target=-65.0
	game.ambience.volume_db = move_toward(game.ambience.volume_db,score_target,delta*4)
	feed_clock += delta
	if feed and feed_clock > 0.4 and game.player.position.distance_to(Vector3(3.2,0,-1.8)) < 7:
		feed_clock = 0
		feed.render_target_update_mode = SubViewport.UPDATE_ONCE
	if beat == "":return
	if beat == "vent_pass":return # Actual physical movement belongs to the shared route mover below.
	elapsed += delta
	if beat == "wrong_direction":
		# The recorded wall-side appearance is the start of the relay encounter.
		# Do not run the old retreat-into-wall vignette in the traversable basement.
		var direction: Vector3 = game.player.position-game.presence.position
		game.presence.rotation.y = lerp_angle(game.presence.rotation.y,atan2(-direction.x,-direction.z),1-exp(-delta*1.8))
		actor.set_mode("watch")
		if elapsed>1.5 or direction.length()<2.6:
			beat = ""
			game.threat.begin_basement()
		return
	var seen := visible_to_player()
	hidden_for = 0.0 if seen else hidden_for+delta
	if elapsed > 0.8 and elapsed <= hold:actor.set_mode("watch")
	# No disappearance in direct sight. Turn and walk into cover, then remove only after occlusion.
	if elapsed > hold:
		actor.locomotion(0.46)
		var desired_yaw := atan2(-retreat.x,-retreat.z)
		game.presence.rotation.y = lerp_angle(game.presence.rotation.y,desired_yaw,1.0-exp(-delta*1.5))
		var from: Vector3 = game.presence.position+Vector3(0,0.6,0)
		var query := PhysicsRayQueryParameters3D.create(from,from+retreat*0.4)
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() and walk_distance < 1.4:
			game.presence.position += retreat*delta*0.46
			walk_distance += delta*0.46
			step_distance += delta*0.46
			if step_distance > 0.33:
				step_distance = 0
				game.sound("step",game.presence.position,-29).pitch_scale = 0.83
		else:actor.set_mode("listen")
		if hidden_for > 0.35:
			game.presence.visible = false
			game.threat.set_collision(false)
			beat = ""
