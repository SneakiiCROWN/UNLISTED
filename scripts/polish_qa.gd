extends Node
var g: Node
var output := ""
var checks: Array[Dictionary] = []
func check(id: String,okay: bool,detail := "") -> void:
	checks.append({"name":id,"passed":okay,"detail":detail})
	print("POLISH_QA ","PASS " if okay else "FAIL ",id," ",detail)
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds,true,false,true).timeout
func until_done() -> void:
	for i in 150:
		if g.horror.audition=="":return
		await wait(0.1)
func shot(id: String) -> void:
	g.presentation.clear_transients();g.subtitle.text = "";g.caption_until = 0
	await RenderingServer.frame_post_draw
	check("capture "+id,g.get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))==OK)
func use_button(id: String) -> void:
	g.player.position = Vector3(3.3,0.03,-7.3)
	await wait(0.2)
	g.player.camera.look_at(g.targets[id].global_position)
	await wait(0.05)
	var ray: Dictionary = g.player.target()
	check("real transport ray "+id,not ray.is_empty() and ray.collider.get_meta("interaction","")==id,str(ray.get("position","none")))
	g.try_interact()
func run(game: Node) -> void:
	g = game
	output = ProjectSettings.globalize_path("res://qa") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA")
	g.checkpoint_path = output.path_join("polish_checkpoint.json")
	g.presentation.prefs.data = g.presentation.PREFS.DEFAULTS.duplicate();g.presentation.apply_preferences(false)
	g.new_game();g.presentation.clear_transients()
	g.presentation.show_exclusion()
	check("comparison requires both auditions",g.presentation.buttons["Exclude channel A"].disabled and g.presentation.buttons["Exclude channel B"].disabled)
	g.resume();await wait(0.2)
	g.player.position = Vector3(0,0.03,2.6);g.player.rotation.y = 0;g.player.camera.rotation = Vector3.ZERO
	Input.action_press("forward");await wait(3.5);Input.action_release("forward");await wait(0.3)
	check("new sequence uses actual recorded movement",g.events.get("memory_trace",[]).size()>=4)
	g.stage = 3;g.report_read = true;g.brass_key = true
	for l in g.lamps:l.light_energy = 0.8
	g.horror.house_responds()
	await use_button("audition_source")
	check("source audition starts in world",g.horror.audition=="A" and not g.menu_open)
	var reel: Node3D = get_tree().get_nodes_in_group("archive_reels")[0]
	var angle := reel.rotation.y;await wait(0.4)
	check("physical reels animate",absf(reel.rotation.y-angle)>0.2)
	g.show_menu("PAUSED");var clock: float = g.horror.audition_clock;await wait(0.3)
	check("pause suspends tape timeline",is_equal_approx(clock,g.horror.audition_clock))
	g.resume();await until_done()
	check("source audition completes without return",g.events.get("audition_A",false) and not g.events.get("audition_B",false))
	await use_button("audition_return");await until_done()
	check("return adds unrecorded arrival",g.events.get("audition_B",false) and g.horror.audition_tail)
	check("audition never creates a lethal actor",not g.threat.active() and not g.presence.visible)
	await use_button("exclude_return")
	check("comparison unlocks after listening",not g.presentation.buttons["Exclude channel B"].disabled)
	await wait(0.4);await shot("V01_channel_comparison")
	g.presentation.buttons["Exclude channel A"].pressed.emit();await wait(0.2)
	check("wrong comparison is recoverable",g.player.active and not g.events.get("memory_confirmed",false) and not g.ended)
	g.interact("exclude_return");g.presentation.buttons["Exclude channel B"].pressed.emit()
	check("correct comparison earns contextual record",g.events.get("memory_confirmed",false) and g.events.notes.has("SIMON / RETURN CHANNEL"))
	g.resume();await wait(0.5)
	check("physical receipt emerges",g.memory_receipt.visible)
	await shot("V02_transport_receipt")
	check("archive worker notices camera",absf(g.horror.feed_ghost.rotation.y)>0.1)
	g.save_game();g.load_game();await wait(0.3)
	check("memory deduction and receipt persist",g.events.get("memory_confirmed",false) and g.memory_receipt.visible and g.horror.audition=="")
	var interior = g.sound("step",Vector3(0,0,-4),-45)
	var cellar = g.sound("step",Vector3(0,-3,-18),-45)
	check("room-dependent acoustic buses",interior.bus=="HouseInterior" and cellar.bus=="HouseCellar")
	check("acoustics preserve SFX volume control",AudioServer.get_bus_send(AudioServer.get_bus_index("HouseInterior"))=="SFX" and AudioServer.get_bus_send(AudioServer.get_bus_index("HouseCellar"))=="SFX")
	var count := g.get_child_count();g.doors.utility.set_open(g.doors.utility.opened,0.01)
	check("save restoration does not bang doors",g.get_child_count()==count)
	g.player.position = Vector3(0,0.03,-4);g.player.camera.look_at(Vector3(0,1.4,2.6))
	g.threat.begin();g.threat.grace = 0;g.threat.change("observe")
	check("solid actor is visible to visibility test",g.horror.visible_to_player())
	for i in 30:
		if g.threat.state=="stalk":break
		await wait(0.1)
	check("initial detection stages a stalk",g.threat.state=="stalk")
	var pos: Vector3 = g.presence.position;await wait(0.4)
	check("observed stalk holds still",g.presence.position.distance_to(pos)<0.08)
	g.player.camera.rotate_y(PI);await wait(0.45)
	check("unobserved stalk approaches physically",g.presence.position.distance_to(pos)>0.06)
	g.player.camera.look_at(g.presence.position+Vector3(0,1.4,0))
	g.threat.change("retreat");g.threat.route.clear();g.threat.clock = 2.0
	await wait(0.7)
	check("retreat never vanishes in direct sight",g.presence.visible)
	g.player.camera.rotate_y(PI);await wait(0.4)
	check("retreat clears after occlusion",not g.presence.visible and g.presence.collision_layer==0)
	g.threat.reset();g.presence.position = Vector3(0,0,-7);g.presence.look_at(Vector3(0,0,-3));g.presence.visible = true
	g.player.position = Vector3(0,0.03,-3.7);g.player.camera.look_at(Vector3(0,1.3,-7));g.surveyor_actor.set_mode("watch")
	await wait(0.6);await shot("V03_refined_surveyor")
	check("skinned coat imported",g.surveyor_actor.figure.find_child("*inspection*",true,false)!=null)
	var failed := 0
	for item in checks:if not item.passed:failed += 1
	var f := FileAccess.open(output.path_join("polish_report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks},"\t"));f.close()
	print("POLISH_QA_COMPLETE passed=",checks.size()-failed," failed=",failed)
	for audio in g.find_children("*","AudioStreamPlayer3D",true,false):audio.stop()
	for audio in g.find_children("*","AudioStreamPlayer",true,false):audio.stop()
	await wait(0.5)
	get_tree().paused = false;await g.qa_exit(0 if failed==0 else 1)
