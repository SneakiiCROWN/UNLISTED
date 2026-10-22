extends Node3D
# One consequence of discovering Simon's inspection note. Never appears in sight.
var game: Node3D
const SPAWN:=Vector3(0,.04,-4.6)
const SEARCH:=Vector3(6.25,.04,-4.8)
func _ready() -> void:
	name="InspectionSearch"
	# Existing office portal, with capsule-clear points in front of the storage corner.
	var previous:=17
	for point in [Vector3(5.3,.04,-6),Vector3(6.25,.04,-4.8)]:
		var id: int=game.threat.graph.get_point_count();game.threat.graph.add_point(id,point);game.threat.graph.connect_points(previous,id);previous=id
func _physics_process(_delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	if game.events.get("inspection_search_pending",false):
		if game.threat.active() or game.presence.visible or game.horror.beat!="" or game.chapter.active or game.chapter.return_clock>=0 or game.impossible_room.active or game.recount.active:return
		if game.player.position.y<-.2 or game.player.position.x<1.6 or game.player.position.z> -3 or game.player.position.distance_to(SPAWN)<3:return
		if game.chapter.point_visible(SPAWN+Vector3.UP*1.65):return
		game.events.inspection_search_pending=false;game.events.inspection_search_started=true
		game.events.threat_pending=true;game.events.threat_resolved=false;game.events.threat_origin="inspection";game.events.threat_spawn=[SPAWN.x,SPAWN.y,SPAWN.z]
		game.threat.begin(false,SPAWN);game.threat.last_known=SEARCH;game.save_game(true)
	if not game.events.get("inspection_search_started",false) or game.events.get("inspection_search_done",false):return
	if game.events.get("threat_origin","")!="inspection":return
	if game.threat.state=="observe":
		game.threat.last_known=SEARCH;game.threat.change("investigate");game.threat.plan(SEARCH)
	if game.events.get("threat_resolved",false) and not game.threat.active():
		game.events.inspection_search_done=true;game.save_game(true)
