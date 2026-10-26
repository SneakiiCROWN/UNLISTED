extends Node
# Explicit alternative entry scene for diagnosis only. Never selected by New Game
# or project.godot. Original world/intro are loaded intact after the diagnostic idle.
var output:=""
var begun:=0
var previous:=0
var phase:="title_without_world"
var ui: Control
var game: Node3D
var passed: Array=[]
func record(event: String) -> void:
	var row:={"event":event,"phase":phase,"seconds":(Time.get_ticks_usec()-begun)/1000000.0,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
	passed.append(row)
	var f:=FileAccess.open(output.path_join("deferred_report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"scope":"Diagnostic2D title, no gameplay construction before boot; actual original New Game afterwards, private data only.","events":passed},"\t"));f.close()
	print("DEFERRED_DIAGNOSTIC ",event)
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;begun=Time.get_ticks_usec()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--case-output="):output=arg.trim_prefix("--case-output=")
	assert(not output.is_empty() and "--visual-probe" in OS.get_cmdline_user_args())
	DirAccess.make_dir_recursive_absolute(output)
	var cfg:=ConfigFile.new();cfg.load(OS.get_executable_path().get_base_dir().path_join("QA/presentation_settings.cfg"))
	if int(cfg.get_value("presentation","display_mode",0))==1:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:DisplayServer.window_set_size(cfg.get_value("presentation","resolution",Vector2i(1280,720)))
	ui=Control.new();ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.theme=load("res://themes/unlisted.tres");add_child(ui)
	var shade:=ColorRect.new();shade.color=Color("111a18");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(shade)
	var list:=VBoxContainer.new();ui.add_child(list);list.position=Vector2(95,108);list.custom_minimum_size=Vector2(600,0)
	for text_ in ["DIAGNOSTIC ONLY / GAMEPLAY WORLD NOT CREATED","UNLISTED","No Record. No Exit."]:
		var label:=Label.new();label.text=text_;label.add_theme_font_size_override("font_size",58 if text_=="UNLISTED" else 18);list.add_child(label)
	var start: Button=load("res://scenes/ui/menu_button.tscn").instantiate();start.text="New Game / deferred initialization";list.add_child(start);start.pressed.connect(boot)
	var quit: Button=load("res://scenes/ui/menu_button.tscn").instantiate();quit.text="Quit diagnostic";list.add_child(quit);quit.pressed.connect(func():record("menu Quit");get_tree().quit())
	record("minimal title ready")
func boot() -> void:
	if phase!="title_without_world":return
	phase="building_original_world";record("New Game requested; construction starts now")
	game=load("res://scenes/main.tscn").instantiate()
	game.checkpoint_path=output.path_join("checkpoint.json")
	get_tree().root.add_child(game);get_tree().current_scene=game
	game.presentation.prefs.path=output.path_join("settings.cfg")
	ui.visible=false;game.presentation.begin_new_game();record("original cinematic started")
	phase="arrival"
func _process(_delta: float) -> void:
	var seconds_: int=int((Time.get_ticks_usec()-begun)/1000000)
	if seconds_/15!=previous:
		previous=seconds_/15;record("heartbeat")
	if phase=="title_without_world" and seconds_>=135:boot()
	elif phase=="arrival" and is_instance_valid(game) and game.presentation.section=="game":
		phase="recovery_checks";record("original arrival restores control="+str(game.player.active))
		game.presentation.show_menu(false)
		game.presentation.buttons.Resume.pressed.emit()
		await get_tree().create_timer(.3,true).timeout
		record("pause/resume control="+str(game.player.active))
		game.save_game(true);game.load_game();record("private save/load control="+str(game.player.active))
		game.presentation.return_to_title();record("return to original title section="+str(game.presentation.section))
		phase="completed";record("completed")
		await game.qa_exit(0)
