extends "res://scripts/recording_repair_qa.gd"
var samples: Array=[]
func pad(button: int) -> void:
	for down in [true,false]:
		var event:=InputEventJoypadButton.new();event.button_index=button;event.pressed=down;event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event);await wait(.08)
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	check("Production profile selected before world construction",g.atmosphere_profile!=null and g.atmosphere_profile.active==g.presentation.prefs.data.atmosphere_mode)
	await wait(1);await shot("A00_ordinary_title")
	g.presentation.settings_origin="title";g.presentation.last_tab="Display";g.presentation.show_settings()
	await wait(.3)
	# Select the real graphics tab through the same UI builder, if its label differs.
	g.presentation.fill_settings("Display")
	await wait(.2);await shot("A01_settings")
	check("Settings panel stays inside native layout",g.presentation.card.get_global_rect().end.y<=g.presentation.screen.size.y)
	check("Production menu exposes three atmosphere choices",g.presentation.controls.has("atmosphere_mode"))
	if g.presentation.controls.has("atmosphere_mode"):
		var option: OptionButton=g.presentation.controls.atmosphere_mode
		var original: int=g.presentation.prefs.data.atmosphere_mode
		var next: int=(original+1)%3
		option.item_selected.emit(next)
		var loaded=load("res://scripts/preferences.gd").new();loaded.path=g.presentation.prefs.path;loaded.load_file()
		check("Settings selection persists through actual menu signal",loaded.data.atmosphere_mode==next)
		check("Selection defers live GPU and collision replacement",g.atmosphere_profile.active==original)
		option.item_selected.emit(original)
	g.presentation.settings_back()
	g.presentation.buttons["New Game"].pressed.emit()
	for i in 350:
		if g.presentation.section=="game":break
		await wait(.1)
	check("Unmodified arrival reaches player-controlled game",g.presentation.section=="game" and g.player.active)
	await shot("A02_arrival_at_gate")
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS;AudioServer.add_bus_effect(0,recorder)
	recorder.set_recording_active(true);recording=true
	await travel(Vector2(0,18.3),"reach gate")
	await use("front_gate")
	await travel(Vector2(0,15.3),"walk through gate")
	await travel(Vector2(0,8),"walk actual approach")
	g.player.camera.look_at(Vector3(0,1.3,3.5));await shot("A03_integrated_front")
	g.save_game(true);g.load_game();await wait(.4)
	check("Case save/load retains startup graphics choice",g.atmosphere_profile.active==g.atmosphere_at_boot and g.player.active)
	await action("pause");check("Pause suspends game",g.menu_open and get_tree().paused)
	await action("pause");check("Resume restores game",not g.menu_open and not get_tree().paused)
	await pad(JOY_BUTTON_START);check("Controller Start pauses integrated gameplay",g.menu_open and get_tree().paused)
	await pad(JOY_BUTTON_B);check("Controller B resumes integrated gameplay",not g.menu_open and not get_tree().paused)
	var views=[
		["A04_porch_out",Vector3(0,.04,5.8),Vector3(0,1.3,21)],
		["A05_lounge",Vector3(2.7,.04,2.6),Vector3(5.5,.9,.2)],
		["A06_window",Vector3(5.9,.04,2.6),Vector3(7.5,1.6,2)],
		["A07_office",Vector3(4.9,.04,-7.5),Vector3(5,1,-9.4)],
		["A08_cellar",Vector3(0,-2.99,-17.2),Vector3(-1.5,-1.5,-23)],
		["A09_service_yard",Vector3(-11,.04,-10.9),Vector3(-17,1,-14)],
		["A10_shed",Vector3(-13,.04,-13.5),Vector3(-17,1,-15)],
		["A11_woodland",Vector3(-9,.04,-20),Vector3(-20,3,-35)],
		["A12_car",Vector3(-3,.04,20),Vector3(-6,1,22)]]
	# These labelled eye-height placements are visual inspections, not route proof.
	recording=false
	for view in views:
		g.player.position=view[1];g.player.velocity=Vector3.ZERO;g.player.camera.look_at(view[2]);await wait(.7);await shot(view[0])
	var probes:=g.find_children("*","ReflectionProbe",true,false)
	check("No rejected reflection probes",probes.is_empty())
	var no_static:=true
	for mesh in g.find_children("*","MeshInstance3D",true,false):
		var mat: Material=mesh.material_override
		if mat is ShaderMaterial and mat.shader.resource_path=="res://shaders/phase2_window.gdshader":
			if mat.get_shader_parameter("reflection_strength")!=0.0:no_static=false
	check("No misleading static room image",no_static)
	g.presentation.prefs.data.reduced_motion=true;g.presentation.apply_preferences(false)
	var frozen:=true
	for mesh in g.find_children("*","MeshInstance3D",true,false):
		var mat: Material=mesh.material_override
		if mat is ShaderMaterial and mat.shader.resource_path=="res://shaders/phase2_window.gdshader" and mat.get_shader_parameter("motion")!=0.0:frozen=false
	check("Reduced motion reaches wet glass",frozen)
	var cfg:=FileAccess.open(output.path_join("atmosphere.json"),FileAccess.WRITE);cfg.store_string(JSON.stringify(g.atmosphere_profile.report,"\t"));cfg.close()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-next-atmosphere="):
			g.presentation.prefs.data.atmosphere_mode=int(arg.trim_prefix("--save-next-atmosphere="));g.presentation.persist()
	await finish_run()
