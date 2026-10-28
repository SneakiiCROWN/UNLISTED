extends "res://scripts/recording_repair_qa.gd"
# Fixed placed views; not route timing, human play or standalone GPU timings.
var intervals: Array=[]
var process_ms: Array=[]
var physics_ms: Array=[]
var sampling:=false
var last_tick:=0
var results: Array=[]
func _process(_delta: float) -> void:
 if not sampling:return
 var tick:=Time.get_ticks_usec()
 if last_tick>0:
  intervals.append((tick-last_tick)/1000.0)
  process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
  physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
 last_tick=tick
func statistics(values: Array) -> Dictionary:
 if values.is_empty():return {}
 var ordered:=values.duplicate();ordered.sort()
 var total:=0.0
 for v in ordered:total+=v
 return {"samples":ordered.size(),"average_ms":total/ordered.size(),"median_ms":ordered[int(ordered.size()*.5)],"p95_ms":ordered[mini(ordered.size()-1,int(ordered.size()*.95))],"p99_ms":ordered[mini(ordered.size()-1,int(ordered.size()*.99))]}
func measure(id: String) -> void:
 phase=id;await wait(.8)
 intervals.clear();process_ms.clear();physics_ms.clear();last_tick=0;sampling=true
 await wait(2.5);sampling=false
 results.append({"view":id,"intervals":statistics(intervals),"process_cpu":statistics(process_ms),"physics_cpu":statistics(physics_ms),"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"render_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"resources":Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)})
 await shot("H_"+id)
func run(current: Node) -> void:
 g=current;started_at=Time.get_ticks_usec()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
 assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output)
 g.checkpoint_path=output.path_join("checkpoint.json")
 await exact_resolution()
 if "--health-validation" in OS.get_cmdline_user_args():
  await validate_health();return
 var startup_msec:=Time.get_ticks_msec()
 if "--health-settings-only" in OS.get_cmdline_user_args():
  var begin:=Time.get_ticks_usec()
  for i in 30:g.presentation.apply_preferences(false)
  var elapsed:=Time.get_ticks_usec()-begin
  check("thirty unchanged settings refreshes",g.presentation.prefs.data.master==0.0)
  var output_file:=FileAccess.open(output.path_join("health_settings.json"),FileAccess.WRITE)
  output_file.store_string(JSON.stringify({"iterations":30,"elapsed_usec":elapsed,"profile":g.atmosphere_at_boot,"scope":"Synchronous real native settings refresh work, not total frame/GPU performance."}));output_file.close()
  output_file=FileAccess.open(output.path_join("repair_report.json"),FileAccess.WRITE);output_file.store_string(JSON.stringify({"checks":checks,"failed":checks.filter(func(c):return not c.passed).size()}));output_file.close()
  await g.qa_exit(0 if checks.all(func(c):return c.passed) else 1);return
 await measure("menu")
 g.new_game();await wait(.4);g.ambient_director.enabled=false
 for view in [["arrival",Vector3(0,.04,18),Vector3(0,1,4)],["front",Vector3(0,.04,7.8),Vector3(0,1,3.5)],["woodland",Vector3(-9,.04,-20),Vector3(-20,3,-35)],["shed",Vector3(-13,.04,-13.5),Vector3(-17,1,-15)],["lounge",Vector3(2.7,.04,2.6),Vector3(5.5,.9,.2)],["office",Vector3(4.9,.04,-7.5),Vector3(5,1,-9.4)],["cellar",Vector3(0,-2.99,-17.2),Vector3(-1.5,-1.5,-23)]]:
  g.player.position=view[1];g.player.velocity=Vector3.ZERO;g.player.camera.look_at(view[2])
  await measure(view[0])
 # Saved transformed state uses the same restoration as player recovery.
 g.events.impossible_room_active=true;g.impossible_room.restore_saved()
 g.player.position=Vector3(2.7,.04,2.6);g.player.camera.look_at(Vector3(5.5,.9,.2))
 await measure("impossible")
 g.impossible_room.reset()
 check("nine real views sampled",results.size()==9 and results.all(func(v):return v.intervals.get("samples",0)>10))
 var file:=FileAccess.open(output.path_join("health_performance.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"scope":"Uncapped fixed native placed views with real systems. Screenshots outside measurement. Engine process/physics monitors and wall frame intervals; no direct GPU timestamps or total system/VRAM accounting. Not gameplay duration or human approval.","startup_msec":startup_msec,"profile":g.atmosphere_at_boot,"results":results},"\t"));file.close()
 file=FileAccess.open(output.path_join("repair_report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failed":checks.filter(func(c):return not c.passed).size()}));file.close()
 await g.qa_exit(0 if checks.all(func(c):return c.passed) else 1)

func validate_health() -> void:
 var cfg:=ConfigFile.new()
 for pair in [["master",{"bad":true}],["music","broken"],["sensitivity",INF],["invert_y","yes"],["resolution",Vector2i(-10,0)],["visual_preset","bad"],["subtitle_scale",NAN]]:cfg.set_value("presentation",pair[0],pair[1])
 var path:=output.path_join("malformed_settings.cfg");cfg.save(path)
 var prefs=load("res://scripts/preferences.gd").new();prefs.path=path;prefs.load_file()
 for key in ["master","music","sensitivity","invert_y","resolution","visual_preset","subtitle_scale"]:
  check("malformed preference defaults safely: "+key,prefs.data[key]==prefs.DEFAULTS[key])
 cfg=ConfigFile.new();cfg.set_value("audio","volume",.37);cfg.save(path);prefs.load_file()
 check("legacy volume remains compatible",is_equal_approx(prefs.data.master,.37))
 var sample_root:=Node3D.new();add_child(sample_root)
 var sample_a: MeshInstance3D=g.box(sample_root,Vector3.ZERO,Vector3(.123,.456,.789),Color.WHITE)
 var sample_b: MeshInstance3D=g.box(sample_root,Vector3.ONE,Vector3(.123,.456,.789),Color.BLACK)
 var valid_boxes:=is_instance_valid(sample_a) and is_instance_valid(sample_b)
 check("box constructors return valid instances before dereference",valid_boxes)
 if not valid_boxes:
  push_error("HEALTH_BOX_CONTRACT_REFUSED: no null property reads or queue_free")
  sample_root.queue_free();await g.qa_exit(1);return
 check("equal immutable box geometry shares one resource",sample_a.mesh==sample_b.mesh)
 check("shared geometry preserves separate materials and transforms",sample_a.material_override!=sample_b.material_override and sample_a.position!=sample_b.position and sample_a.mesh.size.is_equal_approx(Vector3(.123,.456,.789)))
 sample_root.queue_free()
 var legacy:={"schema":1,"pos":[0,.1,9]}
 check("legacy minimal checkpoint accepted",g.checkpoint_usable(legacy))
 for bad in [{"doors":{"front":"true"}},{"door_swing":{"front":"open"}},{"door_swing":{"front":NAN}}]:
  var data:=legacy.duplicate(true);data.merge(bad,true)
  check("malformed door state rejected before mutation",not g.checkpoint_usable(data))
 var valid:=legacy.duplicate(true);valid.doors={"front":true};valid.door_swing={"front":-1.55}
 check("legitimate saved door state accepted",g.checkpoint_usable(valid))
 if g.atmosphere_at_boot>0:
  var original: bool=g.presentation.prefs.data.reduced_motion
  for value in [true,false,original]:
   g.presentation.prefs.data.reduced_motion=value;g.presentation.apply_preferences(false)
   check("window accessibility state updates",g.atmosphere_profile.accessibility_motion==(0 if value else 1))
   var windows:=0
   for mesh in g.find_children("*","MeshInstance3D",true,false):
    var material: Material=mesh.material_override
    if material is ShaderMaterial and material.shader.resource_path=="res://shaders/phase2_window.gdshader":
     windows+=1;check("actual window motion uniform matches setting",float(material.get_shader_parameter("motion"))==(0.0 if value else 1.0))
   check("real glass materials were checked",windows>0)
 g.new_game();await wait(.2)
 for pad_used in [false,true,false]:
  g.controller.used=pad_used;await wait(.1)
  check("interaction icon follows input type",g.presentation.prompt_icon.texture==(g.presentation.INTERACTION_PAD if pad_used else g.presentation.INTERACTION_KEY))
 await shot("H_validation_game")
 var file:=FileAccess.open(output.path_join("repair_report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failed":checks.filter(func(c):return not c.passed).size()}));file.close()
 await g.qa_exit(0 if checks.all(func(c):return c.passed) else 1)
