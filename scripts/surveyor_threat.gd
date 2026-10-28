extends Node3D
# One authored encounter. Navigation follows surveyed walkable portals, while actual
# movement/collision, sight rays and hearing determine the result each time.
var game: Node3D
var state := "dormant"
var visual_line_of_sight:=false
var clock := 0.0
var age := 0.0
var grace := 0.0
var suspicion := 0.0
var lost := 0.0
var last_known := Vector3.ZERO
var route := PackedVector3Array()
var graph := AStar3D.new()
var step_distance := 0.0
var footstep_index:=0
var stuck := 0.0
var missed_attacks := 0
var deaths := 0
var door_wait := 0.0
var enabled := true
var search_leg := 0
var search_heading := 0.0
var search_anchor := Vector3.ZERO
var search_focus := Vector3.ZERO
var search_pause := 0.0
var search_visited: Array[int]=[]
var collision_active := false
var stalk_used := false
var memory_routes: Array[int]=[]
var service_edges: Array=[]
var last_voice:=-100.0
var last_attack_voice:=-100.0
var voice_player: AudioStreamPlayer3D
var heard_at:=-1000.0
var heard_strength:=0.0
var hearing_pause:=0.0

func _ready() -> void:
	# Points sit inside door clearances, clear of the furnished room edges.
	var points := [Vector3(0,-3,-22),Vector3(0,-3,-18),Vector3(0,-3,-15.5),Vector3(0,-1.5,-12.5),Vector3(0,0,-9),Vector3(0,0,-7),Vector3(0,0,-4),Vector3(0,0,-1),Vector3(0,0,1),Vector3(0,0,2.7),Vector3(-0.8,0,-7),Vector3(-2.2,0,-7),Vector3(-3.1,0,-7),Vector3(-4.5,0,-8.8),Vector3(-4.5,0,-11.7),Vector3(0.8,0,-7),Vector3(2.2,0,-7),Vector3(3.2,0,-7),Vector3(0.8,0,1),Vector3(2.2,0,1),Vector3(3.2,0,1),Vector3(-0.8,0,1),Vector3(-2.2,0,1),Vector3(-3.1,0,1)]
	for i in points.size():graph.add_point(i,points[i])
	for i in range(9):graph.connect_points(i,i+1)
	for chain in [[5,10,11,12,13,14],[5,15,16,17],[8,18,19,20],[8,21,22,23]]:
		for i in range(chain.size()-1):graph.connect_points(chain[i],chain[i+1])
	# Relay-room side aisles connect the recorded corner to the central ramp route.
	for point in [Vector3(-3.7,-3,-16.1),Vector3(3.7,-3,-16.1),Vector3(-2.8,-3,-18.3),Vector3(2.8,-3,-18.3)]:
		graph.add_point(graph.get_point_count(),point)
	for pair in [[24,26],[25,27],[26,1],[27,1],[24,2],[25,2]]:graph.connect_points(pair[0],pair[1])
	# The turned-over tables leave player-height clearance, but the Surveyor is
	# taller. Survey actual side aisles rather than forcing it under the furniture.
	for point in [Vector3(2.85,0,-.55),Vector3(4.5,0,-1.2),Vector3(3,0,1.9),Vector3(4.5,0,1.85)]:
		var id:=graph.get_point_count();graph.add_point(id,point);memory_routes.append(id);graph.set_point_disabled(id,true)
	graph.connect_points(20,memory_routes[0]);graph.connect_points(memory_routes[0],memory_routes[1])
	graph.connect_points(20,memory_routes[2]);graph.connect_points(memory_routes[2],memory_routes[3])
	# Walkable maintenance aisles around the west bench and east generator.
	# These are actor-sized routes, not eye-height sight lines over furniture.
	var service: Array[int]=[]
	for point in [Vector3(-3.3,-3,-20),Vector3(-3.3,-3,-22),Vector3(2,-3,-18),Vector3(2,-3,-20),Vector3(2,-3,-22.1),Vector3(4,-3,-22.1),Vector3(4,-3,-17.3)]:
		var id:=graph.get_point_count();graph.add_point(id,point);service.append(id)
	service_edges=[[24,26],[25,27],[26,1],[27,1],[24,2],[25,2],[26,service[0]],[service[0],service[1]],[service[1],0],[27,service[2]],[service[2],service[3]],[service[3],service[4]],[service[4],0],[service[4],service[5]],[25,service[6]],[service[6],27]]
	for pair in service_edges:graph.connect_points(pair[0],pair[1])

func reset() -> void:
	heard_at=-1000;heard_strength=0;hearing_pause=0
	visual_line_of_sight=false
	stop_voice();last_voice=-100;last_attack_voice=-100
	for id in memory_routes:graph.set_point_disabled(id,true)
	state = "dormant"
	clock = 0
	age = 0
	grace = 5
	suspicion = 0
	lost = 0
	search_pause=0;search_leg=0;search_visited.clear()
	route.clear()
	set_collision(false)
	game.presence.velocity = Vector3.ZERO

func set_collision(value: bool) -> void:
	collision_active = value
	game.presence.collision_layer = 16 if value else 0

func arm() -> void:
	if active() or game.events.get("threat_resolved",false):return
	game.events.threat_pending = true
	game.save_game()
	begin()

func begin_basement() -> void:
	game.events.threat_origin = "basement"
	game.events.threat_pending = true
	# Save the established relay checkpoint, never the actor's contact position.
	begin(true)

func begin(basement := false,position_override: Variant=null) -> void:
	if game.horror.beat=="vent_pass":
		# A scripted request cannot relocate a visible staged body or attack a
		# player still confined in the crawl. Outside, hand over this same body.
		if game.horror.vent_protected():return
		position_override=game.presence.position
		game.horror.release_vent(false)
	game.horror.stop_audition()
	heard_at=-1000;heard_strength=0;hearing_pause=0
	stalk_used = false
	game.horror.beat = ""
	game.presence.position = Vector3(0,0.04,2.6)
	game.presence.rotation.y = 0
	if game.presence.position.distance_to(game.player.position)<4.0:
		game.presence.position = Vector3(0,0.04,-7.3)
		game.presence.look_at(Vector3(game.player.position.x,0.04,game.player.position.z))
	if basement:
		game.presence.position = Vector3(-3.7 if game.horror.variant==0 else 3.7,-2.99,-16.1)
		game.presence.look_at(Vector3(game.player.position.x,-2.99,game.player.position.z))
	if position_override is Vector3:
		game.presence.position=position_override
		game.presence.look_at(Vector3(game.player.position.x,game.presence.position.y,game.player.position.z))
	var facing: Vector3=game.player.position-game.presence.position
	if Vector2(facing.x,facing.z).length()>.05:game.presence.rotation.y=atan2(-facing.x,-facing.z)
	game.presence.visible = true
	game.presence.velocity = Vector3.ZERO
	set_collision(true)
	state = "warning"
	clock = 0
	age = 0
	lost = 0
	suspicion = 0
	stuck = 0
	search_leg = 0
	grace = 3.0 if basement else 4.5
	game.surveyor_actor.set_mode("listen")
	game.sound("latch",Vector3(0,1,3.8),-23)
	var breathing=voice("warning",-28)
	if breathing:game.sound_caption("Breathing, close by.",2.5,"CELLAR" if game.presence.position.y<-.5 else "HALL",breathing)

func stop_voice() -> void:
	if is_instance_valid(voice_player):voice_player.stop();voice_player.queue_free()
	voice_player=null

func voice(slot: String,db: float) -> AudioStreamPlayer3D:
	var now: float=game.time_in_game
	if slot=="attack":
		if now-last_attack_voice<10:return null
		last_attack_voice=now
	elif now-last_voice<32:return null
	last_voice=now;stop_voice()
	voice_player=game.sound("surveyor_"+slot,game.presence.position+Vector3.UP*1.45,db-6)
	voice_player.reparent(game.presence)
	return voice_player

func active() -> bool:
	return state not in ["dormant","complete","dead"]

func clear_line(from: Vector3,to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from,to,1)
	q.exclude = [game.player.get_rid(),game.presence.get_rid()]
	return game.get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func can_see_player() -> bool:
	var from: Vector3 = game.presence.position+Vector3(0,1.65,0)
	var target: Vector3 = game.player.camera.global_position
	var diff := target-from
	if diff.length() > (12.0 if game.player.torch.visible else 8.0):return false
	if diff.length() > 1.65 and -game.presence.global_basis.z.dot(diff.normalized()) < 0.30:return false
	return player_sight(from,target) or player_sight(from,game.player.position+Vector3.UP*(.55 if game.player.crouched else 1.0))

func player_sight(from: Vector3,to: Vector3) -> bool:
	if game.get_node("LivingRoomFinishes").blocks_sight(from,to):return false
	# Closed transparent glazing stops bodies, not light. Never skip opaque
	# walls/frames/doors, and retain the old solid test for hearing and attacks.
	var ray:=PhysicsRayQueryParameters3D.create(from,to,1)
	ray.exclude=[game.player.get_rid(),game.presence.get_rid()]
	for i in 4:
		var hit:=game.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty():return true
		if not hit.collider.get_meta("transparent_glass",false):return false
		var skip: Array[RID]=ray.exclude;skip.append(hit.collider.get_rid());ray.exclude=skip
	return false

func hear(point: Vector3,loudness: float) -> void:
	if state not in ["observe","investigate","search"] or grace > 0:return
	var range_ := loudness*(1.0 if clear_line(game.presence.position+Vector3.UP,point+Vector3.UP) else 0.45)
	if game.presence.position.distance_to(point) > range_:return
	var strength: float=range_/(1.0+game.presence.position.distance_to(point))
	var recent: bool=game.time_in_game-heard_at<1.5
	# A quiet rattle cannot instantly cancel a stronger sound already being
	# investigated. Nearby repeated contacts do not restart the listening pose.
	if recent and (strength<heard_strength*.85 or point.distance_to(last_known)<.65):return
	heard_at=game.time_in_game;heard_strength=strength;hearing_pause=.65
	last_known = point
	change("investigate")
	plan(last_known)

func change(next: String) -> void:
	state = next
	clock = 0
	stuck = 0
	if state == "pursue":voice("pursuit",-26)
	if state == "attack":
		game.surveyor_actor.set_mode("attack")
		var breathing=voice("attack",-23)
		if breathing:game.sound_caption("A sharp intake of breath.",1,"NEARBY",breathing)
	if state in ["search","observe","recovery"]:game.surveyor_actor.set_mode("watch")
	if state=="search":
		search_heading=game.presence.rotation.y;search_anchor=last_known
		search_focus=last_known;search_pause=0;search_leg=0;search_visited.clear()

func next_search_point() -> bool:
	# Search the place actually heard/seen, then an adjacent clear approach.
	# Never choose a destination from Eli's hidden position or through a wall.
	var best:=-1;var best_score:=-INF
	for id in graph.get_point_ids():
		if id in search_visited or graph.is_point_disabled(id):continue
		var point: Vector3=graph.get_point_position(id)
		var from_body: Vector3=point-game.presence.position
		if absf(point.y-game.presence.position.y)>.35 or point.distance_to(search_anchor)>3.1:continue
		if from_body.length()<.85 or from_body.length()>3.4 or not route_clear(game.presence.position,point):continue
		var score: float=-game.presence.global_basis.z.dot(from_body.normalized())-.12*from_body.length()
		if score>best_score:best=id;best_score=score
	if best<0:return false
	search_visited.append(best);search_leg+=1;search_pause=0
	search_focus=graph.get_point_position(best);plan(search_focus)
	return not route.is_empty()

func closest(point: Vector3) -> int:
	var best := -1
	var distance := INF
	for id in graph.get_point_ids():
		if graph.is_point_disabled(id):continue
		var p := graph.get_point_position(id)
		var score := p.distance_to(point)
		if score < distance and route_clear(point,p):
			distance = score
			best = id
	return graph.get_closest_point(point) if best < 0 else best

func route_clear(from: Vector3,to: Vector3) -> bool:
	if absf(from.y+3)<.2 and absf(to.y+3)<.2:
		# Reuse the actual 2.05 m / .38 m capsule. Lift a few centimetres solely
		# for a horizontal query above the floor; movement/gravity stay unchanged.
		return not game.presence.test_move(Transform3D(Basis.IDENTITY,from+Vector3.UP*.035),to-from)
	return clear_line(from+Vector3.UP*.85,to+Vector3.UP*.85)

func plan(point: Vector3) -> void:
	for id in memory_routes:graph.set_point_disabled(id,not game.impossible_room.active)
	for pair in service_edges:
		var clear:=route_clear(graph.get_point_position(pair[0]),graph.get_point_position(pair[1]))
		if clear and not graph.are_points_connected(pair[0],pair[1]):graph.connect_points(pair[0],pair[1])
		elif not clear and graph.are_points_connected(pair[0],pair[1]):graph.disconnect_points(pair[0],pair[1])
	var from := closest(game.presence.position)
	var to := closest(point)
	route = graph.get_point_path(from,to)
	if game.presence.position.z < -15 and absf(game.presence.position.y+3)<.2:
		# On the flat cellar floor, keep the furthest capsule-clear route point.
		# Nearest-node replans otherwise reverse at an adjacent branch every .5 s.
		var skip:=0
		for i in range(route.size()-1,0,-1):
			if route[i].z < -15 and absf(route[i].y+3)<.2 and route_clear(game.presence.position,route[i]):skip=i;break
		for i in skip:route.remove_at(0)
	elif route.size() > 1 and route_clear(game.presence.position,route[1]):route.remove_at(0)
	elif not route.is_empty() and game.presence.position.distance_to(route[0]) < 0.45:route.remove_at(0)
	# A direct final segment is only allowed inside the same clear room/floor.
	var end := graph.get_point_position(to)
	if absf(end.y-point.y)<0.6 and point.distance_to(end)<3.0 and route_clear(end,point):route.append(point)

func move_route(delta: float,speed: float,staged:=false) -> void:
	var body: CharacterBody3D = game.presence
	if route.is_empty():
		body.velocity.x = 0;body.velocity.z = 0
		game.surveyor_actor.locomotion(0)
		return
	var target := route[0]
	var diff := Vector3(target.x-body.position.x,0,target.z-body.position.z)
	if diff.length() < 0.23:
		route.remove_at(0)
		return
	door_wait = maxf(0,door_wait-delta)
	for d in game.doors.values():
		if body.position.distance_to(d.position) < 1.25 and not d.opened:
			# Passing a closed room is not an instruction to open it. Only the
			# segment actually crossing this doorway may operate its leaf.
			var here: Vector3=d.to_local(body.global_position)
			var there: Vector3=d.to_local(target)
			if here.z*there.z>0 and absf(there.z)>.22:continue
			var t: float=clampf(here.z/(here.z-there.z),0,1) if absf(here.z-there.z)>.001 else 1.0
			var crossing: Vector3=here.lerp(there,t)
			if absf(crossing.x)>d.clear_half_width+.15 or absf(crossing.y)>.7:continue
			if d.locked:route.clear();return
			d.open_away_from(body.global_position)
			d.set_open(true,0.85)
			door_wait = 1.05
	if door_wait > 0:
		game.surveyor_actor.set_mode("watch")
		return
	var direction := diff.normalized()
	body.rotation.y = lerp_angle(body.rotation.y,atan2(-direction.x,-direction.z),1-exp(-delta*3.2))
	# Facing must catch up before full speed; corners are turns, not side-sliding.
	var alignment := maxf(0.15,-body.global_basis.z.dot(direction))
	body.velocity.x = move_toward(body.velocity.x,direction.x*speed*alignment,delta*6.0)
	body.velocity.z = move_toward(body.velocity.z,direction.z*speed*alignment,delta*6.0)
	body.velocity.y = -0.2 if body.is_on_floor() else body.velocity.y-20*delta
	var before := body.position
	body.move_and_slide()
	var distance := Vector2(body.position.x-before.x,body.position.z-before.z).length()
	game.surveyor_actor.locomotion(distance/maxf(delta,0.001),speed>2)
	if body.is_on_floor():step_distance += distance
	if step_distance > 0.72 and body.is_on_floor():
		# Retain distance overshoot, so low frame rates do not stretch the stride.
		# Contact is at the real body/floor, not a repetitive centred vocal loop.
		step_distance -= .72
		var cue: AudioStreamPlayer3D=game.sound("step",body.position,-24 if footstep_index%2==0 else -25)
		cue.pitch_scale=.78 if footstep_index%2==0 else .82
		cue.max_distance=13;cue.unit_size=1.3;footstep_index+=1
	stuck = stuck+delta if distance < delta*0.08 else 0
	if stuck > 2.0:
		# A moved chair/closed door is cover. Never warp through it to reach the player.
		route.clear()
		if not staged:change("search")
	elif stuck>0.65 and route.size()<12:
		# A short swept sidestep recovers a corner/prop contact without teleporting.
		for side in [direction.cross(Vector3.UP),-direction.cross(Vector3.UP)]:
			if not body.test_move(body.global_transform,side*0.7):
				route.insert(0,body.position+side*0.7)
				stuck = 0
				break

func resolve() -> void:
	game.events.threat_pending = false
	game.events.threat_resolved = true
	state = "complete"
	set_collision(false)
	game.presence.visible = false
	game.presence.velocity = Vector3.ZERO
	game.surveyor_actor.set_mode("listen")
	game.save_game()

func _physics_process(delta: float) -> void:
	if not enabled or not game.started or game.menu_open or game.ended:return
	if state=="capture":return
	if state == "dormant":
		if game.events.get("threat_pending",false):
			if game.events.get("threat_origin","") in ["window","inspection","last_call","vent_follow"] and game.events.get("threat_spawn",[]).size()==3:
				var p: Array=game.events.threat_spawn;begin(false,Vector3(p[0],p[1],p[2]))
			elif game.events.get("threat_origin","")=="basement" and game.horror.beat!="wrong_direction":begin(true)
			elif game.player.position.y > -0.3 and game.player.position.z > -8.2:begin()
		return
	if not active():return
	clock += delta
	age += delta
	grace = maxf(0,grace-delta)
	var seen := can_see_player()
	# Share the existing perception result with visual attention. No extra gaze
	# raycasts, hidden-player tracking or changed detection rules.
	visual_line_of_sight=seen
	var distance: float = game.presence.position.distance_to(game.player.position)
	if state == "warning":
		if seen:
			var toward: Vector3=game.player.position-game.presence.position
			game.presence.rotation.y=lerp_angle(game.presence.rotation.y,atan2(-toward.x,-toward.z),1-exp(-delta*1.6))
		if grace <= 0:change("observe")
		return
	if state == "attack":
		# Acquire the body-facing direction early in the warning, then commit.
		# Close-range detection also sees behind us; that must not start a backward grab.
		if clock<0.45:
			var toward: Vector3 = game.player.position-game.presence.position
			game.presence.rotation.y = lerp_angle(game.presence.rotation.y,atan2(-toward.x,-toward.z),1-exp(-delta*9))
		# Windup is escapable. Contact is checked at the end, never at its start.
		if clock >= 1.1:
			var direction: Vector3 = game.player.position-game.presence.position
			direction.y = 0
			if distance < 1.35 and -game.presence.global_basis.z.dot(direction.normalized())>0.25 and clear_line(game.presence.position+Vector3.UP*1.3,game.player.camera.global_position):
				if game.presentation.prefs.data.story_mode or (game.dev_mode and is_instance_valid(game.dev_tools) and game.dev_tools.invulnerable):
					change("recovery");clock = -2
				else:
					state = "capture";deaths += 1
					game.capture_director.begin()
			else:missed_attacks += 1;change("recovery")
		return
	if state == "recovery":
		if clock > 1.4:change("search");plan(last_known)
		return
	# An escaping player keeps the safe yard break. Walking back up to a retreating
	# actor indoors earns a fresh warning, rather than a harmless rigid mannequin.
	var yard_escape: bool=game.player.position.y>-.4 and game.player.position.z< -10.7 and game.player.position.x< -3
	if state=="retreat" and seen and distance<2.2 and not yard_escape:
		game.events.threat_pending=true;game.events.threat_resolved=false
		last_known=game.player.position;suspicion=1.0;change("warning");grace=1.2
		return
	if seen and state != "retreat":
		lost = 0
		last_known = game.player.position
		suspicion += delta*(0.6 if Input.is_action_pressed("crouch") else 1.0)
		if suspicion >= 1.0 and state not in ["pursue","stalk"]:
			if not stalk_used and distance>4.5:
				stalk_used = true
				change("stalk")
			else:change("pursue")
			plan(last_known)
	else:
		lost += delta
		suspicion = maxf(0,suspicion-delta*0.35)
	if state == "stalk":
		if game.horror.visible_to_player():
			game.surveyor_actor.set_mode("watch")
			game.presence.velocity.x=0;game.presence.velocity.z=0
			var toward: Vector3=last_known-game.presence.position
			game.presence.rotation.y=lerp_angle(game.presence.rotation.y,atan2(-toward.x,-toward.z),1-exp(-delta*1.8))
		else:move_route(delta,0.55)
		if clock>1.8 or distance<3.5:change("pursue");plan(last_known)
	elif state == "pursue":
		if distance < 1.05 and seen and grace <= 0:change("attack");return
		if lost > 2.2:change("search");plan(last_known)
		elif clock > 0.5:clock = 0;plan(last_known)
		move_route(delta,2.65)
	elif state == "investigate":
		if hearing_pause>0:
			hearing_pause=maxf(0,hearing_pause-delta)
			game.presence.velocity.x=0;game.presence.velocity.z=0
			game.surveyor_actor.set_mode("listen")
			var toward: Vector3=last_known-game.presence.position
			if Vector2(toward.x,toward.z).length()>.05:game.presence.rotation.y=lerp_angle(game.presence.rotation.y,atan2(-toward.x,-toward.z),1-exp(-delta*2.5))
		else:
			move_route(delta,1.05)
			if route.is_empty():change("search")
	elif state == "search":
		move_route(delta,0.85)
		if route.is_empty():
			search_pause+=delta
			game.presence.rotation.y=lerp_angle(game.presence.rotation.y,search_heading+sin(search_pause*.72)*.55,1-exp(-delta*1.5))
			# A held listen before each short approach gives the player readable
			# escape windows. Two probes at most; no endless room patrol or new chase.
			if search_pause>1.6 and search_leg<2:
				if not next_search_point():search_leg=2
				else:search_heading=atan2(-(search_focus.x-game.presence.position.x),-(search_focus.z-game.presence.position.z))
		if (lost>8 and clock>4 and search_leg>0 and route.is_empty()) or clock>14:
			change("retreat");plan(Vector3(0,0,2.7))
	elif state == "observe":
		if clock > 3.5:last_known = Vector3(0,0,-6.5);change("investigate");plan(last_known)
	elif state == "retreat":
		move_route(delta,0.95)
		if not game.horror.visible_to_player() and clock > 1.0:resolve()
		elif route.is_empty() and clock > 2.5:
			# Still observed: remain bodily present, but the completed encounter stops pursuing.
			game.events.threat_resolved = true
			game.events.threat_pending = false
			# Being watched never makes a visible body intangible.
			if not game.horror.visible_to_player():resolve()
	# A service-yard escape breaks the encounter. Departure occurs under cover.
	if active() and game.player.position.y > -0.4 and game.player.position.z < -10.7 and game.player.position.x < -3:
		if state != "retreat":change("retreat");plan(Vector3(0,0,2.7))
