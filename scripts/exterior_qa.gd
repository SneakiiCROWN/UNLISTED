extends "res://scripts/capture_qa.gd"
# Native movement proof, separate from the explicitly positioned visual fixtures.
func run(game: Node) -> void:
	g=game
	output=ProjectSettings.globalize_path("res://qa/exterior_native") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA/exterior_native")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output)
	g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution()
	g.new_game();g.events.chair=true;g.threat.enabled=false
	g.horror.set_process(false);g.horror.set_physics_process(false)
	started_at=Time.get_ticks_usec();started_unix_seconds=Time.get_unix_time_from_system();recording=true
	recorder=AudioEffectRecord.new();recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder);recorder.set_recording_active(true)
	await wait(0.3)
	await travel(Vector2(0,14.7),"spawn to garden gate")
	await use("front_gate");await wait(0.8)
	check("gate opens through interaction",g.doors.front_gate.opened)
	await travel(Vector2(0,19.5),"gate outward crossing")
	await use("front_gate");await wait(0.8)
	check("gate closes from lane side",not g.doors.front_gate.opened)
	await travel(Vector2(0,19),"approach closed gate within reach")
	await use("front_gate");await wait(0.8)
	check("gate open before return crossing",g.doors.front_gate.opened)
	await travel(Vector2(0,17),"return to gate threshold")
	await use("front_gate")
	check("occupied gate refuses closing",g.doors.front_gate.opened)
	await travel(Vector2(0,14.7),"gate inward crossing")
	await use("front_gate");await wait(0.8)
	check("gate closes from garden side",not g.doors.front_gate.opened)
	# Wait for the physical leaf, not only its destination flag, before re-aiming.
	for i in 30:
		if absf(g.doors.front_gate.pivot.rotation.y)<.01:break
		await wait(.05)
	# The closed leaf is farther away than the swung-open one. Approach within
	# the player's ordinary 3D interaction reach instead of aiming from its edge.
	await travel(Vector2(0,15.2),"approach closed gate from garden")
	await use("front_gate");await wait(0.8)
	await travel(Vector2(0,23),"garden to country lane")
	await shot("E01_gate_house_return")
	await travel(Vector2(12,24),"lane east along curve")
	await travel(Vector2(0,23),"lane return from east")
	await travel(Vector2(-12,24),"lane west along curve")
	await travel(Vector2(0,23),"lane return from west")
	g.player.camera.look_at(Vector3(0,2.4,3.5));await shot("E02_house_from_lane")
	await travel(Vector2(0,14),"lane back into garden")
	await travel(Vector2(0,8),"garden approach return")
	await travel(Vector2(-8.8,7),"front garden side approach")
	await travel(Vector2(-8.8,-8.8),"house west circulation")
	await travel(Vector2(-8.8,-12.5),"west circulation into service yard")
	check("new outdoor approach preserves locked shed prerequisite",g.doors.shed.locked and not g.shed_read)
	g.doors.shed.locked=false
	await travel(Vector2(-12.4,-14),"shed exterior approach")
	await use("shed");await wait(0.8)
	await travel(Vector2(-16,-14),"shed entrance inward")
	await travel(Vector2(-12.4,-14),"shed entrance return")
	for point in [Vector2(-13.05,-14),Vector2(-13.05,-17.8),Vector2(-21,-17.8),Vector2(-21,-10.3),Vector2(-21,-17.8),Vector2(-13.05,-17.8),Vector2(-13.05,-14),Vector2(-12,-12.5),Vector2(-4.5,-12)]:
		await travel(point,"shed perimeter "+str(point))
	g.doors.service.locked=false
	await travel(Vector2(-4.5,-11.6),"service threshold approach")
	await use("service");await wait(0.8)
	await travel(Vector2(-4.5,-8.6),"service threshold inward")
	await travel(Vector2(-4.5,-12),"service threshold outward")
	var state=g.get_world_3d().direct_space_state
	var query:=PhysicsRayQueryParameters3D.create(Vector3(0,0.4,-12.5),Vector3(0,-4,-12.5),1)
	var hit: Dictionary=state.intersect_ray(query)
	check("no hidden ground across basement descent",not hit.is_empty() and hit.position.y< -0.8,str(hit.get("position")))
	query=PhysicsRayQueryParameters3D.create(Vector3(-6.4,1.6,1),Vector3(-10,1.6,1),1)
	hit=state.intersect_ray(query)
	check("kitchen window retains physical glass",not hit.is_empty() and hit.collider.name=="ClosedWindowGlass",str(hit.get("collider")))
	await travel(Vector2(-8.8,-12.5),"yard to west circulation")
	await travel(Vector2(-8.8,7),"west circulation return")
	await travel(Vector2(0,8),"return to original spawn approach")
	check("return grade remains level",absf(g.player.position.y)<0.08,str(g.player.position))
	g.save_game()
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(g.checkpoint_path))
	check("gate included in compatible save",saved.get("doors",{}).has("front_gate"))
	var old: Dictionary=saved.duplicate(true);old.doors.erase("front_gate");old.door_swing.erase("front_gate")
	g.apply_save(old);await wait(0.1)
	check("older save defaults gate closed",not g.doors.front_gate.opened)
	g.apply_save(saved);await wait(0.1)
	check("saved open gate restores",g.doors.front_gate.opened)
	recorder.set_recording_active(false);recorder.get_recording().save_to_wav(output.path_join("game_bus.wav"))
	recording=false;await wait(0.2)
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	for spec in [["input_trace.json",trace],["frames.json",frames],["repair_report.json",{"passed":checks.size()-failed,"failed":failed,"checks":checks,"started_unix_seconds":started_unix_seconds,"duration_seconds":seconds(),"capture":"Native automated movement; real collisions and focused interaction. No human playtest."}]]:
		var file:=FileAccess.open(output.path_join(spec[0]),FileAccess.WRITE);file.store_string(JSON.stringify(spec[1],"\t"));file.close()
	print("EXTERIOR_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1,true)
