extends "res://scripts/continuation_qa.gd"
# Native staged art/experimental-scene inspection. No claim of fresh route or
# human playability. The ordinary world is never rearranged for these captures.
func execute() -> void:
	await setup()
	g.events.chair=true;g.events.yard=true;g.events["return"]=true
	for door in g.doors.values():door.locked=false;door.set_open(true,0)
	await wait(.4)
	await property_views();await room_views()
	if not "--house-views-only" in OS.get_cmdline_user_args():await study_checks()
	var failed:=0
	for c in checks:
		if not c.passed:failed+=1
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Staged native changed-property/room views, room ownership/save recovery and explicitly armed study checks. Not a fresh story route, human art/fear/listening or performance benchmark."},"\t"));file.close()
	g.qa_exit(0 if failed==0 else 1)

func pose(id: String,feet: Vector3,target: Vector3,crouch:=false) -> void:
	g.player.position=feet;g.player.velocity=Vector3.ZERO;g.player.restore_stance(crouch)
	g.player.camera.current=true;g.player.camera.look_at(target)
	g.presentation.clear_transients();g.subtitle.text="";g.caption_until=0
	await wait(.45);await shot(id)

func property_views() -> void:
	for spec in [
		["P01_arrival_car",Vector3(-9,.04,23),Vector3(-5.6,.85,21.6)],
		["P02_lane",Vector3(4,.04,23),Vector3(26,1.8,27)],
		["P03_gate",Vector3(0,.04,20.0),Vector3(0,.90,17)],
		["P04_house_approach",Vector3(0,.04,8.2),Vector3(0,1.8,3.6)],
		["P05_west_circuit",Vector3(-8.9,.04,2),Vector3(-8.9,.30,-8)],
		["P06_foundation",Vector3(-9,.04,0),Vector3(-7.60,.40,-2)],
		["P07_house_gutter",Vector3(-9,.04,6),Vector3(-7.66,2.78,3.5)],
		["P08_service_yard",Vector3(-10,.04,-12),Vector3(-17,1.1,-14)],
		["P09_shed_roof",Vector3(-21,.04,-18),Vector3(-17,2.3,-14)],
		["P10_shed_drain",Vector3(-21.5,.04,-16.7),Vector3(-20.4,.35,-16.55)],
		["P11_shed_bench",Vector3(-16,.04,-14),Vector3(-17.7,.95,-16)],
		["P12_feed_junction",Vector3(-21.5,.04,-12.5),Vector3(-20.15,1.4,-12.35)],
		["P13_east_return",Vector3(12.3,.04,-3),Vector3(9,.3,6.5)],
		["P14_service_exit",Vector3(13.6,.04,-7.4),Vector3(10,.0,-8.35)],
		["P15_woodland_depth",Vector3(-12,.04,-18),Vector3(-15,4,-35)]]:
		await pose(spec[0],spec[1],spec[2])
	check("complete changed property native views",true)

func room_views() -> void:
	for spec in [
		["I01_lounge",Vector3(2.5,.04,.5),Vector3(6.35,.65,.5)],
		["I02_sofa_throw",Vector3(4.8,.04,1.25),Vector3(6.35,.68,1.4)],
		["I03_office",Vector3(4.3,.04,-6.8),Vector3(3.3,.90,-8.52)],
		["I04_recorder",Vector3(3.3,.04,-7.75),Vector3(3.3,.94,-8.52)],
		["I05_hall_microphone",Vector3(.1,.04,-2.2),Vector3(1.4,1.62,-3.05)],
		["I06_cot",Vector3(-5.6,.04,-6.8),Vector3(-6.8,.65,-5.35)],
		["I07_cellar",Vector3(0,-2.99,-21),Vector3(-1.5,-1.2,-23.5)],
		["I08_generator",Vector3(2.2,-2.99,-18.8),Vector3(3.85,-2.0,-20)],
		["I09_records",Vector3(4,-2.99,-9.8),Vector3(4.95,-1.5,-7.18)]]:
		await pose(spec[0],spec[1],spec[2])
	await pose("I10_crawl_hangers",Vector3(3.25,-2.99,-12.5),Vector3(2.7,-1.9,-13.5),true)
	g.events.spare_offered=true;g.events.spare_uncovered=true;g.events.spare_hunt_done=true;g.spare_place.restore()
	await pose("I11_occupied_mirror",Vector3(-5.95,.04,-5.35),g.spare_mirror.center)
	await wait(.8);await shot("I12_mirror_updated")
	g.spare_mirror.touch();check("occupied mirror observation still earned",g.events.get("spare_glass_seen",false))
	g.events.memory_bedroom_active=true;g.chapter.set_room(true)
	await pose("I13_copied_bedroom",Vector3(2.7,.04,.4),Vector3(6.2,.8,-1.5))
	await pose("I14_wallpaper_seam",Vector3(4.8,.04,-1.1),Vector3(5.85,1.4,-2.9))
	check("new lounge details and reading lamp leave with original room",not g.lounge_contents.is_visible_in_tree() and not g.get_node("LoungeContents/LoungeReadingLamp").is_visible_in_tree() and g.chapter.room.is_visible_in_tree())
	g.save_game(true);g.load_game();await wait(.25)
	check("copied room and new art ownership survive load",g.chapter.active and g.chapter.room.is_visible_in_tree() and not g.lounge_contents.is_visible_in_tree())
	g.events.memory_bedroom_active=false;g.chapter.set_room(false)
	check("return restores ordinary lounge and hides copied details",g.lounge_contents.is_visible_in_tree() and not g.chapter.room.is_visible_in_tree())

func study_checks() -> void:
	g.started=false;g.presentation.show_menu(true);await wait(.2)
	var before: String=FileAccess.get_file_as_string(g.checkpoint_path)
	var dev: bool=g.dev_mode
	var footprint=load("res://scenes/property_memory_study.tscn").instantiate();g.add_child(footprint)
	var recorder_study=load("res://scenes/recorder_memory_study.tscn").instantiate();g.add_child(recorder_study)
	check("experimental studies default disabled",not footprint.enable_preview and not recorder_study.enable_preview and not recorder_study.is_processing())
	g.dev_mode=false;footprint.enable_preview=true;recorder_study.enable_preview=true
	check("ordinary release cannot arm either study",not footprint.prepare_preview(g) and not recorder_study.start_preview(g))
	g.dev_mode=true
	var camera:=Camera3D.new();g.add_child(camera);camera.current=true
	g.presentation.stage.set_active(false)
	var controls: Dictionary={}
	for control in [g.presentation.body,g.presentation.status,g.presentation.footer,g.presentation.shade,g.presentation.card,g.presentation.toast,g.presentation.menu_navigation]:controls[control]=control.visible;control.visible=false
	check("explicit footprint study prepares",footprint.prepare_preview(g));footprint.reveal_preview();await wait(.4)
	camera.global_position=Vector3(-23,1.65,-14.7);camera.look_at(Vector3(-20.4,.25,-13.3));await wait(.5);await shot("E01_unreturned_steps")
	check("footprint study shows seven marks without repeat",footprint.get_node("UnreturnedSteps").visible and footprint.get_node("UnreturnedSteps").get_child_count()==7 and not footprint.prepare_preview(g))
	var needle: Node3D=g.get_node("ArchiveTransport/ReturnMeterNeedle");var angle_: float=needle.rotation.y
	check("recorder preview starts",recorder_study.start_preview(g));await wait(3.30)
	check("authored needle moves and actual cue plays",absf(needle.rotation.y-angle_)>.1 and recorder_study.sources.any(func(a):return is_instance_valid(a) and a.playing))
	camera.global_position=Vector3(3.30,1.30,-7.70);camera.look_at(Vector3(3.30,.92,-8.52));await shot("E02_late_recorder")
	await wait(8.1)
	check("recorder completion restores angles/audio",not recorder_study.running and is_equal_approx(needle.rotation.y,angle_) and recorder_study.sources.is_empty())
	await wait(.1)
	var reduced: bool=g.presentation.prefs.data.reduced_motion;g.presentation.prefs.data.reduced_motion=true
	check("reduced motion preview starts",recorder_study.start_preview(g));await wait(.2)
	check("reduced motion omits reel creep",recorder_study.reels.is_empty());recorder_study.finish_preview();await wait(.1)
	check("explicit study cancellation restores state",not recorder_study.running and is_equal_approx(needle.rotation.y,angle_))
	g.presentation.prefs.data.reduced_motion=reduced
	check("title-exit preview starts",recorder_study.start_preview(g));await wait(.1);g.started=true;await wait(.1)
	check("starting case cancels preview",not recorder_study.running);g.started=false
	footprint.queue_free();recorder_study.queue_free();camera.queue_free();await wait(.15)
	for control in controls:control.visible=controls[control]
	g.presentation.stage.set_active(true)
	check("studies preserve saved case bytes",FileAccess.get_file_as_string(g.checkpoint_path)==before)
	g.dev_mode=dev
