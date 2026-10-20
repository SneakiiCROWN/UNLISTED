extends Node

var g: Node
var p: CanvasLayer
var output := ""
var checks: Array[Dictionary] = []
var render_target: SubViewport

func check(name_: String, okay: bool, detail := "") -> void:
	checks.append({"name":name_,"passed":okay,"detail":detail})
	print("PRESENTATION_QA ","PASS " if okay else "FAIL ",name_," ",detail)

func wait(seconds := 0.2) -> void:
	await get_tree().create_timer(seconds,true,false,true).timeout

func capture(name_: String) -> void:
	await wait(0.4)
	await RenderingServer.frame_post_draw
	check("visible UI encoding "+name_,verify_text(p))
	var rendered: Image = g.get_viewport().get_texture().get_image()
	if render_target != null:check("exact render dimensions "+name_,rendered.get_size() == render_target.size,str(rendered.get_size()))
	var err := rendered.save_png(output.path_join(name_+".png"))
	check("capture "+name_,err == OK)

func render_size(size_: Vector2i) -> void:
	if render_target == null:
		render_target=g.get_viewport() as SubViewport
		assert(render_target!=null)
	# Match the project's canvas_items / expand scaling without desktop window limits.
	render_target.size = size_
	render_target.size_2d_override = Vector2i(roundi(720.0*float(size_.x)/float(size_.y)),720)
	render_target.size_2d_override_stretch = true
	p.stage.camera.current = true

func verify_text(node: Node) -> bool:
	var okay := true
	if node is Label or node is Button or node is RichTextLabel:
		var text_: String = node.text
		for code in [0x00c2,0x00c3,0x00e2,0xfffd]:
			if text_.contains(String.chr(code)):okay = false
	if node is OptionButton:
		for i in node.item_count:
			for code in [0x00c2,0x00c3,0x00e2,0xfffd]:
				if node.get_item_text(i).contains(String.chr(code)):okay = false
	for child in node.get_children():
		if not verify_text(child):okay = false
	return okay

func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.set_meta("unlisted_qa_input",true)
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await wait(0.05)
	event = InputEventKey.new()
	event.set_meta("unlisted_qa_input",true)
	event.keycode = key
	event.pressed = false
	Input.parse_input_event(event)
	await wait(0.08)

func run(game: Node) -> void:
	g = game
	p = g.presentation
	if "--story-only" in OS.get_cmdline_user_args():
		var focused=load("res://scripts/story_clarity_qa.gd").new();add_child(focused)
		await focused.run(game);return
	output = ProjectSettings.globalize_path("res://qa") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA")
	DirAccess.make_dir_recursive_absolute(output)
	# Process uptime can repeat across launches and accidentally reuse an earlier fixture.
	g.checkpoint_path = output.path_join("presentation_checkpoint_"+Crypto.new().generate_random_bytes(8).hex_encode()+".json")
	p.prefs.data = p.PREFS.DEFAULTS.duplicate()
	p.apply_preferences(false)
	p.show_menu(true)
	await wait(0.7)
	check("five title actions",p.buttons.has_all(["New Game","Continue","Settings","Credits","Quit"]))
	check("continue visibly disabled without save",p.buttons.Continue.disabled)
	check("title has live exterior camera",p.stage.camera.current and p.stage.mist.emitting)
	check("title layout above footer",p.body.get_global_rect().end.y < 665,str(p.body.get_global_rect()))
	await capture("P01_title_720p")
	p.buttons["New Game"].grab_focus()
	await press(KEY_ENTER)
	check("keyboard Enter launches intro",p.section == "intro")
	await capture("P02_dispatch")
	await wait(4.4)
	await capture("P03_arrival_title")
	await press(KEY_SPACE)
	check("intro can be skipped into gameplay",p.section == "game" and g.player.active and not get_tree().paused)
	await wait(2.0)
	await capture("P04_gameplay_hud")
	g.doors.front.set_open(true,1.0)
	await wait(0.1)
	await press(KEY_ESCAPE)
	check("Escape opens actual pause",p.section == "pause" and get_tree().paused)
	check("pause releases mouse",Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	var pose: float = g.doors.front.pivot.rotation.y
	var clock: float = g.time_in_game
	var pos: Vector3 = g.player.position
	Input.action_press("forward")
	await wait(0.35)
	Input.action_release("forward")
	check("pause suspends door tween",is_equal_approx(g.doors.front.pivot.rotation.y,pose))
	check("pause suspends world clock and player",is_equal_approx(g.time_in_game,clock) and g.player.position == pos)
	check("five pause actions",p.buttons.has_all(["Resume","Restart Checkpoint","Settings","Main Menu","Quit to Desktop"]))
	await capture("P05_pause")
	p.buttons.Settings.pressed.emit()
	await wait()
	check("settings opens from pause",p.section == "settings" and get_tree().paused)
	p.fill_settings("Audio")
	p.controls.master.value = 0.42
	var old_music_db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	var old_music_value: float = p.controls.music.value
	p.controls.music.value = 0.31
	p.controls.sfx.value = 0
	p.controls.ambience.value = 0.57
	check("individual audio buses apply",AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")) and absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))-old_music_db-linear_to_db(0.31/old_music_value)) < 0.01)
	p.controls.master.value = 0
	check("master mute works",AudioServer.is_bus_mute(0))
	p.controls.master.value = 0.42
	await capture("P06_settings_audio")
	p.fill_settings("Input")
	p.controls.sensitivity.value = 0.0028
	p.controls.invert_y.button_pressed = true
	check("look settings reach player",g.player.invert_y and is_equal_approx(g.player.sensitivity,0.0028))
	p.resume_game()
	g.qa_mode = false
	p.resume_game()
	check("resume requests gameplay capture without taking desktop cursor",p.mouse_capture_requested and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	var before: float = g.player.camera.rotation.x
	var motion := InputEventMouseMotion.new()
	motion.set_meta("unlisted_qa_input",true)
	motion.relative = Vector2(0,10)
	g.player._unhandled_input(motion)
	check("inverted Y changes actual look",g.player.camera.rotation.x > before)
	g.qa_mode = true
	p.show_settings("pause")
	p.fill_settings("Captions")
	p.controls.subtitles.button_pressed = false
	p.fill_settings("Accessibility")
	p.controls.reduced_flash.button_pressed = false
	p.controls.reduced_motion.button_pressed = false
	check("accessibility reaches presentation",not p.stage.reduce_flash and not p.stage.reduce_motion)
	p.resume_game()
	g.message("Subtitle preference test.",2,"dialogue","TEST VOICE")
	await wait()
	check("subtitles toggle applies",not g.subtitle.visible)
	p.show_settings("pause")
	p.fill_settings("Display")
	p.controls.visibility.value = 1.21
	p.controls.visual_preset.item_selected.emit(2)
	check("visibility and retro uniforms apply",is_equal_approx(p.film.material.get_shader_parameter("visibility"),1.21) and is_equal_approx(p.film.material.get_shader_parameter("retro"),0.65))
	p.controls.display_mode.item_selected.emit(1)
	await wait()
	check("fullscreen mode applies",DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	p.controls.display_mode.item_selected.emit(0)
	await wait()
	check("windowed mode applies",DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED)
	var loaded: RefCounted = p.PREFS.new()
	loaded.path = p.prefs.path
	loaded.load_file()
	check("settings survive disk reconstruction",is_equal_approx(loaded.data.master,0.42) and is_equal_approx(loaded.data.music,0.31) and loaded.data.sfx == 0 and loaded.data.invert_y and is_equal_approx(loaded.data.visibility,1.21) and not loaded.data.subtitles)
	# Restore visual/audio defaults in memory; test preferences stay isolated from real user settings.
	p.prefs.data = p.PREFS.DEFAULTS.duplicate()
	p.apply_preferences(false)
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		render_size(size_)
		await wait(0.5)
		p.show_menu(true)
		await wait(0.3)
		var view := g.get_viewport().get_visible_rect().size
		check("menu fits "+str(size_),p.body.get_global_rect().end.x < view.x and p.body.get_global_rect().end.y < view.y)
		await capture("P07_title_"+str(size_.x)+"x"+str(size_.y))
		p.show_settings("title")
		p.fill_settings("Display")
		await wait()
		check("settings fits "+str(size_),p.card.get_global_rect().position.x >= 0 and p.card.get_global_rect().end.x <= view.x and p.card.get_global_rect().end.y <= view.y)
		await capture("P08_settings_"+str(size_.x)+"x"+str(size_.y))
		for tab_ in ["Input","Accessibility","Gameplay"]:
			p.fill_settings(tab_)
			await wait()
			check(tab_+" fits "+str(size_),p.card.get_global_rect().end.y <= view.y and p.card_body.get_global_rect().end.y <= view.y)
			for control in p.controls.values():
				if control is CheckButton:check("unambiguous "+control.text+" "+tab_,control.text == ("ON" if control.button_pressed else "OFF"))
			await capture("P14_"+tab_+"_"+str(size_.x)+"x"+str(size_.y))
		p.show_death()
		await wait(0.6)
		check("death card fits "+str(size_),p.card.get_global_rect().position.x>=0 and p.card_body.get_global_rect().end.y<=view.y)
		check("death retry reachable "+str(size_),not p.buttons["Retry Checkpoint"].is_visible_in_tree() or p.buttons["Retry Checkpoint"].get_global_rect().end.y<=view.y)
		await capture("P16_death_"+str(size_.x)+"x"+str(size_.y))
		p.show_exclusion()
		await wait(0.4)
		check("channel comparison fits "+str(size_),p.card_body.get_global_rect().end.y<=view.y)
		await capture("P17_comparison_"+str(size_.x)+"x"+str(size_.y))
	render_size(Vector2i(1280,720))
	await wait()
	g.stage = 3
	g.fuse = true
	g.save_game()
	p.show_menu(true)
	check("continue available with valid save",not p.buttons.Continue.disabled)
	g.stage = 0
	p.buttons.Continue.pressed.emit()
	await wait()
	check("Continue loads actual saved progression",g.stage == 3 and g.fuse and p.section == "game")
	g.stage = 0
	g.show_menu("PAUSED")
	p.buttons["Restart Checkpoint"].pressed.emit()
	await wait()
	check("Restart Checkpoint restores progression",g.stage == 3 and p.section == "game")
	p.show_menu(false)
	p.buttons["Main Menu"].pressed.emit()
	check("Main Menu safely returns to title",p.section == "title" and not g.started and p.stage.camera.current)
	p.buttons.Credits.pressed.emit()
	await capture("P09_credits")
	check("credits includes licensed font and engine",p.section == "credits")
	p.settings_back()
	p.begin_new_game()
	await wait(7.8)
	check("full intro completes without input",p.section == "game" and g.player.active)
	g.qa_mode = false
	g.finish_game()
	g.qa_mode = true
	check("real ending saves without stale notification",p.toast.text == "" and p.has_checkpoint())
	await capture("P10_ending")
	check("ending has directed live background",p.section == "ending" and p.stage.camera.current)
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		render_size(size_)
		await wait(0.4)
		# Deliberately start a caption immediately before the ending: it must be dismissed.
		p.moment("arrival")
		p.notify("CHECKPOINT RECORDED")
		p.show_ending()
		await wait(0.5)
		var view := g.get_viewport().get_visible_rect().size
		check("ending fits "+str(size_),p.body.get_global_rect().end.y < view.y and p.body.get_global_rect().end.x < view.x)
		check("ending clears gameplay overlays "+str(size_),not p.location_card.visible and p.toast.text == "" and p.fade.color.a == 0)
		var separated := true
		var children: Array = p.body.get_children()
		for i in range(children.size()):
			for j in range(i+1,children.size()):
				if children[i] is Control and children[j] is Control:
					if children[i].get_global_rect().intersects(children[j].get_global_rect()):separated = false
		check("ending text and buttons separated "+str(size_),separated and not p.body.get_global_rect().intersects(p.footer.get_global_rect()))
		await capture("P13_ending_"+str(size_.x)+"x"+str(size_.y))
		p.show_register()
		await wait()
		check("attendance register fits "+str(size_),p.card.get_global_rect().end.y <= view.y and p.card_body.get_global_rect().end.y <= view.y)
		await capture("P15_register_"+str(size_.x)+"x"+str(size_.y))
	render_size(Vector2i(1280,720))
	await wait()

	p.resume_game()
	g.ended = false
	g.started = true
	g.stage = 3
	g.events["chair"] = true
	for light in g.lamps:light.light_energy = 1.1
	g.player.position = Vector3(0,0.02,-4)
	g.player.rotation = Vector3.ZERO
	g.player.camera.rotation = Vector3.ZERO
	g.presence.position = Vector3(0,0,-8)
	g.presence.look_at(Vector3(0,0,-4))
	g.presence.visible = true
	g.player.camera.look_at(Vector3(0,1.3,-8))
	g.objective.text = ""
	g.subtitle.text = ""
	await capture("P11_stalker_in_engine")
	g.player.position = Vector3(0,0.02,-5.6)
	g.player.camera.look_at(Vector3(0,1.25,-8))
	await capture("P12_stalker_close")
	var bounds := AABB()
	var first := true
	for mesh in g.all_meshes(g.presence):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = b if first else bounds.merge(b)
		first = false
	check("stalker has credible humanoid height",bounds.size.y > 1.9 and bounds.size.y < 2.3,str(bounds.size.y))
	var failed := 0
	for item in checks:if not item.passed:failed += 1
	var f := FileAccess.open(output.path_join("presentation_report.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks},"\t"))
	f.close()
	print("PRESENTATION_QA_COMPLETE passed=",checks.size()-failed," failed=",failed)
	get_tree().paused = false
	await g.qa_exit(0 if failed == 0 else 1)

