extends CanvasLayer
# Explicit development exports, or editor + --unlisted-dev only. No production
# autoload, ordinary saves, external processes, or arbitrary script execution.
const BOOKMARKS := {"Porch":Vector3(0,0.08,7),"Garden gate":Vector3(0,0.08,14.5),"Country lane":Vector3(0,0.08,23),"Hall":Vector3(0,0.08,-4),"Utility":Vector3(-4.5,0.08,-8),"Service yard":Vector3(-8,0.08,-12),"Shed":Vector3(-16,0.08,-14),"Basement":Vector3(0,-2.92,-18)}
var game: Node
var panel: PanelContainer
var diagnostic: Label
var audio_info: Label
var status: Label
var armed: CheckButton
var coords: LineEdit
var bookmarks: OptionButton
var speed: SpinBox
var free_camera: Camera3D
var opened := false
var flying := false
var invulnerable := false
var paused_before := false
var active_before := false
var mouse_before := Input.MOUSE_MODE_VISIBLE
var previous: Transform3D
var saved_pose: Transform3D
var snapshot: Dictionary = {}
var look_hit: Dictionary = {}
var last_target := ""
var refresh := 0.0
var output := "user://development/evidence"
var navigation_overlay: MeshInstance3D

func _ready() -> void:
	if not game.dev_mode:queue_free();return
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	DirAccess.make_dir_recursive_absolute(output)
	build_ui()
	previous = game.player.global_transform
	saved_pose = previous
	log_event("development_session",{"checkpoint":game.checkpoint_path,"settings":game.presentation.prefs.path})
	if "--dev-tools-qa" in OS.get_cmdline_user_args():call_deferred("run_qa")

func run_qa() -> void:
	game.prepare_automated_qa()
	var qa=load("res://scripts/development_qa.gd").new()
	add_child(qa)
	await qa.run(game,self)

func label(parent: Node, text: String, size := 18) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size",size)
	parent.add_child(node)
	return node

func row(parent: Node) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation",12)
	parent.add_child(node)
	return node

func button(parent: Node,text: String,callback: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.pressed.connect(callback)
	node.custom_minimum_size.y = 38
	parent.add_child(node)
	return node

func build_ui() -> void:
	panel = PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 28;panel.offset_right = -28
	panel.offset_top = 24;panel.offset_bottom = -24
	panel.theme = preload("res://themes/unlisted.tres")
	var backing:=StyleBoxFlat.new();backing.bg_color=Color("101817")
	backing.border_color=Color("53645d");backing.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel",backing)
	var margin := MarginContainer.new()
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,18)
	panel.add_child(margin)
	var scroll := ScrollContainer.new();margin.add_child(scroll)
	var body := VBoxContainer.new();body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",10);scroll.add_child(body)
	label(body,"UNLISTED / DEVELOPMENT ONLY",26)
	label(body,"F1 close / resume    |    Separate test saves    |    World suspended while inspecting",16)
	status = label(body,"Read-only inspection. Enable test actions explicitly before changing the world.")
	diagnostic = label(body,"");diagnostic.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var copies := row(body)
	button(copies,"Copy player coordinates",func():DisplayServer.clipboard_set(str(game.player.global_position)))
	button(copies,"Copy target path",func():DisplayServer.clipboard_set(last_target))
	button(copies,"Screenshot",capture)
	button(copies,"Log diagnostics",func():log_event("inspection",{"text":diagnostic.text,"audio":audio_info.text});status.text="Diagnostics logged in development/evidence.")
	armed = CheckButton.new();armed.text = "Enable isolated test actions (never changes the ordinary save)";body.add_child(armed)
	var travel := row(body)
	bookmarks = OptionButton.new()
	for name_ in BOOKMARKS:bookmarks.add_item(name_)
	travel.add_child(bookmarks)
	button(travel,"Safe teleport",func():teleport_to(BOOKMARKS[bookmarks.get_item_text(bookmarks.selected)]))
	button(travel,"Remember position",func():saved_pose=game.player.global_transform;status.text="Position remembered.")
	button(travel,"Return to bookmark",func():teleport_to(saved_pose.origin))
	button(travel,"Previous position",func():teleport_to(previous.origin))
	var custom := row(body)
	coords = LineEdit.new();coords.placeholder_text = "X, Y, Z";coords.tooltip_text="World coordinates, for example -8, 0.08, -12";coords.size_flags_horizontal=Control.SIZE_EXPAND_FILL;custom.add_child(coords)
	button(custom,"Validate and teleport",coordinate_teleport)
	button(custom,"Teleport near look hit",func():
		if not look_hit.is_empty():teleport_to(look_hit.position+look_hit.normal*0.65))
	var fly := row(body)
	button(fly,"Free camera / noclip fly",toggle_fly)
	button(fly,"Restore normal controls",func():stop_fly();status.text="Normal camera, collision and movement restored.")
	label(fly,"Fly speed")
	speed = SpinBox.new();speed.min_value=0.5;speed.max_value=20;speed.step=0.5;speed.value=4;fly.add_child(speed)
	label(body,"Free camera: WASD + Q/E up/down, Shift faster, mouse look. F1 inspect, Esc restore. Player body stays safe.",16)
	var states := row(body)
	button(states,"Snapshot test state",take_snapshot)
	button(states,"Restore test state",restore_snapshot)
	button(states,"Load isolated checkpoint",func():
		if allow_action() and game.presentation.has_checkpoint():close_panel();game.load_game())
	button(states,"Reset encounter",func():
		if allow_action():
			game.events.erase("threat_pending");game.events.erase("threat_origin")
			game.threat.reset();game.presence.visible=false;game.horror.reset();log_event("reset_encounter"))
	var events := row(body)
	var immunity:=CheckButton.new();immunity.text="Temporary invulnerability";events.add_child(immunity)
	immunity.toggled.connect(func(value):
		if allow_action():invulnerable=value;log_event("invulnerability",{"enabled":value})
		else:immunity.set_pressed_no_signal(invulnerable))
	button(events,"Test hall encounter",func():
		if allow_action():game.threat.begin();log_event("hall_encounter");close_panel())
	button(events,"Test cellar encounter",func():
		if allow_action() and game.player.position.y < -2:game.threat.begin_basement();log_event("cellar_encounter");close_panel()
		else:status.text="Use the basement bookmark first. Test actions must be enabled.")
	button(events,"Preview yard watcher",func():
		if allow_action() and game.player.position.y> -0.3:game.horror.begin("watcher");log_event("yard_watcher");close_panel())
	button(events,"Test timber sound",func():
		if allow_action():game.sound("door",game.player.position+Vector3(2,1,0),-26);log_event("sound",{"sample":"door","offset":Vector3(2,1,0)}))
	var previews:=row(body)
	button(previews,"Preview room memory",func():
		if not allow_action():return
		if game.impossible_room.begin():log_event("impossible_room");close_panel()
		else:status.text="Stand outside the lounge, close its door and end other active encounters first.")
	button(previews,"Preview warned contact",func():
		if not allow_action():return
		if game.threat.active() and game.presence.position.distance_to(game.player.position)<1.3 and game.threat.can_see_player():
			game.threat.change("attack");close_panel()
		else:status.text="Start an encounter and stand within real contact range. Preview preserves the escapable warning.")
	button(previews,"Navigation / target overlay",toggle_navigation)
	var seed_row := row(body)
	var seed_value := SpinBox.new();seed_value.max_value=2147483647;seed_value.value=17;seed_row.add_child(seed_value)
	button(seed_row,"Set repeatable random seed",func():
		if allow_action():
			seed(int(seed_value.value));game.horror.rng.seed=int(seed_value.value)
			game.events.horror_seed=int(seed_value.value);game.events.horror_variant=int(seed_value.value)%2
			game.horror.variant=int(seed_value.value)%2
			log_event("seed",{"value":seed_value.value}))
	audio_info = label(body,"");audio_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label(body,"Not yet implemented: inverted-room controls. Engine collision overlay needs a debug export template.",16)
	panel.visible=false

func allow_action() -> bool:
	if not armed.button_pressed or not game.started or game.ended or game.presentation.section!="game" or game.physical.held:
		status.text="Start or resume gameplay, enable test actions, and release any carried prop first."
		return false
	return true

func open_panel() -> void:
	if opened:return
	paused_before = get_tree().paused
	active_before = game.player.active
	mouse_before = Input.mouse_mode
	game.player.active=false
	get_tree().paused=true
	opened=true;panel.visible=true
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	armed.button_pressed=false
	refresh_diagnostics()

func close_panel() -> void:
	if not opened:return
	opened=false;panel.visible=false
	if flying:
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if game.automated_qa else Input.MOUSE_MODE_CAPTURED
	else:
		get_tree().paused=paused_before
		game.player.active=active_before
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if game.automated_qa else mouse_before

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode==KEY_F1:
			if opened:close_panel()
			else:open_panel()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode==KEY_ESCAPE and (opened or flying):
			stop_fly();close_panel();get_viewport().set_input_as_handled()
	if flying and not opened and event is InputEventMouseMotion:
		free_camera.rotation.y-=event.relative.x*0.0022
		free_camera.rotation.x=clampf(free_camera.rotation.x-event.relative.y*0.0022,-1.5,1.5)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if flying and not opened:
		var axis := Input.get_vector("left","right","forward","back")
		var motion := free_camera.global_basis*Vector3(axis.x,0,axis.y)
		motion.y+=float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q))
		free_camera.position+=motion.limit_length()*speed.value*delta*(3 if Input.is_action_pressed("sprint") else 1)
	refresh+=delta
	if opened and refresh>0.25:refresh=0;refresh_diagnostics()

func room_name(point: Vector3) -> String:
	if point.y < -1:return "Cellar"
	if point.x < -14:return "Service shed / perimeter"
	if point.z < -10 or point.z>4 or absf(point.x)>7.5:return "Exterior"
	if point.x < -1.5:return "Utility" if point.z < -4 else "Kitchen"
	if point.x > 1.5:return "Office" if point.z < -4 else "Lounge"
	return "Hall"

func refresh_diagnostics() -> void:
	var camera: Camera3D=free_camera if flying else game.player.camera
	var query := PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position-camera.global_basis.z*30)
	query.exclude=[game.player.get_rid()]
	look_hit=game.player.get_world_3d().direct_space_state.intersect_ray(query)
	var hit_text := "No hit within 30 m"
	last_target=""
	if not look_hit.is_empty():
		var collider: Node=look_hit.collider
		last_target=str(collider.get_path())
		hit_text="%s | %.2f m | at %s | layer %s"%[last_target,camera.global_position.distance_to(look_hit.position),look_hit.position,collider.get("collision_layer")]
	diagnostic.text="Scene %s | %s | stage %d | %s\nPlayer %s | yaw %.1f | camera %s / %s\n%s\nSurveyor %s | grace %.2f | target %s | route %s\nKeys: brass %s / cellar %s | fuse %s | isolated %s\nCheckpoint %s\n%.1f FPS / %.2f ms | nodes %d | objects %d | static memory %.1f MB\nCaption (legacy, unclassified): %s"%[game.scene_file_path,room_name(game.player.position),game.stage,"free camera" if flying else "normal controller",game.player.position,rad_to_deg(game.player.rotation.y),camera.global_position,camera.global_rotation_degrees,hit_text,game.threat.state,game.threat.grace,game.threat.last_known,game.threat.route.size(),game.brass_key,game.shed_read,game.fuse,game.isolated,game.checkpoint_path,Engine.get_frames_per_second(),Performance.get_monitor(Performance.TIME_PROCESS)*1000,Performance.get_monitor(Performance.OBJECT_NODE_COUNT),Performance.get_monitor(Performance.OBJECT_COUNT),Performance.get_monitor(Performance.MEMORY_STATIC)/1048576,game.subtitle.text]
	var buses: Array=[]
	for i in AudioServer.bus_count:buses.append("%s %.1f dB%s"%[AudioServer.get_bus_name(i),AudioServer.get_bus_volume_db(i)," MUTED" if AudioServer.is_bus_mute(i) else ""])
	var sources: Array=[]
	for node in game.find_children("*","",true,false):
		if (node is AudioStreamPlayer or node is AudioStreamPlayer3D) and node.playing:sources.append(str(node.get_path())+" / "+str(node.stream.resource_path))
	audio_info.text="Audio: "+" | ".join(buses)+"\nActive sources: "+"\n".join(sources)+"\nHorror beat: "+game.horror.beat+" / events: "+str(game.events.keys())
	diagnostic.text=diagnostic.text.replace("Caption (legacy, unclassified):", "Current rendered text:")
	audio_info.text+="\nText owner / category / paired stream: "+JSON.stringify(game.message_info)
	if game.capture_director.active:audio_info.text+="\nCapture: "+str(game.capture_director.clock)+" / "+str(game.surveyor_actor.capture_diagnostics)

func toggle_navigation() -> void:
	if is_instance_valid(navigation_overlay):navigation_overlay.queue_free();return
	var geometry:=ImmediateMesh.new()
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo=true;material.no_depth_test=true
	geometry.surface_begin(Mesh.PRIMITIVE_LINES,material)
	var graph: AStar3D=game.threat.graph
	for id in graph.get_point_ids():
		if graph.is_point_disabled(id):continue
		for neighbor in graph.get_point_connections(id):
			if neighbor<id or graph.is_point_disabled(neighbor):continue
			geometry.surface_set_color(Color("b0ac72") if graph.get_point_position(id).y< -1 else Color("67b495"))
			geometry.surface_add_vertex(graph.get_point_position(id)+Vector3.UP*0.08)
			geometry.surface_add_vertex(graph.get_point_position(neighbor)+Vector3.UP*0.08)
	geometry.surface_set_color(Color("d6a56c"))
	geometry.surface_add_vertex(game.presence.position+Vector3.UP*1.4)
	geometry.surface_add_vertex(game.threat.last_known+Vector3.UP*1.4)
	geometry.surface_end()
	navigation_overlay=MeshInstance3D.new();navigation_overlay.mesh=geometry
	game.add_child(navigation_overlay)
	status.text="Authored AI portals and current target snapshot; toggle again to clear."

func coordinate_teleport() -> void:
	var values:=coords.text.split(",")
	if values.size()!=3:status.text="Enter three finite numbers separated by commas.";return
	for value in values:
		if not value.strip_edges().is_valid_float():status.text="Invalid coordinate.";return
	teleport_to(Vector3(float(values[0]),float(values[1]),float(values[2])))

func teleport_to(point: Vector3) -> bool:
	if not allow_action():return false
	if not point.is_finite() or absf(point.x)>30 or absf(point.z)>35 or point.y < -4 or point.y>4:
		status.text="Outside the surveyed test bounds.";return false
	var space: PhysicsDirectSpaceState3D=game.player.get_world_3d().direct_space_state
	var ray:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.35,point+Vector3.DOWN*1.2,1)
	var floor_hit: Dictionary=space.intersect_ray(ray)
	if floor_hit.is_empty() or floor_hit.normal.y < 0.75:status.text="No safe walkable floor near that height.";return false
	var destination: Vector3=floor_hit.position+Vector3.UP*0.04
	var capsule:=CapsuleShape3D.new();capsule.radius=0.28;capsule.height=1.72
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule
	query.transform=Transform3D(Basis.IDENTITY,destination+Vector3.UP*0.86)
	query.collision_mask=1|16|32;query.exclude=[game.player.get_rid()]
	if not space.intersect_shape(query,1).is_empty():status.text="Blocked: capsule clearance is insufficient.";return false
	previous=game.player.global_transform
	game.player.position=destination;game.player.velocity=Vector3.ZERO
	status.text="Validated teleport to "+str(destination)+". Story flags unchanged."
	log_event("teleport",{"from":previous.origin,"to":destination})
	return true

func toggle_fly() -> void:
	if flying:stop_fly();return
	if not allow_action():return
	free_camera=Camera3D.new();game.add_child(free_camera)
	free_camera.global_transform=game.player.camera.global_transform
	free_camera.fov=game.player.camera.fov;free_camera.cull_mask=game.player.camera.cull_mask
	flying=true;free_camera.current=true
	close_panel()

func stop_fly() -> void:
	if not flying:return
	flying=false
	game.player.camera.current=true
	free_camera.queue_free()
	# The first inspection saved the actual gameplay pause/input state. Opening
	# the inspector during flight must not replace that return state.
	get_tree().paused=false if game.presentation.section=="game" else true
	game.player.active=game.presentation.section=="game"
	if not opened:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if game.automated_qa else Input.MOUSE_MODE_CAPTURED if game.player.active else Input.MOUSE_MODE_VISIBLE
	paused_before=get_tree().paused;active_before=game.player.active
	mouse_before=Input.MOUSE_MODE_CAPTURED if active_before else Input.MOUSE_MODE_VISIBLE

func take_snapshot() -> void:
	if not allow_action():return
	snapshot=game.save_data().duplicate(true)
	status.text="Isolated state remembered in memory; ordinary checkpoint untouched."
	log_event("snapshot")

func restore_snapshot() -> void:
	if not allow_action() or snapshot.is_empty():return
	stop_fly();close_panel()
	game.apply_save(snapshot.duplicate(true))
	log_event("restore_snapshot")

func log_event(kind: String,data := {}) -> void:
	var path:=output.path_join("session.jsonl")
	var file:=FileAccess.open(path,FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file:
		file.seek_end();file.store_line(JSON.stringify({"time":Time.get_datetime_string_from_system(),"event":kind,"data":data}));file.close()

func capture() -> void:
	var stamp:=Time.get_datetime_string_from_system().replace(":","-")+"_"+str(Time.get_ticks_msec())
	panel.visible=false
	await RenderingServer.frame_post_draw
	var path:=output.path_join(stamp+".png")
	var error:=get_viewport().get_texture().get_image().save_png(path)
	panel.visible=opened
	status.text="Screenshot: "+ProjectSettings.globalize_path(path) if error==OK else "Screenshot failed: "+str(error)
	log_event("screenshot",{"path":path,"error":error,"player":game.player.position})
