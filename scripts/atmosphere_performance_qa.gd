extends "res://scripts/recording_repair_qa.gd"
var measuring:=false
var last_tick:=0
var samples: Array=[]
func _process(_delta: float) -> void:
	if not measuring:return
	var tick:=Time.get_ticks_usec()
	if last_tick>0:
		samples.append({"seconds":seconds(),"frame_ms":(tick-last_tick)/1000.0,"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"render_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"position":str(g.player.position),"phase":phase})
	last_tick=tick
func run(current: Node) -> void:
	if "--health-sample" in OS.get_cmdline_user_args():
		var probe=load("res://scripts/health_profile_qa.gd").new();probe.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(probe);await probe.run(current);return
	g=current;started_at=Time.get_ticks_usec()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();g.new_game();await wait(2)
	await travel(Vector2(0,18.3),"reach real gate");await use("front_gate")
	await travel(Vector2(0,14.5),"enter property for moving sample")
	await shot("P00_start")
	measuring=true;var start:=seconds();var legs:=0
	while seconds()-start<90:
		await travel(Vector2(.8 if legs%2==0 else -.8,7.7 if legs%2==0 else 15.5),"continuous approach leg "+str(legs))
		legs+=1
	measuring=false
	await shot("P01_finish")
	check("Continuous real movement sampled for at least ninety seconds",seconds()-start>=90 and samples.size()>300 and legs>=10)
	var times: Array=[];var draws: Array=[];var stutters:=0
	for s in samples:
		times.append(s.frame_ms);draws.append(s.draws)
		if s.frame_ms>33.333:stutters+=1
	times.sort();draws.sort()
	var report:={"scope":"Ninety-second native input-driven movement, uncaptured frames, complete production systems active. Process-frame intervals, not GPU timestamps; engine render memory is not total GPU VRAM. Outdoor approach only, not whole-game or minimum-spec guarantee.","profile":g.atmosphere_at_boot,"size":str(g.get_viewport().get_texture().get_size()),"duration_seconds":seconds()-start,"legs":legs,"samples":samples.size(),"median_ms":times[times.size()/2],"p95_ms":times[int(times.size()*.95)],"max_ms":times.back(),"intervals_over_33ms":stutters,"median_draws":draws[draws.size()/2],"first":samples.front(),"last":samples.back()}
	var f:=FileAccess.open(output.path_join("moving_performance.json"),FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	f=FileAccess.open(output.path_join("moving_samples.json"),FileAccess.WRITE);f.store_string(JSON.stringify(samples));f.close()
	# No audio recorder or capture is used during measurement.
	f=FileAccess.open(output.path_join("repair_report.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failed":checks.filter(func(c):return not c.passed).size()}));f.close()
	await g.qa_exit(0 if checks.all(func(c):return c.passed) else 1)
