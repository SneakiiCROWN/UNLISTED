extends Node
# Explicit diagnostic only: retain root Window/world, reject app-local input.
var game: Node
var output: String
var duration:=240.0
var start:=0
var ignored:=0
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 assert(not game.native_capture_directory.is_empty() and game.get_viewport()==get_tree().root)
 for action in InputMap.get_actions():Input.action_release(action);InputMap.action_erase_events(action)
 var window:=get_tree().root
 window.set_flag(Window.FLAG_NO_FOCUS,true);window.set_flag(Window.FLAG_MOUSE_PASSTHROUGH,true);window.position=Vector2i(-16000,-16000)
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 start=Time.get_ticks_usec()
 # Local viewport injection, never Windows/desktop input. It must not start New Game.
 var event:=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_A;event.pressed=true
 window.push_input(event)
func _input(_event: InputEvent) -> void:
 ignored+=1;get_tree().root.set_input_as_handled()
func _process(_delta: float) -> void:
 var window:=get_tree().root
 if window.position!=Vector2i(-16000,-16000):window.position=Vector2i(-16000,-16000)
 var elapsed: float=(Time.get_ticks_usec()-start)/1000000.0
 var invalid: bool=game.started or game.presentation.section!="title"
 if not invalid and elapsed<duration:return
 set_process(false)
 var file:=FileAccess.open(output.path_join("native_capture_end.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"elapsed":elapsed,"section":game.presentation.section,"started":game.started,"root_window":game.get_viewport()==window,"input_events_rejected":ignored,"invalid_state":invalid,"scope":"Explicit muted/off-screen root-Window diagnostic; input rejected locally, no world/viewport handoff. Programmed title Quit, not foreground-owner stability clearance."}));file.close()
 print("NATIVE_CAPTURE_TIMED_TITLE_QUIT ",elapsed)
 if invalid:get_tree().quit(96)
 else:game.presentation.buttons["Quit"].pressed.emit()
