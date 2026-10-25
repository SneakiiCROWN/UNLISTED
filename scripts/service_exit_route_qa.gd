extends "res://scripts/witness_carbon_qa.gd"
# Continuous input route: existing item and real impact, no awards or relocations.
func play_store() -> void:
	await super.play_store()
	if not await travel(Vector2(0,-7),"return by original ramp"):return
	if not await travel(Vector2(-3.1,-7),"investigate with utility tools"):return
	if not await travel(Vector2(-3.2,-7.75),"original tool tin approach"):return
	var tin: RigidBody3D=g.physical.props.tin
	g.player.camera.look_at(tin.global_position);await action("interact")
	check("fresh investigation picks up existing tool tin",g.physical.held==tin)
	if g.physical.held!=tin:return
	if not await travel(Vector2(-3.1,-7),"carried tool clears utility"):return
	if not await travel(Vector2(0,-7),"carry tool to cellar hall"):return
	if not await travel(Vector2(0,-18),"carry tool down original ramp"):return
	if not await travel(Vector2(3.25,-16.1),"tool reaches original crawl"):return
	if not await travel(Vector2(3.25,-12.8),"carry tool through low passage",false,true):return
	if not await travel(Vector2(3.25,-9.3),"tool enters records store",false,true):return
	if not await travel(Vector2(5,-8.35),"find service incline from below"):return
	g.player.camera.look_at(Vector3(8,-1.2,-8.35));await shot("X02_records_access")
	if not await travel(Vector2(10.25,-8.35),"carry tool up service incline",false,true):return
	g.player.camera.look_at(g.targets.exit_catch.global_position);await wait(.4)
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.set_meta("unlisted_qa_input",true);Input.parse_input_event(click)
	await wait(.1);click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=false;click.set_meta("unlisted_qa_input",true);Input.parse_input_event(click);await wait(2)
	check("fresh route thrown tool frees real catch",g.events.get("exit_catch_free",false) and g.physical.held==null)
	if not g.events.get("exit_catch_free",false):return
	if not await use("exit_grille"):return
	await wait(1.5)
	check("fresh route witnesses departure before crossing",g.events.get("exit_false_departure",false) and g.player.position.x<11)
	if not g.events.get("exit_false_departure",false):return
	g.player.camera.look_at(Vector3(11.8,.6,-8.35));await shot("X03_open_return")
	if not await travel(Vector2(5,-8.35),"new incline reconnects original store",false,true):return
	await wait(.3);check("normal standing resumes in records aisle",not g.player.crouched and g.player.can_stand())
	if not await travel(Vector2(5,-9.6),"follow wire to existing terminal"):return
	if not await use("exit_receipt",false):return
	check("contact evidence earns no later clues",g.events.get("exit_receipt_read",false) and g.events.get("witness_carbon_read",false) and not g.events.get("line_strip_read",false) and not g.events.get("memory_confirmed",false))
	await shot("X04_false_departure_evidence");await action("ui_cancel");await wait(.4)
	check("continuous discovery starts local search",g.events.get("exit_blackout_running",false) and g.threat.active() and g.events.threat_origin=="service_exit")
	await wait(2);g.player.camera.look_at(Vector3(3.25,-2,-10.4));await shot("X05_blackout_store")
	if not await travel(Vector2(5,-8.35),"blackout escape through working aisle"):return
	if not await travel(Vector2(12.2,-8.35),"real crouched service escape",false,true):return
	if not await travel(Vector2(13.25,-8.35),"new escape reaches open property"):return
	for i in 200:
		if g.events.get("exit_blackout_done",false):break
		await wait(.15)
	check("local search preserves relay encounter",g.events.get("exit_blackout_done",false) and not g.events.get("threat_resolved",true) and not g.threat.active() and not g.events.get("threat_pending",true))
	g.save_game();g.load_game();await wait(.3)
	check("outside save retains both discoveries",g.events.get("exit_receipt_read",false) and g.events.get("witness_carbon_read",false) and g.events.get("exit_blackout_done",false))
	g.player.camera.look_at(Vector3(9.5,.3,-8.35));await shot("X01_exterior_bulkhead");await shot("X06_yard_escape")
	await return_tool()

func return_tool() -> void:
	var tin: RigidBody3D=g.physical.props.tin
	if not await travel(Vector2(10.25,-8.35),"return to retrieve thrown tool",false,true):return
	g.player.camera.look_at(tin.global_position);await action("interact")
	check("same thrown tool remains retrievable",g.physical.held==tin)
	if g.physical.held!=tin:return
	if not await travel(Vector2(5,-8.35),"carry recovered tool down incline",false,true):return
	if not await travel(Vector2(3.25,-9.3),"rejoin original records aisle"):return
	if not await travel(Vector2(3.25,-12.8),"old crawl retains prop clearance",false,true):return
	if not await travel(Vector2(3.25,-16.1),"return to cellar with tool",false,true):return
	if not await travel(Vector2(0,-18),"old relay route remains clear"):return
	if not await travel(Vector2(0,-7),"return tool up original ramp"):
		await shot("X07_blocked_ramp")
		await travel(Vector2(0,-7),"diagnostic crouched ramp with same tool",false,true)
		await shot("X08_crouched_ramp");return
	if not await travel(Vector2(-3.1,-7),"recovered tool returns to utility"):return
	if not await travel(Vector2(-3.2,-7.75),"leave tool beside original bench"):return
	g.player.camera.look_at(g.physical.homes.tin.origin);await action("interact");await wait(1)
	check("tool remains usable for later weight puzzle",g.physical.held==null and tin.position.x< -2.5 and tin.position.x> -3.8 and tin.position.z< -7.8 and tin.position.z> -9.8)
	if not await travel(Vector2(-3.1,-7),"return from tool bench"):return
	if not await travel(Vector2(0,-7),"original hall progression continues"):return
	await travel(Vector2(0,-18),"new evidence rejoins isolation progression")
