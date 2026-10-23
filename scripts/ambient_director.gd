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
const WINDOW:=Vector3(7.47,1.6,2)
const STEPS:=Vector3(-4.9,.03,-7.8)
func _ready() -> void:
	name="HouseAmbientDirector"
	restore()
func restore() -> void:
	for source in sources:
		if is_instance_valid(source):source.stop();source.queue_free()
	sources.clear();queue.clear();emitted.clear();elapsed=0
	policy.restore(game.events.get("atmosphere",{}),int(game.events.get("horror_seed",17))+5903)
	game.events.atmosphere=policy.data
func set_seed(value: int) -> void:
	policy.restore({},value);game.events.atmosphere=policy.data;restore()
func blocked() -> bool:
	return (is_instance_valid(game.last_call) and game.last_call.busy()) or not enabled or intensity<=0 or not game.started or game.menu_open or game.ended or game.stage<3 or not game.events.get("case_v3",false) or game.threat.active() or game.presence.visible or game.horror.beat!="" or game.horror.audition!="" or game.horror.echo_index>=0 or game.recount.active or game.chapter.active or game.chapter.watch_clock>=0 or game.chapter.return_clock>=0 or game.impossible_room.active or not game.dead_line.sequence.is_empty() or game.dead_line.quiet>0 or game.maintenance.surprise_armed or game.spare_place.hunt_running or game.events.get("departure_pending","")!="" or game.player.position.y<-.2 or absf(game.player.position.x)>7.4 or game.player.position.z>3.8 or game.player.position.z< -9.8
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
	return result
func request(id: String) -> bool:
	# F1/native QA uses the same safety and spatial eligibility as normal scheduling.
	if blocked() or not queue.is_empty() or not id in eligible():return false
	for event in policy.EVENTS:
		if event.id==id and int(policy.data.used.get(id,0))>=event.limit:return false
	policy.consume(id);game.events.atmosphere=policy.data
	last_event=id;elapsed=0
	if id=="window_taps":
		queue=[{"at":0.0,"where":WINDOW,"sound":"foley/drop_wood_1","db":-34.0,"pitch":1.3,"caption":"Two light taps at the window.","source":"LOUNGE WINDOW"},{"at":.83,"where":WINDOW,"sound":"foley/drop_wood_2","db":-36.0,"pitch":1.15}]
	elif id=="empty_room_steps":
		for i in 3:queue.append({"at":i*.91,"where":STEPS+Vector3(.26*i,0,.36*i),"sound":"step","db":-31.0-i,"pitch":.89,"caption":"Footsteps across the hall." if i==0 else "","source":"UTILITY ROOM"})
	else:
		var tin: RigidBody3D=game.physical.props.can0
		tin.sleeping=false;tin.apply_central_impulse(Vector3(.015,.015,-.4))
	# Record optional events before playback; loading never repeats a spent scare.
	history.append({"id":id,"time":game.time_in_game,"player":game.player.position})
	if is_instance_valid(game.dev_tools):game.dev_tools.log_event("ambient_event",{"id":id,"seed":policy.data.seed,"draw":policy.data.draw})
	game.save_game(true)
	return true
func _physics_process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	var held_off:=blocked()
	if held_off:
		for source in sources:
			if is_instance_valid(source):source.stop()
		queue.clear()
	if not queue.is_empty():
		elapsed+=delta
		for i in range(queue.size()-1,-1,-1):
			var item: Dictionary=queue[i]
			if elapsed<float(item.at):continue
			queue.remove_at(i)
			var cue: AudioStreamPlayer3D=game.sound(item.sound,item.where,float(item.db)-linear_to_db(1.0/maxf(intensity,.1)))
			cue.pitch_scale=item.pitch;sources.append(cue)
			emitted.append({"where":item.where,"playing":cue.playing,"sample":cue.get_meta("sample")})
			if emitted.size()>8:emitted.pop_front()
			if str(item.get("caption",""))!="":game.sound_caption(item.caption,2.6,item.source,cue)
		return
	# Discard freed players to keep the long-session bookkeeping bounded.
	sources=sources.filter(func(source):return is_instance_valid(source))
	var next: String=policy.tick(delta,eligible() if not held_off else [],held_off)
	game.events.atmosphere=policy.data
	if next!="":request(next)
