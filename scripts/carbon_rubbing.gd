extends Control
# Graphite coverage follows pencil strokes; old row progress remains readable.
const TEXT:=["Kitchen radio: 104.6.","I phoned home. Eli answered. He's safe.","I shut the lounge door. Now it's his room."]
const HAND=preload("res://assets/fonts/Kalam-Regular.ttf")
const PAPER=preload("res://assets/original/aged_paper.png")
var game: Node
var coverage: Array=[]
var cells: Array=[]
var strokes: Array[Vector2]=[]
var dragging:=false
var pencil:=Vector2(-100,-100)
var sound_wait:=0.0
var friction: AudioStreamPlayer
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	custom_minimum_size=Vector2(800,390);mouse_filter=Control.MOUSE_FILTER_STOP
	coverage=game.events.get("carbon_coverage",[0.0,0.0,0.0]).duplicate()
	cells=game.events.get("carbon_cells",[]).duplicate(true)
	if cells.size()!=3:
		cells=[]
		for row in 3:
			var values: Array=[]
			for col in 16:values.append(1.0 if game.events.get("carbon_read",false) or col<float(coverage[row])*16 else 0.0)
			cells.append(values)
	for value in game.events.get("carbon_strokes",[]):
		if value is Array and value.size()==2:strokes.append(Vector2(value[0],value[1]))
	friction=AudioStreamPlayer.new();friction.stream=load("res://assets/audio/foley/paper_handling.ogg");friction.bus="SFX";friction.volume_db=-35;add_child(friction)
	update_ink()
func _process(delta: float) -> void:
	sound_wait=maxf(0,sound_wait-delta)
	if game.presentation.section!="document" and friction.playing:friction.stop()
func _draw() -> void:
	var sheet:=Rect2(23,16,754,347)
	for i in range(12,0,-1):draw_rect(Rect2(sheet.position+Vector2(i*.7,i*1.1),sheet.size),Color(0,0,0,.012))
	draw_rect(sheet,Color("c5bda1"))
	draw_texture_rect(PAPER,sheet,false,Color(1.25,1.15,.96,.22))
	for i in range(8):draw_rect(Rect2(sheet.position+Vector2(i,i),sheet.size-Vector2(i*2,i*2)),Color(.26,.21,.15,.012),false,1)
	draw_line(Vector2(405,17),Vector2(408,361),Color(.25,.22,.17,.13),2)
	draw_line(Vector2(409,17),Vector2(411,361),Color(1,.95,.78,.22),1)
	draw_line(Vector2(24,184),Vector2(775,187),Color(.24,.20,.15,.12),1)
	for x in [54,66]:draw_arc(Vector2(x,34),2.2,0,TAU,9,Color(.27,.24,.19,.55),1)
	draw_string(HAND,Vector2(58,63),"23:18   /   S. Ward",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color(.23,.24,.20,.72))
	for p in strokes:
		for k in 4:draw_line(p+Vector2(-18,-5+k*3),p+Vector2(18,4+k*2),Color(.1,.12,.11,.045),1,true)
	for row in 3:
		var x:=58.0;var text: String=TEXT[row]
		for i in text.length():
			var width:=HAND.get_string_size(text[i],HORIZONTAL_ALIGNMENT_LEFT,-1,28).x
			var column:=clampi(int((x-40)/44.0),0,15)
			var amount:=1.0 if game.events.get("carbon_read",false) else float(cells[row][column])
			var alpha:=.018+amount*(.61+.12*sin(i*2.1+row))
			draw_string(HAND,Vector2(x,118+row*74+sin(i*1.73+row)*.8),text[i],HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color(.14,.17,.15,alpha))
			x+=width
	if Rect2(Vector2(20,15),Vector2(760,350)).has_point(pencil):
		draw_line(pencil+Vector2(5,-7),pencil+Vector2(64,-80),Color(.08,.08,.06,.20),9,true)
		draw_line(pencil+Vector2(3,-5),pencil+Vector2(59,-77),Color("73634b"),7,true)
		draw_line(pencil+Vector2(4,-6),pencil+Vector2(59,-76),Color("b19969"),2,true)
		draw_colored_polygon(PackedVector2Array([pencil,pencil+Vector2(1,-12),pencil+Vector2(10,-7)]),Color("c5ae82"))
		draw_line(pencil,pencil+Vector2(3,-5),Color("343a33"),2,true)
func rub(point: Vector2) -> void:
	if game.events.get("carbon_read",false):return
	if not Rect2(Vector2(40,85),Vector2(705,220)).has_point(point):return
	if not strokes.is_empty() and strokes[-1].distance_to(point)<7:return
	strokes.append(point)
	if strokes.size()>180:strokes.pop_front()
	for row in 3:
		if absf(point.y-(113+row*74))>30:continue
		var col:=clampi(int((point.x-40)/44.0),0,15)
		for index in range(maxi(0,col-1),mini(16,col+2)):cells[row][index]=minf(1,float(cells[row][index])+.55)
		coverage[row]=0.0
		for value in cells[row]:coverage[row]+=float(value)/16
	if sound_wait<=0:
		friction.pitch_scale=.94+float(strokes.size()%5)*.025;friction.play();sound_wait=.42
	update_ink();queue_redraw()
func update_ink() -> void:
	game.events.carbon_coverage=coverage.duplicate();game.events.carbon_cells=cells.duplicate(true)
	var saved: Array=[]
	for p in strokes:saved.append([p.x,p.y])
	game.events.carbon_strokes=saved
	if float(coverage.min())>=.78 and not game.events.get("carbon_read",false):game.chapter.complete_rubbing()
	queue_redraw()
func complete_accessibly() -> void:
	coverage=[1.0,1.0,1.0]
	for row in 3:
		for col in 16:cells[row][col]=1.0
	update_ink();queue_redraw()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		dragging=event.pressed;pencil=event.position
		if not dragging:game.save_game()
		else:rub(event.position)
		accept_event()
	if event is InputEventMouseMotion:
		pencil=event.position
		if dragging:rub(event.position);accept_event()
		queue_redraw()
