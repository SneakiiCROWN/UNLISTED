extends Node

var g: Node
var checks: Array[Dictionary] = []
var output := ""
var frame_times: Array[float] = []

func _process(delta: float) -> void:
	if g != null and g.started and not g.menu_open: frame_times.append(delta*1000)

func check(name_: String, success: bool, detail := "") -> void:
	checks.append({"name":name_,"passed":success,"detail":detail})
	print("QA ", "PASS " if success else "FAIL ",name_," ",detail)

func settle(frames := 4) -> void:
	for i in range(frames): await get_tree().physics_frame

func look_from(pos: Vector3, target: Vector3) -> void:
	g.player.position = pos
	g.player.velocity = Vector3.ZERO
	g.player.rotation = Vector3.ZERO
	g.player.camera.rotation = Vector3.ZERO
	await settle()
	g.player.camera.look_at(target)
	await settle()

func use_target(id: String, pos: Vector3) -> void:
	var body: Node3D = g.targets[id]
	await look_from(pos,body.global_position)
	var hit: Dictionary = g.player.target()
	var got := "none"
	if not hit.is_empty(): got = str(hit.collider.get_meta("interaction","solid"))
	check("ray interaction "+id,got == id,"hit="+got)
	if got == id: g.try_interact()
	await settle()
	if g.journal.visible: g.resume()

func walk_to(point: Vector2, label_: String) -> void:
	var remaining := 999.0
	var start := Vector2(g.player.position.x,g.player.position.z)
	var limit := int(start.distance_to(point)/2.15*60)+150
	Input.action_press("forward")
	for i in range(limit):
		var diff := point-Vector2(g.player.position.x,g.player.position.z)
		remaining = diff.length()
		if remaining < 0.16: break
		g.player.rotation.y = atan2(-diff.x,-diff.y)
		g.player.camera.rotation = Vector3.ZERO
		await get_tree().physics_frame
	Input.action_release("forward")
	await settle(10)
	check("physical route "+label_,remaining < 0.2,str(g.player.position))

func capture(name_: String, pos: Vector3, at: Vector3) -> void:
	await look_from(pos,at)
	g.prompt.text = ""
	g.subtitle.text = ""
	await RenderingServer.frame_post_draw
	var img := g.get_viewport().get_texture().get_image()
	var err := img.save_png(output.path_join(name_+".png"))
	check("capture "+name_,err == OK)

func run(game: Node) -> void:
	g = game
	g.presentation.prefs.data = g.presentation.PREFS.DEFAULTS.duplicate()
	g.presentation.apply_preferences(false)
	output = ProjectSettings.globalize_path("res://qa") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA")
	DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path = output.path_join("test_checkpoint.json")
	await settle(6)
	check("title menu",g.menu_open and not g.player.active)
	check("presence model loaded",g.all_meshes(g.presence).size()>5)
	await RenderingServer.frame_post_draw
	g.get_viewport().get_texture().get_image().save_png(output.path_join("00_title.png"))
	g.new_game()
	await settle(30)
	check("spawn grounded",g.player.is_on_floor(),str(g.player.position))
	var start: Vector3 = g.player.position
	Input.action_press("forward")
	await settle(65)
	Input.action_release("forward")
	await settle(12)
	check("physical movement",g.player.position.z < start.z - 1)
	await use_target("order",Vector3(-1.0,0.02,5.6))
	check("work order objective",g.stage == 1)
	await look_from(Vector3(0,0.02,5.3),Vector3(0,1.62,1))
	Input.action_press("forward")
	await settle(65)
	Input.action_release("forward")
	await settle(10)
	check("closed front door blocks movement",g.player.position.z > 4.25,str(g.player.position))
	await use_target("front",Vector3(0,0.02,5.5))
	await settle(60)
	check("front door animation",absf(g.doors.front.pivot.rotation.y)>1.4)
	await look_from(Vector3(0,0.02,5.3),Vector3(0,1.62,1.0))
	Input.action_press("forward")
	await settle(90)
	Input.action_release("forward")
	await settle(12)
	check("walk through open front door",g.player.position.z < 3.7,str(g.player.position))
	await use_target("lounge",Vector3(0,0.02,1))
	await settle(55)
	await look_from(Vector3(0,0.02,1),Vector3(3,1.62,1))
	await walk_to(Vector2(2.7,1),"hall to lounge")
	await walk_to(Vector2(3.2,1.8),"lounge seating clearance")
	await walk_to(Vector2(2.7,1),"lounge exit turn")
	await walk_to(Vector2(0,1),"lounge to hall")
	await walk_to(Vector2(-2.7,1),"hall to kitchen")
	await walk_to(Vector2(-4.8,1),"kitchen clearance")
	await walk_to(Vector2(0,1),"kitchen to hall")
	await use_target("utility",Vector3(0,0.02,-7))
	await settle(55)
	await walk_to(Vector2(-3,-7),"hall to utility")
	await use_target("fuse",Vector3(-3.5,0.02,-7.3))
	check("fuse acquired",g.fuse)
	await use_target("breaker",Vector3(-2.65,0.02,2.2))
	check("mains restored",g.stage == 3)
	await look_from(Vector3(0,0.02,-1.0),Vector3(0,1.62,-7))
	await settle(35)
	check("chair event transformed model",g.events.has("chair") and absf(g.chair.rotation.z)>1.3)
	await use_target("office",Vector3(0,0.02,-7))
	await settle(55)
	await walk_to(Vector2(3,-7),"hall to office")
	await use_target("security",Vector3(5.6,0.02,-7.0))
	check("archive unlocks service",g.report_read and not g.doors.service.locked)
	await settle(35)
	check("office door supernatural closure",g.events.has("office") and absf(g.doors.office.pivot.rotation.y)<0.1)
	await use_target("service",Vector3(-4.5,0.02,-8.5))
	await settle(55)
	await use_target("shed",Vector3(-12.5,0.02,-14))
	await settle(55)
	await look_from(Vector3(-4.5,0.02,-8),Vector3(-4.5,1.62,-12))
	await walk_to(Vector2(-4.5,-11.8),"utility to porch")
	await walk_to(Vector2(-11.9,-12.4),"service yard west")
	await walk_to(Vector2(-12.4,-14),"shed approach")
	await walk_to(Vector2(-16,-14),"through shed doorway")
	await walk_to(Vector2(-12.4,-14),"return through shed")
	await walk_to(Vector2(-13.05,-14),"shed side turn")
	await walk_to(Vector2(-13.05,-17.8),"maintenance gap south")
	await walk_to(Vector2(-21,-17.8),"shed rear west")
	await walk_to(Vector2(-21,-10.3),"shed west side")
	await walk_to(Vector2(-21,-17.8),"shed west side return")
	await walk_to(Vector2(-13.05,-17.8),"shed rear return")
	await walk_to(Vector2(-13.05,-14),"maintenance gap north")
	Input.action_press("crouch")
	await walk_to(Vector2(-12.4,-14),"crouch at shed approach")
	Input.action_release("crouch")
	await walk_to(Vector2(-11.9,-12.4),"return yard turn")
	await walk_to(Vector2(-4.5,-12.4),"yard to porch")
	await walk_to(Vector2(-4.5,-8),"porch to utility")
	await use_target("shed_record",Vector3(-18,0.02,-15.2))
	check("manual override unlocks basement",g.shed_read and not g.doors.basement.locked)
	await look_from(Vector3(-9,0.02,-12.4),Vector3(-5,1.5,-12.4))
	await settle(20)
	check("yard apparition executed",g.events.has("yard") and g.presence.visible)
	await capture("01_entrance",Vector3(0,0.02,8.2),Vector3(0,1.6,4))
	await capture("02_hallway",Vector3(0,0.02,2.7),Vector3(0,1.55,-8))
	await capture("03_living_room",Vector3(2.3,0.02,2.6),Vector3(5.0,1.3,-0.5))
	await capture("04_kitchen",Vector3(-2.2,0.02,-0.6),Vector3(-5,1.3,2))
	await capture("05_shed",Vector3(-14.9,0.02,-13),Vector3(-18,1.1,-15))
	await use_target("basement",Vector3(0,0.02,-8.4))
	await settle(55)
	await look_from(Vector3(0,0.02,-9.1),Vector3(0,0,-14))
	g.player.camera.rotation = Vector3.ZERO
	Input.action_press("forward")
	await settle(240)
	Input.action_release("forward")
	await settle(30)
	check("physical ramp descent",g.player.position.y < -2.7 and g.player.is_on_floor(),str(g.player.position))
	await walk_to(Vector2(0,-9.0),"basement ramp ascent")
	await use_target("valve0",Vector3(-2.7,-2.98,-22))
	check("wrong sequence resets safely",g.valve_order.is_empty())
	await use_target("valve1",Vector3(-1.5,-2.98,-22))
	await use_target("valve0",Vector3(-2.7,-2.98,-22))
	await use_target("valve2",Vector3(-0.3,-2.98,-22))
	check("valve puzzle solved",g.valve_order == [1,0,2])
	await use_target("isolate",Vector3(2,-2.98,-22))
	check("isolation and basement presence",g.isolated and g.events.has("basement"))
	await settle(190)
	await capture("06_basement",Vector3(0,-2.98,-16),Vector3(0,-1.5,-22.5))
	await capture("07_relay_close",Vector3(-1.1,-2.98,-21.0),Vector3(-1.1,-1.4,-23.4))
	await capture("08_service_yard",Vector3(-7.8,0.02,-12.7),Vector3(-16,1.7,-14))
	await capture("09_office",Vector3(2.3,0.02,-5.2),Vector3(5.2,1.1,-8.8))
	await capture("10_utility",Vector3(-2.4,0.02,-5.2),Vector3(-5,1.2,-8.8))
	await capture("11_approach",Vector3(1.2,0.02,9.8),Vector3(0,2.7,3.5))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(g.save_data()))
	g.stage = 0
	g.isolated = false
	g.apply_save(saved)
	check("save serialization roundtrip",g.isolated and g.shed_read and g.valve_order == [1,0,2])
	g.save_game()
	g.isolated = false
	g.stage = 0
	g.load_game()
	check("checkpoint disk save and load",g.isolated and g.stage >= 3 and g.shed_read)
	g.show_menu("PAUSED")
	var paused: Vector3 = g.player.position
	Input.action_press("forward")
	await settle(20)
	Input.action_release("forward")
	check("pause blocks movement",g.player.position.distance_to(paused) < 0.001)
	g.resume()
	await look_from(Vector3(0,0.02,-6),Vector3(0,1.62,2))
	await settle(8)
	check("changed hallway return event",g.events.has("return"))
	check("game ambience resumes before ending",g.ambience.playing)
	await use_target("order",Vector3(-1.0,0.02,5.6))
	check("attendance choice reached",g.presentation.section == "register")
	g.presentation.buttons["Simon Ward / PRESENT"].pressed.emit()
	check("ending reached by interaction",g.ended and g.menu_open)
	check("ending menu ambience playback",g.presentation.menu_drone.playing)
	g.show_settings()
	await settle(5)
	check("settings fit viewport",g.menu.get_global_rect().position.y >= 0 and g.menu.get_global_rect().end.y <= g.get_viewport().get_visible_rect().size.y)
	g.set_volume(0)
	check("volume mute",AudioServer.is_bus_mute(0))
	g.set_volume(g.volume)
	var perf := frame_times.duplicate()
	perf.sort()
	var median: float = perf[perf.size()/2] if not perf.is_empty() else 0.0
	var p95: float = perf[int(perf.size()*0.95)] if not perf.is_empty() else 0.0
	print("PERFORMANCE median_ms=",median," p95_ms=",p95)
	var failed := 0
	for result in checks:
		if not result.passed: failed += 1
	var f := FileAccess.open(output.path_join("runtime_report.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"engine":Engine.get_version_info(),"frame_time_ms":{"median":median,"p95":p95,"samples":perf.size()}},"\t"))
	f.close()
	print("UNLISTED_QA_COMPLETE passed=",checks.size()-failed," failed=",failed)
	g.visible = false
	await RenderingServer.frame_post_draw
	await g.qa_exit(0 if failed == 0 else 1)
