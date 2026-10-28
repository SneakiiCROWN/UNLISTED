extends CanvasLayer

const INTERACTION_KEY = preload("res://assets/ui/input/keyboard_e.png")
const INTERACTION_PAD = preload("res://assets/ui/input/xbox_x.png")
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
var applied_cover: float=-1.0
var shade: TextureRect
var body: VBoxContainer
var normal_panel: StyleBox
var card: PanelContainer
var card_body: VBoxContainer
var tabs: HBoxContainer
var rows: VBoxContainer
var note: RichTextLabel
var stamina_root: VBoxContainer
var stamina_bar: ProgressBar
var stamina_alpha:=0.0
var battery_root: VBoxContainer
var battery_bar: ProgressBar
var battery_caption: Label
var battery_detail: Label
var battery_status_time:=0.0
var hud: Control
var objective: Label
var reticle: Label
var prompt_icon: TextureRect
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
var diagnostic_silent_menu:=false
var diagnostic_title_trace:=false
var location_card: VBoxContainer
var fade: ColorRect
var transition: Tween
var moment_tween: Tween
var toast_tween: Tween
var arrival_sequence: Node3D
var cinematic_arrival_enabled:=true
var arrival_fade: Tween
var arrival_lens: Tween
var menu_navigation: Label
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
	prefs.path = load("res://scripts/atmosphere_profile.gd").preferences_path(game)
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
	normal_panel=background
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
	anchored(prompt,Control.PRESET_BOTTOM_LEFT,Rect2(84,-78,840,38))
	prompt_icon=TextureRect.new();hud.add_child(prompt_icon);anchored(prompt_icon,Control.PRESET_BOTTOM_LEFT,Rect2(44,-75,30,30));prompt_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;prompt_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;prompt_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	prompt.add_theme_color_override("font_shadow_color",Color(0,0,0,0.95))
	prompt.add_theme_constant_override("shadow_offset_x",2)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	reticle = label(hud,"+",18)
	anchored(reticle,Control.PRESET_CENTER,Rect2(-3,-10,6,20))
	reticle.modulate = Color(0.7,0.8,0.77,0.45)
	battery_root=VBoxContainer.new();hud.add_child(battery_root)
	anchored(battery_root,Control.PRESET_BOTTOM_RIGHT,Rect2(-210,-101,170,62));battery_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	battery_caption=label(battery_root,"",16,"Meta")
	battery_bar=ProgressBar.new();battery_bar.custom_minimum_size=Vector2(170,7);battery_bar.show_percentage=false;battery_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;battery_root.add_child(battery_bar)
	var backing:=StyleBoxFlat.new();backing.bg_color=Color("252f2e");battery_bar.add_theme_stylebox_override("background",backing)
	var fill:=StyleBoxFlat.new();fill.bg_color=Color("a8b6a3");battery_bar.add_theme_stylebox_override("fill",fill)
	battery_detail=label(battery_root,"",13,"Meta");battery_root.visible=false
	stamina_root=VBoxContainer.new();hud.add_child(stamina_root);anchored(stamina_root,Control.PRESET_BOTTOM_RIGHT,Rect2(-185,-139,145,28));stamina_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label(stamina_root,"STAMINA",12,"Meta")
	stamina_bar=ProgressBar.new();stamina_root.add_child(stamina_bar);stamina_bar.custom_minimum_size=Vector2(145,5);stamina_bar.show_percentage=false;stamina_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stamina_bar.add_theme_stylebox_override("background",backing.duplicate());stamina_bar.add_theme_stylebox_override("fill",fill.duplicate());stamina_root.visible=false

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
	diagnostic_silent_menu=game.qa_mode and "--title-no-audio" in OS.get_cmdline_user_args()
	diagnostic_title_trace=game.qa_mode and "--title-trace" in OS.get_cmdline_user_args()
	ambience = AudioStreamPlayer.new()
	ambience.stream = load("res://assets/audio/wind.wav")
	ambience.bus = "Ambience"
	ambience.volume_db = -17
	add_child(ambience)
	if diagnostic_title_trace:ambience.finished.connect(func():print("TITLE_OPERATION wind restart before");ambience.play();print("TITLE_OPERATION wind restart after"))
	else:ambience.finished.connect(ambience.play)
	if not diagnostic_silent_menu:ambience.play()
	menu_drone = AudioStreamPlayer.new()
	menu_drone.stream = load("res://assets/audio/hollow.wav")
	menu_drone.bus = "Music"
	menu_drone.volume_db = -33
	add_child(menu_drone)
	if diagnostic_title_trace:menu_drone.finished.connect(func():print("TITLE_OPERATION drone restart before");menu_drone.play();print("TITLE_OPERATION drone restart after"))
	else:menu_drone.finished.connect(menu_drone.play)
	if not diagnostic_silent_menu:menu_drone.play()
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
	game.player.sprint_latched=false;game.player.sprinting=false
	game.player.velocity = Vector3.ZERO
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.visible = false

func show_menu(main: bool) -> void:
	if is_instance_valid(game.final_account) and game.final_account.phase()=="boarding":fade.color.a=0
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
	menu_navigation=label(body,"ENTER SELECT / UP-DOWN NAVIGATE / ESC BACK",12,"Meta");menu_navigation.modulate=Color("728988")
	if main:buttons["New Game"].grab_focus()
	else:buttons["Resume"].grab_focus()
	entrance_animation(body)

func has_checkpoint() -> bool:
	if not FileAccess.file_exists(game.checkpoint_path):return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(game.checkpoint_path))
	return game.checkpoint_usable(data)

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
	if is_instance_valid(game.final_account):game.final_account.cleanup();fade.color.a=0
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
	if is_instance_valid(arrival_sequence):return
	if cinematic_arrival_enabled and is_instance_valid(game.get_node_or_null("BriarLaneExterior/EliArrivalCar")):
		var scene=load("res://scenes/arrival_study.tscn")
		if scene is PackedScene and scene.can_instantiate():
			clear_transients();arrival_sequence=scene.instantiate();arrival_sequence.game=game;arrival_sequence.integrated=true;game.add_child(arrival_sequence);return
	begin_original_intro()

func recover_arrival_removal() -> void:
	if is_inside_tree() and is_instance_valid(game) and game.is_inside_tree() and section=="intro" and not is_instance_valid(arrival_sequence):complete_intro(true)

func begin_original_intro() -> void:
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
	intro_lines("ELI WARD / NIGHT CALL-OUT","17 BRIAR LANE","Dad disappeared on a job here in 1998. They never found him.\nTonight someone reported a television playing in the empty house.\nI asked dispatch to give me the call.")
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
	toast.text = "A / B / START  SKIP" if game.controller.used else "SPACE / E / ESC  SKIP"
	toast.modulate.a = 0.65

func complete_intro(from_arrival:=false) -> void:
	if is_instance_valid(arrival_sequence) and not from_arrival:
		arrival_sequence.finish();return
	if intro_tween and intro_tween.is_valid():intro_tween.kill()
	intro_text.visible = false
	intro_text.modulate.a = 1
	toast.text = ""
	game.new_game(from_arrival)
	if from_arrival:
		fade.color.a=1;arrival_fade=create_tween();arrival_fade.tween_property(fade,"color:a",0.0,.75)

func clear_card() -> void:
	# Card buttons are destroyed below; never retain stale node handles from a prior view.
	buttons.clear()
	var focus:=get_viewport().gui_get_focus_owner()
	if is_instance_valid(focus) and card_body.is_ancestor_of(focus):focus.release_focus()
	card.add_theme_stylebox_override("panel",normal_panel)
	note.remove_theme_color_override("default_color");note.remove_theme_font_override("normal_font")
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
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",14)
	var settings_scroll := ScrollContainer.new()
	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_scroll.follow_focus = true
	card_body.add_child(settings_scroll)
	settings_scroll.add_child(rows)
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

func slider(key: String, text: String, min_: float, max_: float, step_: float, percent := true,scale_:=1000.0) -> void:
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
	value_label.text = str(roundi(s.value*100))+"%" if percent else str(snappedf(s.value*scale_,0.1))
	controls[key] = s
	s.value_changed.connect(func(value):
		prefs.data[key] = value
		value_label.text = str(roundi(value*100))+"%" if percent else str(snappedf(value*scale_,0.1))
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
			var sprint_row:=setting_row("Sprint control")
			var sprint_option:=OptionButton.new();sprint_option.add_item("Hold to sprint");sprint_option.add_item("Toggle sprint");sprint_option.selected=prefs.data.sprint_mode;sprint_option.size_flags_horizontal=Control.SIZE_EXPAND_FILL;sprint_row.add_child(sprint_option);controls.sprint_mode=sprint_option
			sprint_option.item_selected.connect(func(index):prefs.data.sprint_mode=index;game.player.sprint_latched=false;persist())
			label(rows,"Run in short bursts. Walking lets you catch your breath.",16,"Meta")
			toggle("story_mode","Story mode / survive capture")
			toggle("torch_contacts","Occasional loose torch contact")
			label(rows,"Standard play includes lethal, escapable encounters.\nStory mode keeps the encounter but prevents death.\nShort sprints help you gain distance. Doors and corners break sight;\nquiet movement gives it less to follow.",18)
		"Audio":
			for pair in [["master","Master volume"],["music","Music"],["sfx","Sound effects"],["ambience","Environmental ambience"]]:slider(pair[0],pair[1],0,1,0.01)
			label(rows,"The house is quiet by design. Listen before you move.",15,"Meta").modulate = Color("839b98")
		"Input":
			slider("sensitivity","Mouse sensitivity",0.0005,0.006,0.0001,false)
			toggle("invert_y","Invert vertical look")
			slider("pad_sensitivity","Controller look speed",.5,3.5,.1,false,1.0)
			slider("pad_deadzone","Controller stick deadzone",.10,.35,.01)
			toggle("reminders","Brief first-use reminders")
			var legend: String="STICKS MOVE / LOOK / X USE / B CROUCH / L3 SPRINT\nRB LIGHT / Y BATTERY / D-PAD UP CHARGE / DOWN TAP\nBACK NOTES / LEFT HINT / START PAUSE / B BACK IN MENUS\nCARRY: X RELEASE / RT THROW / LT + RIGHT STICK ROTATE" if is_instance_valid(game.controller) and game.controller.used else "WASD MOVE / SHIFT SPRINT / CTRL CROUCH / E USE\nF LIGHT / T BATTERY / B CHARGE / V TAP TORCH\nJ NOTES / H OPTIONAL HINT / ESC PAUSE\nCARRY: E RELEASE / LEFT MOUSE THROW / R + MOUSE ROTATE"
			label(rows,legend,16,"Meta")
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
			row = setting_row("Property atmosphere")
			var atmosphere := OptionButton.new()
			for name_ in load("res://scripts/atmosphere_profile.gd").NAMES:atmosphere.add_item(name_)
			atmosphere.selected = prefs.data.atmosphere_mode
			atmosphere.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(atmosphere);controls.atmosphere_mode = atmosphere
			var atmosphere_notice := label(rows,"Atmosphere changes apply next launch. Original remains the fallback.",15,"Meta")
			atmosphere.item_selected.connect(func(idx):prefs.data.atmosphere_mode=idx;persist();atmosphere_notice.text="Saved. Restart UNLISTED to apply "+atmosphere.get_item_text(idx)+"." if idx!=game.atmosphere_at_boot else "This atmosphere is active. Changes apply next launch.")
			slider("retro","Colour depth effect",0.0,1.0,0.01)
			label(rows,"World pixels and colour depth change; interface text stays sharp.",15,"Meta")
		"Captions":
			toggle("subtitles","Dialogue subtitles")
			toggle("sound_captions","Environmental sound captions")
			toggle("observations","Eli's observations")
			slider("subtitle_scale","Caption text size",0.8,1.4,0.1)
			toggle("caption_backing","Caption background")
			label(rows,"Sound captions identify audible events. Observations are Eli's own thoughts.\nRecorded material is labelled separately from a live voice.",16)
		"Accessibility":
			toggle("reduced_flash","Reduce light flicker")
			toggle("reduced_motion","Reduce camera motion")
			toggle("viewmodel","Visible handheld torch")
			toggle("battery_persistent","Always show torch battery")
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
	label(card_body,"ARCHITECTURE     Elegant Crow\nFURNITURE          Daniel Jurys / GameDev Deck / Kenney\nMACHINERY         chilly_durango\nMATERIALS           Poly Haven / AmbientCG\nAMBIENCE             CAPTNPHANTOM\nTYPE     Andrew Gleeson / Indian Type Foundry\nCHARACTER / MOTION    Quaternius (CC0)\nENGINE                 Godot 4.7.2",20)
	label(card_body,"Original story, adapted Surveyor, interface and staging. Sound effects by WASD Sound. Vehicles: Bricchi Games / GGBotNet.\nElectronics: Animimo Studios. Input icons: Kenney.\nThird-party licences accompany this build.\nGodot Engine is distributed under the MIT licence.",16)
	add_button("Back",settings_back,true,card_body).grab_focus()

func inspect_document(title_: String, text: String) -> void:
	pause_world()
	section = "document"
	clear_card()
	var paper: StyleBoxFlat=normal_panel.duplicate();paper.bg_color=Color("beb69b");paper.border_color=Color("655e49");card.add_theme_stylebox_override("panel",paper)
	label(card_body,"PROPERTY SERVICES  /  RECOVERED RECORD",14,"Meta").modulate=Color("464e41")
	label(card_body,title_,27,"Title").modulate=Color("2d382f")
	note.add_theme_color_override("default_color",Color("29362e"))
	if "SIMON" in title_.to_upper():note.add_theme_font_override("normal_font",load("res://assets/fonts/Kalam-Regular.ttf"))
	rule(card_body)
	note.visible = true
	note.text = text
	note.bbcode_enabled = false
	note.custom_minimum_size = Vector2(800,385)
	card_body.move_child(note,card_body.get_child_count()-1)
	var close_record: Button=add_button("Close record  /  ESC",resume_game,true,card_body)
	close_record.text="Put away  /  B" if game.controller.used else "Put away  /  ESC"
	close_record.grab_focus()
	entrance_animation(card)

func show_exclusion() -> void:
	pause_world()
	clear_transients()
	footer.visible = false
	body.visible = false
	clear_card()
	section = "document"
	label(card_body,"FIELD TEST / HALL MICROPHONE",15,"Meta")
	label(card_body,"THE LAST FOOTSTEP",32,"Title")
	var heard_both: bool=game.events.get("audition_A",false) and game.events.get("audition_B",false)
	var explanation: Label=label(card_body,"HALL MICROPHONE / TONIGHT\n\n"+("I stood still after playback stopped. There was one more step.\nDid it come from the recording, or the room?" if heard_both else "These are my footsteps, recorded in the hall tonight.\nI can play them again and listen from here.\nDad's 1998 service reel loads separately."),20)
	explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var state_a := "heard" if game.events.get("audition_A",false) else "not heard"
	var state_b := "heard" if game.events.get("audition_B",false) else "not heard"
	var available: bool = game.stage>=3 and not game.threat.active()
	label(card_body,"Recording: "+state_a+"     /     Replay: "+state_b+"\n"+(("Playing recording" if game.horror.audition=="A" else "Replaying recording") if game.horror.audition!="" else (("Mark where the extra step came from." if heard_both else "Play once, then replay before comparing.") if available else "Playback unavailable: "+("no power" if game.stage<3 else "movement nearby"))),18)
	var row := HBoxContainer.new();card_body.add_child(row)
	for channel in ["A","B"]:
		var play_button:=add_button("Listen "+channel,func():resume_game();game.horror.audition_channel(channel),available,row)
		play_button.text="Play recording" if channel=="A" else "Replay and listen"
	var ready_: bool = game.events.get("audition_A",false) and game.events.get("audition_B",false)
	var exclude_a:=add_button("Exclude channel A",func():game.horror.exclude_channel("A"),ready_,card_body);exclude_a.text="From the recording"
	var exclude_b:=add_button("Exclude channel B",func():game.horror.exclude_channel("B"),ready_,card_body);exclude_b.text="From the room"
	add_button("Leave recorder",resume_game,true,card_body).grab_focus()
	entrance_animation(card)

func show_register() -> void:
	pause_world()
	footer.visible = false
	clear_transients()
	clear_card()
	section = "register"
	label(card_body,"PROPERTY 17 / ATTENDANCE REGISTER",16,"Meta")
	label(card_body,"SIMON WARD / NO EXIT RECORDED",32,"Title")
	var context:="Simon was still inside when the office marked him absent."
	if game.events.get("case_v3",false):context="Dad knew I was at home. He found my room here anyway.\nHe went back to check whether someone was trapped."
	if game.events.get("witness_carbon_read",false):context="Dad never signed the clearance. The machine filed it while he was inside.\nI have the unsigned carbon and his account of what happened."
	if game.events.get("exit_receipt_read",false):context="The service exit printed my departure before I crossed it.\nDad's EMPTY entry doesn't prove he left either. I have his report."
	if game.events.get("call_complete",false):context="Dad's later page says he called home, then heard the speaker repeat our conversation.\nHe used the recorder to get past the man at the stairs.\nI found that page and repeated his test with the speaker disconnected."
	label(card_body,"1998 / Simon Ward: marked absent, with no recorded exit.\nTonight / Eli Ward: still here.\n\n"+context,19)
	if game.events.get("equipment_date_compared",false):label(card_body,"2018 stock label kept separate / date of use unknown",15,"Meta")
	var close_call:=add_button("Simon Ward / PRESENT",func():game.finish_attendance("accounted_for"),true,card_body)
	close_call.text="Correct Dad's false absence";close_call.grab_focus()
	label(card_body,"Close my service call. Keep his papers. Dad remains missing.",16,"Meta")
	if not game.events.get("case_v2",false):add_button("Eli Ward / PRESENT",func():resume_game();game.sound("relay",Vector3(0,1.5,4),-26);game.message("My arrival is entered. Dad's exit is still blank.",4),true,card_body)
	if game.events.get("memory_confirmed",false):
		var keep_case:=add_button("Attach original / keep Simon's case open",func():game.finish_attendance("on_record"),true,card_body)
		keep_case.text="Submit Dad's records and tonight's comparison"
		label(card_body,"Leave the fault open. Ask dispatch to investigate. Record me as a witness.",16,"Meta")
	if game.events.get("case_v2",false):label(card_body,"Either way, take the receipt from the clip below and return to the car.\nNeither choice tells me where Dad went.",16)
	add_button("Leave register",resume_game,true,card_body)
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
	label(card_body,"Your last checkpoint is intact.",21)
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
	var physical_departure: bool=is_instance_valid(game.final_account) and game.final_account.phase()=="departed"
	if retained:
		label(body,"1998 / Simon Ward     STILL MISSING\nTonight / Eli Ward      WITNESS RECORDED",21)
		var text_:="I've kept Dad's originals with the comparison I recorded tonight.\n\nI'm taking them to dispatch. I want someone to investigate the house.\nDad is still missing. This report has my name on it."
		if not physical_departure:text_="I sent the comparison with Dad's report. The fault stays open.\n\nHe is still missing. But his account is on record now, and so is mine."
		label(body,text_,19)
	else:
		label(body,"1998 / Simon Ward     PRESENT\nTonight / Eli Ward      DEPARTURE RECORDED\nSimon is still missing.",21)
		var text_:="I kept Dad's records and corrected the entry that said he wasn't here.\n\nMy service call is closed. His disappearance isn't.\nI still don't know where he went."
		if not physical_departure:text_="I corrected Dad's entry and closed my call-out.\nHe was here. He never signed out.\n\nI still have his service key. I still don't know where he went."
		label(body,text_,19)
	add_button("Credits",show_credits)
	add_button("Main Menu",func():game.started = false;show_menu(true))
	add_button("Quit to Desktop",func():get_tree().quit())
	buttons.Credits.grab_focus()
	entrance_animation(body)

func clear_transients() -> void:
	if toast_tween and toast_tween.is_valid():toast_tween.kill()
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
	film.material.set_shader_parameter("raster_height",[0.0,540.0,360.0][prefs.data.visual_preset])
	if game.atmosphere_profile != null:game.atmosphere_profile.refresh_accessibility(game)
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
	# New feedback owns its lifetime; an older fading message cannot hide it.
	if toast_tween and toast_tween.is_valid():toast_tween.kill()
	toast.text = text
	toast_tween = create_tween()
	toast.modulate.a = 1
	toast_tween.tween_interval(2.5)
	toast_tween.tween_property(toast,"modulate:a",0.0,0.5)

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
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if section=="intro":complete_intro()
		elif section=="pause":resume_game()
		elif game.started and not game.ended and section!="dead":show_menu(false)
		return
	if section == "intro" and ((event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_E,KEY_ESCAPE]) or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		complete_intro()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		match section:
			"game","capture":game.show_menu("PAUSED")
			"pause","document","register":resume_game()
			"settings","credits":settings_back()

func show_battery_status(duration:=3.5) -> void:
	battery_status_time=maxf(battery_status_time,duration)
func _process(delta: float) -> void:
	if not is_instance_valid(game):return
	if is_instance_valid(menu_navigation):menu_navigation.text="A SELECT / D-PAD NAVIGATE / B BACK" if is_instance_valid(game.controller) and game.controller.used else "ENTER SELECT / UP-DOWN NAVIGATE / ESC BACK"
	var covered: bool=section=="game" and game.player.crouched and game.player.near_cover() and (not game.threat.active() or not game.threat.can_see_player())
	cover_amount=move_toward(cover_amount,1.0 if covered else 0.0,delta*3)
	if applied_cover!=cover_amount:
		film.material.set_shader_parameter("cover",cover_amount);applied_cover=cover_amount
	if resume_requested:resume_now()
	if stage.active:
		atmosphere_time += delta
		if atmosphere_time > 27:
			atmosphere_time = 0
			if diagnostic_title_trace:print("TITLE_OPERATION creak before ",stage.clock)
			if not diagnostic_silent_menu:creak.play()
			if diagnostic_title_trace:print("TITLE_OPERATION creak after ",stage.clock)
		if ambience.volume_db!=-17:ambience.volume_db = move_toward(ambience.volume_db,-17,delta*8)
		if menu_drone.volume_db!=-33:menu_drone.volume_db = move_toward(menu_drone.volume_db,-33,delta*12)
	else:
		if ambience.volume_db!=-80:ambience.volume_db = move_toward(ambience.volume_db,-80,delta*35)
		if menu_drone.volume_db!=-80:menu_drone.volume_db = move_toward(menu_drone.volume_db,-80,delta*35)
	if section == "game":
		stamina_alpha=move_toward(stamina_alpha,1.0 if game.player.sprinting or game.player.stamina<.999 else 0.0,delta*2.5)
		stamina_root.visible=stamina_alpha>.001;stamina_root.modulate.a=stamina_alpha;stamina_bar.value=game.player.stamina*100.0
		battery_status_time=maxf(0,battery_status_time-delta)
		var charge: float=game.equipment.data.get("charge",100.0)
		battery_root.visible=battery_status_time>0 or prefs.data.get("battery_persistent",false)
		battery_root.modulate.a=1.0 if prefs.data.get("battery_persistent",false) else clampf(battery_status_time/.65,0,1)
		battery_bar.value=charge;battery_caption.text="TORCH %d%%"%ceili(charge)
		battery_caption.modulate=Color("d3a785") if charge<=20 else Color("b8c3b3")
		battery_detail.text="WINDING / %d%%"%mini(100,roundi(game.equipment.winding/3.2*100)) if game.equipment.winding>0 else ["OFF","WHITE","UV"][clampi(int(game.equipment.data.get("mode",1)),0,2)]+" / %d spare"%int(game.equipment.data.get("spares",0))
		# Fit the backing to the actual wrapped caption instead of reserving a
		# large black panel when only two short lines are shown.
		subtitle.offset_bottom=-104
		subtitle.offset_top=-104-maxf(36,subtitle.get_minimum_size().y)
		reticle.visible = prompt.text != ""
		prompt_icon.visible=prompt.text!=""
		var icon: Texture2D=INTERACTION_PAD if game.controller.used else INTERACTION_KEY
		if prompt_icon.texture!=icon:prompt_icon.texture=icon
		objective.visible = location_card.modulate.a < 0.05 and subtitle.text == ""
		var category: String=game.message_info.get("category","observation")
		subtitle.visible = subtitle.text!="" and (prefs.data.sound_captions if category in ["sound","recording"] else (prefs.data.subtitles if category=="dialogue" else prefs.data.observations))
		objective.text = game.current_objective().replace("WORK ORDER 17   /   ","")
