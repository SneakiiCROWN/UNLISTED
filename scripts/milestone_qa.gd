extends Node

var g: Node
var output := ""
var checks: Array[Dictionary] = []
var performance: Array[Dictionary] = []
func check(id: String,okay: bool,detail := "") -> void:
	checks.append({"name":id,"passed":okay,"detail":detail})
	print("MILESTONE_QA ","PASS " if okay else "FAIL ",id," ",detail)

func wait(seconds := 0.2) -> void:
	await get_tree().create_timer(seconds,true,false,true).timeout

func shot(id: String,pos: Vector3,look: Vector3) -> void:
	g.player.position = pos
	g.player.velocity = Vector3.ZERO
	g.player.camera.look_at(look)
	g.presentation.clear_transients()
	g.subtitle.text = ""
	g.hint_until = 0
	await wait(0.4)
	await RenderingServer.frame_post_draw
	check("capture "+id,g.get_viewport().get_texture().get_image().save_png(output.path_join(id+".png")) == OK)

func run(game: Node) -> void:
	g = game
	output = ProjectSettings.globalize_path("res://qa") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA")
	g.checkpoint_path = output.path_join("milestone_checkpoint.json")
	g.presentation.prefs.data = g.presentation.PREFS.DEFAULTS.duplicate()
	g.presentation.apply_preferences(false)
	g.new_game()
	g.presentation.clear_transients()
	for l in g.lamps:l.light_energy = 1.1
	await wait(0.5)
	check("new game hides route checklist",g.current_objective() == "")
	g.request_hint()
	check("optional hint is available",g.current_objective() != "")
	g.hint_until = 0
	await shot("N01_fuse",Vector3(-3.5,0.02,-7.7),Vector3(-3.5,0.84,-8.8))
	await shot("N02_panel",Vector3(-2.65,0.02,2.15),Vector3(-2.65,1.4,3.68))
	await shot("N03_kitchen",Vector3(-2.6,0.02,-0.8),Vector3(-5.2,1.3,2.7))
	await shot("N04_utility",Vector3(-2.3,0.02,-5.0),Vector3(-4.5,1.1,-8.5))
	await shot("N05_office",Vector3(2.3,0.02,-4.7),Vector3(5.1,1.2,-8.2))
	await shot("N06_yard",Vector3(-6.8,0.02,-12.2),Vector3(-15,1.6,-14))
	await shot("N07_shed",Vector3(-15,0.02,-13),Vector3(-18,1.4,-15.5))
	await shot("N08_basement",Vector3(0,-2.98,-16.3),Vector3(-1.2,-1.6,-23))
	await shot("N09_house_side",Vector3(-12,0.02,-9),Vector3(-5,2,-5))
	for point in [Vector3(0,1,9),Vector3(-4,1,1),Vector3(4,1,1),Vector3(4,1,-7),Vector3(-4,1,-7),Vector3(-8,1,-12.4),Vector3(-17,1,-14),Vector3(0,-2,-21)]:
		var query := PhysicsRayQueryParameters3D.create(point,point-Vector3(0,2,0))
		query.exclude = [g.player.get_rid()]
		check("floor support "+str(point),not g.get_world_3d().direct_space_state.intersect_ray(query).is_empty())
	check("articulated Surveyor joints",g.surveyor_actor.skeleton.get_bone_count() == 65)
	check("Surveyor walk animation",g.surveyor_actor.animator.has_animation("surveyor/walk"))
	g.presence.position = Vector3(0,0,-8)
	g.presence.look_at(Vector3(0,0,-4))
	g.presence.visible = true
	await shot("N10_surveyor_detail",Vector3(0,0.02,-5.2),Vector3(0,1.4,-8))
	g.presence.visible = false
	g.player.position = Vector3(-9,0.02,-12.4)
	g.player.camera.look_at(Vector3(-5.8,1.6,-12.2))
	g.horror.variant = 0
	g.horror.begin("watcher")
	await wait(1.1)
	await shot("N10_watcher",g.player.position,g.presence.position+Vector3(0,1.6,0))
	check("watcher head remains visible above cover",g.horror.visible_to_player())
	var original_hold: float = g.horror.hold
	g.horror.hold = 999
	var head_yaw: float = g.surveyor_actor.gaze.yaw
	await wait(0.8)
	check("head tracks over time",absf(head_yaw-g.surveyor_actor.gaze.yaw)>0.001)
	await wait(2.0)
	check("head turns towards player in model coordinates",absf(g.surveyor_actor.gaze.yaw-g.surveyor_actor.gaze.target_yaw)<0.11)
	g.horror.hold = original_hold
	var motion_dir := output.path_join("surveyor_motion_frames")
	DirAccess.make_dir_recursive_absolute(motion_dir)
	for frame in range(36):
		await wait(0.1)
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png(motion_dir.path_join("%03d.png" % frame))
	g.player.camera.rotate_y(PI)
	await wait(4.2)
	check("watcher withdraws out of sight",not g.presence.visible)
	g.stage = 3
	g.horror.house_responds()
	await wait(0.4)
	g.horror.feed.get_texture().get_image().save_png(output.path_join("N11_feed_raw.png"))
	await shot("N11_impossible_feed",Vector3(3.2,0.02,-0.3),Vector3(3.2,1.2,-1.85))
	check("impossible feed isolated from player camera",g.horror.feed_ghost.visible and (g.player.camera.cull_mask & 4) == 0)
	g.events["chair"] = true
	g.player.position = Vector3(0,0.02,-4)
	g.player.camera.look_at(Vector3(0,1.4,-9))
	g.presentation.prefs.data.visual_preset = 0
	g.presentation.prefs.data.retro = 0
	g.presentation.apply_preferences(false)
	await shot("N12_clean",g.player.position,Vector3(0,1.4,-9))
	g.presentation.prefs.data.visual_preset = 1
	g.presentation.prefs.data.retro = 0.32
	g.presentation.apply_preferences(false)
	await shot("N13_modern_psx",g.player.position,Vector3(0,1.4,-9))
	check("viewmodel present",is_instance_valid(g.player.viewmodel) and g.player.viewmodel.visible)
	check("torch independent of cosmetic viewmodel",g.player.torch.get_parent() == g.player.camera)
	g.presentation.prefs.data.reduced_motion = true
	await wait(0.8)
	var vpos: Vector3 = g.player.viewmodel.position
	await wait(0.2)
	check("reduced motion steadies hand",g.player.viewmodel.position.distance_to(vpos)<0.001)
	g.player.position = Vector3(0,0.02,-9.65)
	g.player.camera.look_at(Vector3(0,1.6,-10))
	await wait()
	check("viewmodel retracts near wall or door",not g.player.viewmodel.visible)
	check("retraction leaves light working",g.player.torch.visible and g.player.torch.light_energy > 0)
	g.player.position = Vector3(0,0.02,-4)
	g.horror.begin("wrong_direction")
	check("wrong-direction beat starts",g.horror.beat == "wrong_direction" and g.presence.visible)
	for variant_ in [0,1,0]:
		g.horror.variant = variant_
		g.horror.begin("watcher")
		check("watcher staged variant "+str(variant_),g.presence.position.z < -15.5 and g.presence.visible)
		g.horror.hold = 0.05
		g.player.camera.look_at(Vector3(0,1,0))
		await wait(0.6)
		check("variant clears without blocking progression "+str(variant_),not g.presence.visible and g.doors.service.locked)
	g.events["notes"] = {"Observed clue":"COOLANT / SUPPLY / OCCUPANCY"}
	g.open_casebook()
	check("journal recalls discovered records",g.journal.text.contains("Observed clue"))
	g.resume()
	g.save_game()
	var seed_: int = g.events.horror_seed
	g.load_game()
	check("save preserves encounter seed and notes",int(g.events.horror_seed) == seed_ and g.events.notes.has("Observed clue"))
	check("load clears transient encounter",g.horror.beat == "" and not g.presence.visible)
	# Legacy schema-1 saves have neither encounter metadata nor stored door states.
	var legacy: Dictionary = g.save_data().duplicate(true)
	legacy.erase("doors")
	legacy.events = {}
	g.apply_save(legacy)
	check("v0.2 save fields remain compatible",g.started and g.stage == legacy.stage and g.events.has("horror_seed"))
	g.player.viewmodel.queue_free()
	await wait()
	var action := InputEventAction.new()
	action.action = "flashlight"
	action.pressed = true
	var light_before: bool = g.player.torch.visible
	g.player._unhandled_input(action)
	check("flashlight works without viewmodel",g.player.torch.visible != light_before)
	g.player.torch.visible = light_before
	# Exact-size offscreen engine rendering avoids desktop window clamps.
	var target := SubViewport.new()
	target.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_tree().root.add_child(target)
	g.reparent(target)
	g.horror.feed.world_3d = g.get_world_3d()
	g.player.camera.current = true
	g.horror.beat = ""
	g.presence.visible = false
	g.player.position = Vector3(0,0.02,-4)
	g.player.camera.look_at(Vector3(0,1.5,-8))
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		target.size = size_
		target.size_2d_override = Vector2i(roundi(720.0*float(size_.x)/size_.y),720)
		target.size_2d_override_stretch = true
		await wait(0.5)
		var times: Array[float] = []
		var before_ := Time.get_ticks_usec()
		for i in range(60):
			await RenderingServer.frame_post_draw
			var now_ := Time.get_ticks_usec()
			times.append(float(now_-before_)/1000.0)
			before_ = now_
		times.sort()
		performance.append({"resolution":str(size_),"median_ms":times[30],"p95_ms":times[57],"frames":60})
		check("render performance sample "+str(size_),times[57]<50,str(times[57])+" ms p95 on this host")
		var image_: Image = target.get_texture().get_image()
		check("exact game render "+str(size_),image_.get_size() == size_)
		image_.save_png(output.path_join("N16_hall_"+str(size_.x)+"x"+str(size_.y)+".png"))
	g.presentation.show_register()
	g.presentation.buttons["Eli Ward / PRESENT"].pressed.emit()
	check("incorrect attendance remains recoverable",not g.ended and g.player.active)
	g.presentation.show_register()
	g.presentation.buttons["Simon Ward / PRESENT"].pressed.emit()
	check("correct attendance reaches ending",g.ended and g.presentation.section == "ending")
	var failed := 0
	for result in checks:if not result.passed:failed += 1
	var f := FileAccess.open(output.path_join("milestone_report.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"performance_samples":performance},"\t"))
	f.close()
	print("MILESTONE_QA_COMPLETE passed=",checks.size()-failed," failed=",failed)
	await g.qa_exit(0 if failed==0 else 1)
