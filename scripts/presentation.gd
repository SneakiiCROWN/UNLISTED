extends CanvasLayer

const PREFS = preload("res://scripts/preferences.gd")
const STAGE = preload("res://scripts/menu_stage.gd")
const MENU_BUTTON = preload("res://scenes/ui/menu_button.tscn")
const THEME = preload("res://themes/unlisted.tres")
var game: Node
var pending_notice := ""
var prefs: RefCounted
var stage: Node3D
var screen: Control
var film: ColorRect
var cover_amount:=0.0
var shade: TextureRect
var body: VBoxContainer
var card: PanelContainer
var card_body: VBoxContainer
var tabs: HBoxContainer
var rows: VBoxContainer
var note: RichTextLabel
var hud: Control
var objective: Label
var reticle: Label
var prompt: Label
var subtitle: Label
var toast: Label
var main_title: Label
var status: Label
var section := "title"
var settings_origin := "title"
var mouse_capture_requested:=false
var pending_moment := ""
var controls: Dictionary = {}
var buttons: Dictionary = {}
var ambience: AudioStreamPlayer
var creak: AudioStreamPlayer
var menu_drone: AudioStreamPlayer
var atmosphere_time := 0.0
var location_card: VBoxContainer
var fade: ColorRect
var transition: Tween
var moment_tween: Tween
var arrival_fade: Tween
var arrival_lens: Tween
var footer: Label
var last_tab := "Audio"
var display_resolution := Vector2i(1280,720)
var intro_text: VBoxContainer
var intro_tween: Tween
var death_backing: ColorRect
var resume_requested := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	prefs = PREFS.new()
	if game.dev_mode:prefs.path = "user://development/settings.cfg"
	if game.qa_mode:
		var dir := ProjectSettings.globalize_path("res://qa") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA")
		DirAccess.make_dir_recursive_absolute(dir)
		prefs.path = dir.path_join("presentation_settings.cfg")
	prefs.load_file()
	prefs.ensure_buses()
	stage = Node3D.new()
	stage.set_script(STAGE)
	stage.game = game
	game.add_child(stage)
	build_screen()
	apply_preferences(not game.qa_mode)
	setup_sound()

func full(control: Control, parent: Node) -> void:
	parent.add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func anchored(control: Control, preset: Control.LayoutPreset, rect: Rect2) -> void:
	control.set_anchors_and_offsets_preset(preset)
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y

func label(parent: Node, text: String, size := 20, type_ := "") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size",size)
	if type_ != "":l.theme_type_variation = type_
	parent.add_child(l)
	return l

func rule(parent: Node) -> void:
	var line := ColorRect.new()
	line.color = Color(0.45,0.57,0.58,0.3)
	line.custom_minimum_size = Vector2(0,1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func build_screen() -> void:
	screen = Control.new()
	full(screen,self)
	screen.theme = THEME
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	film = ColorRect.new()
	full(film,screen)
	film.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := ShaderMaterial.new()
	shader.shader = load("res://shaders/film.gdshader")
	film.material = shader
	death_backing = ColorRect.new()
	full(death_backing,screen)
	death_backing.color = Color("080d10")
	death_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_backing.visible = false
	shade = TextureRect.new()
	full(shade,screen)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0,0.38,0.72,1])
	gradient.colors = PackedColorArray([Color(0.015,0.025,0.032,0.96),Color(0.015,0.025,0.032,0.84),Color(0.015,0.025,0.032,0.25),Color(0.015,0.025,0.032,0.06)])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2.ZERO
	gradient_texture.fill_to = Vector2(1,0)
	shade.texture = gradient_texture
	body = VBoxContainer.new()
	screen.add_child(body)
	body.position = Vector2(95,108)
	body.custom_minimum_size = Vector2(470,0)
	body.add_theme_constant_override("separation",4)
	status = label(screen,"PROPERTY SERVICES    /    NIGHT REGISTER",15,"Meta")
	status.position = Vector2(95,51)
	status.modulate = Color("829998")
	footer = label(screen,"17 BRIAR LANE     /     23:17     /     OCCUPANCY: UNCONFIRMED",14,"Meta")
	anchored(footer,Control.PRESET_BOTTOM_LEFT,Rect2(95,-48,1080,22))
	footer.modulate = Color("80928f")
	card = PanelContainer.new()
	screen.add_child(card)
	anchored(card,Control.PRESET_CENTER,Rect2(-470,-300,940,600))
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.025,0.043,0.052,0.97)
	background.border_width_left = 1
	background.border_width_top = 1
	background.border_color = Color(0.40,0.53,0.52,0.45)
	background.content_margin_left = 38
	background.content_margin_right = 38
	background.content_margin_top = 25
	background.content_margin_bottom = 25
	card.add_theme_stylebox_override("panel",background)
	card_body = VBoxContainer.new()
	card_body.add_theme_constant_override("separation",12)
	card.add_child(card_body)
	card.visible = false
	note = RichTextLabel.new()
	full(note,card_body)
	note.bbcode_enabled = true
	note.custom_minimum_size = Vector2(800,420)
	note.add_theme_font_size_override("normal_font_size",22)
	note.visible = false
	hud = Control.new()
	full(hud,screen)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := VBoxContainer.new()
	hud.add_child(h)
	anchored(h,Control.PRESET_BOTTOM_LEFT,Rect2(36,-155,730,60))
	var tag := label(h,"PROPERTY SERVICES  /  CALL 017",13,"Meta")
	tag.visible = false
	objective = label(h,"",18)
	objective.modulate = Color("c7cec5")
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size.x = 720
	prompt = label(hud,"",23)
	anchored(prompt,Control.PRESET_BOTTOM_LEFT,Rect2(44,-78,840,38))
	prompt.add_theme_color_override("font_shadow_color",Color(0,0,0,0.95))
	prompt.add_theme_constant_override("shadow_offset_x",2)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	reticle = label(hud,"+",18)
	anchored(reticle,Control.PRESET_CENTER,Rect2(-3,-10,6,20))
	reticle.modulate = Color(0.7,0.8,0.77,0.45)
	subtitle = label(hud,"",21)
	anchored(subtitle,Control.PRESET_CENTER_BOTTOM,Rect2(-410,-220,820,125))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast = label(screen,"",15,"Meta")
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	anchored(toast,Control.PRESET_BOTTOM_RIGHT,Rect2(-510,-72,470,48))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	toast.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	location_card = VBoxContainer.new()
	screen.add_child(location_card)
	location_card.position = Vector2(45,480)
	location_card.modulate.a = 0
	label(location_card,"",16,"Meta").name = "MomentTag"
	label(location_card,"",28,"Title").name = "MomentTitle"
	fade = ColorRect.new()
	full(fade,screen)
	fade.color = Color(0.008,0.013,0.018,0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_text = VBoxContainer.new()
	screen.add_child(intro_text)
	anchored(intro_text,Control.PRESET_CENTER,Rect2(-440,-85,880,170))
	intro_text.visible = false

func setup_sound() -> void:
	ambience = AudioStreamPlayer.new()
	ambience.stream = load("res://assets/audio/wind.wav")
	ambience.bus = "Ambience"
	ambience.volume_db = -17
	add_child(ambience)
	ambience.finished.connect(ambience.play)
	ambience.play()
	menu_drone = AudioStreamPlayer.new()
	menu_drone.stream = load("res://assets/audio/hollow.wav")
	menu_drone.bus = "Music"
	menu_drone.volume_db = -33
	add_child(menu_drone)
	menu_drone.finished.connect(menu_drone.play)
	menu_drone.play()
	creak = AudioStreamPlayer.new()
	creak.stream = load("res://assets/audio/foley/drop_wood_2.wav")
	creak.bus = "SFX"
	creak.volume_db = -31
	add_child(creak)

func clear_body() -> void:
	for child in body.get_children():body.remove_child(child);child.queue_free()
	buttons.clear()

func add_button(text: String, callback: Callable, enabled := true, parent: Node = null) -> Button:
	var b: Button = MENU_BUTTON.instantiate()
	b.text = text
	b.disabled = not enabled
	(body if parent == null else parent).add_child(b)
	b.pressed.connect(func(): click_sound(); callback.call())
	b.mouse_entered.connect(func(): if not b.disabled:b.grab_focus())
	buttons[text] = b
	return b

func click_sound() -> void:
	var audio := AudioStreamPlayer.new()
	audio.stream = load("res://assets/audio/latch.wav")
	audio.bus = "SFX"
	audio.volume_db = -30
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()

func pause_world() -> void:
	resume_requested = false
	game.menu_open = true
	game.player.active = false
	game.player.velocity = Vector3.ZERO
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.visible = false

func show_menu(main: bool) -> void:
	death_backing.visible = false
	clear_transients()
	footer.visible = true
	footer.text = "17 BRIAR LANE     /     23:17     /     OCCUPANCY: UNCONFIRMED"
	pause_world()
	section = "title" if main else "pause"
	stage.set_active(main)
	if not main:game.player.camera.current = true
	card.visible = false
	note.visible = false
	body.visible = true
	shade.visible = true
	status.visible = true
	clear_body()
	label(body,"A NIGHT CALL AT 17 BRIAR LANE" if main else "WORK ORDER 017  /  IN PROGRESS",15,"Meta").modulate = Color("a5b4aa")
	main_title = label(body,"UNLISTED" if main else "PAUSED",82 if main else 58,"Title")
	main_title.modulate = Color("e1e2d8")
	var desc := label(body,"No Record. No Exit." if main else "The house can wait.",19)
	desc.modulate = Color("94a4a2")
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 12
	body.add_child(spacer)
	if main:
		add_button("New Game",begin_new_game)
		var completed := false
		if has_checkpoint():
			var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.checkpoint_path))
			completed = saved.get("ended",false)
		add_button("View Ending" if completed else "Continue",game.load_game,has_checkpoint())
		add_button("Settings",func(): show_settings("title"))
		add_button("Credits",show_credits)
		add_button("Quit",func(): get_tree().quit())
	else:
		add_button("Resume",resume_game)
		if is_instance_valid(game.recount) and game.recount.active:
			add_button("Skip recount",func():game.recount.complete(true);resume_game())
		add_button("Restart Checkpoint",restart_checkpoint,has_checkpoint())
		add_button("Settings",func(): show_settings("pause"))
		add_button("Main Menu",return_to_title)
		add_button("Quit to Desktop",quit_game)
	rule(body)
	label(body,"ENTER  SELECT     UP / DOWN  NAVIGATE     ESC  BACK",12,"Meta").modulate = Color("728988")
	if main:buttons["New Game"].grab_focus()
	else:buttons["Resume"].grab_focus()
	entrance_animation(body)

func has_checkpoint() -> bool:
	if not FileAccess.file_exists(game.checkpoint_path):return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(game.checkpoint_path))
	return data is Dictionary and data.get("schema",0) == 1 and data.get("pos",[]).size() == 3

func entrance_animation(control: Control) -> void:
	if transition and transition.is_valid():transition.kill()
	control.modulate.a = 0
	transition = create_tween()
	transition.tween_property(control,"modulate:a",1.0,0.28)

func resume_game() -> void:
	# Resuming in a physics-frame signal can step active rigid bodies twice before
	# their pending state queries flush. Complete that request in the idle UI pass.
	if get_tree().paused and Engine.is_in_physics_frame():
		resume_requested = true
		return
	resume_now()

func resume_now() -> void:
	resume_requested = false
	death_backing.visible = false
	footer.visible = false
	get_tree().paused = false
	game.menu_open = false
	game.player.active = true
	game.player.camera.current = true
	stage.set_active(false)
	section = "game"
	body.visible = false
	shade.visible = false
	card.visible = false
	note.visible = false
	status.visible = false
	hud.visible = true
	mouse_capture_requested=not game.qa_mode
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_capture_requested and not game.automated_qa else Input.MOUSE_MODE_VISIBLE
	if pending_moment != "":moment(pending_moment);pending_moment = ""
	if pending_notice!="":notify(pending_notice);pending_notice = ""
	if is_instance_valid(game.capture_director) and game.capture_director.active:
		game.menu_open=true;game.player.active=false
		section="capture";hud.visible=false

func return_to_title() -> void:
	if game.started and not game.ended and section != "dead":game.save_game()
	if is_instance_valid(game.capture_director):game.capture_director.cancel()
	game.started = false
	show_menu(true)

func quit_game() -> void:
	if game.started and not game.ended and section != "dead":game.save_game()
	get_tree().quit()

func restart_checkpoint() -> void:
	if has_checkpoint():game.load_game();notify("CHECKPOINT RESTORED")

func intro_lines(tag: String, title_: String, small: String) -> void:
	for child in intro_text.get_children():intro_text.remove_child(child);child.queue_free()
	var a := label(intro_text,tag,15,"Meta")
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a.modulate = Color("8fa5a2")
	var b := label(intro_text,title_,56,"Title")
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var c := label(intro_text,small,18)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func begin_new_game() -> void:
	clear_transients()
	footer.visible = false
	pause_world()
	section = "intro"
	body.visible = false
	card.visible = false
	shade.visible = false
	status.visible = false
	stage.set_active(true)
	intro_text.visible = true
	fade.color.a = 1
	intro_lines("ELI WARD / NIGHT CALL-OUT","17 BRIAR LANE","My father disappeared on a job here in 1998.\nTonight the same address turned up on my call sheet.")
	intro_tween = create_tween()
	intro_tween.tween_interval(5.0)
	intro_tween.tween_callback(func():intro_text.visible = false)
	intro_tween.tween_property(fade,"color:a",0.0,1.0)
	intro_tween.tween_interval(1.3)
	intro_tween.tween_callback(func():intro_lines("17 BRIAR LANE","UNLISTED","No Record. No Exit.");intro_text.visible = true;intro_text.modulate.a = 0)
	intro_tween.tween_property(intro_text,"modulate:a",1.0,0.9)
	intro_tween.tween_interval(0.8)
	intro_tween.tween_property(fade,"color:a",1.0,0.7)
	intro_tween.tween_callback(complete_intro)
	toast.text = "SPACE / E / ESC  SKIP"
	toast.modulate.a = 0.65

func complete_intro() -> void:
	if intro_tween and intro_tween.is_valid():intro_tween.kill()
	intro_text.visible = false
	intro_text.modulate.a = 1
	toast.text = ""
	game.new_game()

func clear_card() -> void:
	status.visible = false
	for child in card_body.get_children():
		if child == note:note.visible = false;continue
		card_body.remove_child(child)
		child.queue_free()
	card.visible = true
	body.visible = false
	controls.clear()

func show_settings(origin := "") -> void:
	if origin != "":settings_origin = origin
	elif section in ["title","pause","ending"]:settings_origin = section
	pause_world()
	section = "settings"
	clear_card()
	label(card_body,"PREFERENCES  /  PROPERTY SERVICES",14,"Meta").modulate = Color("8ca4a1")
	label(card_body,"SETTINGS",32,"Title")
	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation",8)
	card_body.add_child(tabs)
	for name_ in ["Audio","Input","Display","Captions","Accessibility","Gameplay"]:
		var b := Button.new()
		b.text = name_
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		b.pressed.connect(func(): fill_settings(name_))
	rule(card_body)
	rows = VBoxContainer.new()
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",14)
	card_body.add_child(rows)
	fill_settings(last_tab)
	var back := HBoxContainer.new()
	card_body.add_child(back)
	var explanation := label(back,"Changes save automatically.",15,"Meta")
	explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var b := add_button("Back",settings_back,true,back)
	b.custom_minimum_size.x = 120
	entrance_animation(card)
	for tab_button in tabs.get_children():
		if tab_button.text == last_tab:tab_button.grab_focus()

func setting_row(text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 42
	row.add_theme_constant_override("separation",28)
	rows.add_child(row)
	var l := label(row,text,20)
	l.custom_minimum_size.x = 280
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return row

func slider(key: String, text: String, min_: float, max_: float, step_: float, percent := true) -> void:
	var row := setting_row(text)
	var s := HSlider.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.min_value = min_
	s.max_value = max_
	s.step = step_
	s.value = prefs.data[key]
	s.custom_minimum_size.x = 250
	row.add_child(s)
	var value_label := label(row,"",17,"Meta")
	value_label.custom_minimum_size.x = 65
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.text = str(roundi(s.value*100))+"%" if percent else str(snappedf(s.value*1000,0.1))
	controls[key] = s
	s.value_changed.connect(func(value):
		prefs.data[key] = value
		value_label.text = str(roundi(value*100))+"%" if percent else str(snappedf(value*1000,0.1))
		apply_preferences(false)
		persist())

func toggle(key: String, text: String) -> void:
	var row := setting_row(text)
	var b := CheckButton.new()
	b.text = "ON" if prefs.data[key] else "OFF"
	b.button_pressed = prefs.data[key]
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(b)
	controls[key] = b
	b.toggled.connect(func(value):b.text = "ON" if value else "OFF";prefs.data[key] = value;apply_preferences(false);persist())

func fill_settings(tab: String) -> void:
	last_tab = tab
	for child in rows.get_children():rows.remove_child(child);child.queue_free()
	controls.clear()
	for b in tabs.get_children():
		b.modulate = Color("e0d8b7") if b.text == tab else Color("8da3a1")
		if b.text == tab:b.grab_focus()
	match tab:
		"Gameplay":
			toggle("story_mode","Story mode / survive capture")
			label(rows,"Standard play includes one lethal, escapable encounter.\nStory mode keeps the encounter but prevents death.\nYou can outrun the Surveyor. Doors and corners break sight;\nquiet movement gives it less to follow.",18)
		"Audio":
			for pair in [["master","Master volume"],["music","Music / tonal score"],["sfx","Sound effects"],["ambience","Environmental ambience"]]:slider(pair[0],pair[1],0,1,0.01)
			label(rows,"The house is quiet by design. Listen before you move.",15,"Meta").modulate = Color("839b98")
		"Input":
			slider("sensitivity","Mouse sensitivity",0.0005,0.006,0.0001,false)
			toggle("invert_y","Invert vertical look")
			toggle("reminders","Brief first-use reminders")
			label(rows,"WASD  MOVE    SHIFT  SPRINT    CTRL  CROUCH\nE  INTERACT    F  FLASHLIGHT    ESC  PAUSE\nJ  FIELD NOTES    H  OPTIONAL HINT\nCARRIED PROPS: E RELEASE / LEFT MOUSE THROW / R ROTATE",17,"Meta")
		"Display":
			var row := setting_row("Display mode")
			var mode := OptionButton.new()
			mode.add_item("Windowed")
			mode.add_item("Borderless fullscreen")
			mode.selected = prefs.data.display_mode
			mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(mode)
			controls.display_mode = mode
			mode.item_selected.connect(func(idx):prefs.data.display_mode = idx;apply_display();persist())
			row = setting_row("Window resolution")
			var res := OptionButton.new()
			var resolutions := [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]
			for size_ in resolutions:res.add_item(str(size_.x)+" x "+str(size_.y))
			res.selected = maxi(0,resolutions.find(prefs.data.resolution))
			res.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(res)
			controls.resolution = res
			res.item_selected.connect(func(idx):prefs.data.resolution = resolutions[idx];apply_display();persist())
			slider("visibility","Visibility / exposure",0.8,1.5,0.01)
			row = setting_row("World presentation")
			var preset := OptionButton.new()
			for name_ in ["Clean","Modern PSX","Stronger Retro"]:preset.add_item(name_)
			preset.selected = prefs.data.visual_preset
			preset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(preset)
			controls.visual_preset = preset
			preset.item_selected.connect(func(idx):prefs.data.visual_preset = idx;prefs.data.retro = [0.0,0.32,0.65][idx];apply_preferences(false);persist())
			label(rows,"Fullscreen uses your desktop resolution. Text remains crisp.",15,"Meta")
		"Captions":
			toggle("subtitles","Spoken dialogue subtitles")
			toggle("sound_captions","Environmental sound captions")
			toggle("observations","Observation text")
			slider("subtitle_scale","Caption text size",0.8,1.4,0.1)
			toggle("caption_backing","Caption background")
			label(rows,"Sound captions identify audible events. Observations are Eli's own thoughts.\nRecorded material is labelled separately from a live voice.",16)
		"Accessibility":
			toggle("reduced_flash","Reduce light flicker")
			toggle("reduced_motion","Reduce camera motion")
			toggle("viewmodel","Visible handheld torch")
			label(rows,"Interaction prompts and readable records stay legible.\nMotion reduction also steadies the handheld torch.",16)

func settings_back() -> void:
	if settings_origin == "ending":show_ending()
	else:show_menu(settings_origin == "title")

func show_credits() -> void:
	if section in ["title","pause","ending"]:settings_origin = section
	pause_world()
	section = "credits"
	clear_card()
	label(card_body,"UNLISTED",42,"Title")
	label(card_body,"An original night call for SneakiiCROWN",19)
	rule(card_body)
	label(card_body,"ARCHITECTURE     Elegant Crow\nFURNITURE          Daniel Jurys / GameDev Deck\nMACHINERY         chilly_durango\nMATERIALS           Poly Haven / AmbientCG\nAMBIENCE             CAPTNPHANTOM\nANALOG MONO     Andrew Gleeson\nCHARACTER / MOTION    Quaternius (CC0)\nENGINE                 Godot 4.7.2",20)
	label(card_body,"Original story, adapted Surveyor, interface and staging. Sound effects by WASD Sound.\nThird-party licences accompany this build.\nGodot Engine is distributed under the MIT licence.",16)
	add_button("Back",settings_back,true,card_body).grab_focus()

func inspect_document(title_: String, text: String) -> void:
	pause_world()
	section = "document"
	clear_card()
	label(card_body,"PROPERTY SERVICES  /  RECOVERED RECORD",14,"Meta")
	label(card_body,title_,27,"Title")
	rule(card_body)
	note.visible = true
	note.text = text
	note.bbcode_enabled = false
	note.custom_minimum_size = Vector2(800,385)
	card_body.move_child(note,card_body.get_child_count()-1)
	add_button("Close record  /  ESC",resume_game,true,card_body).grab_focus()
	entrance_animation(card)

func show_exclusion() -> void:
	pause_world()
	clear_transients()
	footer.visible = false
	body.visible = false
	clear_card()
	section = "document"
	label(card_body,"PROPERTY SERVICES / CHANNEL EXCLUSION",15,"Meta")
	label(card_body,"SOURCE / RETURN",32,"Title")
	label(card_body,"Optional investigation / the attendance register does not require this test.\nA  /  FIELD MICROPHONE     B  /  RETURN FROM PROPERTY\n\nKeep the source. Exclude an arrival absent from the microphone.",20)
	var state_a := "heard" if game.events.get("audition_A",false) else "not heard"
	var state_b := "heard" if game.events.get("audition_B",false) else "not heard"
	var available: bool = game.stage>=3 and not game.threat.active()
	label(card_body,"A: "+state_a+"     /     B: "+state_b+"\n"+("Playing "+game.horror.audition if game.horror.audition!="" else ("Listen to each complete track before excluding." if available else "Playback unavailable: "+("no power" if game.stage<3 else "the Surveyor is nearby"))),18)
	var row := HBoxContainer.new();card_body.add_child(row)
	for channel in ["A","B"]:
		add_button("Listen "+channel,func():resume_game();game.horror.audition_channel(channel),available,row)
	var ready_: bool = game.events.get("audition_A",false) and game.events.get("audition_B",false)
	add_button("Exclude channel A",func():game.horror.exclude_channel("A"),ready_,card_body)
	add_button("Exclude channel B",func():game.horror.exclude_channel("B"),ready_,card_body)
	add_button("Leave transport",resume_game,true,card_body).grab_focus()
	entrance_animation(card)

func show_register() -> void:
	pause_world()
	footer.visible = false
	clear_transients()
	clear_card()
	section = "register"
	label(card_body,"PROPERTY 17 / ATTENDANCE REGISTER",16,"Meta")
	label(card_body,"UNCLOSED CALL / 1998",32,"Title")
	var final_line:="and keep his case open. Take the receipt out to the lane." if game.events.get("case_v2",false) else "and keep his case open. The sheet will be sent to dispatch."
	var context:="Simon was still inside when the office marked him absent."
	if game.events.get("case_v3",false):context="He found my drawing here. I was at home.\nHe stayed because he thought someone else was trapped."
	label(card_body,"SIMON WARD    1998 / MARKED ABSENT / NO EXIT\nELI WARD          TONIGHT / ARRIVAL RECORDED\n\n"+context+"\n\nCorrect his entry and close the call, or attach the evidence\n"+final_line,20)
	var close_call:=add_button("Simon Ward / PRESENT",func():game.finish_attendance("accounted_for"),true,card_body)
	close_call.text="Correct Simon's entry / close the call";close_call.grab_focus()
	if not game.events.get("case_v2",false):add_button("Eli Ward / PRESENT",func():resume_game();game.sound("relay",Vector3(0,1.5,4),-26);game.message("Your arrival is already entered. Simon's departure is still blank.",5),true,card_body)
	if game.events.get("memory_confirmed",false):
		label(card_body,"Original source retained. You can refuse the old close-out and leave his case open.",16,"Meta")
		var keep_case:=add_button("Attach original / keep Simon's case open",func():game.finish_attendance("on_record"),true,card_body)
		keep_case.text="Attach the evidence / keep the case open"
	add_button("Leave the sheet",resume_game,true,card_body)
	entrance_animation(card)

func show_death(already_black := false) -> void:
	clear_transients()
	pause_world()
	section = "dead"
	death_backing.visible = true
	death_backing.modulate.a = 1 if already_black else 0
	if not already_black:create_tween().tween_property(death_backing,"modulate:a",1.0,0.45)
	stage.set_active(false)
	game.player.camera.current = true
	footer.visible = false
	body.visible = false
	shade.visible = true
	clear_card()
	label(card_body,"PROPERTY 17 / ATTENDANCE LOST",15,"Meta")
	label(card_body,"NO DEPARTURE RECORDED",34,"Title")
	rule(card_body)
	label(card_body,"The house remembers where you stopped.\nYour last checkpoint is intact.",21)
	add_button("Retry Checkpoint",restart_checkpoint,has_checkpoint(),card_body).grab_focus()
	add_button("Main Menu",return_to_title,true,card_body)
	add_button("Quit to Desktop",quit_game,true,card_body)
	game.sound("latch",game.player.position,-22)
	# A short fade, no forced spin, shake or flashing image.
	card.modulate.a = 0
	if transition and transition.is_valid():transition.kill()
	transition = create_tween()
	transition.tween_interval(0.45)
	transition.tween_property(card,"modulate:a",1.0,0.35)

func show_ending() -> void:
	clear_transients()
	footer.visible = true
	var retained: bool=game.events.get("ending","accounted_for")=="on_record"
	footer.text = "23:18     /     CLOSE-OUT DISPUTED" if retained else "23:18     /     REGISTER CORRECTED"
	pause_world()
	section = "ending"
	stage.set_active(true)
	stage.ending_outcome="on_record" if retained else "accounted_for"
	stage.clock=0
	stage.shadow.visible = false
	card.visible = false
	shade.visible = true
	body.visible = true
	status.visible = true
	clear_body()
	label(body,"PROPERTY 17  /  ORIGINAL RETAINED" if retained else "PROPERTY 17  /  REGISTER CORRECTED",14,"Meta")
	label(body,"ON\nRECORD" if retained else "ACCOUNTED\nFOR",48,"Title")
	rule(body)
	if retained:
		label(body,"1998 / Simon Ward     STILL MISSING\nTonight / Eli Ward      WITNESS RECORDED",21)
		label(body,"You attach both pages and the faulty recording.\nDad's disappearance stays open.\nDispatch takes your name as a witness.\n\nYou haven't brought him home.\nThey cannot call this an empty house again." if game.events.get("case_v3",false) else "You attach the original. The call stays open.\nDispatch receives your copy at 23:18.\nSeventeen Briar Lane stays in the file.\n\nYou have not brought your father home.\nYou have stopped them calling him absent.",19)
	else:
		label(body,"1998 / Simon Ward     PRESENT\nTonight / Eli Ward      DEPARTURE RECORDED",21)
		label(body,"You correct Simon's entry.\nHe refused to call the house empty.\nHis name will stay on the record.\nYou close tonight's job and walk away.\n\nYou keep the page he wrote for you." if game.events.get("case_v3",false) else "You send the corrected call sheet.\nSimon Ward was here. He never logged out.\nDispatch acknowledges your departure,\nbut cannot find the address on its route.\n\nYou keep your father's service key.",19)
	add_button("Credits",show_credits)
	add_button("Main Menu",func():game.started = false;show_menu(true))
	add_button("Quit to Desktop",func():get_tree().quit())
	buttons.Credits.grab_focus()
	entrance_animation(body)

func clear_transients() -> void:
	if moment_tween and moment_tween.is_valid():moment_tween.kill()
	if arrival_fade and arrival_fade.is_valid():arrival_fade.kill()
	if arrival_lens and arrival_lens.is_valid():
		arrival_lens.kill()
		game.player.camera.fov=77
	location_card.modulate.a = 0
	location_card.visible = false
	pending_moment = ""
	toast.text = ""
	toast.modulate.a = 0
	fade.color.a = 0

func persist() -> void:
	if prefs.save_file() != OK:notify("SETTINGS COULD NOT BE SAVED")

func apply_preferences(display := false) -> void:
	prefs.apply_audio()
	game.volume = prefs.data.master
	game.sensitivity = prefs.data.sensitivity
	game.reduced_flash = prefs.data.reduced_flash
	game.player.sensitivity = prefs.data.sensitivity
	game.player.invert_y = prefs.data.invert_y
	subtitle.add_theme_font_size_override("font_size",roundi(21*prefs.data.subtitle_scale))
	var caption_style:=StyleBoxFlat.new()
	caption_style.bg_color=Color(0.025,0.035,0.03,0.88 if prefs.data.caption_backing else 0.0)
	caption_style.content_margin_left=12;caption_style.content_margin_right=12
	caption_style.content_margin_top=6;caption_style.content_margin_bottom=6
	subtitle.add_theme_stylebox_override("normal",caption_style)
	stage.reduce_motion = prefs.data.reduced_motion
	stage.reduce_flash = prefs.data.reduced_flash
	film.material.set_shader_parameter("visibility",prefs.data.visibility)
	film.material.set_shader_parameter("retro",prefs.data.retro)
	film.material.set_shader_parameter("pixel_stride",[1.0,1.35,2.2][prefs.data.visual_preset])
	if display:apply_display()

func apply_display() -> void:
	if prefs.data.display_mode == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var usable := DisplayServer.screen_get_usable_rect()
		var size_: Vector2i = prefs.data.resolution
		# Keep the window and its controls reachable on smaller desktop work areas.
		size_.x = mini(size_.x,usable.size.x)
		size_.y = mini(size_.y,usable.size.y)
		DisplayServer.window_set_size(size_)
		DisplayServer.window_set_position(usable.position+(usable.size-size_)/2)
	DisplayServer.window_set_min_size(Vector2i(960,540))

func notify(text: String) -> void:
	toast.text = text
	var t := create_tween()
	toast.modulate.a = 1
	t.tween_interval(2.5)
	t.tween_property(toast,"modulate:a",0.0,0.5)

func moment(id: String) -> void:
	if moment_tween and moment_tween.is_valid():moment_tween.kill()
	var names := {"arrival":["23:17  /  NIGHT CALL","17 BRIAR LANE"],"discovery":["ARCHIVE 1998","A NAME REMOVED"]}
	if names.has(id):
		location_card.visible = true
		location_card.get_node("MomentTag").text = names[id][0]
		location_card.get_node("MomentTitle").text = names[id][1]
		location_card.modulate.a = 0
		moment_tween = create_tween()
		moment_tween.tween_property(location_card,"modulate:a",1.0,0.8)
		moment_tween.tween_interval(2.2)
		moment_tween.tween_property(location_card,"modulate:a",0.0,1.0)
	if id in ["chair","isolation"]:
		var drone: AudioStreamPlayer = game.ambience
		var t := game.create_tween()
		t.tween_property(drone,"volume_db",-42.0,0.6)
		t.tween_interval(1.6)
		t.tween_property(drone,"volume_db",-27.0,2.0)
	if id == "arrival":
		fade.color.a = 1
		arrival_fade = create_tween()
		arrival_fade.tween_property(fade,"color:a",0.0,1.8)
		if not prefs.data.reduced_motion:
			game.player.camera.fov = 82
			arrival_lens = game.create_tween()
			arrival_lens.tween_property(game.player.camera,"fov",77.0,3.0)

func _unhandled_input(event: InputEvent) -> void:
	if section == "intro" and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_E,KEY_ESCAPE]:
		get_viewport().set_input_as_handled()
		complete_intro()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		match section:
			"game","capture":game.show_menu("PAUSED")
			"pause","document","register":resume_game()
			"settings","credits":settings_back()

func _process(delta: float) -> void:
	if not is_instance_valid(game):return
	var covered: bool=section=="game" and game.player.crouched and game.player.near_cover() and (not game.threat.active() or not game.threat.can_see_player())
	cover_amount=move_toward(cover_amount,1.0 if covered else 0.0,delta*3)
	film.material.set_shader_parameter("cover",cover_amount)
	if resume_requested:resume_now()
	if stage.active:
		atmosphere_time += delta
		if atmosphere_time > 27:
			atmosphere_time = 0
			creak.play()
		ambience.volume_db = move_toward(ambience.volume_db,-17,delta*8)
		menu_drone.volume_db = move_toward(menu_drone.volume_db,-33,delta*12)
	else:
		ambience.volume_db = move_toward(ambience.volume_db,-80,delta*35)
		menu_drone.volume_db = move_toward(menu_drone.volume_db,-80,delta*35)
	if section == "game":
		# Fit the backing to the actual wrapped caption instead of reserving a
		# large black panel when only two short lines are shown.
		subtitle.offset_bottom=-104
		subtitle.offset_top=-104-maxf(36,subtitle.get_minimum_size().y)
		reticle.visible = prompt.text != ""
		objective.visible = location_card.modulate.a < 0.05 and subtitle.text == ""
		var category: String=game.message_info.get("category","observation")
		subtitle.visible = subtitle.text!="" and (prefs.data.sound_captions if category in ["sound","recording"] else (prefs.data.subtitles if category=="dialogue" else prefs.data.observations))
		objective.text = game.current_objective().replace("WORK ORDER 17   /   ","")
