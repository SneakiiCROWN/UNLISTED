extends "res://scripts/recording_repair_qa.gd"
# Real movement and focused interaction; only legacy migration uses a fixture.
func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec()
	output=OS.get_executable_path().get_base_dir().path_join("QA/arrival")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	if "--car-presentation" in OS.get_cmdline_user_args():await car_presentation();return
	if "--comparison-reread-only" in OS.get_cmdline_user_args():
		var source:=""
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--earned-checkpoint="):source=arg.trim_prefix("--earned-checkpoint=")
		var earned: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
		earned.ended=false # Revisit the earned evidence in an explicit post-route fixture.
		g.apply_save(earned);g.player.position=Vector3(3.3,.04,-7.3);g.player.velocity=Vector3.ZERO;g.presentation.clear_transients();await wait(.4)
		check("earned comparison is already present",g.events.get("memory_confirmed",false))
		await use("source_copy",false)
		check("physical source copy uses canonical title and body",g.presentation.section=="document" and g.events.notes.has(g.NOTES.COMPARISON_TITLE) and g.events.notes[g.NOTES.COMPARISON_TITLE]==g.NOTES.SOURCE_COPY)
		await shot("R07_corrected_comparison");await finish_arrival();return
	g.new_game();g.presentation.clear_transients();await wait(1)
	check("new case starts outside front gate",g.player.position.z>18.5 and not g.doors.front_gate.opened)
	await shot("G01_arrival_at_gate")
	await travel(Vector2(0,18.3),"walk to garden gate");await use("front_gate")
	await travel(Vector2(0,15.1),"walk through garden gate")
	await travel(Vector2(0,5.3),"walk from gate to front door")
	check("first door prompt is knock",g.interaction_name("front")=="Knock")
	await shot("G02_knock_prompt")
	g.player.camera.look_at(g.targets.front.global_position);await wait(.2)
	await action("interact");await action("interact")
	check("extra press cannot bypass knock",g.doors.front.arrival_busy and not g.doors.front.opened)
	await action("ui_cancel");var angle: float=g.doors.front.pivot.rotation.y;await wait(.5)
	check("pause freezes first-door movement",g.menu_open and is_equal_approx(angle,g.doors.front.pivot.rotation.y))
	g.presentation.buttons.Resume.pressed.emit();await wait(1.5)
	check("one knock eases physical leaf ajar",g.events.get("front_checked",false) and g.events.get("front_ajar",false) and not g.doors.front.opened and absf(g.doors.front.pivot.rotation.y)>.15 and absf(g.doors.front.pivot.rotation.y)<.25)
	check("next prompt opens door",g.interaction_name("front")=="Open door")
	await shot("G03_door_ajar")
	g.save_game();g.load_game();await wait(.2)
	check("retry restores ajar without replaying knock",g.events.get("front_ajar",false) and not g.doors.front.arrival_busy and absf(g.doors.front.pivot.rotation.y)>.15)
	await use("front");await wait(.3)
	check("second press fully opens leaf",g.doors.front.opened and absf(g.doors.front.pivot.rotation.y)>1.4 and not g.events.get("front_ajar",false))
	await travel(Vector2(0,1),"enter through front door");await travel(Vector2(0,2.5),"inside door approach")
	await use("front");await wait(.3)
	check("subsequent close is normal",not g.doors.front.opened and absf(g.doors.front.pivot.rotation.y)<.02)
	await use("front");await wait(.3)
	check("subsequent open is normal",g.doors.front.opened and absf(g.doors.front.pivot.rotation.y)>1.4)
	await shot("G04_normal_door")
	# A pre-feature save never receives a retroactive knock or relocation.
	var old: Dictionary=g.save_data();old.events.erase("arrival_check");old.events.erase("front_checked");old.events.erase("front_ajar");old.doors.front=false
	g.apply_save(old);await wait(.1)
	check("legacy save retains its position",g.player.position.distance_to(Vector3(old.pos[0],old.pos[1],old.pos[2]))<.2)
	await use("front");await wait(.3)
	check("legacy door opens on first press",g.doors.front.opened and absf(g.doors.front.pivot.rotation.y)>1.4)
	await finish_arrival()

func finish_arrival() -> void:
	var failed:=0
	for entry in checks:
		if not entry.passed:failed+=1
	var file=FileAccess.open(output.path_join("repair_report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"elapsed_seconds":seconds()},"\t"));file.close()
	print("ARRIVAL_QA_COMPLETE passed=",checks.size()-failed," failed=",failed)
	g.qa_exit(0 if failed==0 else 1)


func car_presentation() -> void:
	g.new_game();await wait(2);g.presentation.clear_transients();g.threat.enabled=false;g.threat.reset();g.events.chair=true
	var car: Node3D=g.get_node("BriarLaneExterior/EliArrivalCar")
	var bounds:=AABB();var first:=true
	for mesh in g.all_meshes(car):
		var actual: AABB=mesh.global_transform*mesh.get_aabb();bounds=actual if first else bounds.merge(actual);first=false
	check("arrival car has human scale and grounded wheels",bounds.size.x>4.3 and bounds.size.x<4.7 and bounds.size.y>1.4 and bounds.size.y<1.7 and bounds.position.y>-.05 and bounds.position.y<.03,str(bounds))
	g.player.camera.look_at(Vector3(-4.5,1.0,21.6));await wait(.3);await shot("C01_car_from_arrival")
	g.player.position=Vector3(-2,.04,18.8);g.player.camera.look_at(Vector3(-5.6,.85,21.6));await wait(.3)
	for spec in [[0,0.0,"C02_clean_world"],[1,.32,"C03_modern_psx"],[2,.65,"C04_stronger_retro"]]:
		g.presentation.prefs.data.visual_preset=spec[0];g.presentation.prefs.data.retro=spec[1];g.presentation.apply_preferences(false);await wait(.2);await shot(spec[2])
	g.presentation.prefs.data.visual_preset=1;g.presentation.prefs.data.retro=.32;g.presentation.apply_preferences(false)
	if not "--car-layouts-only" in OS.get_cmdline_user_args():
		await travel(Vector2(-5.6,19.4),"approach parked driver side")
		g.player.rotation.y=PI;Input.action_press("forward");await wait(1);Input.action_release("forward");await wait(.2)
		check("real movement meets car surface without passing through",g.player.position.z>19.8 and g.player.position.z<20.95,str(g.player.position))
		await shot("C05_fitted_collision")
		await travel(Vector2(-5.6,19.3),"step back from driver side")
		await travel(Vector2(-2.8,19.3),"walk around front of parked car")
		await travel(Vector2(-2.8,24),"walk around nose to open lane")
		await travel(Vector2(-8.4,24),"walk behind parked car along lane")
		await travel(Vector2(-8.4,19.3),"walk around rear of car")
		await travel(Vector2(0,19.3),"return to gate approach")
		g.player.camera.look_at(Vector3(-5.6,1,21.6));await shot("C06_gate_car_context")
		g.save_game();g.load_game();await wait(.2)
		check("car survives load without changing arrival or gate",is_instance_valid(car) and not g.doors.front_gate.opened and not g.events.get("front_checked",false))
	# Same-eye-height interior comparison, no UI pixelation.
	g.player.position=Vector3(0,.04,-4);g.player.camera.look_at(Vector3(0,1.4,-9));await wait(.2)
	for spec in [[0,0.0,"C07_hall_clean"],[1,.32,"C08_hall_modern_psx"]]:
		g.presentation.prefs.data.visual_preset=spec[0];g.presentation.prefs.data.retro=spec[1];g.presentation.apply_preferences(false);await wait(.2);await shot(spec[2])
	g.presentation.show_settings();g.presentation.fill_settings("Display");await wait(.3)
	g.presentation.controls.visual_preset.item_selected.emit(2);await wait(.1)
	var actual_cfg=load("res://scripts/preferences.gd").new();actual_cfg.path=g.presentation.prefs.path;actual_cfg.load_file()
	check("actual graphics preset updates shader and persists",actual_cfg.data.visual_preset==2 and is_equal_approx(g.presentation.film.material.get_shader_parameter("raster_height"),360.0))
	g.presentation.controls.visual_preset.item_selected.emit(1);g.presentation.controls.retro.value=.28;await wait(.1);actual_cfg.load_file()
	check("comfort intensity slider is functional and saved",is_equal_approx(actual_cfg.data.retro,.28) and is_equal_approx(g.presentation.film.material.get_shader_parameter("retro"),.28))
	check("Display Back remains visible",g.get_viewport().get_visible_rect().encloses(g.presentation.buttons.Back.get_global_rect()))
	# Settings retain the owner's selection; defaults only affect new settings files.
	var cfg=load("res://scripts/preferences.gd").new();cfg.path=output.path_join("visual_settings.cfg");cfg.data.visual_preset=0;cfg.data.retro=.11;cfg.save_file();cfg.load_file()
	check("existing clean and custom intensity persist",cfg.data.visual_preset==0 and is_equal_approx(cfg.data.retro,.11))
	check("world filter precedes all readable UI",g.presentation.film.get_index()<g.presentation.card.get_index())
	await shot("C09_readable_settings");await finish_arrival()
