extends Node
var g: Node
var checks: Array[Dictionary] = []
var output := ""
func check(id: String,okay: bool,detail := "") -> void:
	checks.append({"name":id,"passed":okay,"detail":detail})
	print("SYSTEMS_QA ","PASS " if okay else "FAIL ",id," ",detail)
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds,true,false,true).timeout
func shot(id: String) -> void:
	g.presentation.clear_transients();g.caption_until = 0;g.subtitle.text = ""
	await RenderingServer.frame_post_draw
	check("capture "+id,g.get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))==OK)
func run(game: Node) -> void:
	g = game
	output = ProjectSettings.globalize_path("res://qa") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA")
	g.checkpoint_path = output.path_join("systems_checkpoint.json")
	g.presentation.prefs.data = g.presentation.PREFS.DEFAULTS.duplicate()
	g.presentation.apply_preferences(false)
	g.new_game();g.presentation.clear_transients()
	for l in g.lamps:l.light_energy = 1.1
	await wait(1)
	var cup: RigidBody3D = g.physical.props.cup
	var metal: RigidBody3D = g.physical.props.spare
	var supported:=true
	for body in g.physical.props.values():
		var q:=PhysicsRayQueryParameters3D.create(body.global_position,body.global_position-Vector3.UP*.45,1)
		q.exclude=[body.get_rid(),g.player.get_rid()]
		if g.get_world_3d().direct_space_state.intersect_ray(q).is_empty():supported=false
	check("all carryable props have nearby physical support",supported)
	check("essential items remain fixed",not g.targets.fuse is RigidBody3D and not g.targets.valve0 is RigidBody3D)
	check("props settle on furniture",cup.position.y>0.80 and cup.position.y<1.0 and metal.position.y>0.8 and metal.position.y<1.1,str(cup.position)+" "+str(metal.position))
	check("weights and friction differ",metal.mass>cup.mass*3 and cup.physics_material_override.friction>=0.6)
	g.player.position = Vector3(4.6,0.03,1.2)
	g.player.camera.look_at(cup.position)
	await wait(0.15)
	var ray: Dictionary = g.player.target()
	check("real ray finds carryable mug",not ray.is_empty() and ray.collider==cup)
	check("pickup succeeds",g.physical.use() and g.physical.held==cup)
	await wait(0.6)
	check("held prop follows swept target",cup.position.distance_to(g.player.camera.global_position)<1.4 and cup.freeze)
	await shot("S01_carry")
	var before := cup.basis
	g.physical.rotate_held(Vector2(20,-10))
	check("held rotation works",not cup.basis.is_equal_approx(before))
	g.physical.release(false)
	check("drop returns rigid body",g.physical.held==null and not cup.freeze and cup.linear_velocity.length()<1)
	await wait(1.5)
	check("dropped object remains inside world",cup.position.y>-0.2 and cup.position.is_finite())
	# Repeat with the heavier spare and throw into the actual shed wall.
	g.player.position = Vector3(-17.25,0.03,-14.9)
	g.player.camera.look_at(metal.position)
	await wait(0.2)
	check("heavy prop pickup",g.physical.use() and g.physical.held==metal)
	await wait(0.5)
	g.player.camera.look_at(Vector3(-17.25,1.2,-17))
	await wait(0.4)
	g.physical.release(true)
	check("throw has bounded physical velocity",metal.linear_velocity.length()>3 and metal.linear_velocity.length()<=6.1)
	await wait(1.5)
	check("CCD prevents shed wall escape",metal.position.z>-17.25 and metal.position.y>-0.3,str(metal.position))
	await wait(4)
	check("thrown object settles",metal.linear_velocity.length()<0.12,str(metal.linear_velocity))
	var state: Dictionary = g.physical.snapshot()
	g.save_game();metal.position = Vector3(0,-10,0)
	g.load_game();await wait(0.3)
	check("prop transforms save and restore",metal.position.distance_to(Vector3(state.spare[0],state.spare[1],state.spare[2]))<0.18)
	metal.position.y = -8
	await wait(0.2)
	check("out of world recovery",metal.position.distance_to(g.physical.homes.spare.origin)<0.5)
	# Carry towards a solid partition; the prop must stop at the wall.
	cup.position = Vector3(0.9,1.45,-4);cup.linear_velocity = Vector3.ZERO
	g.player.position = Vector3(0,0.03,-4);g.player.camera.look_at(cup.position)
	await wait(0.05)
	check("wall probe pickup",g.physical.use() and g.physical.held==cup)
	g.player.camera.look_at(Vector3(4,1.55,-4))
	await wait(0.5)
	check("carried shape cannot cross partition",cup.position.x<1.45,str(cup.position))
	g.physical.release(false)
	check("drop restores player collision",not cup.get_collision_exceptions().has(g.player))
	var wood_audio = g.sound("step",Vector3(0,0,-4),-40)
	var stone_audio = g.sound("step",Vector3(0,-3,-18),-40)
	check("recorded material footsteps load",wood_audio.stream!=null and stone_audio.stream!=null and str(wood_audio.get_meta("sample")).contains("wood") and str(stone_audio.get_meta("sample")).contains("stone"))
	# A real walk records the cadence. The replay must derive from those events.
	g.new_game();g.presentation.clear_transients()
	for l in g.lamps:l.light_energy = 1.1
	g.player.position = Vector3(0,0.03,2.6);g.player.rotation.y = 0;g.player.camera.rotation = Vector3.ZERO
	Input.action_press("forward")
	await wait(3.5)
	Input.action_release("forward")
	await wait(0.3)
	check("actual walking records steps",g.events.get("memory_trace",[]).size()>=4)
	check("actual hall route recorded",g.events.get("memory_hall",[]).size()>=4)
	g.stage = 3;g.horror.house_responds()
	var trace: Array = g.events.memory_trace.duplicate(true)
	await wait(8)
	check("stillness triggers one archived echo",g.events.get("memory_echo",false) and g.horror.echo_index==-1)
	check("echo retains player cadence",g.events.get("memory_cadence",[]).size()==trace.size() and g.events.memory_cadence[0]==trace[0][3])
	var feed_before: Vector3 = g.horror.feed_ghost.position
	await wait(0.7)
	check("archive reenacts actual route",feed_before.distance_to(g.horror.feed_ghost.position)>0.15)
	g.player.position = Vector3(3.2,0.03,-0.3);g.player.camera.look_at(Vector3(3.2,1.2,-1.85))
	g.interact("television")
	check("interactive discovery records witnessed echo",g.events.get("memory_reviewed",false) and g.presentation.section=="document" and g.presentation.note.text==g.events.notes["CAM 02 / HALL"])
	g.resume();await wait(0.3)
	await shot("S02_house_memory_feed")
	# An optional handled object returns only when both endpoints are unseen and clear.
	cup = g.physical.props.cup
	g.events.remembered_cup = [4.6,0.88,0]
	cup.call("relocate",Transform3D(Basis.IDENTITY,Vector3(3.5,0.2,1.5)))
	g.player.position = Vector3(3.5,0.03,2.6);g.player.camera.look_at(cup.position)
	await wait(0.15)
	check("no visible paranormal pop",not g.physical.repeat_placement())
	g.player.position = Vector3(0,0.03,-5);g.player.camera.look_at(Vector3(0,1.5,-8))
	await wait(0.3)
	check("house repeats handled object placement under cover",g.events.get("cup_repeated",false) and cup.position.distance_to(Vector3(4.6,0.88,0))<0.15,str(cup.position)+" repeated="+str(g.events.get("cup_repeated",false)))
	check("paranormal repeat is one shot",not g.physical.repeat_placement())
	var saved: Dictionary = JSON.parse_string(JSON.stringify(g.save_data()))
	g.apply_save(saved)
	check("memory survives save roundtrip",g.events.memory_reviewed and g.events.cup_repeated and g.horror.echo_trace.size()==trace.size())
	var legacy := saved.duplicate(true)
	legacy.events = {};g.apply_save(legacy)
	check("schema one legacy save remains supported",g.started and g.player.active and not g.events.has("memory_echo"))
	var failed := 0
	for item in checks:if not item.passed:failed += 1
	var file := FileAccess.open(output.path_join("systems_report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks},"\t"));file.close()
	print("SYSTEMS_QA_COMPLETE passed=",checks.size()-failed," failed=",failed)
	get_tree().paused = false
	await g.qa_exit(0 if failed==0 else 1)
