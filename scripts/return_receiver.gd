extends VBoxContainer
var game: Node
var dial: HSlider
var display: Label
var hiss: AudioStreamPlayer
var committed_frequency:=98.0
var dial_sound: AudioStreamPlayer
var dial_cooldown:=0.0
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;custom_minimum_size=Vector2(800,250)
	var p=game.presentation
	display=p.label(self,"",30,"Title")
	p.label(self,"FM   88 -------------------- 108",17,"Meta")
	dial=HSlider.new();dial.min_value=88;dial.max_value=108;dial.step=.1;dial.value=float(game.events.get("receiver_frequency",98.0));dial.custom_minimum_size.y=65;add_child(dial)
	committed_frequency=dial.value
	dial.value_changed.connect(tune)
	p.label(self,"Turn the dial, then listen. Left / right also adjusts the station.",17)
	p.add_button("Listen",listen,true,self)
	hiss=AudioStreamPlayer.new();hiss.stream=load("res://assets/audio/wind.wav");hiss.bus="SFX";hiss.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(hiss)
	hiss.finished.connect(func():if is_visible_in_tree():hiss.play())
	dial_sound=AudioStreamPlayer.new();dial_sound.stream=load("res://assets/audio/sound_touch/radio_dial.ogg");dial_sound.bus="SFX";dial_sound.volume_db=-34;add_child(dial_sound)
	tune(dial.value);hiss.play();dial.grab_focus()
	var button:=AudioStreamPlayer.new();button.stream=load("res://assets/audio/sound_touch/radio_switch.ogg");button.bus="SFX";button.volume_db=-33;add_child(button);button.finished.connect(button.queue_free);button.play()
func tune(value: float) -> void:
	if is_instance_valid(dial_sound) and dial_cooldown<=0 and not is_equal_approx(value,float(game.events.get("receiver_frequency",98.0))):
		dial_sound.play();dial_cooldown=.22
	game.events.receiver_frequency=value
	display.text="%.1f MHz"%value
	if is_instance_valid(hiss):
		var strength:=maxf(0,1-absf(value-game.PUZZLES.station(game.events))/1.5)
		if not game.isolated:strength=0
		hiss.volume_db=-27-strength*13;hiss.pitch_scale=.9+strength*.25
func listen() -> void:
	commit_progress()
	if not game.isolated:
		display.text="I can only hear interference while the service equipment is running.";return
	if absf(dial.value-game.PUZZLES.station(game.events))>.051:
		game.sound("latch",game.chapter.radio.global_position,-35)
		return
	game.chapter.receive_return()
	game.presentation.resume_game()

func commit_progress() -> void:
	# One write on leaving/explicit listening, never on every dial tick.
	if is_equal_approx(dial.value,committed_frequency):return
	game.events.receiver_frequency=dial.value
	game.save_game(true);committed_frequency=dial.value
func close_radio() -> void:
	commit_progress();game.presentation.resume_game()
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or game.presentation.section!="document":return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		commit_progress() # Leave Back/Pause to the existing presentation handler.
func _process(_delta: float) -> void:
	dial_cooldown=maxf(0,dial_cooldown-_delta)
	if not is_visible_in_tree() or game.presentation.section!="document":
		if is_instance_valid(hiss):hiss.stop()
		if is_instance_valid(dial_sound):dial_sound.stop()
