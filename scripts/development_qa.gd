extends Node
var failed:=0
var checks: Array=[]
func check(value: bool,name_: String) -> void:
	checks.append({"test":name_,"passed":value})
	print("DEV_QA ","PASS " if value else "FAIL ",name_)
	if not value:failed+=1
func key(code: Key) -> void:
	var event:=InputEventKey.new();event.set_meta("unlisted_qa_input",true);event.physical_keycode=code;event.keycode=code;event.pressed=true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event=InputEventKey.new();event.set_meta("unlisted_qa_input",true);event.physical_keycode=code;event.keycode=code;event.pressed=false
	Input.parse_input_event(event)
	await get_tree().process_frame
func run(game: Node,dev: CanvasLayer) -> void:
	var output:=ProjectSettings.globalize_path("user://development/qa")
	DirAccess.make_dir_recursive_absolute(output)
	game.new_game();game.presentation.clear_transients()
	await get_tree().create_timer(0.3).timeout
	check(game.checkpoint_path=="user://development/checkpoint.json","checkpoint isolated")
	check(game.presentation.prefs.path=="user://development/settings.cfg","preferences isolated")
	await key(KEY_F1)
	check(dev.opened and get_tree().paused and not game.player.active,"F1 suspends and opens inspector")
	var before: Vector3=game.player.position
	check(not dev.teleport_to(Vector3(-8,0.08,-12)) and game.player.position==before,"read-only default rejects teleport")
	dev.armed.button_pressed=true
	check(not dev.teleport_to(Vector3(100,0,0)),"out-of-bounds rejected")
	check(not dev.teleport_to(Vector3(-7.5,0.08,-7)),"wall capsule rejected")
	check(dev.teleport_to(Vector3(-8,0.08,-12)),"service-yard bookmark clear")
	dev.take_snapshot();game.fuse=true
	dev.restore_snapshot()
	await get_tree().process_frame
	check(not game.fuse and game.player.active and not get_tree().paused,"isolated snapshot restores state and controls")
	await key(KEY_F1);dev.armed.button_pressed=true
	var position_before: Vector3=game.player.position
	dev.toggle_fly()
	check(dev.flying and get_tree().paused and dev.free_camera.current,"free camera holds world and player")
	var camera_before: Vector3=dev.free_camera.position
	Input.action_press("forward")
	await get_tree().create_timer(0.4).timeout
	Input.action_release("forward")
	check(dev.free_camera.position.distance_to(camera_before)>0.5 and game.player.position==position_before,"actual fly input moves only camera")
	await key(KEY_F1)
	check(dev.opened and dev.flying,"F1 inspects during flight")
	await key(KEY_ESCAPE)
	check(not dev.flying and not dev.opened and game.player.active and not get_tree().paused and game.player.camera.current,"Escape restores camera and gameplay")
	await key(KEY_F1)
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		var viewport:=game.get_viewport() as SubViewport
		viewport.size=size_;viewport.size_2d_override=Vector2i(roundi(720.0*float(size_.x)/size_.y),720)
		await get_tree().create_timer(0.2).timeout
		dev.refresh_diagnostics()
		await RenderingServer.frame_post_draw
		var rendered:=game.get_viewport().get_texture().get_image()
		check(rendered.get_size()==size_,"exact development render "+str(size_))
		rendered.save_png(output.path_join("F1_%dx%d.png"%[size_.x,size_.y]))
	await dev.capture()
	check(dev.status.text.begins_with("Screenshot:"),"screenshot capture returns a real file")
	await key(KEY_F1)
	await key(KEY_F1);dev.armed.button_pressed=true
	check(dev.teleport_to(Vector3(.3,.08,1)),"safe room-preview position")
	var room_preview: Button
	for node in dev.panel.find_children("*","Button",true,false):
		if node.text=="Preview room memory":room_preview=node
	check(room_preview!=null,"room-memory preview is exposed in actual F1 tools")
	if room_preview:
		room_preview.pressed.emit();await get_tree().create_timer(.2).timeout
		check(game.impossible_room.active and not dev.opened and game.player.active,"F1 preview uses the live room system and restores controls")
	game.new_game();await get_tree().create_timer(.2).timeout
	game.presentation.show_menu(true)
	await key(KEY_F1)
	check(dev.opened and get_tree().paused,"title inspection")
	await key(KEY_F1)
	check(get_tree().paused and not game.player.active and game.presentation.section=="title","title remains paused on close")
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failed":failed,"editor":OS.has_feature("editor"),"dev_feature":OS.has_feature("unlisted_dev")},"\t"));file.close()
	await game.qa_exit(0 if failed==0 else 1)
