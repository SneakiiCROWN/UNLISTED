extends Control
# Two real records, generous magnetic registration, persistent manual placement.
const HAND=preload("res://assets/fonts/Kalam-Regular.ttf")
const PAPER=preload("res://assets/original/aged_paper.png")
var game: Node
var offset:=Vector2(125,50)
var angle:=.20
var placed:=false
var dragging:=false
var grab:=Vector2.ZERO
var assisted:=false
var dirty:=false
var save_clock:=0.0
var ready_for_match:=false
const CENTRE:=Vector2(400,207)
const SHEET:=Rect2(-252,-158,504,316)
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;custom_minimum_size=Vector2(800,425)
	mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	var pose: Array=game.events.get("call_plan_pose",[125.0,50.0,.20])
	offset=Vector2(pose[0],pose[1]);angle=float(pose[2]);placed=game.events.get("call_plan_placed",false)
	ready_for_match=game.last_call.plans_available();grab_focus();queue_redraw()
func remember(force:=true) -> void:
	game.events.call_plan_pose=[offset.x,offset.y,angle];game.events.call_plan_placed=placed
	dirty=true
	if force:game.save_game(true);dirty=false;save_clock=0
func turn(amount: float) -> void:
	if not ready_for_match or game.events.get("call_plan_aligned",false):return
	placed=true;angle=wrapf(angle+amount,-PI,PI);try_register();remember();queue_redraw()
func place_sheet() -> void:
	if not ready_for_match:return
	placed=true;remember();queue_redraw()
func try_register() -> void:
	if not placed or not ready_for_match or game.events.get("call_plan_aligned",false):return
	# About a hand-width of translation and six degrees: never pixel-perfect.
	if offset.length()<25 and absf(angle)<deg_to_rad(6):
		offset=Vector2.ZERO;angle=0;dragging=false;assisted=false
		game.last_call.align_plans();remember()
func assist() -> void:
	if not ready_for_match:return
	placed=true;assisted=true
func _process(delta: float) -> void:
	if not is_visible_in_tree() or game.presentation.section!="document":return
	if ready_for_match and not game.events.get("call_plan_aligned",false):
		var arrows:=Input.get_vector("ui_left","ui_right","ui_up","ui_down") if has_focus() and not game.controller.used else Vector2.ZERO
		var stick:=Input.get_vector("inspect_left","inspect_right","inspect_up","inspect_down")
		if placed and (arrows+stick).length()>.1:
			offset+=(arrows+stick).limit_length()*delta*155;try_register();remember(false)
		if assisted:
			offset=offset.move_toward(Vector2.ZERO,delta*65);angle=move_toward(angle,0,delta*.12);try_register();remember(false)
	save_clock+=delta
	if dirty and save_clock>.4:remember()
	queue_redraw()
func _gui_input(event: InputEvent) -> void:
	if not ready_for_match or game.events.get("call_plan_aligned",false):return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				var local: Vector2=(event.position-CENTRE-offset).rotated(-angle)
				if SHEET.has_point(local):placed=true;dragging=true;grab=event.position-offset;assisted=false;grab_focus()
			else:dragging=false;try_register();remember()
			accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			turn(deg_to_rad(-3 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 3));accept_event()
	elif event is InputEventMouseMotion and dragging:
		offset=(event.position-grab).clamp(Vector2(-200,-105),Vector2(200,105));try_register();queue_redraw();accept_event()
	elif event.is_action_pressed("ui_accept"):place_sheet();accept_event()
	elif has_focus() and not game.controller.used and (event.is_action("ui_left") or event.is_action("ui_right") or event.is_action("ui_up") or event.is_action("ui_down")):accept_event()
func plan(marked: bool) -> void:
	var ink:=Color(.28,.26,.19,.85) if not marked else Color(.18,.30,.28,.78)
	# Surveyed arrangement: stairwell enters the cellar at the lower landing;
	# the bay is to its west, and the existing records crawl is to its east.
	draw_polyline(PackedVector2Array([Vector2(-198,22),Vector2(-198,116),Vector2(198,116),Vector2(198,22)]),ink,2,true)
	for pair in [[Vector2(-198,22),Vector2(-25,22)],[Vector2(25,22),Vector2(198,22)],[Vector2(-25,-65),Vector2(-25,22)],[Vector2(25,-65),Vector2(25,22)]]:draw_line(pair[0],pair[1],ink,2,true)
	for y in range(-60,23,13):draw_line(Vector2(-25,y),Vector2(25,y),ink,1,true)
	draw_polyline(PackedVector2Array([Vector2(62,22),Vector2(62,-65),Vector2(198,-65),Vector2(198,22)]),ink,2,true)
	draw_string(HAND,Vector2(-47,-76),"stairwell",HORIZONTAL_ALIGNMENT_LEFT,-1,16,ink)
	draw_string(HAND,Vector2(-80,142),"LOWER LANDING",HORIZONTAL_ALIGNMENT_LEFT,-1,15,ink)
	draw_string(HAND,Vector2(83,-20),"records",HORIZONTAL_ALIGNMENT_LEFT,-1,16,ink)
	draw_polyline(PackedVector2Array([Vector2(150,-53),Vector2(150,12),Vector2(12,12),Vector2(12,93)]),ink,1.5,true)
	if marked:
		draw_polyline(PackedVector2Array([Vector2(-172,22),Vector2(-172,-48),Vector2(-88,-48),Vector2(-88,22)]),Color("775541"),2,true)
		draw_arc(Vector2(-157,22),54,PI*1.5,TAU,22,Color("775541"),2,true)
		draw_line(Vector2(-157,22),Vector2(-157,-32),Color("775541"),2,true)
		draw_string(HAND,Vector2(-230,63),"Door here. Not on plan.",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("654b3c"))
		draw_string(HAND,Vector2(-166,-18),"recess",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("654b3c"))
func _draw() -> void:
	var aligned: bool=game.events.get("call_plan_aligned",false)
	draw_rect(Rect2(8,5,784,386),Color("353c35"));draw_rect(Rect2(19,16,762,363),Color("d0c8a0"))
	draw_set_transform(CENTRE)
	draw_rect(SHEET,Color("c5b996"));draw_texture_rect(PAPER,SHEET,false,Color(1,1,1,.25));plan(false)
	draw_string(HAND,Vector2(-230,-126),"PROPERTY SERVICES / No. 17 / ISSUED 1998",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("4b4b3b"))
	if ready_for_match:
		draw_set_transform(CENTRE+offset,angle)
		draw_rect(SHEET,Color(.79,.77,.62,.28 if placed else .65));draw_rect(SHEET,Color(.47,.42,.29,.7),false,1)
		plan(true)
		draw_string(HAND,Vector2(-230,-99),"S. WARD / measured in cellar / after the lounge",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("4c594a"))
	draw_set_transform(Vector2.ZERO)
	var text_: String="The stairwell walls line up. His sketch adds a door on the west side." if aligned else ("Place the tracing and match the stairs, walls and service line." if ready_for_match else "The printed 1998 plan is already here. Dad kept his measured tracing in the old reel sleeve.")
	draw_string(ThemeDB.fallback_font,Vector2(22,410),text_,HORIZONTAL_ALIGNMENT_LEFT,756,17,Color("bbc1ae"))
