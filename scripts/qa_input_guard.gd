extends Node
# Automated tests own a private viewport. No desktop activity monitoring or hooks.
const TEST_MARKER:="unlisted_qa_input"
var game: Node
var target: SubViewport
var ignored_events:=0
var accepted_events:=0
var foreground_profile:=false

func attach(current: Node) -> void:
	game=current;process_mode=Node.PROCESS_MODE_ALWAYS
	var window:=get_tree().root
	window.set_flag(Window.FLAG_NO_FOCUS,true)
	window.set_flag(Window.FLAG_MOUSE_PASSTHROUGH,true)
	window.position=Vector2i(-16000,-16000)
	for id in ["pause","crouch_toggle","forward","back","left","right","sprint","crouch","interact","flashlight","journal","hint","battery_status","battery_replace","torch_tap","throw_prop","inspect_left","inspect_right","inspect_up","inspect_down"]:
		Input.action_release(id);InputMap.action_erase_events(id)
	target=SubViewport.new();target.name="IsolatedAutomatedViewport"
	target.audio_listener_enable_3d=true;target.size=Vector2i(1280,720)
	target.size_2d_override=Vector2i(1280,720);target.size_2d_override_stretch=true
	target.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	window.add_child(target);game.reparent(target)
	target.set_meta("automated_input_isolated",true)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	print("QA_INPUT_ISOLATED private viewport; off-screen non-interactive window; no desktop input hooks")
	foreground_profile="--foreground-profile" in OS.get_cmdline_user_args()
	if foreground_profile:
		# Explicit opt-in only: render the isolated test viewport on the desktop.
		# The same input guard still rejects all unmarked physical input.
		window.set_flag(Window.FLAG_NO_FOCUS,false)
		window.set_flag(Window.FLAG_MOUSE_PASSTHROUGH,false)
		window.position=Vector2i(60,60);window.size=Vector2i(1280,720)
		window.title="UNLISTED - isolated performance capture (no player input)"
		var display:=TextureRect.new();display.texture=target.get_texture()
		display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		display.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;display.mouse_filter=Control.MOUSE_FILTER_IGNORE
		window.add_child(display)
		if DisplayServer.has_method("window_move_to_foreground"):DisplayServer.call("window_move_to_foreground")

func _input(event: InputEvent) -> void:
	if not is_instance_valid(game):return
	if event is InputEventAction or event.get_meta(TEST_MARKER,false):
		accepted_events+=1
		game.get_viewport().push_input(event)
	else:
		# Counts only. Never record the user's keys, text, apps or pointer position.
		ignored_events+=1
	get_tree().root.set_input_as_handled()

func _process(_delta: float) -> void:
	# Keep normal QA off the desktop; explicit display-mode assertions still run.
	var window:=get_tree().root
	if not foreground_profile and window.mode==Window.MODE_WINDOWED and window.position!=Vector2i(-16000,-16000):window.position=Vector2i(-16000,-16000)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
