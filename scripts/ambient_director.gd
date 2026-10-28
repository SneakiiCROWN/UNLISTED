extends Node3D
# Small environmental events only. Never starts, teleports or resolves an enemy.
var game: Node3D
var policy=preload("res://scripts/ambient_schedule.gd").new()
var enabled:=true
var intensity:=1.0
var queue: Array=[]
var sources: Array[AudioStreamPlayer3D]=[]
var elapsed:=0.0
var last_event:=""
var history: Array=[]
var emitted: Array=[]
var skipped_late: Array=[]
var latch_clock:=-1.0
const WINDOW:=Vector3(7.47,1.6,2)
const STEPS:=Vector3(-4.9,.03,-7.8)
func _ready() -> void:
	name="HouseAmbientDirector"
	restore()
func restore() -> void:
	reset_latch()
	var room: Node=game.get_node_or_null("LivingRoomFinishes")
	if room:room.reset_response()
	for source in sources:
		if is_instance_valid(source):source.stop();source.queue_free()
	sources.clear();queue.clear();emitted.clear();elapsed=0
	policy.restore(game.events.get("atmosphere",{}),int(game.events.get("horror_seed",17))+5903)
	game.events.atmosphere=policy.data
func set_seed(value: int) -> void:
	policy.restore({},value);game.events.atmosphere=policy.data;restore()
func response_blocked() -> bool:
	# Shared reservation rules for subtle authored responses, including outdoors.
	if float(policy.data.get("quiet",0))>0:return true
	return latch_clock>=0 or (is_instance_valid(game.final_account) and game.final_account.pending()) or not game.started or game.menu_open or game.ended or game.threat.active() or game.events.get("threat_pending",false) or game.presence.visible or game.horror.beat!="" or game.horror.audition!="" or game.horror.echo_index>=0 or game.recount.active or game.chapter.active or game.chapter.watch_clock>=0 or game.chapter.return_clock>=0 or game.impossible_room.active or not game.dead_line.sequence.is_empty() or game.dead_line.quiet>0 or game.maintenance.surprise_armed or game.spare_place.hunt_running or game.last_call.busy() or game.events.get("exit_blackout_running",false) or game.events.get("exit_blackout_pending",false) or game.events.get("inspection_search_pending",false) or game.events.get("witness_echo_pending",false) or game.events.get("departure_pending","")!="" or not queue.is_empty() or sources.any(func(a):return is_instance_valid(a) and a.playing)

func blocked() -> bool:
	if game.events.get("threat_pending",false) or game.events.get("exit_blackout_running",false) or game.events.get("exit_blackout_pending",false) or game.events.get("inspection_search_pending",false) or game.events.get("witness_echo_pending",false):return true
	if is_instance_valid(game.final_account) and game.final_account.pending():return true
	return (is_instance_valid(game.recorder_memory) and game.recorder_memory.running) or (is_instance_valid(game.last_call) and game.last_call.busy()) or not enabled or intensity<=0 or not game.started or game.menu_open or game.ended or game.stage<3 or not game.events.get("case_v3",false) or game.threat.active() or game.presence.visible or game.horror.beat!="" or game.horror.audition!="" or game.horror.echo_index>=0 or game.recount.active or game.chapter.active or game.chapter.watch_clock>=0 or game.chapter.return_clock>=0 or game.impossible_room.active or not game.dead_line.sequence.is_empty() or game.dead_line.quiet>0 or game.maintenance.surprise_armed or game.spare_place.hunt_running or game.events.get("departure_pending","")!="" or game.player.position.y<-.2 or absf(game.player.position.x)>7.4 or game.player.position.z>3.8 or game.player.position.z< -9.8
func noticed(point: Vector3) -> bool:
	return game.chapter.point_visible(point)
func eligible() -> Array[String]:
	var result: Array[String]=[]
	var p: Vector3=game.player.position
	# The visitor is outside an actual ground-floor window, not behind a solid wall.
	if p.x>1.6 and p.z> -3 and p.distance_to(WINDOW)<8:result.append("window_taps")
	# Office listeners hear a short path in the empty utility room across the hall.
	if p.x>1.6 and p.z< -3 and p.distance_to(STEPS)<11 and not noticed(STEPS+Vector3.UP):result.append("empty_room_steps")
	var tin: RigidBody3D=game.physical.props.can0
	if p.x< -1.6 and p.z> -3 and game.physical.held!=tin and tin.position.distance_to(game.physical.homes.can0.origin)<.12 and tin.linear_velocity.length()<.08 and p.distance_to(tin.position)>2.2 and not noticed(tin.position):result.append("kitchen_tin")
	# The house's aftermath belongs to a witnessed, restored room, never a
	# prediction of a room the player has not seen or the copied bedroom.
	if game.events.get("impossible_room_resolved",false) and game.events.get("impossible_room_revisited",false):
		if not game.impossible_room.inside(p) and not curtain_visible():result.append("curtains_drawn")
		if game.impossible_room.inside(p):result.append("ceiling_return")
	return result

func curtain_visible() -> bool:
	# Both existing and destination cloth volume, including exterior glazing.
	for y in [.46,1.40,2.48]:
		for z in [1.04,1.50,2.0,2.50,2.98]:
			var drape: float=(1.0-smoothstep(.95,1.22,y))*.18
			if game.impossible_room.visible_point(Vector3(7.10-drape,y,z)):return true
	return false
func request(id: String) -> bool:
	# F1/native QA uses the same safety and spatial eligibility as normal scheduling.
	if blocked() or not queue.is_empty() or float(policy.data.get("quiet",0))>0 or not id in eligible():return false
	for event in policy.EVENTS:
		if event.id==id and int(policy.data.used.get(id,0))>=event.limit:return false
	policy.consume(id);game.events.atmosphere=policy.data
	last_event=id;elapsed=0
	if id=="window_taps":
		var room: Node=game.get_node_or_null("LivingRoomFinishes")
		if room:room.respond_window()
		queue=[{"at":0.0,"where":WINDOW,"sound":"foley/drop_wood_1","db":-34.0,"pitch":1.3,"caption":"Two light taps at the window.","source":"LOUNGE WINDOW"},{"at":.83,"where":WINDOW,"sound":"foley/drop_wood_2","db":-36.0,"pitch":1.15}]
	elif id=="empty_room_steps":
		# An unseen path ends at the real utility door, followed by silence and
		# a small attempt at its handle. Never moves the leaf or adds an actor.
		var door: Node3D=game.doors.utility
		var closed: bool=not door.opened and absf(door.pivot.rotation.y)<.03 and not door.arrival_busy
		for i in 4:
			queue.append({"at":i*.82,"where":STEPS.lerp(Vector3(-1.95,.03,-7),i/3.0),"sound":"step","db":-33.0+i*.65,"pitch":.86+i*.015,"caption":"Footsteps approach the utility door." if i==0 and closed else ("Footsteps across the hall." if i==0 else ""),"source":"UTILITY ROOM"})
		if closed:latch_clock=0.0
	elif id=="curtains_drawn":
		game.get_node("LivingRoomFinishes").draw_curtains()
		queue=[{"at":0.0,"where":Vector3(7.20,2.55,2.0),"sound":"latch","db":-36.0,"pitch":.68,"caption":"Curtain rings click in the lounge.","source":"LOUNGE WINDOW"}]
	elif id=="ceiling_return":
		for i in 4:
			queue.append({"at":i*.88,"where":Vector3(3.1+i*.9,2.88,-1.7+i*1.1),"sound":"step","db":-32.0-i*.7,"pitch":.81+i*.018,"caption":"Footsteps cross above the lounge." if i==0 else "","source":"OVERHEAD"})
		queue.append({"at":4.6,"where":Vector3(6.3,2.75,2.3),"sound":"foley/drop_wood_2","db":-37.0,"pitch":.65})
	else:
		var tin: RigidBody3D=game.physical.props.can0
		tin.sleeping=false;tin.apply_central_impulse(Vector3(.015,.015,-.4))
	# Record optional events before playback; loading never repeats a spent scare.
	var end:=0.0
	for cue in queue:end=maxf(end,float(cue.at))
	policy.data.quiet=end+5.0
	history.append({"id":id,"time":game.time_in_game,"player":game.player.position})
	if is_instance_valid(game.dev_tools):game.dev_tools.log_event("ambient_event",{"id":id,"seed":policy.data.seed,"draw":policy.data.draw})
	game.save_game(true)
	return true
func _physics_process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	policy.data.quiet=maxf(0,float(policy.data.get("quiet",0))-delta)
	var held_off:=blocked()
	if held_off:
		reset_latch()
		for source in sources:
			if is_instance_valid(source):source.stop()
		queue.clear()
	if latch_clock>=0:update_latch(delta)
	if not queue.is_empty():
		elapsed+=delta
		# Authored paths are chronological. Do not reverse simultaneous due cues
		# or dump an obsolete cluster of footsteps after a long simulation hitch.
		while not queue.is_empty() and elapsed>=float(queue[0].at):
			var item: Dictionary=queue.pop_front()
			if elapsed-float(item.at)>.65:
				skipped_late.append({"at":item.at,"elapsed":elapsed,"sound":item.sound})
				if skipped_late.size()>8:skipped_late.pop_front()
				continue
			var cue: AudioStreamPlayer3D=game.sound(item.sound,item.where,float(item.db)-linear_to_db(1.0/maxf(intensity,.1)))
			cue.pitch_scale=item.pitch;sources.append(cue)
			emitted.append({"where":item.where,"playing":cue.playing,"sample":cue.get_meta("sample")})
			if emitted.size()>8:emitted.pop_front()
			if str(item.get("caption",""))!="":game.sound_caption(item.caption,2.6,item.source,cue)
		return
	# Discard freed players to keep the long-session bookkeeping bounded.
	sources=sources.filter(func(source):return is_instance_valid(source))
	# Visibility queries are needed only when a scheduling draw is due. Explicit
	# requests still recheck eligibility immediately before changing the world.
	var available: Array[String]=eligible() if not held_off and float(policy.data.remaining)<=delta else []
	var next: String=policy.tick(delta,available,held_off or float(policy.data.get("quiet",0))>0)
	game.events.atmosphere=policy.data
	if next!="":request(next)

func reset_latch() -> void:
	latch_clock=-1
	if not is_instance_valid(game) or not game.doors.has("utility"):return
	for id in ["HandleFront","HandleBack"]:
		var handle: Node3D=game.doors.utility.pivot.get_node_or_null(id)
		if handle:handle.rotation.z=0

func update_latch(delta: float) -> void:
	var door: Node3D=game.doors.utility
	# Player interaction always wins. No leaf motion, door lock or forced wait.
	if door.opened or absf(door.pivot.rotation.y)>.03:
		reset_latch();return
	var before:=latch_clock;latch_clock+=delta
	for at in [3.8,4.65]:
		if before<at and latch_clock>=at:
			var cue: AudioStreamPlayer3D=game.sound("latch",door.pivot.to_global(Vector3(.985,1.12,.08)),-34)
			cue.pitch_scale=.77;cue.max_distance=7;sources.append(cue)
			emitted.append({"where":cue.global_position,"playing":cue.playing,"sample":cue.get_meta("sample"),"kind":"utility_latch"})
			if emitted.size()>8:emitted.pop_front()
			if at==3.8:game.sound_caption("The utility door latch rattles.",2.0,"UTILITY DOOR",cue)
	var angle:=0.0
	if not game.presentation.prefs.data.reduced_motion:
		for at in [3.8,4.65]:
			var t: float=latch_clock-at
			if t>=0 and t<.62:angle-=sin(PI*t/.62)*.38
	for id in ["HandleFront","HandleBack"]:
		var handle: Node3D=door.pivot.get_node_or_null(id)
		if handle:handle.rotation.z=angle
	if latch_clock>5.4:reset_latch()
