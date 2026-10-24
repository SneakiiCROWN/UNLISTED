extends "res://scripts/recording_repair_qa.gd"
# Explicit native fixtures isolate support physics and text migration; captures
# and ordinary carrying remain real rendered/input behaviour, not human approval.
func top_at(root: Node3D,point: Vector3) -> float:
	var top:=-INF
	for mesh in g.all_meshes(root):
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array=mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var count: int=indices.size() if not indices.is_empty() else vertices.size()
			for i in range(0,count,3):
				var corners: Array[Vector3]=[]
				for j in 3:corners.append(mesh.global_transform*vertices[indices[i+j] if not indices.is_empty() else i+j])
				var hit: Variant=Geometry3D.ray_intersects_triangle(Vector3(point.x,10,point.z),Vector3.DOWN,corners[0],corners[1],corners[2])
				if hit is Vector3:top=maxf(top,hit.y)
	return top

func render_bounds(root: Node3D) -> AABB:
	var bounds:=AABB();var first:=true
	for mesh in g.all_meshes(root):
		var actual: AABB=mesh.global_transform*mesh.get_aabb()
		bounds=actual if first else bounds.merge(actual);first=false
	return bounds

func clear_weights() -> void:
	for id in g.physical.props:g.physical.props[id].call("relocate",g.physical.homes[id])
	await wait(.8)

func put(id: String,offset: Vector3) -> void:
	g.physical.props[id].call("relocate",Transform3D(Basis.IDENTITY,g.investigation.pad+offset))

func run(current: Node) -> void:
	g=current;started_at=Time.get_ticks_usec()
	output=OS.get_executable_path().get_base_dir().path_join("QA/director")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="):output=arg.trim_prefix("--evidence=")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	await exact_resolution();g.new_game();g.stage=3;g.threat.enabled=false;g.threat.reset()
	g.events.threat_resolved=true;g.events.chair=true;g.events["return"]=true
	for light in g.lamps:light.light_energy=.6
	for door in g.doors.values():door.locked=false;door.set_open(true,0)
	await wait(2)
	for id in ["counter_mug","can0","can1","can2","pot"]:
		var body: RigidBody3D=g.physical.props[id]
		var root: Node3D=g.get_node("KitchenStove" if id=="pot" else ("KitchenBase48" if id=="counter_mug" else "KitchenBase38"))
		var y:=top_at(root,body.position)
		var bottom: float=body.position.y-body.get_node("PropShape").shape.size.y/2
		check("rendered kitchen support "+id,is_finite(y) and absf(bottom-y)<.015,"bottom %.5f actual triangle %.5f"%[bottom,y])
	var vase: AABB=render_bounds(g.physical.props.counter_vase)
	var separated:=true
	for id in ["can0","can1","can2"]:
		if vase.intersects(render_bounds(g.physical.props[id])):separated=false
	check("counter tins do not intersect portable vase",separated,str(vase))
	check("vase sits on actual cabinet surface",absf(vase.position.y-top_at(g.get_node("KitchenBase38"),vase.get_center()))<.005,"bottom="+str(vase.position.y)+" top="+str(top_at(g.get_node("KitchenBase38"),vase.get_center()))+" pose="+str(g.physical.props.counter_vase.transform))
	# Stand in the room and traverse its actual clear aisle before the close view.
	g.player.position=Vector3(-2.8,.04,1)
	await travel(Vector2(-4.9,1),"kitchen centre aisle")
	for view in [["D01_kitchen",Vector3(-2.8,.04,-1),Vector3(-5.8,.9,2.5)],["D02_counter",Vector3(-4.5,.04,1.9),Vector3(-4.9,.87,3.2)],["D03_stove",Vector3(-5.5,.04,1.4),Vector3(-7.04,.86,1.45)]]:
		g.player.position=view[1];g.player.velocity=Vector3.ZERO;g.player.camera.look_at(view[2]);g.presentation.clear_transients();g.subtitle.text="";await wait(.5);await shot(view[0])
	# Legacy notes update in place without injecting unearned records or flags.
	var fixture: Dictionary={"notes":{"SIMON / RETURN CHANNEL":"obsolete 1998 recording","THE SPARE PLACE":"Dad returned in 1999","private player note":"keep"},"old_progress":true}
	g.NOTES.refresh_collected(fixture)
	check("legacy collected paper gets current wording",fixture.notes[g.NOTES.COMPARISON_TITLE]==g.NOTES.SOURCE_COPY and not fixture.notes.has("SIMON / RETURN CHANNEL"))
	check("birthday contradiction remains explicitly false",fixture.notes["THE SPARE PLACE"]==g.NOTES.SPARE_CARD_NOTE)
	check("no unearned clues or progression inserted",fixture.notes.size()==3 and fixture.size()==2 and fixture.notes["private player note"]=="keep")
	g.isolated=true;g.player.position=Vector3(-1,-2.99,-20)
	await clear_weights()
	put("tin",Vector3(0,.3,0));await wait(2)
	check("tool tin holds physical release",g.investigation.open,str(g.physical.props.tin.supports))
	g.player.camera.look_at(g.investigation.pad);await shot("D04_tin_release")
	await clear_weights();put("pot",Vector3(0,.3,0));await wait(2)
	check("ordinary cooking pot is another valid weight",g.investigation.open,str(g.physical.props.pot.supports))
	await clear_weights()
	for i in 3:put("can"+str(i),Vector3(-.24+i*.24,.25,0))
	await wait(2)
	check("three ordinary tins combine their supported mass",g.investigation.open,str(g.investigation.supported_weight()))
	await shot("D05_combined_weight")
	await clear_weights();put("counter_mug",Vector3(-.2,.2,0));put("kitchen_mug",Vector3(0,.2,0));put("can0",Vector3(.2,.25,0));await wait(2)
	check("mixed cup and tin solution works",g.investigation.open,str(g.investigation.supported_weight()))
	await clear_weights();put("cup",Vector3(0,.2,0));await wait(2)
	check("one light cup cannot hold spring",not g.investigation.open)
	await clear_weights()
	var slab:=Node3D.new();g.add_child(slab)
	g.box(slab,g.investigation.pad+Vector3(0,.23,0),Vector3(.5,.04,.5),Color.GRAY,true)
	put("tin",Vector3(0,.5,0));await wait(2)
	check("weight supported above plate cannot activate it",not g.investigation.open,str(g.physical.props.tin.supports))
	slab.queue_free();await clear_weights()
	put("tin",Vector3(0,.12,0));put("can0",Vector3(0,.36,0));await wait(2)
	check("stacked supported bodies transmit mass without double count",g.investigation.supported_weight()>1.3 and g.investigation.supported_weight()<1.4,str(g.investigation.supported_weight())+" / "+str(g.physical.props.can0.position)+" / "+str(g.physical.props.can0.supports)+" / "+str(g.physical.props.can0.linear_velocity))
	g.save_game();g.load_game();await wait(2)
	check("stacked release recovers after real save load",g.investigation.open)
	await clear_weights()
	# Reuse the earned original's real carry/drop/cross/read interaction test.
	g.player.position=Vector3(-3.1,.04,-7)
	await recover_field_return()
	check("original remains obtainable with normal carrying",g.events.get("field_return_read",false))
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	var file=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Native labelled support/text fixtures; actual carrying and kitchen traversal. Not a full fresh route or human review."},"\t"));file.close()
	print("DIRECTOR_QA_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)

