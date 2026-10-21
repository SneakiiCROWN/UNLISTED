extends Node3D
# A mechanical evidence puzzle, followed by an actual departure through the property.
var game: Node3D
var cover: MeshInstance3D
var open:=false
var weighted_for:=0.0
var departure_clock:=0.0
var departure_cue:=0
var pad:=Vector3(1.6,-2.995,-20.0)

func _ready() -> void:
	name="FieldInvestigation"
	var metal="res://assets/dusk/psx_house_steel_01.png"
	var root:=Node3D.new();root.name="OriginalFieldReturnCase";add_child(root);root.position=Vector3(3.85,-2.3,-23.72)
	var back: MeshInstance3D=game.box(root,Vector3(0,0,.04),Vector3(.70,.73,.14),Color("3c453d"))
	back.material_override=game.texture_mat(metal,Color("53594b"))
	game.paper(Vector3(3.85,-2.3,-23.59),"field_notebook","S. WARD\nFIELD RETURN\n1998\n\nORIGINAL")
	var paper: Node3D=game.targets.field_notebook.get_parent()
	var ink: Label3D=paper.find_children("*","Label3D",false,false)[0]
	ink.font_size=13;ink.pixel_size=.0033
	cover=game.box(root,Vector3(0,0,.17),Vector3(.59,.66,.035),Color("3c453d"))
	cover.material_override=game.texture_mat(metal,Color("53594b"))
	game.box(cover,Vector3(.22,-.10,.035),Vector3(.04,.16,.025),Color("222a25"))
	var plate: MeshInstance3D=game.box(self,pad-Vector3.UP*.0025,Vector3(.86,.005,.90),Color("55594a"))
	plate.name="MechanicalReleasePad";plate.material_override=game.texture_mat(metal,Color("706951"))
	for x in [-.34,.34]:game.box(self,pad+Vector3(x,.004,0),Vector3(.012,.008,.56),Color("a1986a"))
	var repair=load("res://scripts/environment_repair.gd").new();repair.g=game
	repair.tube(Vector3(1.95,-2.99,-20),Vector3(4.11,-2.99,-20),.012)
	repair.tube(Vector3(4.11,-2.99,-20),Vector3(4.11,-2.99,-23.56),.012)
	repair.tube(Vector3(4.11,-2.96,-23.56),Vector3(4.11,-2.42,-23.56),.018)
	# A real sight-blocking maintenance screen shelters the existing rest corner.
	var screen: MeshInstance3D=game.box(self,Vector3(-5.55,.82,-4.7),Vector3(.09,1.64,1.8),Color("485247"),true)
	screen.name="UtilityMaintenanceScreen";screen.material_override=game.texture_mat("res://assets/original/work_canvas.png",Color(.8,.8,.7))
	for z in [-5.58,-3.82]:repair.tube(Vector3(-5.55,.02,z),Vector3(-5.55,1.70,z),.022)
	restore()

func restore() -> void:
	open=game.events.get("field_return_read",false);weighted_for=0
	cover.position.x=-.66 if open else 0.0
	game.targets.field_notebook.collision_layer=1 if open else 0
	game.targets.field_notebook.get_parent().visible=not game.events.get("field_return_read",false)
	departure_clock=0;departure_cue=0

func read_original() -> void:
	if not open:return
	game.events.field_return_read=true
	game.targets.field_notebook.get_parent().visible=false
	game.inspect_text("SIMON / ORIGINAL FIELD RETURN",game.NOTES.ORIGINAL)
	game.save_game()

func _process(delta: float) -> void:
	if not game.started or game.menu_open or game.ended:return
	var weight:=0.0
	var feet: Vector3=game.player.global_position-pad
	if absf(feet.x)<.43 and absf(feet.z)<.45 and absf(feet.y)<.1 and game.player.is_on_floor():weight=70.0
	for body in game.physical.props.values():
		if body==game.physical.held:continue
		var p: Vector3=body.global_position-pad
		if absf(p.x)<.43 and absf(p.z)<.45 and p.y>0 and p.y<.4 and body.linear_velocity.length()<.45:weight+=body.mass
	weighted_for=weighted_for+delta if weight>=.8 and game.isolated else 0.0
	var released: bool=game.events.get("field_return_read",false) or weighted_for>.4
	if released!=open:
		open=released
		var catch: AudioStreamPlayer3D=game.sound("latch",cover.global_position,-25)
		game.sound_caption("A spring catch releases." if open else "The catch snaps shut.",2,"RETURN DRAWER",catch)
	cover.position.x=move_toward(cover.position.x,-.66 if open else 0.0,delta*.8)
	game.targets.field_notebook.collision_layer=1 if open and cover.position.x<-.55 and not game.events.get("field_return_read",false) else 0
	if str(game.events.get("departure_pending",""))=="":return
	departure_clock+=delta
	if departure_cue<2 and departure_clock>2.0+departure_cue*3.0:
		game.sound("step",Vector3(0,0,-1+departure_cue*3),-27);departure_cue+=1
	if game.player.position.z>21 and absf(game.player.position.x)<9 and game.player.position.y>-.4:
		game.events.ending=game.events.departure_pending
		game.events.departure_pending=""
		game.finish_game()
