extends Node
# Joypad events stay in the game's viewport. Isolated QA never reads desktop input.
var game: Node
var used:=false
var move:=Vector2.ZERO
var look:=Vector2.ZERO
var ui_axis:=Vector2.ZERO
var repeat_clock:=0.0
var rotating:=false
var trigger_down:=false
var held: Dictionary={}
var button_actions: Dictionary={}
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(func(_device,connected):if not connected:clear())
func emit_action(id: String,pressed: bool) -> void:
	if pressed:Input.action_press(id)
	else:Input.action_release(id)
	held[id]=pressed
	var event:=InputEventAction.new();event.action=id;event.pressed=pressed
	get_viewport().push_input(event)
func clear() -> void:
	move=Vector2.ZERO;look=Vector2.ZERO;ui_axis=Vector2.ZERO;rotating=false;trigger_down=false
	for id in held:
		if held[id]:emit_action(id,false)
	button_actions.clear()
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_WINDOW_FOCUS_OUT and is_instance_valid(game) and not game.automated_qa:clear()
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:used=false
	elif event is InputEventMouseMotion:
		if event.relative.length()>2:used=false
	if event is InputEventJoypadButton:
		used=true
		var actions: Dictionary={JOY_BUTTON_A:"ui_accept",JOY_BUTTON_B:"ui_cancel",JOY_BUTTON_X:"interact",JOY_BUTTON_Y:"battery_replace",JOY_BUTTON_LEFT_SHOULDER:"crouch",JOY_BUTTON_RIGHT_SHOULDER:"flashlight",JOY_BUTTON_LEFT_STICK:"sprint",JOY_BUTTON_BACK:"journal",JOY_BUTTON_START:"pause",JOY_BUTTON_DPAD_UP:"battery_status",JOY_BUTTON_DPAD_DOWN:"torch_tap",JOY_BUTTON_DPAD_LEFT:"hint"}
		var id: String=actions.get(event.button_index,"")
		if event.button_index==JOY_BUTTON_B and not game.menu_open and game.player.active:id="crouch_toggle"
		if game.menu_open and event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:
			id={JOY_BUTTON_DPAD_UP:"ui_up",JOY_BUTTON_DPAD_DOWN:"ui_down",JOY_BUTTON_DPAD_LEFT:"ui_left",JOY_BUTTON_DPAD_RIGHT:"ui_right"}[event.button_index]
		# A loose contact must not steal Down navigation from every paper/menu.
		# Only the actual torch inspection has the tap-to-restore control.
		if game.presentation.section=="document" and event.button_index==JOY_BUTTON_DPAD_DOWN and game.equipment.data.get("contact_fault",false) and game.presentation.card_body.has_node("ReportSleeveScan"):id="torch_tap"
		# Route release back to the action that received the press, even if it changed screens.
		if event.pressed:button_actions[event.button_index]=id
		else:
			id=button_actions.get(event.button_index,"");button_actions.erase(event.button_index)
		get_viewport().set_input_as_handled()
		if id!="":emit_action(id,event.pressed)
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value)>.25:used=true
		match event.axis:
			JOY_AXIS_LEFT_X:move.x=event.axis_value
			JOY_AXIS_LEFT_Y:move.y=event.axis_value
			JOY_AXIS_RIGHT_X:look.x=event.axis_value
			JOY_AXIS_RIGHT_Y:look.y=event.axis_value
			JOY_AXIS_TRIGGER_LEFT:rotating=event.axis_value>.5
			JOY_AXIS_TRIGGER_RIGHT:
				var down: bool=event.axis_value>.5
				if down!=trigger_down:emit_action("throw_prop",down);trigger_down=down
		get_viewport().set_input_as_handled()
func stick(value: Vector2) -> Vector2:
	var dead: float=game.presentation.prefs.data.get("pad_deadzone",.20)
	var magnitude: float=value.length()
	return Vector2.ZERO if magnitude<=dead else value.normalized()*minf(1,(magnitude-dead)/(1-dead))
func _process(delta: float) -> void:
	if not is_instance_valid(game.presentation):return
	if game.menu_open:
		var inspect:=stick(look)
		for pair in [["inspect_left",maxf(0,-inspect.x)],["inspect_right",maxf(0,inspect.x)],["inspect_up",maxf(0,-inspect.y)],["inspect_down",maxf(0,inspect.y)]]:
			if pair[1]>0:Input.action_press(pair[0],pair[1])
			elif held.get(pair[0],false):Input.action_release(pair[0])
			held[pair[0]]=pair[1]>0
		var axis:=stick(move)
		var next:=Vector2.ZERO
		if axis.length()>.45:next=Vector2(signf(axis.x),0) if absf(axis.x)>absf(axis.y) else Vector2(0,signf(axis.y))
		repeat_clock-=delta
		if next!=Vector2.ZERO and (next!=ui_axis or repeat_clock<=0):
			var id: String="ui_left" if next.x<0 else ("ui_right" if next.x>0 else ("ui_up" if next.y<0 else "ui_down"))
			emit_action(id,true);emit_action(id,false);repeat_clock=.30 if next!=ui_axis else .14
		ui_axis=next
	else:
		ui_axis=Vector2.ZERO
		for id in ["inspect_left","inspect_right","inspect_up","inspect_down"]:
			if held.get(id,false):Input.action_release(id);held[id]=false
