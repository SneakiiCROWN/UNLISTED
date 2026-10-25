extends Node
var game: Node
func run(current: Node) -> void:
	game=current
	var root:=get_tree().root
	root.set_flag(Window.FLAG_NO_FOCUS,true)
	var output:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--exterior-output="):output=arg.trim_prefix("--exterior-output=")
	assert(not output.is_empty())
	DirAccess.make_dir_recursive_absolute(output)
	var viewport: SubViewport
	if game.automated_qa:
		viewport=game.get_viewport() as SubViewport
	else:
		viewport=SubViewport.new();root.add_child(viewport);game.reparent(viewport)
	var capture_size:=Vector2i(1920,1080)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-size="):
			var dimensions:=arg.trim_prefix("--capture-size=").split("x")
			capture_size=Vector2i(int(dimensions[0]),int(dimensions[1]))
	assert(capture_size.x>=1280 and capture_size.x<=3840 and capture_size.y>=720 and capture_size.y<=2160)
	viewport.size=capture_size
	viewport.size_2d_override=Vector2i(1280,720);viewport.size_2d_override_stretch=true
	viewport.audio_listener_enable_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	game.checkpoint_path=output.path_join("fixture_checkpoint.json")
	game.new_game();game.presentation.clear_transients()
	var terrain:=game.get_node_or_null("BriarLaneExterior/ContinuousWoodlandTerrain")
	if terrain:print("TERRAIN_NORMAL ",terrain.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL][0])
	game.player.active=false;game.events.chair=true;game.threat.enabled=false
	game.horror.set_process(false);game.horror.set_physics_process(false)
	game.doors.service.locked=false;game.doors.service.set_open(true,0.01)
	game.doors.shed.locked=false;game.doors.shed.set_open(true,0.01)
	var views:=[
		["01_porch_approach",Vector3(0,0.04,8.2),Vector3(0,1.8,3.6)],
		["02_entrance_sign",Vector3(1.15,0.04,5.55),Vector3(1.25,1.65,4.14)],
		["03_porch_sky_horizon",Vector3(1.2,0.04,6.4),Vector3(5,6.5,22)],
		["04_kitchen_window",Vector3(-6.35,0.04,1),Vector3(-15,2,1)],
		["05_lounge_window",Vector3(6.3,0.04,2),Vector3(15,2,2)],
		["06_rear_door_inside",Vector3(-4.5,0.04,-8.4),Vector3(-7,1.7,-14)],
		["07_rear_door_outside",Vector3(-5.2,0.04,-12.2),Vector3(-4.5,1.7,-9.7)],
		["08_service_yard",Vector3(-11,0.04,-12.5),Vector3(-17,1.7,-14)],
		["09_shed_entrance",Vector3(-13,0.04,-14),Vector3(-17,1.8,-14)],
		["10_shed_perimeter",Vector3(-21,0.04,-17.8),Vector3(-16,2,-14)],
		["11_yard_horizon",Vector3(-12,0.04,-17.8),Vector3(-12,4,-29)],
		["12_front_three_quarter",Vector3(-8,0.04,10),Vector3(0,2.3,3)],
		["13_east_foundation",Vector3(10,0.04,0),Vector3(7,1.8,-4)],
		["14_spawn_turnaround",Vector3(0,0.04,9),Vector3(0,1.3,23)],
		["15_front_gate",Vector3(0,0.04,14.5),Vector3(0,0.9,17)],
		["16_lane_toward_house",Vector3(0,0.04,23),Vector3(0,2.4,3.5)],
		["17_lane_east",Vector3(4,0.04,23),Vector3(26,1.8,27)]
	]
	var manifest:=[]
	for spec in views:
		game.player.position=spec[1];game.player.rotation=Vector3.ZERO
		game.player.camera.rotation=Vector3.ZERO;game.player.camera.current=true
		game.player.camera.look_at(spec[2]);game.player.torch.visible=true
		await get_tree().create_timer(0.45).timeout
		game.presentation.clear_transients();game.subtitle.text="";game.presentation.hud.visible=false
		await RenderingServer.frame_post_draw
		var rendered:=viewport.get_texture().get_image()
		assert(rendered.get_size()==capture_size)
		var saved:=rendered.save_png(output.path_join(spec[0]+".png"))
		if saved!=OK or rendered.get_size()!=capture_size:
			push_error("Exterior image capture failed: "+str(spec[0])+" error="+str(saved))
			await game.qa_exit(1);return
		manifest.append({"view":spec[0],"player":str(spec[1]),"look_at":str(spec[2]),"resolution":str(capture_size),"fixture":"Explicit player-height visual placement; not traversal proof"})
	if "--sky-diagnostic" in OS.get_cmdline_user_args():
		for node in game.find_children("*","GeometryInstance3D",true,false):node.visible=false
		game.presentation.film.visible=false
		game.player.position=Vector3(1.2,0.04,6.4);game.player.camera.look_at(Vector3(5,6.5,22))
		await get_tree().create_timer(0.2).timeout;await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output.path_join("D_sky_only.png"))
		for node in game.get_children():
			if node is WorldEnvironment:node.environment.fog_enabled=false
		await get_tree().create_timer(0.2).timeout;await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output.path_join("D_sky_without_fog.png"))
	var file:=FileAccess.open(output.path_join("views.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"\t"));file.close()
	await game.qa_exit(0)
