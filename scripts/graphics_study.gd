extends "res://scripts/recording_repair_qa.gd"
var profile:="original"
var measurements: Array=[]
func run(current: Node) -> void:
 g=current;started_at=Time.get_ticks_usec()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
  if arg.begins_with("--graphics-profile="):profile=arg.trim_prefix("--graphics-profile=")
 assert(profile in ["original","wet","lights","probe","glass","ao","ssil","ssr","balanced","enhanced"])
 assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output)
 g.checkpoint_path=output.path_join("checkpoint.json");g.presentation.prefs.path=output.path_join("settings.cfg")
 await exact_resolution();g.new_game();g.stage=3;g.threat.enabled=false;g.threat.reset()
 g.events.chair=true;g.events["return"]=true;g.events.impossible_room_resolved=true;g.events.threat_resolved=true
 g.presentation.clear_transients();g.player.restore_stance(false)
 # Same powered fixture as the preserved 36-frame spatial baseline.
 for lamp in g.lamps:lamp.light_energy=.6
 for door in g.doors.values():door.locked=false;door.set_open(true,.01)
 var policy=load("res://scripts/graphics_profile_study.gd").new()
 var config: Dictionary=policy.apply(g,profile)
 g.ambient_director.enabled=false
 var views=[
  ["V08_lane",Vector3(0,.04,17),Vector3(0,1.5,2)],
  ["P01_wet_approach",Vector3(-.2,.04,13.8),Vector3(.1,.6,5.4)],
  ["P02_puddle",Vector3(1.5,.04,10.2),Vector3(-.5,.1,8.8)],
  ["V01_porch",Vector3(0,.04,7.2),Vector3(0,1.4,3.7)],
  ["V02_lounge",Vector3(2.7,.04,2.6),Vector3(5.5,.9,.2)],
  ["W01_window",Vector3(5.9,.04,2.6),Vector3(7.5,1.6,2.0)],
  ["V07_cellar",Vector3(0,-2.99,-17.2),Vector3(-1.5,-1.5,-23)]
 ]
 var performance_only: bool="--graphics-performance" in OS.get_cmdline_user_args()
 for view in views:
  g.player.position=view[1];g.player.velocity=Vector3.ZERO;g.player.camera.look_at(view[2]);g.caption_until=0;g.subtitle.text=""
  await wait(1.5)
  if performance_only:
   if view[0] in ["V08_lane","V02_lounge","V07_cellar"]:await measure(view[0])
  else:await shot(view[0])
 # Movement uses existing physics in the unchanged real gate-to-porch route.
 g.player.position=Vector3(0,.04,15.8);g.player.camera.rotation=Vector3.ZERO;g.player.rotation=Vector3.ZERO
 if "--graphics-record" in OS.get_cmdline_user_args():
  started_unix_seconds=Time.get_unix_time_from_system();capture_interval=1.0/20.0
  recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
  AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
 if "--graphics-walk" in OS.get_cmdline_user_args():
  g.player.camera.rotation.x=-.15
  await travel(Vector2(0,7.2),"Unchanged front path physics");await shot("P03_walked_to_porch")
 var report={"scope":"Isolated actual exported game study, fixed render size per process. Powered camera-placement fixture plus labelled movement when requested. Existing world/story retained; not normal owner gameplay or artistic approval.","profile":profile,"render_size":str(g.get_viewport().size),"configuration":config,"preferences":g.presentation.prefs.data,"measurements":measurements,"checks":checks,"engine":Engine.get_version_info(),"physics_unchanged":true}
 var f:=FileAccess.open(output.path_join("graphics_report.json"),FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
 print("GRAPHICS_STUDY_COMPLETE ",profile)
 # Release experimental probe captures before normal QA shutdown.
 for probe in policy.probes:
  probe.visible=false;probe.queue_free()
 policy.probes.clear()
 for i in 4:await get_tree().process_frame
 if recording:
  await wait(1.0);await finish_run(false)
 else:await g.qa_exit(0)
func measure(id: String) -> void:
 var samples: Array=[];var draws: Array=[];var primitives: Array=[];var excluded:=0
 var previous:=Time.get_ticks_usec();var end:=previous+5000000
 while Time.get_ticks_usec()<end:
  await get_tree().process_frame
  var now:=Time.get_ticks_usec()
  if get_tree().root.has_focus():
   samples.append((now-previous)/1000.0);draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME));primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
  else:excluded+=1
  previous=now
 samples.sort();draws.sort();primitives.sort()
 measurements.append({"view":id,"focused_frames":samples.size(),"excluded_unfocused":excluded,"median_ms":samples[samples.size()/2] if samples.size()>0 else null,"p95_ms":samples[int(samples.size()*.95)] if samples.size()>0 else null,"max_ms":samples.back() if samples.size()>0 else null,"median_draws":draws[draws.size()/2] if draws.size()>0 else null,"median_primitives":primitives[primitives.size()/2] if primitives.size()>0 else null,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"render_video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"scope":"Five-second stationary focused process-frame intervals; no readback during sample; not sustained gameplay or GPU timestamp."})
