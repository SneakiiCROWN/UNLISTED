extends Control
# Original paper interaction: strokes reveal pressure marks, not a timed progress bar.
var game: Node
var coverage: Array=[]
var lines: Array[Label]=[]
var strokes: Array[Vector2]=[]
var dragging:=false
const TEXT:=["104.6 / HOME","ELI IS AT HOME. I RANG.","THE DOOR WAS SHUT WHEN IT CHANGED."]
func _ready() -> void:
	custom_minimum_size=Vector2(800,300);mouse_filter=Control.MOUSE_FILTER_STOP
	coverage=game.events.get("carbon_coverage",[0.0,0.0,0.0]).duplicate()
	for i in 3:
		var ink:=Label.new();add_child(ink);ink.text=TEXT[i];ink.position=Vector2(52,68+i*68)
		ink.add_theme_font_size_override("font_size",24);ink.add_theme_color_override("font_color",Color("272c29"));ink.mouse_filter=Control.MOUSE_FILTER_IGNORE;lines.append(ink)
	update_ink()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("9d947a"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("554e3c"),false,2)
	for i in 28:draw_line(Vector2(18,10+i*10),Vector2(size.x-18,10+i*10),Color(.35,.30,.22,.035),1)
	for i in strokes.size():
		var p: Vector2=strokes[i]
		draw_line(p-Vector2(21,5),p+Vector2(21,5),Color(.15,.17,.15,.055),8,true)
		for k in 3:draw_line(p+Vector2(-20,-4+k*3),p+Vector2(20,5+k*3),Color(.1,.12,.1,.075),1,true)
func rub(point: Vector2) -> void:
	if game.events.get("carbon_read",false):return
	if not Rect2(Vector2(28,35),size-Vector2(56,65)).has_point(point):return
	if not strokes.is_empty() and strokes[-1].distance_to(point)<7:return
	strokes.append(point)
	if strokes.size()>300:strokes.pop_front()
	for i in 3:
		if absf(point.y-(82+i*68))<28:coverage[i]=minf(1.0,float(coverage[i])+.07)
	update_ink();queue_redraw()
func update_ink() -> void:
	game.events.carbon_coverage=coverage.duplicate()
	for i in 3:lines[i].modulate.a=.035+.965*float(coverage[i])
	if float(coverage.min())>=.78 and not game.events.get("carbon_read",false):
		game.chapter.complete_rubbing()
func complete_accessibly() -> void:
	coverage=[1.0,1.0,1.0];update_ink();queue_redraw()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		dragging=event.pressed
		if not dragging:game.save_game()
		else:rub(event.position)
		accept_event()
	if event is InputEventMouseMotion and dragging:rub(event.position);accept_event()
