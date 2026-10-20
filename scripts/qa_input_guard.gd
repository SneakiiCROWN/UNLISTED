extends Node
# Automated tests own a private viewport. No desktop activity monitoring or hooks.
const TEST_MARKER:="unlisted_qa_input"
var game: Node
var target: SubViewport
var ignored_events:=0
var accepted_events:=0

func attach(current: Node) -> void:
	game=current;process_mode=Node.PROCESS_MODE_ALWAYS
	var window:=get_tree().root
	window.set_flag(Window.FLAG_NO_FOCUS,true)
	window.set_flag(Window.FLAG_MOUSE_PASSTHROUGH,true)
	window.position=Vector2i(-16000,-16000)
	for id in ["forward","back","left","right","sprint","crouch","interact","flashlight","journal","hint"]:
		Input.action_release(id);InputMap.action_erase_events(id)
	target=SubViewport.new();target.name="IsolatedAutomatedViewport"
	target.audio_listener_enable_3d=true;target.size=Vector2i(1280,720)
	target.size_2d_override=Vector2i(1280,720);target.size_2d_override_stretch=true
	target.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	window.add_child(target);game.reparent(target)
	target.set_meta("automated_input_isolated",true)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	print("QA_INPUT_ISOLATED private viewport; off-screen non-interactive window; no desktop input hooks")

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
	if window.mode==Window.MODE_WINDOWED and window.position!=Vector2i(-16000,-16000):window.position=Vector2i(-16000,-16000)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
