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
 if "--bake-window-cube" in OS.get_cmdline_user_args():
  await bake_window();return
 var policy=load("res://scripts/graphics_phase2_profile.gd" if "--graphics-phase2" in OS.get_cmdline_user_args() else "res://scripts/graphics_profile_study.gd").new()
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
 if "--graphics-phase3" in OS.get_cmdline_user_args():
  views.append_array(load("res://scripts/graphics_phase3_property.gd").new().views())
  if not "--property-baseline" in OS.get_cmdline_user_args():
   config.property=load("res://scripts/graphics_phase3_property.gd").new().apply(g)
 var performance_only: bool="--graphics-performance" in OS.get_cmdline_user_args()
 var measured_views: Array=["V08_lane","E02_porch_outward","E06_yard_shed"] if "--graphics-phase3" in OS.get_cmdline_user_args() else ["V08_lane","V02_lounge","V07_cellar"]
 for view in views:
  if performance_only and not view[0] in measured_views:continue
  g.player.position=view[1];g.player.velocity=Vector3.ZERO;g.player.camera.look_at(view[2]);g.caption_until=0;g.subtitle.text=""
  await wait(1.5)
  if performance_only:
   if view[0] in measured_views:await measure(view[0])
  else:await shot(view[0])
 if "--graphics-phase2" in OS.get_cmdline_user_args() and not performance_only:
  await window_visibility()
 # Movement uses existing physics in the unchanged real gate-to-porch route.
 var window_motion: bool="--graphics-window-record" in OS.get_cmdline_user_args()
 g.player.position=Vector3(5,.04,2.8) if window_motion else Vector3(0,.04,15.8);g.player.camera.rotation=Vector3.ZERO;g.player.rotation=Vector3.ZERO
 if "--graphics-record" in OS.get_cmdline_user_args() or window_motion:
  started_unix_seconds=Time.get_unix_time_from_system();capture_interval=1.0/20.0
  recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
  AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true);recording=true
 if window_motion:
  await window_camera_motion()
 elif "--graphics-walk" in OS.get_cmdline_user_args():
  g.player.camera.rotation.x=-.15
  await travel(Vector2(0,7.2),"Unchanged front path physics");await shot("P03_walked_to_porch")
 if "--property-route" in OS.get_cmdline_user_args():await load("res://scripts/graphics_phase3_route.gd").new().run(self,g)
 var report={"scope":"Isolated actual exported game study, fixed render size per process. Powered camera-placement fixture plus labelled movement when requested. Existing world/story retained; not normal owner gameplay or artistic approval.","profile":profile,"render_size":str(g.get_viewport().size),"configuration":config,"preferences":g.presentation.prefs.data,"measurements":measurements,"checks":checks,"engine":Engine.get_version_info(),"physics_unchanged":not ("--graphics-phase3" in OS.get_cmdline_user_args() and not "--property-baseline" in OS.get_cmdline_user_args()),"property_baseline":"--property-baseline" in OS.get_cmdline_user_args()}
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
 measurements.append({"view":id,"focused_frames":samples.size(),"excluded_unfocused":excluded,"median_ms":samples[samples.size()/2] if samples.size()>0 else null,"p95_ms":samples[int(samples.size()*.95)] if samples.size()>0 else null,"average_fps":1000.0/(samples.reduce(func(a,b):return a+b,0.0)/samples.size()) if samples.size()>0 else null,"spikes_over_33ms":samples.filter(func(t):return t>33.3).size(),"max_ms":samples.back() if samples.size()>0 else null,"median_draws":draws[draws.size()/2] if draws.size()>0 else null,"median_primitives":primitives[primitives.size()/2] if primitives.size()>0 else null,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"render_video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"scope":"Five-second stationary focused process-frame intervals; no readback during sample; not sustained gameplay or GPU timestamp."})

func bake_window() -> void:
 var view:=SubViewport.new();view.size=Vector2i(128,128);view.world_3d=g.get_world_3d();view.render_target_update_mode=SubViewport.UPDATE_DISABLED;g.add_child(view)
 var cam:=Camera3D.new();cam.fov=90;cam.cull_mask=1;cam.near=.08;view.add_child(cam);cam.global_position=Vector3(5,1.4,1)
 var faces: Array[Image]=[]
 var dirs=[Vector3.RIGHT,Vector3.LEFT,Vector3.UP,Vector3.DOWN,Vector3.BACK,Vector3.FORWARD]
 for i in 6:
  cam.look_at(cam.global_position+dirs[i],Vector3.BACK if i in [2,3] else Vector3.UP)
  view.render_target_update_mode=SubViewport.UPDATE_ONCE
  await RenderingServer.frame_post_draw
  var image:=view.get_texture().get_image();image.convert(Image.FORMAT_RGBA8);image.generate_mipmaps();faces.append(image)
  image.save_png(output.path_join("cube_"+str(i)+".png"))
 var cube:=Cubemap.new();var err:=cube.create_from_images(faces);assert(err==OK)
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--cube-output="):
   var save_error:=ResourceSaver.save(cube,arg.trim_prefix("--cube-output="))
   if save_error!=OK:push_error("WINDOW_CUBE_SAVE_FAILED "+str(save_error));await g.qa_exit(94);return
 view.queue_free();faces.clear();cube=null
 for i in 4:await get_tree().process_frame
 print("WINDOW_CUBE_BAKED native room six faces, no ReflectionProbe")
 await g.qa_exit(0)
func window_visibility() -> void:
 # Actual current actor, static visibility fixture only; no new story encounter.
 var body: Node3D=g.presence;var old:=body.transform;var was_visible:=body.visible
 var horror_process: bool=g.horror.is_processing();var horror_physics: bool=g.horror.is_physics_processing()
 g.horror.set_process(false);g.horror.set_physics_process(false)
 body.position=Vector3(8.7,.04,2.4);body.visible=true;g.surveyor_actor.figure.visible=true;g.surveyor_actor.set_mode("watch")
 body.look_at(Vector3(5.9,.04,2.6))
 g.player.position=Vector3(5.9,.04,2.6);g.player.camera.look_at(Vector3(8.7,1.5,2));await wait(.8);check("Actual outside actor retained for glass view",body.visible and body.position.distance_to(Vector3(8.7,.04,2.4))<.05);await shot("W02_actor_outside")
 body.visible=false
 g.player.position=Vector3(9.3,.04,2.7);g.player.camera.look_at(Vector3(6.0,1.35,1.4));await wait(.8);await shot("W03_from_outside")
 body.position=Vector3(5.2,.04,2.4);body.visible=true;body.look_at(Vector3(9.3,.04,2.7));g.player.camera.look_at(body.position+Vector3.UP*1.4);await wait(.8);await shot("W04_actor_inside")
 check("Actual inside actor retained for glass view",body.visible and body.position.distance_to(Vector3(5.2,.04,2.4))<.05)
 body.position=Vector3(8.7,.04,2.4);g.player.position=Vector3(10.4,.04,3.0);g.player.camera.look_at(body.position+Vector3.UP*1.4);await wait(.8);await shot("W05_actor_direct_control")
 body.transform=old;body.visible=was_visible
 g.horror.set_process(horror_process);g.horror.set_physics_process(horror_physics)

func window_camera_motion() -> void:
 # Camera-motion evidence only, not a physics traversal or new scripted event.
 var active_before: bool=g.player.active;g.player.active=false;phase="isolated window camera strafe"
 var start:=Time.get_ticks_usec();var elapsed:=0.0
 while elapsed<3.0:
  elapsed=(Time.get_ticks_usec()-start)/1000000.0
  var t:=clampf(elapsed/3.0,0.0,1.0)
  g.player.position=Vector3(5.0,.04,lerpf(2.8,1.8,t))
  g.player.camera.look_at(Vector3(7.5,1.55,2.0))
  await get_tree().process_frame
 g.player.active=active_before
