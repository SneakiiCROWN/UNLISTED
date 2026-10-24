extends Control
# Saved observation coverage, not persistent glowing ink. Filename retained for old QA/save references.
const HAND=preload("res://assets/fonts/Kalam-Regular.ttf")
const PAPER=preload("res://assets/original/aged_paper.png")
var game: Node
var coverage: Array=[]
var cells: Array=[]
var dragging:=false
var beam:=Vector2(-200,-200)
var previous:=Vector2(-200,-200)
var auto_clock:=-1.0
var TEXT: Array[String]=[]
var needed: Array[int]=[]
var dirty:=false
func _ready() -> void:
	name="ReportSleeveScan"
	process_mode=Node.PROCESS_MODE_ALWAYS
	custom_minimum_size=Vector2(800,390);mouse_filter=Control.MOUSE_FILTER_STOP;focus_mode=Control.FOCUS_ALL
	TEXT=game.PUZZLES.lines(game.events)
	if game.events.get("carbon_read",false) and not game.events.has("uv_rows"):game.events.uv_rows=[true,true,true]
	for line in TEXT:needed.append(clampi(ceili((18+HAND.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,28).x)/44.0),1,16))
	coverage=game.events.get("carbon_coverage",[0.0,0.0,0.0]).duplicate()
	cells=game.events.get("carbon_cells",[]).duplicate(true)
	if cells.size()!=3:
		cells=[]
		for row in 3:
			var values: Array=[]
			for col in 16:values.append(1.0 if game.events.get("carbon_read",false) or col<float(coverage[row])*16 else 0.0)
			cells.append(values)
	grab_focus();queue_redraw()
func _process(delta: float) -> void:
	if not is_visible_in_tree() or game.presentation.section!="document":return
	game.equipment.step_power(delta,false)
	var stick:=Input.get_vector("inspect_left","inspect_right","inspect_up","inspect_down")
	if stick.length()>.1:
		auto_clock=-1
		if beam.x<0:beam=Vector2(400,180)
		beam=(beam+stick*delta*360).clamp(Vector2(40,85),Vector2(745,305));scan(beam)
	if auto_clock>=0 and game.equipment.is_uv():
		auto_clock+=delta
		var row:=mini(2,int(auto_clock/3.2));var progress:=fmod(auto_clock,3.2)/3.2
		beam=Vector2(45+progress*700,113+row*74)
		scan(beam)
		if auto_clock>=9.6:auto_clock=-1;commit_progress()
	queue_redraw()
func _draw() -> void:
	var uv: bool=game.equipment.is_uv()
	var sheet:=Rect2(23,16,754,347)
	for i in range(8,0,-1):draw_rect(Rect2(sheet.position+Vector2(i*.7,i*1.1),sheet.size),Color(0,0,0,.018))
	draw_rect(sheet,Color("313b47") if uv else Color("b8b19b"))
	draw_texture_rect(PAPER,sheet,false,Color(.55,.6,.8,.20) if uv else Color(1.2,1.1,.95,.24))
	draw_line(Vector2(405,17),Vector2(408,361),Color(.2,.19,.16,.17),2)
	draw_string(HAND,Vector2(58,63),"REPORT SLEEVE / S. WARD",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color(.55,.61,.63,.8) if uv else Color(.23,.24,.2,.72))
	if uv and sheet.has_point(beam):
		for i in range(9,0,-1):draw_circle(beam,12*i,Color(.24,.18,.65,.016))
	for row in 3:
		var x:=58.0;var text: String=TEXT[row]
		for i in text.length():
			var width:=HAND.get_string_size(text[i],HORIZONTAL_ALIGNMENT_LEFT,-1,28).x
			var point:=Vector2(x+width*.5,108+row*74)
			var light:=smoothstep(105.0,35.0,point.distance_to(beam)) if uv else 0.0
			if light>.005:draw_string(HAND,Vector2(x,118+row*74+sin(i*1.73+row)*.8),text[i],HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color(.45,.95,.74,light*.95))
			x+=width
	if uv and sheet.has_point(beam):draw_arc(beam,74,0,TAU,50,Color(.46,.5,.9,.12),1,true)
	draw_string(ThemeDB.fallback_font,Vector2(45,383),"Recorded in field notes" if game.events.get("carbon_read",false) else "Move the UV beam over the sleeve to reveal the ink",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("a6aea7"))
func scan(point: Vector2) -> void:
	if not game.equipment.is_uv():return
	if not Rect2(Vector2(40,85),Vector2(705,220)).has_point(point):previous=point;return
	if previous.distance_to(point)<7:return
	previous=point
	dirty=true
	for row in 3:
		if absf(point.y-(113+row*74))>30:continue
		var col:=clampi(int((point.x-40)/44.0),0,15)
		for index in range(maxi(0,col-1),mini(16,col+2)):cells[row][index]=minf(1,float(cells[row][index])+.38)
		coverage[row]=0.0
		for index in needed[row]:coverage[row]+=float(cells[row][index])/needed[row]
	game.events.carbon_coverage=coverage.duplicate();game.events.carbon_cells=cells.duplicate(true)
	var rows: Array=game.events.get("uv_rows",[false,false,false]).duplicate()
	var changed:=false
	for row in 3:
		var read: bool=float(coverage[row])>=.72
		if row==0:
			var number_start:=clampi(int((18+HAND.get_string_size("Kitchen radio: ",HORIZONTAL_ALIGNMENT_LEFT,-1,28).x)/44),0,15)
			for index in range(number_start,needed[0]):read=read and float(cells[0][index])>=.65
		if read and not rows[row]:rows[row]=true;changed=true
	game.events.uv_rows=rows
	if rows[0] and not game.events.get("carbon_read",false):game.chapter.complete_rubbing();dirty=false
	elif changed and game.events.get("carbon_read",false):
		game.events.notes[game.NOTES.INSPECTION_TITLE]=game.NOTES.rubbing_note(game.events);game.save_game(true);dirty=false

	queue_redraw()
func rub(point: Vector2) -> void:
	# Legacy tooling entry, now subject to real UV state and movement.
	beam=point;scan(point)
func complete_accessibly() -> void:
	if not game.equipment.is_uv():game.presentation.notify("Switch the torch to UV light first.");return
	auto_clock=0;previous=Vector2(-200,-200)
func commit_progress() -> void:
	if not dirty:return
	game.save_game(true);dirty=false
func close_sheet() -> void:
	commit_progress();game.presentation.resume_game()
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or game.presentation.section!="document":return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		commit_progress();return
	if event.is_action_pressed("flashlight"):
		game.equipment.cycle();queue_redraw();accept_event()
	elif event.is_action_pressed("torch_tap"):game.equipment.tap_contact();accept_event()
	elif event.is_action_pressed("battery_status"):game.equipment.status();accept_event()
	elif event.is_action_pressed("battery_replace"):game.equipment.replace_pack();accept_event()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		dragging=event.pressed;beam=event.position;auto_clock=-1
		if dragging:scan(beam)
		else:commit_progress()
		accept_event()
	if event is InputEventMouseMotion:
		beam=event.position
		if dragging:scan(beam);accept_event()
		queue_redraw()
