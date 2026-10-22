extends VBoxContainer
var game: Node
var dial: HSlider
var display: Label
var hiss: AudioStreamPlayer
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;custom_minimum_size=Vector2(800,250)
	var p=game.presentation
	display=p.label(self,"",30,"Title")
	p.label(self,"FM   88 -------------------- 108",17,"Meta")
	dial=HSlider.new();dial.min_value=88;dial.max_value=108;dial.step=.1;dial.value=float(game.events.get("receiver_frequency",98.0));dial.custom_minimum_size.y=65;add_child(dial)
	dial.value_changed.connect(tune)
	p.label(self,"Tune the receiver, then listen. Left / right also move the dial.",17)
	p.add_button("Listen to receiver",listen,true,self)
	hiss=AudioStreamPlayer.new();hiss.stream=load("res://assets/audio/wind.wav");hiss.bus="SFX";hiss.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(hiss)
	hiss.finished.connect(func():if is_visible_in_tree():hiss.play())
	tune(dial.value);hiss.play();dial.grab_focus()
func tune(value: float) -> void:
	game.events.receiver_frequency=value
	display.text="%.1f MHz"%value
	if is_instance_valid(hiss):
		var strength:=maxf(0,1-absf(value-game.PUZZLES.station(game.events))/1.5)
		if not game.isolated:strength=0
		hiss.volume_db=-27-strength*13;hiss.pitch_scale=.9+strength*.25
func listen() -> void:
	game.save_game()
	if not game.isolated:
		display.text="INTERFERENCE / LIVE SERVICE FEED";return
	if absf(dial.value-game.PUZZLES.station(game.events))>.051:
		game.sound("latch",game.chapter.radio.global_position,-35)
		return
	game.chapter.receive_return()
	game.presentation.resume_game()
func _process(_delta: float) -> void:
	if is_instance_valid(hiss) and (not is_visible_in_tree() or game.presentation.section!="document"):hiss.stop()
