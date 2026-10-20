extends "res://scripts/recording_repair_qa.gd"
func synthetic_key(code: Key) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.pressed=true
	event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event);await wait(0.08)
	event=InputEventKey.new();event.keycode=code;event.pressed=false
	event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event);await wait(0.12)

func run(game: Node) -> void:
	g=game;await exact_resolution()
	output=OS.get_executable_path().get_base_dir().path_join("QA/input_isolation") if not OS.has_feature("editor") else ProjectSettings.globalize_path("res://qa/input_isolation")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	g.new_game();g.events.chair=true;g.threat.enabled=false
	g.horror.set_process(false);g.horror.set_physics_process(false)
	await wait(0.6)
	g.player.position=Vector3(-17.25,0.03,-15.2);g.player.rotation=Vector3.ZERO;g.player.velocity=Vector3.ZERO
	g.player.camera.look_at(g.physical.props.spare.global_position);await wait(0.2)
	await action("interact");await wait(0.5)
	check("synthetic interaction picks up real scrap",g.physical.held==g.physical.props.spare)
	check("carried scrap retains support hand",g.physical.support.visible)
	var ignored: int=g.qa_input_guard.ignored_events
	var physical:=InputEventMouseButton.new();physical.button_index=MOUSE_BUTTON_LEFT;physical.pressed=true
	Input.parse_input_event(physical);await wait(0.1)
	physical=InputEventMouseButton.new();physical.button_index=MOUSE_BUTTON_LEFT;physical.pressed=false;Input.parse_input_event(physical)
	var key:=InputEventKey.new();key.keycode=KEY_E;key.physical_keycode=KEY_E;key.pressed=true
	Input.parse_input_event(key);await wait(0.1)
	key=InputEventKey.new();key.keycode=KEY_E;key.physical_keycode=KEY_E;key.pressed=false;Input.parse_input_event(key)
	await wait(0.1)
	check("unmarked desktop click and E cannot throw or release",g.physical.held==g.physical.props.spare)
	check("unmarked events rejected before private game",g.qa_input_guard.ignored_events>=ignored+4)
	key=InputEventKey.new();key.keycode=KEY_W;key.physical_keycode=KEY_W;key.pressed=true;Input.parse_input_event(key)
	await wait(0.15)
	check("desktop movement key cannot enter polling state",Input.get_vector("left","right","forward","back")==Vector2.ZERO)
	key=InputEventKey.new();key.keycode=KEY_W;key.physical_keycode=KEY_W;key.pressed=false;Input.parse_input_event(key)
	check("automated tests never capture desktop cursor",Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	check("test window rejects focus and passes mouse through",get_tree().root.get_flag(Window.FLAG_NO_FOCUS) and get_tree().root.get_flag(Window.FLAG_MOUSE_PASSTHROUGH))
	await shot("isolated_scrap_carry")
	await action("interact");await wait(0.2)
	check("synthetic release remains functional",g.physical.held==null)
	g.player.position=Vector3(0,0.03,-4);g.player.rotation=Vector3.ZERO;g.player.camera.rotation=Vector3.ZERO;g.player.velocity=Vector3.ZERO
	await wait(0.2);var origin: Vector3=g.player.position
	Input.action_press("forward");await wait(0.35);Input.action_release("forward")
	check("synthetic movement still drives actual physics",g.player.position.distance_to(origin)>0.35)
	await synthetic_key(KEY_ESCAPE)
	check("marked Escape opens real pause",g.presentation.section=="pause" and get_tree().paused)
	await synthetic_key(KEY_ESCAPE)
	check("marked Escape resumes real controls",g.presentation.section=="game" and g.player.active)
	g.presentation.show_menu(true);g.presentation.buttons["New Game"].grab_focus()
	await synthetic_key(KEY_ENTER)
	check("marked Enter activates focused menu button",g.presentation.section=="intro")
	await synthetic_key(KEY_SPACE)
	check("marked Space skips intro to actual gameplay",g.presentation.section=="game" and g.player.active)
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Private automated game viewport only; no desktop hooks, activity monitoring, global key logging or blocked input to other applications."},"\t"));file.close()
	print("INPUT_ISOLATION_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
