extends Node3D
# One recoverable historical recording. Existing tonight A/B evidence stays available.
var game: Node3D
var reel: Node3D
var stored_reel: Node3D
var clock:=0.0
var playing:=false
var next:=0
var motor: AudioStreamPlayer3D
var sources: Array[AudioStreamPlayer3D]=[]
const DECK:=Vector3(3.3,.98,-8.52)
const NOTE_TITLE:="SIMON / SERVICE TEST REEL"
const LABEL:="S. WARD / 1998\nOFFICE LINE TEST\n\nFeed on. Return connected.\nThen both disconnected.\nKeep listening after the motor stops."
const RESULT:="The reel is labelled 1998, in Dad's handwriting.\n\nFirst the motor runs and the test box answers three taps. Then there is a switch click. The motor stops. After a long pause, the same taps come back.\n\nDad wrote 'both disconnected' on the sleeve. That is what he was testing: whether the sound could still come back with no working line.\n\nI can try it on the office box. A noise isn't proof that somebody came back."
const CUES:=[.45,1.1,1.7,2.55,3.1,3.7,5.2,10.0,10.6,11.45]
func _ready() -> void:
	name="HistoricalTestReel";build();restore()
func make_reel(parent: Node3D) -> Node3D:
	var root:=Node3D.new();parent.add_child(root)
	var mesh:=CylinderMesh.new();mesh.top_radius=.091;mesh.bottom_radius=.091;mesh.height=.014;mesh.radial_segments=24
	var tape:=MeshInstance3D.new();tape.mesh=mesh;tape.material_override=game.texture_mat("res://assets/dusk/psx_house_steel_01.png",Color("423829"));root.add_child(tape);tape.position.y=.016
	for y in [.005,.029]:
		var ring:=MeshInstance3D.new();var torus:=TorusMesh.new();torus.inner_radius=.081;torus.outer_radius=.10;torus.rings=24;torus.ring_segments=6;ring.mesh=torus;ring.material_override=game.mat(Color("777568"));root.add_child(ring);ring.position.y=y
		for i in 3:
			var spoke: Node3D=game.box(root,Vector3.ZERO,Vector3(.081,.005,.014),Color("777568"));spoke.rotation.y=i*TAU/3;spoke.position=Vector3(cos(-spoke.rotation.y)*.045,y,sin(-spoke.rotation.y)*.045)
	return root
func build() -> void:
	var rack: Node3D=game.maintenance.rack
	# A bolted lip on the real shelf supports an upright reel sleeve, outside
	# the rack's full-height collision proxy. No unreachable pickup inside its box.
	game.box(rack,Vector3(-.43,.87934375,-.255),Vector3(.28,.020,.16),Color("57574a"))
	reel=Node3D.new();rack.add_child(reel);reel.position=Vector3(-.43,1.01434375,-.266);reel.rotation.x=-PI/2
	var sleeve: Node3D=game.box(reel,Vector3(0,.002,0),Vector3(.24,.004,.25),Color("afa17e"));sleeve.material_override=game.texture_mat("res://assets/original/aged_paper.png",Color("afa17e"))
	make_reel(reel)
	var label: Label3D=game.label3(reel,"S. WARD / 1998\nLINE TEST",Vector3(0,.007,.105),0,12,Color("383b31"));label.quaternion=Quaternion(Vector3.RIGHT,PI/2)*Quaternion(Vector3.UP,PI);label.pixel_size=.0012
	game.collision(reel,Vector3(0,.055,0),Vector3(.25,.11,.25),"test_reel")
	var deck: Node3D=game.get_node("ArchiveTransport")
	game.collision(deck,Vector3(0,.10,-.11),Vector3(.12,.15,.14),"test_reel_deck")
	stored_reel=make_reel(deck);stored_reel.position=Vector3(-.34,.058,-.04)
	game.box(deck,Vector3(-.34,.055,-.04),Vector3(.22,.005,.23),Color("786f59"))
	var tag: Label3D=game.label3(deck,"REEL / 1998",Vector3(-.34,.058,.057),0,11,Color("c3bba1"));tag.rotation.x=-PI/2;tag.pixel_size=.001
func stop() -> void:
	playing=false;clock=0;next=0
	for source in sources:
		if is_instance_valid(source):source.stop();source.queue_free()
	sources.clear();motor=null
	if is_instance_valid(game.horror) and game.horror.audition=="FIELD":game.horror.audition=""
func restore() -> void:
	stop();reel.visible=not game.events.get("test_reel_found",false);game.targets.test_reel.collision_layer=1 if reel.visible else 0
	stored_reel.visible=game.events.get("test_reel_loaded",false)
func use(id: String) -> void:
	if id=="test_reel":
		game.events.test_reel_found=true;game.events.notes[NOTE_TITLE]=LABEL
		restore();game.presentation.notify("1998 test reel taken. It fits the office deck.");game.save_game(true);return
	if game.threat.active():game.presentation.notify("Movement nearby. Not a good time to listen.");return
	game.presentation.pause_world();game.presentation.clear_card();game.presentation.section="document"
	game.presentation.label(game.presentation.card_body,"OFFICE / TAPE DECK",15,"Meta")
	game.presentation.label(game.presentation.card_body,"SERVICE TEST / 1998",30,"Title")
	var body: String=LABEL if game.events.get("test_reel_found",false) else "The deck is already threaded for the hall microphone. A handwritten card beside it says: '1998 line-test reel kept with the service records below.'\n\nThe A/B controls compare my own footsteps tonight. The old test recording is separate."
	if game.events.get("test_reel_heard",false):body=RESULT
	var explanation: Label=game.presentation.label(game.presentation.card_body,body,19)
	explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;explanation.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if game.events.get("test_reel_found",false):
		var caption: String="Replay service test" if game.events.get("test_reel_loaded",false) else "Load reel and listen"
		game.presentation.add_button(caption,func():game.presentation.resume_game();play(),game.stage>=3,game.presentation.card_body)
	if game.stage<3:game.presentation.label(game.presentation.card_body,"The supply light is out.",17,"Meta")
	game.presentation.add_button("Leave deck",game.presentation.resume_game,true,game.presentation.card_body).grab_focus()
func play() -> void:
	if game.stage<3 or game.threat.active() or not game.events.get("test_reel_found",false):return
	game.horror.stop_audition();stop();game.horror.audition="FIELD"
	game.events.test_reel_loaded=true;stored_reel.visible=true;game.save_game(true)
	playing=true;clock=0;next=0
	motor=game.sound("hum",DECK,-32,true);motor.unit_size=1;motor.max_distance=7;sources.append(motor)
	game.sound_caption("Motor running on the recording.",2.5,"1998 TEST REEL",motor,true)
func cue(index: int) -> void:
	if index==6:
		if is_instance_valid(motor):motor.stop()
		var click=game.sound("latch",DECK,-29);sources.append(click)
		game.sound_caption("A switch clicks. The motor stops.",2.5,"1998 TEST REEL",click,true);return
	var audio=game.sound("prop_impact",DECK,-27 if index>=7 else -31);sources.append(audio)
	audio.unit_size=1;audio.max_distance=9;audio.pitch_scale=.82 if index>=7 else 1.12
	if index==0:game.sound_caption("Three taps, then a reply.",3.2,"1998 TEST REEL",audio,true)
	if index==7:game.sound_caption("The same taps, with the motor silent.",3,"1998 TEST REEL",audio,true)
func _physics_process(delta: float) -> void:
	if not playing:return
	if game.horror.audition!="FIELD" or game.ended or game.threat.active():stop();return
	clock+=delta
	for r in get_tree().get_nodes_in_group("archive_reels"):r.rotation.y+=delta*1.8
	while next<CUES.size() and clock>=CUES[next]:cue(next);next+=1
	if clock>=14:
		game.events.test_reel_heard=true;game.events.notes[NOTE_TITLE]=RESULT
		stop();game.save_game(true);game.presentation.notify("Test reel finished / observation kept in field notes.")
