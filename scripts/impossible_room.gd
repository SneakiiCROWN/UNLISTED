extends Node3D
# One authored room-memory, using the actual furnishings and their collisions.
# The player, gravity, doorway, windows and house shell never rotate.
var game: Node3D
var active:=false
var quiet:=0.0
var visited_for:=0.0
var closed_for:=0.0
var surfaces: Node3D
var sight_exclusions: Array[RID]=[]
var settle_clock:=0.0
var visibility_points: Array[Vector3]=[]
const TURN:=Transform3D(Basis(Vector3.RIGHT,PI),Vector3(0,2.8,1.0))

func _ready() -> void:
	name="ImpossibleLoungeMemory"
	# Sample the room's changed volume, not just three furniture centres. A
	# partial view through glazing must also protect the destination geometry.
	for x in [1.72,4.5,7.28]:
		for z in [-2.72,.5,3.72]:
			for y in [.18,1.4,2.62]:visibility_points.append(Vector3(x,y,z))
	sight_exclusions.append(game.player.get_rid())
	for body in game.find_children("*","StaticBody3D",true,false):
		if body.get_meta("transparent_glass",false):sight_exclusions.append(body.get_rid())
	surfaces=Node3D.new();surfaces.name="ReversedRoomSurfaces";add_child(surfaces)
	var floor_=game.box(surfaces,Vector3(4.48,0.009,0.50),Vector3(5.90,0.012,6.80),Color.WHITE)
	floor_.material_override=game.texture_mat("res://assets/dusk/psx_house_ceiling_01.png",Color(.35,.37,.34))
	var ceiling_=game.box(surfaces,Vector3(4.48,2.791,0.50),Vector3(5.90,0.012,6.80),Color.WHITE)
	ceiling_.material_override=game.texture_mat("res://assets/dusk/psx_house_old_wood_01.png",Color(.53,.49,.40))
	for piece in [floor_,ceiling_]:piece.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surfaces.visible=false

func inside(point: Vector3, margin:=0.0) -> bool:
	return point.y>-.4 and point.y<3.2 and point.x>1.5-margin and point.x<7.5+margin and point.z>-3-margin and point.z<4+margin

func closed() -> bool:
	return not game.doors.lounge.opened and absf(game.doors.lounge.pivot.rotation.y)<.03

func safe_to_change() -> bool:
	if inside(game.player.global_position,0.65):return false
	if game.presence.visible and inside(game.presence.global_position,0.65):return false
	return closed() and not can_see_changed_room()

func chair_pose() -> Array:
	var p: Vector3=game.chair.position;var r: Vector3=game.chair.rotation
	return [p.x,p.y,p.z,r.x,r.y,r.z]

func remember_chair() -> void:
	game.events.impossible_chair_pose=chair_pose()

func apply_chair_pose() -> void:
	var pose: Array=game.events.get("impossible_chair_pose",[])
	if pose.size()!=6:return
	game.chair.position=Vector3(pose[0],pose[1],pose[2])
	game.chair.rotation=Vector3(pose[3],pose[4],pose[5])

func reset() -> void:
	if active:
		game.lounge_contents.transform=Transform3D.IDENTITY
		apply_chair_pose()
		if game.events.get("return",false):
			game.chair.position=Vector3(.65,0,-2.8);game.chair.rotation=Vector3(0,PI,0)
	active=false;surfaces.visible=false;quiet=0;closed_for=0;visited_for=0;settle_clock=0

func restore_saved() -> void:
	if not game.events.get("impossible_room_active",false):return
	apply_chair_pose()
	game.lounge_contents.transform=TURN
	active=true;surfaces.visible=true;settle_clock=0

func begin() -> bool:
	if is_instance_valid(game.dead_line) and not game.dead_line.sequence.is_empty():return false
	if active or not safe_to_change() or game.physical.held or game.threat.active() or game.horror.beat!="" or game.horror.audition!="" or game.horror.echo_index>=0:return false
	if game.chapter.active or game.events.get("memory_bedroom_active",false) or game.recount.active:return false
	remember_chair();game.events.impossible_room_active=true
	game.lounge_contents.transform=TURN;surfaces.visible=true;active=true;closed_for=0
	# A loose cup obeys ordinary gravity when its support moves away. It remains
	# an ordinary physical prop, including carry/throw and checkpoint behaviour.
	game.physical.props.cup.sleeping=false
	var cue=game.sound("door",Vector3(4.7,2.4,.5),-33);cue.pitch_scale=.65
	game.sound_caption("Timber strains beyond the door.",2.5,"LOUNGE",cue)
	game.save_game(true)
	return true

func can_see_changed_room() -> bool:
	for point in visibility_points:
		if visible_point(point):return true
	return false

func can_see_furniture() -> bool:
	# Visibility protection is deliberately broader than narrative recognition.
	# Seeing a sliver of floor must not award knowledge of ceiling furniture.
	for point in [game.lounge_contents.to_global(Vector3(6.4,.55,.3)),game.lounge_contents.to_global(Vector3(4.5,.79,.3)),game.targets.television.global_position]:
		if visible_point(point):return true
	return false

func visible_point(point: Vector3) -> bool:
	var camera: Camera3D=game.player.camera
	if camera.is_position_behind(point):return false
	if not game.get_viewport().get_visible_rect().has_point(camera.unproject_position(point)):return false
	var query:=PhysicsRayQueryParameters3D.create(camera.global_position,point,1)
	query.exclude=sight_exclusions
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or game.lounge_contents.is_ancestor_of(hit.collider)

func _process(delta: float) -> void:
	if not game.started or game.menu_open:return
	if not active:
		if inside(game.player.global_position):
			visited_for+=delta
			if visited_for>1.5:game.events.lounge_seen_before=true
		else:visited_for=0
		if game.events.get("impossible_room_resolved",false):
			if not game.events.get("impossible_room_revisited",false) and game.doors.lounge.opened and can_see_furniture():
				game.events.impossible_room_revisited=true
				var notes: Dictionary=game.events.get("notes",{})
				notes["THE ROOM / AFTER THE ARCHIVE"]=str(notes.get("THE ROOM / AFTER THE ARCHIVE",""))+"\nI opened the door again. Everything was back on the floor."
				game.events.notes=notes
			return
		if game.report_read and game.events.get("lounge_seen_before",false) and game.events.get("chair",false) and not game.isolated and safe_to_change() and not game.threat.active() and game.horror.beat=="":
			quiet+=delta
			if not game.events.has("impossible_delay"):game.events.impossible_delay=4.0+float(int(game.events.get("horror_seed",1998))%7)*.65
			if quiet>float(game.events.impossible_delay):begin()
		else:quiet=0
		return
	if not game.events.get("impossible_room_seen",false) and can_see_furniture():
		game.events.impossible_room_seen=true
		var notes: Dictionary=game.events.get("notes",{})
		notes["THE ROOM / AFTER THE ARCHIVE"]="The lounge furniture was fixed to the ceiling. The door and window hadn't moved."
		if game.events.get("memory_reviewed",false):notes["THE ROOM / AFTER THE ARCHIVE"]+=" The drawing beside the television was still signed ELI / AGE 7."
		game.events.notes=notes
		game.save_game(true)
	# One small contact above Eli, attached to the real inverted table. It is
	# spent before playback, so reload cannot repeat or resume an old scare.
	if inside(game.player.global_position) and game.events.get("impossible_room_seen",false) and not game.events.get("impossible_room_settled",false) and not game.threat.active():
		settle_clock+=delta
		if settle_clock>1.3:
			game.events.impossible_room_settled=true
			var cue=game.sound("foley/drop_wood_2",game.lounge_contents.to_global(Vector3(4.5,.79,.3)),-33)
			cue.pitch_scale=.72;game.sound_caption("Wood shifts overhead.",2.0,"LOUNGE",cue)
			game.save_game(true)
	else:settle_clock=0
	if safe_to_change() and game.events.get("impossible_room_seen",false):
		closed_for+=delta
		if closed_for>.35:
			reset();game.events.impossible_room_active=false;game.events.impossible_room_resolved=true
			game.save_game(true)
	else:closed_for=0
