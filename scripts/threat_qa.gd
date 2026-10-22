extends Node
var g: Node
var output := ""
var checks: Array[Dictionary] = []
func check(id: String,okay: bool,detail := "") -> void:
	checks.append({"name":id,"passed":okay,"detail":detail})
	print("THREAT_QA ","PASS " if okay else "FAIL ",id," ",detail)
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds,true,false,true).timeout
func shot(id: String) -> void:
	g.presentation.clear_transients();g.subtitle.text = "";g.caption_until = 0
	await RenderingServer.frame_post_draw
	check("capture "+id,g.get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))==OK)
func setup(pos := Vector3(0,0.03,-6.5)) -> void:
	g.threat.enabled = true
	g.new_game()
	g.presentation.clear_transients()
	g.stage = 3;g.fuse = true;g.brass_key = true;g.report_read = true;g.shed_read = true;g.isolated = true
	g.events = {"chair":true,"yard":true,"basement":true,"return":true,"notes":{"Test record":"Preserve this"}}
	g.valve_order.assign([1,0,2])
	for d in g.doors.values():d.locked = false
	for l in g.lamps:l.light_energy = 0.6
	g.player.position = pos;g.player.velocity = Vector3.ZERO
	g.player.rotation = Vector3.ZERO;g.player.camera.rotation = Vector3.ZERO
	g.threat.arm()
func until_state(value: String,seconds: float) -> bool:
	for i in int(seconds*10):
		if g.threat.state == value:return true
		await wait(0.1)
	return g.threat.state == value
func run(game: Node) -> void:
	g = game
	output = ProjectSettings.globalize_path("res://qa") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA")
	g.checkpoint_path = output.path_join("threat_checkpoint.json")
	g.presentation.prefs.data = g.presentation.PREFS.DEFAULTS.duplicate()
	g.presentation.apply_preferences(false)
	setup()
	var actor: Node = g.surveyor_actor
	check("65 bone humanoid",actor.skeleton.get_bone_count()==65)
	for name_ in ["Head","neck_01","hand_l","hand_r","clavicle_l","calf_r"]:check("articulated "+name_,actor.skeleton.find_bone(name_)>=0)
	for name_ in ["listen","watch","walk","run","attack","react"]:check("skeletal clip "+name_,actor.clips.has(name_))
	check("gaze modifier follows animation",actor.gaze is SkeletonModifier3D)
	var head_id: int = actor.skeleton.find_bone("Head")
	var foot: int = actor.skeleton.find_bone("foot_l")
	actor.set_mode("walk")
	await wait(0.35)
	var before: Vector3 = actor.skeleton.get_bone_global_pose(foot).origin
	await wait(0.32)
	check("walk deforms actual foot",before.distance_to(actor.skeleton.get_bone_global_pose(foot).origin)>0.04,str(before)+" -> "+str(actor.skeleton.get_bone_global_pose(foot).origin))
	check("head transform finite",actor.skeleton.get_bone_global_pose(head_id).is_finite())
	g.player.position = Vector3(0.8,0.03,-1)
	await wait(0.12)
	var yaw: float = actor.gaze.yaw
	await wait(0.7)
	check("delayed skeletal head tracking",absf(actor.gaze.yaw-yaw)>0.01)
	g.player.position = Vector3(0,0.03,1.7)
	await wait(0.4)
	check("load grace prevents contact kill",g.threat.state=="warning" and g.presentation.section=="game")
	g.player.position = Vector3(0,0.03,-4)
	g.player.camera.look_at(g.presence.position+Vector3(0,1.4,0))
	check("sight in clear hall",g.threat.can_see_player())
	g.player.position = Vector3(3,0.03,-7)
	check("wall breaks sight",not g.threat.can_see_player())
	g.player.position = Vector3(0,0.03,-4)
	await wait(4.2)
	check("detect and pursue",await until_state("pursue",4))
	var pursue_start: Vector3 = g.presence.position
	await wait(0.45)
	check("pursuit moves with collision",g.presence.position.distance_to(pursue_start)>0.5)
	await shot("T01_pursuit")
	var chase_dir := output.path_join("pursuit_motion");DirAccess.make_dir_recursive_absolute(chase_dir)
	for frame in 18:
		await wait(0.06);await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png(chase_dir.path_join("%03d.png"%frame))
	check("telegraphed grab",await until_state("attack",7))
	check("not dead at attack start",g.presentation.section=="game")
	await shot("T02_grab_windup")
	check("contact can kill after the directed inspection",await until_state("dead",7))
	check("death releases control and pauses",g.menu_open and get_tree().paused and not g.player.active and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	await wait(0.6)
	await shot("T03_death")
	var checkpoint: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(g.checkpoint_path))
	check("checkpoint before threat is safe",checkpoint.events.threat_pending and checkpoint.pos[2]<-5)
	g.presentation.buttons["Retry Checkpoint"].pressed.emit()
	await wait(0.2)
	check("retry restores controls",g.player.active and not get_tree().paused and g.presentation.section=="game")
	check("retry preserves puzzle and discovered notes",g.isolated and g.fuse and g.brass_key and g.valve_order==[1,0,2] and g.events.notes.has("Test record"))
	check("retry has fresh warning",g.threat.state=="warning" and g.threat.grace>4)
	check("retry position",g.player.position.distance_to(Vector3(0,0,-6.5))<0.15)
	# Hide in the utility room behind its actual closed door, not a flag-based hiding state.
	g.player.position = Vector3(-3.1,0.03,-8.5)
	g.doors.utility.set_open(false,0.01)
	g.player.camera.look_at(Vector3(-1.5,1.4,-7))
	await wait(5)
	check("closed room conceals player",not g.threat.can_see_player())
	g.threat.hear(g.player.position,1)
	check("quiet movement outside hearing range",g.threat.state != "investigate" or g.threat.last_known.distance_to(g.player.position)>0.2)
	g.threat.hear(Vector3(0,0,-6),13)
	check("loud sound starts investigation",g.threat.state=="investigate" and g.threat.last_known.distance_to(Vector3(0,0,-6))<0.1)
	check("cover allows search and withdrawal",await until_state("complete",25))
	check("survival persisted",g.events.get("threat_resolved",false) and not g.events.get("threat_pending",true))
	await shot("T04_after_hiding")
	# A sprint can leave the grab volume during its windup.
	setup(Vector3(0,0.03,-4))
	await until_state("attack",14)
	var misses: int = g.threat.missed_attacks
	g.player.rotation.y = 0
	Input.action_press("forward");Input.action_press("sprint")
	await wait(1.15)
	Input.action_release("forward");Input.action_release("sprint")
	check("sprint evades warned grab",g.threat.state=="recovery" and g.threat.missed_attacks>misses and g.presentation.section=="game")
	# Actual portal routing into a furnished room, including opening its physical door.
	setup(Vector3(3.1,0.03,-7))
	g.threat.grace = 0;g.threat.change("investigate");g.threat.last_known = g.player.position;g.threat.plan(g.player.position)
	g.doors.office.set_open(false,0.01)
	var entered := false
	for i in 160:
		await wait(0.1)
		if g.presence.position.x > 2 and g.presence.position.z < -6:entered = true;break
	check("route through actual office portal",entered,str(g.presence.position)+" "+g.threat.state)
	check("enemy opens unlocked door",g.doors.office.opened)
	setup(Vector3(0,-2.98,-18))
	g.threat.grace = 0;g.threat.change("investigate");g.threat.last_known = g.player.position;g.threat.plan(g.player.position)
	var descended := false
	for i in 260:
		await wait(0.1)
		if g.presence.position.y < -2.7 and g.presence.position.z < -15.4:descended = true;break
	check("enemy navigates physical ramp down",descended,str(g.presence.position))
	setup(Vector3(0,0.03,-6))
	g.presence.position = Vector3(0,-2.97,-18)
	g.threat.grace = 0;g.threat.change("investigate");g.threat.last_known = g.player.position;g.threat.plan(g.player.position)
	var ascended := false
	for i in 220:
		await wait(0.1)
		if g.presence.position.y > -0.15 and g.presence.position.z > -9.5:ascended = true;break
	check("enemy navigates physical ramp up",ascended,str(g.presence.position))
	setup(Vector3(-1.9,0.03,-7))
	g.presence.position = Vector3(-1.08,0.03,-7)
	g.presence.look_at(Vector3(-1.9,0.03,-7))
	g.doors.utility.set_open(false,0.01)
	await wait(0.1)
	g.threat.grace = 0;g.threat.change("attack")
	await wait(1.15)
	check("closed door blocks lethal contact",g.presentation.section=="game" and g.threat.state=="recovery")
	# Story setting follows the same physical encounter without death.
	setup(Vector3(0,0.03,-4))
	g.presentation.prefs.data.story_mode = true
	check("story encounter reaches grab",await until_state("attack",15))
	await wait(1.2)
	check("story mode survives capture",g.presentation.section=="game" and g.threat.state=="recovery")
	var prefs = g.presentation.PREFS.new()
	prefs.path = output.path_join("threat_settings.cfg")
	prefs.data.story_mode = true
	check("story setting writes",prefs.save_file()==OK)
	var loaded = g.presentation.PREFS.new();loaded.path = prefs.path;loaded.load_file()
	check("story setting persists",loaded.data.story_mode)
	g.presentation.prefs.data.story_mode = false
	setup(Vector3(-4.5,0.03,-11.8))
	await wait(5)
	check("yard gives safe escape",await until_state("complete",12),g.threat.state+" "+str(g.presence.position))
	check("hidden actor has no collision",g.presence.collision_layer==0 and not g.presence.visible)
	g.load_game();await wait(0.2)
	check("resolved encounter does not repeat after load",g.threat.state=="dormant" and not g.events.get("threat_pending",true))
	setup(Vector3(0,.03,-5.1))
	g.presence.position=Vector3(0,.03,-7);g.presence.rotation.y=PI
	g.player.camera.look_at(g.presence.position+Vector3.UP*1.5)
	g.threat.change("retreat");g.threat.route.clear();await wait(.2)
	check("approaching visible retreat earns a fresh warning",g.threat.state=="warning" and g.threat.grace>.7 and g.presence.collision_layer==16)
	g.player.position=Vector3(-3.1,.03,-8.5);g.doors.utility.set_open(false,.01)
	g.threat.change("search");g.threat.route.clear()
	var heading: float=g.presence.rotation.y;await wait(1.4)
	check("stationary search scans without continuous spinning",absf(angle_difference(heading,g.presence.rotation.y))<.7 and g.threat.state=="search")
	g.threat.reset();g.presence.visible = true;g.presence.position = Vector3(0,0,-7)
	g.presence.look_at(Vector3(0,0,-3))
	g.player.position = Vector3(0,0.03,-3.5);g.player.camera.look_at(Vector3(0,1.3,-7))
	actor.set_mode("listen")
	await wait(0.5);await shot("T05_character")
	var dir := output.path_join("skeletal_motion");DirAccess.make_dir_recursive_absolute(dir)
	actor.set_mode("walk")
	for frame in 24:
		await wait(0.07);await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png(dir.path_join("%03d.png"%frame))
	var failed := 0
	for item in checks:if not item.passed:failed += 1
	var f := FileAccess.open(output.path_join("threat_report.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks},"\t"));f.close()
	print("THREAT_QA_COMPLETE passed=",checks.size()-failed," failed=",failed)
	get_tree().paused = false
	await g.qa_exit(0 if failed==0 else 1)
