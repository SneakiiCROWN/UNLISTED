extends "res://scripts/recording_repair_qa.gd"
# Embedded control entry. No external main-loop script override.
class RootGuard extends Node:
	func _input(event: InputEvent) -> void:
		if not event is InputEventAction and not event.get_meta("unlisted_qa_input",false):get_viewport().set_input_as_handled()
	func _process(_delta: float) -> void:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
var window: Window
var kind:="fixed"
var wanted:=Vector2i(1920,1080)
var report: Dictionary={"scope":"Same instrumented Windows executable, actual movement. Private settings and checkpoints, no desktop input injection or human playtest.","transitions":[],"samples":[]}
var measuring:=false
var gaps: Array=[]
var draws: Array=[]
var previous:=0
var excluded:=0
var watching_title:=false
var previous_creak_clock:=0.0
var previous_shadow:=false
func _process(delta: float) -> void:
	super._process(delta)
	if watching_title:
		var stage: Node3D=g.presentation.stage
		if g.presentation.atmosphere_time<previous_creak_clock:checkpoint("27-second creak cycle; playing="+str(g.presentation.creak.playing))
		previous_creak_clock=g.presentation.atmosphere_time
		if stage.shadow.visible!=previous_shadow:
			previous_shadow=stage.shadow.visible;checkpoint("47-second silhouette cycle; visible="+str(previous_shadow))
	var now:=Time.get_ticks_usec()
	if measuring and previous>0:
		if window.has_focus():gaps.append((now-previous)/1000.0);draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		else:excluded+=1
	previous=now
func checkpoint(event: String) -> void:
	report.transitions.append({"event":event,"ticks":Time.get_ticks_usec(),"render_size":str(g.get_viewport().size),"window_size":str(window.size),"mode":window.mode,"started":g.started})
	report.checks=checks
	var file:=FileAccess.open(output.path_join("probe_report.json"),FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("STABILITY_PHASE ",event)
func resize_to(size_: Vector2i) -> void:
	checkpoint("before resize "+str(size_));g.get_viewport().size=size_
	await get_tree().process_frame;await RenderingServer.frame_post_draw
	checkpoint("after resize "+str(size_));await wait(.6)
func walk_sample(label_: String) -> void:
	g.player.position=Vector3(0,-2.999,-17.2);g.player.velocity=Vector3.ZERO;await wait(1)
	gaps=[];draws=[];excluded=0;previous=0;measuring=kind!="root"
	var start:=Time.get_ticks_usec();checkpoint("walk begins "+label_)
	for point in [Vector2(0,-21),Vector2(-3.5,-21),Vector2(-3.5,-19),Vector2(0,-19),Vector2(0,-17.2)]:await travel(point,"stability "+label_)
	measuring=false;gaps.sort();draws.sort()
	report.samples.append({"label":label_,"duration_seconds":(Time.get_ticks_usec()-start)/1000000.0,"focused_frames":gaps.size(),"excluded_unfocused":excluded,"median_ms":gaps[gaps.size()/2] if not gaps.is_empty() else null,"p95_ms":gaps[int(gaps.size()*.95)] if not gaps.is_empty() else null,"max_ms":gaps.back() if not gaps.is_empty() else null,"median_draw_calls":draws[draws.size()/2] if not draws.is_empty() else null})
	checkpoint("walk ends "+label_)
func run(current: Node) -> void:
	g=current;window=get_tree().root;started_at=Time.get_ticks_usec()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
		if arg.begins_with("--stability-case="):kind=arg.trim_prefix("--stability-case=")
		if arg.begins_with("--capture-size="):
			var parts:=arg.trim_prefix("--capture-size=").split("x");wanted=Vector2i(int(parts[0]),int(parts[1]))
	if output.is_empty():await g.qa_exit(94);return
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json");g.presentation.prefs.path=output.path_join("settings.cfg")
	if kind=="root":
		for action_ in InputMap.get_actions():InputMap.action_erase_events(action_)
		window.add_child(RootGuard.new());window.set_flag(Window.FLAG_NO_FOCUS,false);window.set_flag(Window.FLAG_MOUSE_PASSTHROUGH,false);window.position=Vector2i(60,60);window.size=Vector2i(1280,720)
		print("QA_INPUT_ISOLATED normal root Window; physical bindings removed, no SubViewport or profiling display")
	else:g.prepare_automated_qa()
	report.kind=kind;report.backend=RenderingServer.get_current_rendering_driver_name();report.method=RenderingServer.get_current_rendering_method();report.adapter=RenderingServer.get_video_adapter_name()
	checkpoint("title ready")
	if "--menu-idle-only" in OS.get_cmdline_user_args():
		# Owner failure reproduction: normal root title, no SubViewport, no
		# New Game, no live resolution loop. Only input/data isolation differs.
		assert(kind=="root")
		if not "--foreground-profile" in OS.get_cmdline_user_args():window.set_flag(Window.FLAG_NO_FOCUS,true);window.set_flag(Window.FLAG_MOUSE_PASSTHROUGH,true)
		g.presentation.apply_display()
		Engine.max_fps=0 # Normal project default; q.run's60fps cap must not mask idle load.
		report.scope="Bounded normal-root main-menu idle, copied owner preferences, physical input blocked, private writes only. No gameplay or repeated resize. Not an uninstrumented owner launch or a crash fix."
		report.max_fps=Engine.max_fps
		report.components={"audio":not g.presentation.diagnostic_silent_menu,"mist":is_instance_valid(g.presentation.stage.mist),"silhouette":not "--title-no-silhouette" in OS.get_cmdline_user_args(),"animation":not g.presentation.stage.diagnostic_stationary}
		if "--title-ui-only" in OS.get_cmdline_user_args():
			g.visible=false
			for node in g.find_children("*","GPUParticles3D",true,false):node.emitting=false
			var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("111a18")
			g.presentation.stage.camera.environment=env
			report.components["3d_background"]=false
		var seconds_: int=360
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--idle-seconds="):seconds_=clampi(int(arg.trim_prefix("--idle-seconds=")),120,900)
		watching_title=true
		await shot("idle_title_start")
		var stop: int=Time.get_ticks_usec()+seconds_*1000000
		while Time.get_ticks_usec()<stop:
			await wait(15)
			report.samples.append({"ticks":Time.get_ticks_usec(),"menu_clock":g.presentation.stage.clock,"section":g.presentation.section,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC),"fps":Engine.get_frames_per_second()})
			checkpoint("idle heartbeat")
		check("title stays idle without starting a case",not g.started and g.presentation.section=="title")
		watching_title=false
		await shot("idle_title_end")
		report.completed=true;checkpoint("idle completed")
		await g.qa_exit(0);return
	if kind=="prestart":
		for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:await resize_to(size_)
	elif kind!="root":await resize_to(wanted)
	g.new_game();g.stage=3;g.events.chair=true;g.events["return"]=true;g.events.threat_resolved=true;g.events.impossible_room_resolved=true;g.threat.enabled=false;g.threat.reset();g.ambient_director.enabled=false
	g.horror.set_process(false);g.horror.set_physics_process(false);g.presentation.clear_transients()
	for door in g.doors.values():door.locked=false;door.set_open(true,0)
	checkpoint("gameplay started")
	if kind=="live":
		for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:await resize_to(size_);await walk_sample(str(size_))
	else:await walk_sample(kind)
	if kind=="root":
		for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
			g.presentation.prefs.data.resolution=size_;g.presentation.apply_display();await wait(.5)
			checkpoint("normal window resolution requested "+str(size_))
			var usable:=DisplayServer.screen_get_usable_rect()
			check("normal window remains reachable "+str(size_),window.size.x<=usable.size.x and window.size.y<=usable.size.y)
		for mode_ in [1,0]:
			g.presentation.prefs.data.display_mode=mode_;g.presentation.apply_display();await wait(.5);checkpoint("normal display mode "+str(mode_))
		g.presentation.show_menu(false);await wait(.2);check("normal root pauses",g.menu_open)
		g.presentation.resume_game();g.save_game(true);g.load_game();await wait(.2);check("normal root resumes and loads",g.player.active and not g.menu_open)
		window.mode=Window.MODE_MINIMIZED;await wait(.3);window.mode=Window.MODE_WINDOWED;await wait(.3);checkpoint("minimise restore; not manual Alt-Tab")
	report.completed=true;checkpoint("completed")
	await g.qa_exit(1 if checks.any(func(item):return not item.passed) else 0)
