extends Node3D
# Hiding is physical cover. No hidden/invulnerable flag and no player teleport.
var game: Node3D
var leaves: Array[Node3D]=[]
var opened:=false
var suspected:=false
var force_clock:=0.0
var held_open:=0.0
var motion: Tween
func _ready() -> void:
	name="OfficeStorageCupboard";position=Vector3(6.35,0,-3.65);rotation.y=PI
	var body: Node3D=game.model("res://assets/interiors/home/storageCupboard.glb",self,Vector3.ZERO,Vector3(1.18,2.06,.86))
	game.chapter.finish_materials(body)
	for leaf_name in ["doorLeft","doorRight"]:
		var found:=body.find_children(leaf_name,"Node3D",true,false)
		if found.is_empty():push_error("Storage cupboard missing fitted door "+leaf_name);continue
		var leaf: Node3D=found[0];leaves.append(leaf)
		var bounds:=AABB();var first:=true
		for mesh in game.all_meshes(leaf):
			var actual: AABB=leaf.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
			bounds=actual if first else bounds.merge(actual);first=false
		game.collision(leaf,bounds.get_center(),bounds.size.max(Vector3(.001,.001,.02)),"storage_door")
	for x in [-.53,.53]:game.collision(self,Vector3(x,1.03,0),Vector3(.12,2.06,.86))
	game.collision(self,Vector3(0,1.03,-.405),Vector3(1.18,2.06,.05))
	game.collision(self,Vector3(0,2.02,0),Vector3(1.18,.08,.86))
	# The imported carcass has no internal shelves/base across the player's route.
	restore()
func inside() -> bool:
	var p:=to_local(game.player.global_position)
	return absf(p.x)<.40 and p.z>-.28 and p.z<.22 and p.y>-.1 and p.y<.4
func restore() -> void:
	if motion and motion.is_valid():motion.kill()
	opened=game.events.get("storage_open",false);suspected=game.events.get("storage_suspected",false)
	force_clock=0;held_open=0
	for i in leaves.size():leaves[i].rotation.y=(-1.45 if i==0 else 1.45) if opened else 0.0
func set_open(value: bool,by_actor:=false) -> void:
	if opened==value:return
	if not value:
		var p:=to_local(game.player.global_position)
		if held_open>0:game.message("He's holding the doors.",1.5);return
		if absf(p.x)<.8 and p.z>.18 and p.z<.9:game.message("I need to step clear of the doors.",1.5);return
		if inside() and game.threat.active() and game.threat.can_see_player():suspected=true
	opened=value;game.events.storage_open=value;game.events.storage_suspected=suspected
	if motion and motion.is_valid():motion.kill()
	motion=create_tween().set_parallel(true)
	for i in leaves.size():motion.tween_property(leaves[i],"rotation:y",(-1.45 if i==0 else 1.45) if value else 0.0,.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	game.sound("door",global_position+Vector3.UP,-33)
	if by_actor:
		held_open=4;game.threat.change("warning");game.threat.grace=1.3
	else:game.threat.hear(global_position,2.0)
	# Never replace the safe approach checkpoint while the player is being hunted.
	if not game.threat.active():game.save_game(true)
func use() -> void:
	set_open(not opened)
func _physics_process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	held_open=maxf(0,held_open-delta)
	if not inside():
		suspected=false;game.events.storage_suspected=false;force_clock=0;return
	if game.threat.active() and game.threat.can_see_player():suspected=true;game.events.storage_suspected=true
	if not game.threat.active() or opened:force_clock=0;return
	if game.threat.state in ["investigate","search","pursue"] and game.threat.last_known.distance_to(global_position)<1.1:suspected=true;game.events.storage_suspected=true
	if suspected and game.presence.position.distance_to(global_position)<1.8 and game.threat.grace<=0:
		force_clock+=delta
		if force_clock>.9:set_open(true,true);force_clock=0
	else:force_clock=0
