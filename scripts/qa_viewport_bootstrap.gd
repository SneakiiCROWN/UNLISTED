extends Node
# Alternative QA entry only. Ordinary main.tscn, intro and owner data are intact.
# Construct render resources in their final world instead of moving a live world.
func _ready() -> void:
	call_deferred("boot")

func boot() -> void:
	var args:=OS.get_cmdline_user_args()
	if not Array(args).any(func(a):return str(a).ends_with("-qa")):
		push_error("QA_BOOTSTRAP_REFUSED: an explicit QA mode is required")
		get_tree().quit(93);return
	var size_:=Vector2i(1920,1080)
	for arg in args:
		if arg.begins_with("--capture-size="):
			var values:=arg.trim_prefix("--capture-size=").split("x")
			if values.size()!=2:get_tree().quit(93);return
			size_=Vector2i(int(values[0]),int(values[1]))
	if size_.x<1280 or size_.x>3840 or size_.y<720 or size_.y>2160:get_tree().quit(93);return
	var window:=get_tree().root
	window.set_flag(Window.FLAG_NO_FOCUS,true);window.set_flag(Window.FLAG_MOUSE_PASSTHROUGH,true);window.position=Vector2i(-16000,-16000)
	var target:=SubViewport.new();target.name="IsolatedAutomatedViewport";target.own_world_3d=true;target.audio_listener_enable_3d=true
	target.size=size_;target.size_2d_override=Vector2i(roundi(720.0*float(size_.x)/size_.y),720);target.size_2d_override_stretch=true
	target.render_target_update_mode=SubViewport.UPDATE_ALWAYS;window.add_child(target)
	var game: Node=load("res://scenes/main.tscn").instantiate();game.set_meta("qa_constructed_in_viewport",true)
	print("QA_VIEWPORT_BOOTSTRAP before game construction size=",size_)
	target.add_child(game)
