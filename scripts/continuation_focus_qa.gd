extends "res://scripts/sound_touch_qa.gd"
# Actual curated prop/input/bench tests plus explicitly labelled collision blocker.
func held_input(value: bool) -> void:
 var event:=InputEventAction.new();event.action="battery_replace";event.pressed=value;event.set_meta("unlisted_qa_input",true);Input.parse_input_event(event)
func run(current: Node) -> void:
 g=current;started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
 assert(not output.is_empty());DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
 await exact_resolution();g.new_game();quiet()
 g.presentation.prefs.data.reduced_motion="--touch-reduced" in OS.get_cmdline_user_args()
 g.brass_key=false;g.shed_read=false;g.interact("basement")
 check("cellar feedback does not assume an uncollected key",not "key doesn't fit" in g.message_info.text and "keyhole" in g.message_info.text)
 g.brass_key=true;g.interact("basement")
 check("cellar feedback acknowledges an unsuitable held key","doesn't fit" in g.message_info.text)
 g.presentation.clear_transients();g.subtitle.text="";g.caption_until=g.time_in_game
 var body: RigidBody3D=await pickup_fixture("work_tape")
 g.player.position=Vector3(-18.10,.03,-14.9);g.player.velocity=Vector3.ZERO
 var plan: Dictionary={}
 for z in [-15.6,-15.8,-16.0]:
  g.player.camera.look_at(Vector3(-18.1,.805,z));await wait(.3)
  plan=g.physical.placement_plan(true)
  if not plan.is_empty():break
 check("real shed bench admits a complete placement",not plan.is_empty(),str(plan))
 if not plan.is_empty():
  await wait(.1);check("clearance-checked placement is advertised",g.prompt.text=="Put down")
  var root:=Node3D.new();g.add_child(root)
  var destination: Transform3D=plan.transform
  g.box(root,destination.origin+Vector3(-.044,.06,0),Vector3(.018,.18,.10),Color.MAGENTA,true)
  await wait(.15)
  check("collision fixture leaves a visible support ray",not g.physical.placement_ray().is_empty())
  check("overlapping destination is not advertised as placement",g.physical.placement_plan(true).is_empty() and g.prompt.text=="Release",g.prompt.text)
  root.queue_free();await wait(.15)
  check("removing obstruction restores valid placement",not g.physical.placement_plan(true).is_empty())
  await shot("C01_real_bench_ready")
  await action("interact");await wait(.3)
  check("actual interaction places rather than throws",g.physical.held==null and g.physical.last_set_down.get("id","")=="work_tape" and absf(body.position.y-.834)<.06,str(body.position))
  await shot("C02_supported_tape")
 body=await pickup_fixture("work_tape")
 g.equipment.data.charge=10.0;g.equipment.data.spares=0;g.equipment.data.mode=1;g.equipment.data.contact_fault=false;g.equipment.apply_light()
 held_input(true);await wait(.35)
 check("carrying blocks winding without stopping ordinary drain",g.equipment.winding==0 and float(g.equipment.data.charge)<10)
 held_input(false);g.physical.release(false);await wait(.1)
 g.equipment.data.charge=10.0;held_input(true);await wait(.65)
 check("free hand starts manual backup",g.equipment.winding>0 and not g.player.torch.visible)
 check("temporary battery meter shows real winding progress",g.presentation.battery_root.visible and g.presentation.battery_detail.text.begins_with("WINDING /"))
 await shot("C03_winding_progress")
 await action("pause");var paused: float=g.equipment.winding;await wait(.25)
 check("pause freezes actual winding",get_tree().paused and is_equal_approx(paused,g.equipment.winding))
 held_input(false);await action("pause");await wait(.15)
 check("interrupted hold cancels without free charge",g.equipment.winding==0 and float(g.equipment.data.charge)<10.1 and g.player.torch.visible)
 g.equipment.data.charge=10.0;held_input(true);await wait(3.5);held_input(false)
 check("complete real hold restores backup and consumes no pack",g.equipment.winding==0 and float(g.equipment.data.charge)>24.5 and float(g.equipment.data.charge)<=25.1 and int(g.equipment.data.spares)==0)
 g.save_game(true);var saved_charge: float=g.equipment.data.charge;g.load_game();await wait(.15);quiet()
 check("backup charge survives save/load",absf(float(g.equipment.data.charge)-saved_charge)<.3 and g.equipment.winding==0)
 await shot("C04_backup_restored")
 # Pickup mid-hold is real interaction, not an injected hand assignment.
 g.equipment.data.charge=10.0;held_input(true);await wait(.15)
 body=await pickup_fixture("work_tape");await wait(.1);held_input(false)
 check("actual pickup interrupts winding without gaining charge",g.physical.held==body and g.equipment.winding==0 and float(g.equipment.data.charge)<10.1)
 g.physical.release(false);held_input(false)
 var file:=FileAccess.open(output.path_join("repair_report.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failed":checks.filter(func(c):return not c.passed).size(),"scope":"Placed native curated props, actual input and real shed bench; temporary collision blocker labelled. No human first playthrough or native crash clearance."},"\t"));file.close()
 await g.qa_exit(0 if checks.all(func(c):return c.passed) else 1)
