extends Node3D

const PUZZLES = preload("res://scripts/case_puzzles.gd")
const NOTES = preload("res://scripts/case_notes.gd")
const PLAYER = preload("res://scripts/player.gd")
const DOOR = preload("res://scripts/door.gd")
const ART = preload("res://scripts/production_art.gd")
const REPAIR = preload("res://scripts/environment_repair.gd")
var atmosphere_profile: RefCounted
var atmosphere_at_boot := 0
var presentation: CanvasLayer
var player: CharacterBody3D
var hud: CanvasLayer
var objective: Label
var prompt: Label
var subtitle: Label
var overlay: ColorRect
var menu: VBoxContainer
var center: CenterContainer
var journal: RichTextLabel
var stage := 0
var fuse := false
var brass_key := false
var report_read := false
var shed_read := false
var isolated := false
var ended := false
var started := false
var menu_open := true
var qa_mode := false
var automated_qa := false
var qa_input_guard: Node
var dev_mode := false
var dev_tools: CanvasLayer
var reduced_flash := true
var volume := 0.7
var sensitivity := 0.0022
var events: Dictionary = {}
var doors: Dictionary = {}
var targets: Dictionary = {}
var lamps: Array[OmniLight3D] = []
var valve_order: Array[int] = []
var valve_visuals: Dictionary = {}
var valve_labels: Dictionary = {}
var chair: Node3D
var presence: CharacterBody3D
var horror: Node3D
var surveyor_actor: Node3D
var threat: Node3D
var physical: Node3D
var capture_director: Node
var memory_receipt: Node3D
var lounge_contents: Node3D
var impossible_room: Node3D
var final_account: Node3D
var recount: Node3D
var investigation: Node3D
var witness: Node3D
var service_exit: Node3D
var maintenance: Node3D
var last_call: Node3D
var property_memory: Node3D
var recorder_memory: Node3D
var field_tape: Node3D
var dead_line: Node3D
var spare_place: Node3D
var storage_hide: Node3D
var inspection_search: Node3D
var controller: Node
var equipment: Node3D
var ambient_director: Node3D
var spare_mirror: Node3D
var chapter: Node3D
var hint_until := 0.0
var tv_light: OmniLight3D
var security_legend: Label3D
var security_screen: MeshInstance3D
var security_light: OmniLight3D
var ambience: AudioStreamPlayer
var time_in_game := 0.0
var caption_until := 0.0
var message_info: Dictionary = {}
var message_history: Array = []
var pulse_time := 0.0
var resources: Dictionary = {}
var foley_index: Dictionary = {}
var spatial_sound_field: Node
var materials: Dictionary = {}
var roomtone: AudioStreamPlayer3D
var fuse_mesh: Node3D
var checkpoint_path := "user://checkpoint.json"
var black := Color(0.025, 0.028, 0.03)
var cream := Color(0.62, 0.56, 0.42)
var rust := Color(0.22, 0.09, 0.055)
var warm := Color(1.0, 0.57, 0.27)
var cold := Color(0.30, 0.66, 0.76)

func _ready() -> void:
	# Explicit QA-only entry, before creating any world/render resources.
	# Export templates forbid command-line scene overrides; ordinary startup
	# keeps the established main scene and never takes this diagnostic branch.
	if "--prebuilt-viewport" in OS.get_cmdline_user_args() and not get_meta("qa_constructed_in_viewport",false):
		call_deferred("enter_private_qa_bootstrap");return
	# Official release templates can reject command-line scene overrides. This
	# explicit private diagnostic selects its entry before constructing the world.
	# The root marker lets its later original New Game instantiate this scene once.
	if "--visual-probe" in OS.get_cmdline_user_args() and "--deferred-title-diagnostic" in OS.get_cmdline_user_args() and not get_tree().root.has_meta("unlisted_deferred_title_boot"):
		get_tree().root.set_meta("unlisted_deferred_title_boot",true)
		set_process(false);set_physics_process(false);set_process_input(false)
		call_deferred("enter_deferred_title_diagnostic")
		return
	dev_mode = OS.has_feature("unlisted_dev") or (OS.has_feature("editor") and "--unlisted-dev" in OS.get_cmdline_user_args())
	if dev_mode:
		DirAccess.make_dir_recursive_absolute("user://development")
		checkpoint_path = "user://development/checkpoint.json"
	qa_mode = "--door-repair-qa" in OS.get_cmdline_user_args() or "--recording-repair-qa" in OS.get_cmdline_user_args() or "--qa" in OS.get_cmdline_user_args() or "--presentation-qa" in OS.get_cmdline_user_args() or "--milestone-qa" in OS.get_cmdline_user_args() or "--threat-qa" in OS.get_cmdline_user_args() or "--systems-qa" in OS.get_cmdline_user_args() or "--polish-qa" in OS.get_cmdline_user_args() or "--visual-probe" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--production-views" in OS.get_cmdline_user_args() or "--graphics-study-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--stability-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--atmosphere-integration-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--nightmare-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--atmosphere-performance-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--witness-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--field-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--last-call-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--exit-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--storage-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--inspection-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--final-account-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--sound-touch-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--night-arrival-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--arrival-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--ambient-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--director-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--spare-place-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--dead-line-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--maintenance-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--caption-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--input-isolation-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--exterior-views" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--hands-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--presence-views" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--impossible-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--service-room-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--exterior-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--capture-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--house-answers-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--vent-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--recount-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--interior-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--investigation-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--missing-minute-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--surveyor-assets-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--house-quality-qa" in OS.get_cmdline_user_args()
	qa_mode = qa_mode or "--house-remembers-qa" in OS.get_cmdline_user_args()
	# Refuse mistyped automation before creating the world or reading/writing a
	# normal case. A harness typo must never fall through to desktop gameplay.
	var automation_requested:=false
	for arg in OS.get_cmdline_user_args():
		if arg.ends_with("-qa") or arg.begins_with("--evidence=") or arg in ["--surveyor-revision","--surveyor-assets","--surveyor-reborn","--surveyor-study","--reborn-views","--reborn-components"]:automation_requested=true
	if automation_requested and not qa_mode and not "--dev-tools-qa" in OS.get_cmdline_user_args():
		push_error("UNKNOWN_QA_MODE: refusing normal startup for unrecognised automation")
		get_tree().quit(93);return
	automated_qa=(qa_mode and not "--visual-probe" in OS.get_cmdline_user_args()) or (dev_mode and "--dev-tools-qa" in OS.get_cmdline_user_args())
	if automated_qa:
		get_tree().root.set_flag(Window.FLAG_NO_FOCUS,true)
		get_tree().root.position=Vector2i(-16000,-16000)
	configure_input()
	load("res://scripts/preferences.gd").new().ensure_buses()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	atmosphere_at_boot = load("res://scripts/atmosphere_profile.gd").selected(self)
	build_world()
	player = CharacterBody3D.new()
	player.set_script(PLAYER)
	player.game = self
	add_child(player)
	player.position = Vector3(0, 0.08, 9)
	player.sensitivity = sensitivity
	build_ui()
	controller=load("res://scripts/field_controller.gd").new();controller.game=self;presentation.add_child(controller)
	horror = Node3D.new()
	horror.set_script(load("res://scripts/horror_director.gd"))
	horror.game = self
	horror.actor = surveyor_actor
	add_child(horror)
	horror.reset()
	threat = load("res://scripts/surveyor_threat.gd").new()
	threat.game = self
	add_child(threat)
	threat.reset()
	physical = load("res://scripts/physical_props.gd").new()
	physical.game = self
	add_child(physical)
	impossible_room=load("res://scripts/impossible_room.gd").new()
	impossible_room.game=self;add_child(impossible_room)
	capture_director=load("res://scripts/surveyor_capture.gd").new()
	capture_director.game=self
	add_child(capture_director)
	recount=load("res://scenes/departure_recount.tscn").instantiate()
	recount.game=self;add_child(recount)
	investigation=load("res://scripts/investigation.gd").new();investigation.game=self;add_child(investigation)
	chapter=load("res://scripts/missing_minute.gd").new();chapter.game=self;add_child(chapter)
	maintenance=load("res://scripts/maintenance_store.gd").new();maintenance.game=self;add_child(maintenance)
	dead_line=load("res://scripts/dead_line.gd").new();dead_line.game=self;add_child(dead_line)
	witness=load("res://scripts/witness_carbon.gd").new();witness.game=self;add_child(witness)
	spare_place=load("res://scripts/spare_place.gd").new();spare_place.game=self;add_child(spare_place)
	spare_mirror=load("res://scripts/spare_mirror.gd").new();spare_mirror.game=self;add_child(spare_mirror)
	ambient_director=load("res://scripts/ambient_director.gd").new();ambient_director.game=self;add_child(ambient_director)
	equipment=load("res://scripts/inspection_gear.gd").new();equipment.game=self;add_child(equipment)
	storage_hide=load("res://scripts/storage_hide.gd").new();storage_hide.game=self;add_child(storage_hide)
	inspection_search=load("res://scripts/inspection_search.gd").new();inspection_search.game=self;add_child(inspection_search)
	service_exit=load("res://scripts/service_exit.gd").new();service_exit.game=self;add_child(service_exit)
	field_tape=load("res://scripts/field_tape.gd").new();field_tape.game=self;add_child(field_tape)
	last_call=load("res://scripts/last_call.gd").new();last_call.game=self;add_child(last_call)
	load("res://scripts/interior_finish.gd").new().build(self)
	var living_rooms=load("res://scripts/living_rooms.gd").new()
	add_child(living_rooms);living_rooms.build(self)
	load("res://scripts/cellar_envelope.gd").new().build(self)
	property_memory=load("res://scripts/property_memory_study.gd").new();property_memory.game=self;add_child(property_memory)
	recorder_memory=load("res://scripts/recorder_memory_study.gd").new();recorder_memory.game=self;recorder_memory.runtime=true;add_child(recorder_memory)
	final_account=load("res://scripts/final_account.gd").new();final_account.game=self;add_child(final_account)
	# The graphics study retains its own explicit fixture policies. Ordinary
	# gameplay and all other QA paths use the same persisted production choice.
	if not "--graphics-study-qa" in OS.get_cmdline_user_args():
		atmosphere_profile = load("res://scripts/atmosphere_profile.gd").new()
		atmosphere_profile.apply(self, atmosphere_at_boot)
	set_volume(volume)
	show_menu("UNLISTED", true)
	if dev_mode:
		var tool_script = load("res://scripts/development_tools.gd")
		if tool_script and tool_script.can_instantiate():
			dev_tools = tool_script.new()
			dev_tools.game = self
			add_child(dev_tools)
	elif "--dev-tools-qa" in OS.get_cmdline_user_args():
		print("DEV_RELEASE_PROTECTED: development flag cannot enable tools or redirect saves")
		call_deferred("qa_exit",0)
	if qa_mode and not "--visual-probe" in OS.get_cmdline_user_args(): call_deferred("run_qa")

func enter_deferred_title_diagnostic() -> void:
	var diagnostic: Node=load("res://scenes/deferred_title_diagnostic.tscn").instantiate()
	get_tree().root.add_child(diagnostic)
	get_tree().current_scene=diagnostic
	queue_free()

func enter_private_qa_bootstrap() -> void:
	var diagnostic: Node=load("res://scenes/qa_viewport_bootstrap.tscn").instantiate()
	get_tree().root.add_child(diagnostic);get_tree().current_scene=diagnostic
	queue_free()

func configure_input() -> void:
	var keys := {"forward":KEY_W, "back":KEY_S, "left":KEY_A, "right":KEY_D, "sprint":KEY_SHIFT, "crouch":KEY_CTRL, "interact":KEY_E, "flashlight":KEY_F,"journal":KEY_J,"hint":KEY_H,"battery_status":KEY_B,"battery_replace":KEY_T,"torch_tap":KEY_V,"throw_prop":KEY_NONE,"pause":KEY_NONE,"crouch_toggle":KEY_NONE}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for id in ["inspect_left","inspect_right","inspect_up","inspect_down"]:
		if not InputMap.has_action(id):InputMap.add_action(id,.20)

func mat(color: Color, emission := false) -> StandardMaterial3D:
	var key := str(color) + str(emission)
	if materials.has(key): return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if emission:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.1
	materials[key] = m
	return m

func texture_mat(path: String, tint := Color.WHITE) -> StandardMaterial3D:
	var key := path+str(tint)
	if materials.has(key): return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(path)
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.95
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.5,0.5,0.5)
	materials[key] = m
	return m

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid := false, glow := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat(color, glow)
	parent.add_child(node)
	node.position = pos
	if solid: collision(parent, pos, size)
	return node

func collision(parent: Node3D, pos: Vector3, size: Vector3, id := "") -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = size
	shape.shape = bounds
	body.add_child(shape)
	parent.add_child(body)
	body.position = pos
	if id != "":
		body.set_meta("interaction", id)
		targets[id] = body
	return body

func all_meshes(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if root is MeshInstance3D: result.append(root)
	for child in root.get_children(): result.append_array(all_meshes(child))
	return result

func model(path: String, parent: Node3D, pos: Vector3, size: Vector3, angle := 0.0, solid := false) -> Node3D:
	if not resources.has(path): resources[path] = load(path)
	var wrapper := Node3D.new()
	parent.add_child(wrapper)
	var source: Node3D = resources[path].instantiate()
	wrapper.add_child(source)
	var bounds := AABB()
	var first := true
	for mesh in all_meshes(source):
		var local: Transform3D = wrapper.global_transform.affine_inverse() * mesh.global_transform
		var aabb: AABB = local * mesh.get_aabb()
		bounds = aabb if first else bounds.merge(aabb)
		first = false
		for idx in range(mesh.get_surface_override_material_count()):
			var original := mesh.get_active_material(idx)
			if original is StandardMaterial3D:
				original.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				original.roughness = 0.95
	var scale_factor := size / bounds.size.max(Vector3(0.001, 0.001, 0.001))
	source.scale *= scale_factor
	source.position -= Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_factor
	wrapper.position = pos
	wrapper.rotation.y = angle
	if solid: collision(wrapper, Vector3(0, size.y / 2, 0), size)
	return wrapper

func surface_height(root: Node3D,point: Vector3,ceiling_y := 10.0) -> float:
	var top:=-INF
	for mesh in all_meshes(root):
		for surface in mesh.mesh.get_surface_count():
			var arrays: Array=mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var count: int=indices.size() if not indices.is_empty() else vertices.size()
			for i in range(0,count,3):
				var corners: Array[Vector3]=[]
				for j in 3:corners.append(mesh.global_transform*vertices[indices[i+j] if not indices.is_empty() else i+j])
				var hit: Variant=Geometry3D.ray_intersects_triangle(Vector3(point.x,ceiling_y,point.z),Vector3.DOWN,corners[0],corners[1],corners[2])
				if hit is Vector3:top=maxf(top,hit.y)
	return top

func wall(pos: Vector3, width: float, angle := 0.0, height := 2.8) -> void:
	var tangent := Vector3(cos(angle),0,-sin(angle))
	var offset := 0.0
	while offset < width - 0.01:
		var w := minf(2.0,width-offset)
		var piece := model("res://assets/architecture/wall_2x2.glb", self, pos+tangent*(-width/2+offset+w/2), Vector3(w, height, 0.18), angle, true)
		piece.set_meta("exterior_wall",pos.y>-1 and (absf(pos.x)>7.4 or is_equal_approx(pos.z,4.0) or is_equal_approx(pos.z,-10.0)))
		if pos.y < -1:piece.add_to_group("service_concrete_walls")
		for mesh in all_meshes(piece):
			var exterior := absf(pos.x) > 7.4 or is_equal_approx(pos.z,4.0) or is_equal_approx(pos.z,-10.0)
			mesh.material_override = texture_mat("res://assets/exterior/Concrete019_1K-JPG_Color.jpg" if pos.y < -1 else ("res://assets/architecture/concrete.jpg" if exterior else "res://assets/original/aged_paper.png"),Color(0.63,0.66,0.60) if exterior else Color(0.76,0.76,0.7))
		# Exterior concrete keeps its outside face; quiet paper lines the occupied interior.
		if pos.y > -1 and (absf(pos.x)>7.4 or is_equal_approx(pos.z,4.0) or is_equal_approx(pos.z,-10.0)):
			var inward := Vector3(-signf(pos.x),0,0) if absf(pos.x)>7.4 else Vector3(0,0,-signf(pos.z))
			# The shed is a separate building centred at (-17,-14). House-relative
			# signs put its east/north/south interior lining on the OUTSIDE face.
			var shed_wall: bool=pos.x>=-20.1 and pos.x<=-13.9 and pos.z>=-17.1 and pos.z<=-10.9
			if shed_wall:
				inward=Vector3(-signf(pos.x+17),0,0) if is_equal_approx(pos.x,-20.0) or is_equal_approx(pos.x,-14.0) else Vector3(0,0,-signf(pos.z+14))
			var center_ := pos+tangent*(-width/2+offset+w/2)
			var lining := box(self,center_+inward*0.099+Vector3(0,height/2,0),Vector3(w,height,0.008),cream)
			if shed_wall:lining.set_meta("shed_interior_lining",true)
			lining.rotation.y = angle
			lining.material_override = texture_mat("res://assets/original/aged_paper.png",Color(0.79,0.83,0.76))
			var skirting := box(self,center_+inward*0.116+Vector3(0,0.10,0),Vector3(w,0.18,0.025),Color(0.17,0.18,0.15))
			skirting.rotation.y = angle
		offset += w
	var trim := Node3D.new()
	add_child(trim)
	trim.position = pos
	trim.rotation.y = angle
	var lower_trim:=box(trim, Vector3(0, 0.12, -0.11), Vector3(width, 0.22, 0.055), Color(0.13, 0.12, 0.10))
	var upper_trim:=box(trim, Vector3(0, height - 0.12, -0.11), Vector3(width, 0.15, 0.07), Color(0.18, 0.17, 0.14))
	if pos.y < -1:
		lower_trim.material_override=texture_mat("res://assets/exterior/Concrete019_1K-JPG_Color.jpg",Color(.25,.28,.25))
		upper_trim.material_override=texture_mat("res://assets/dusk/psx_house_steel_01.png",Color(.25,.27,.24))

func floor_area(x1: float, x2: float, z1: float, z2: float, y := 0.0) -> void:
	var x := x1
	while x < x2 - 0.01:
		var z := z1
		while z < z2 - 0.01:
			var w := minf(2, x2 - x)
			var d := minf(2, z2 - z)
			var tile := model("res://assets/architecture/floor_2x2.glb", self, Vector3(x + w/2, y - 0.15, z + d/2), Vector3(w, 0.15, d))
			if y==0 and z2<=-10 and x1>=-14:tile.add_to_group("duplicate_yard_tiles")
			for mesh in all_meshes(tile): mesh.material_override = texture_mat("res://assets/exterior/Concrete019_1K-JPG_Color.jpg" if y < -1 else "res://assets/dusk/psx_house_old_wood_01.png",Color(0.6,0.59,0.54))
			if y == 0 and z2 <= -10 and x2 >= -14 and x1 < -1.6:
				for mesh in all_meshes(tile):mesh.material_override = texture_mat("res://assets/architecture/concrete.jpg",Color(0.37,0.40,0.35))
			z += 2
		x += 2
	collision(self, Vector3((x1+x2)/2, y - 0.14, (z1+z2)/2), Vector3(x2-x1, 0.28, z2-z1))

func ceiling(x1: float, x2: float, z1: float, z2: float, y := 2.8) -> void:
	var mesh := box(self, Vector3((x1+x2)/2, y + 0.08, (z1+z2)/2), Vector3(x2-x1, 0.16, z2-z1), Color(0.18,0.18,0.16))
	mesh.material_override = texture_mat("res://assets/dusk/psx_house_ceiling_01.png",Color(0.35,0.37,0.34))

func label3(parent: Node3D, text: String, pos: Vector3, angle := 0.0, size := 26, color := Color(0.72,0.73,0.62)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.005
	l.modulate = color
	l.outline_size = 0
	parent.add_child(l)
	l.position = pos
	l.rotation.y = angle
	return l

func lamp(pos: Vector3, color: Color, energy: float, radius := 5.0, powered := false) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.omni_attenuation = 1.3
	light.shadow_enabled = true
	add_child(light)
	light.position = pos
	if powered: lamps.append(light)
	return light

func fixture(pos: Vector3, on := true) -> void:
	box(self, pos, Vector3(0.38, 0.06, 0.38), black)
	box(self, pos - Vector3(0,0.045,0), Vector3(0.27,0.04,0.27), warm if on else cream, false, on)
	lamp(pos - Vector3(0,0.15,0), warm, 1.3 if on else 0.0, 5.5, not on)

func furniture(name_: String, pos: Vector3, size: Vector3, angle := 0.0, solid := true) -> Node3D:
	return model("res://assets/furniture/"+name_+".glb", self, pos, size, angle, solid)

func door(id: String, pos: Vector3, angle := 0.0, locked := false) -> Node3D:
	var node := Node3D.new()
	node.set_script(DOOR)
	node.game = self
	node.door_id = id
	node.locked = locked
	add_child(node)
	node.position = pos
	node.rotation.y = angle
	# The source door FBX also contained a complete brick wall. Only the separated leaf moves.
	for x in [-0.68,0.68]:
		var jamb := box(node,Vector3(x,1.3,0),Vector3(0.12,2.6,0.23),Color(0.25,0.24,0.18))
		jamb.material_override = texture_mat("res://assets/dusk/psx_house_old_wood_01.png",Color(0.42,0.44,0.36))
	var header := box(node,Vector3(0,2.54,0),Vector3(1.48,0.12,0.23),Color(0.25,0.24,0.18))
	header.material_override = texture_mat("res://assets/dusk/psx_house_old_wood_01.png",Color(0.42,0.44,0.36))
	for z in [-0.15,0.15]:
		for x in [-0.74,0.74]: box(node,Vector3(x,1.3,z),Vector3(0.07,2.6,0.045),Color(0.27,0.28,0.22))
		box(node,Vector3(0,2.64,z),Vector3(1.55,0.08,0.045),Color(0.27,0.28,0.22))
	var pivot := Node3D.new()
	node.add_child(pivot)
	pivot.position.x = -0.615
	node.pivot = pivot
	var leaf := model("res://assets/architecture/door_leaf.glb", pivot, Vector3(0.615,0.025,0), Vector3(1.23,2.43,0.09))
	for mesh in all_meshes(leaf):mesh.material_override = texture_mat("res://assets/original/door_paint.png",Color(0.80,0.82,0.76))
	for z in [-0.08,0.08]:
		# A real spindle pivot; same lever footprint, leaf collision and target.
		var spindle:=Node3D.new();spindle.name="HandleFront" if z>0 else "HandleBack"
		pivot.add_child(spindle);spindle.position=Vector3(.985,1.12,z)
		box(spindle,Vector3(.075,0,0),Vector3(.17,.035,.065),Color(.42,.35,.18))
	collision(pivot, Vector3(0.615,1.24,0), Vector3(1.23,2.43,0.09), id)
	# Frame collision is kept out of the clear opening.
	collision(node, Vector3(-0.71,1.3,0), Vector3(0.12,2.6,0.24))
	collision(node, Vector3(0.71,1.3,0), Vector3(0.12,2.6,0.24))
	doors[id] = node
	return node

func opening_wall(pos: Vector3, width: float, angle := 0.0) -> void:
	var tangent := Vector3(cos(angle), 0, -sin(angle))
	var side := (width - 1.5) / 2
	wall(pos - tangent * (0.75+side/2), side, angle)
	wall(pos + tangent * (0.75+side/2), side, angle)
	wall(pos + Vector3(0,2.6,0), 1.5, angle, 0.2)

func table(pos: Vector3, width := 1.5, depth := 0.8) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = pos
	var top := box(node, Vector3(0,0.76,0), Vector3(width,0.08,depth), Color(0.21,0.13,0.075), true)
	top.material_override = texture_mat("res://assets/dusk/psx_house_old_wood_01.png",Color(0.62,0.56,0.48))
	for x in [-1,1]:
		for z in [-1,1]: box(node,Vector3(x*(width/2-0.1),0.37,z*(depth/2-0.1)),Vector3(0.08,0.74,0.08),black)
	return node

func monitor(pos: Vector3, id: String, text: String, angle := 0.0) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = pos
	node.rotation.y = angle
	box(node, Vector3.ZERO, Vector3(0.9,0.68,0.6), Color(0.08,0.075,0.06))
	var screen_ := box(node, Vector3(0,0.03,0.305), Vector3(0.73,0.49,0.02), Color(0.12,0.31,0.28), false, true)
	if id == "television":screen_.name = "TelevisionScreen";screen_.layers = 8
	var legend_ := label3(node,text,Vector3(0,0.04,0.325),0,15,Color(0.6,0.9,0.78))
	if id=="security":
		security_legend=legend_;security_screen=screen_
		legend_.visible=false
		legend_.font_size=16;legend_.pixel_size=.004
		var glass: StandardMaterial3D=screen_.material_override.duplicate()
		glass.albedo_color=Color(.035,.075,.06);glass.emission=Color(.08,.17,.135);glass.emission_energy_multiplier=.6
		screen_.material_override=glass
		for x in [-.30,-.23,-.16]:box(node,Vector3(x,-.285,.315),Vector3(.035,.025,.018),Color("4b5147"))
		box(node,Vector3(.33,-.285,.315),Vector3(.012,.012,.012),Color("7d8468"),false,true)
	if id == "television":legend_.name = "TelevisionLegend";legend_.layers = 8;legend_.position.y = 0.19;legend_.font_size = 10
	collision(node,Vector3.ZERO,Vector3(0.9,0.68,0.65),id)
	return node

func paper(pos: Vector3, id: String, title_: String, angle := 0.0) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = pos
	node.rotation.y = angle
	box(node,Vector3.ZERO,Vector3(0.48,0.6,0.025),Color(0.62,0.56,0.40))
	var ink:=label3(node,title_,Vector3(0,0,0.018),0,17,black)
	var measured:=ThemeDB.fallback_font.get_multiline_string_size(title_,HORIZONTAL_ALIGNMENT_CENTER,-1,17)
	ink.pixel_size=minf(.005,minf(.42/maxf(measured.x,1),.50/maxf(measured.y,1)))

	collision(node,Vector3.ZERO,Vector3(0.50,0.62,0.05),id)

func build_world() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012,0.025,0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.34,0.42,0.49)
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.06,0.10,0.12)
	env.fog_density = 0.009
	env_node.environment = env
	add_child(env_node)
	# Ground and a short, bounded service approach.
	floor_area(-1.5,1.5,4,6.4)
	floor_area(-7.5,7.5,-10,4)
	ceiling(-7.5,7.5,-10,4)
	glazed_wall(Vector3(-7.5,0,-3),14,PI/2,-4)
	glazed_wall(Vector3(7.5,0,-3),14,PI/2,-5)
	glazed_wall(Vector3(-4.5,0,4),6,0,-0.3,0.79)
	glazed_wall(Vector3(4.5,0,4),6,0,0.3,0.79)
	opening_wall(Vector3(0,0,4),3)
	door("front",Vector3(0,0,4))
	paper(Vector3(-1.30,1.52,4.13),"order","NIGHT CALL\n\nE. WARD\n23:17\n\nVACANT")
	fixture(Vector3(0,2.65,5.0))
	# Hall partitions contain actual openings, never overlapping solid walls.
	for x in [-1.5,1.5]:
		opening_wall(Vector3(x,0,1),6,PI/2)
		wall(Vector3(x,0,-3),2,PI/2)
		opening_wall(Vector3(x,0,-7),6,PI/2)
	wall(Vector3(-4.5,0,-3),6)
	wall(Vector3(4.5,0,-3),6)
	opening_wall(Vector3(-4.5,0,-10),6)
	wall(Vector3(4.5,0,-10),6)
	opening_wall(Vector3(0,0,-10),3)
	door("basement",Vector3(0,0,-10),0,true)
	door("lounge",Vector3(1.5,0,1),PI/2)
	door("office",Vector3(1.5,0,-7),PI/2)
	door("utility",Vector3(-1.5,0,-7),PI/2)
	fixture(Vector3(0,2.67,1.5))
	fixture(Vector3(0,2.67,-5.5),false)
	model("res://assets/dusk/psx_prop_radiator_01.glb",self,Vector3(-1.24,0.12,-3),Vector3(1.4,0.78,0.18),PI/2,true)
	furniture("vase",Vector3(1.05,0,-4),Vector3(0.35,0.6,0.35))
	# Occupied living room: a television, conversation seating, fallen chair, clutter.
	lounge_contents=Node3D.new();lounge_contents.name="LoungeContents";add_child(lounge_contents)
	var lounge_before:=get_children()
	var sofa:=furniture("couch",Vector3(6.4,0,0.3),Vector3(2.6,0.95,0.95),PI/2)
	sofa.name="LoungeSofa"
	# The approved source couch is long on Z, not X. Keep the original exact
	# collider/parent, but refit its visual with the correct anatomical axes.
	for mesh in all_meshes(sofa):mesh.visible=false
	# Parent + local quarter-turn = PI: the low front faces west to the TV,
	# with the tall back towards the east wall, within the unchanged footprint.
	var sofa_visual:=model("res://assets/furniture/couch.glb",sofa,Vector3.ZERO,Vector3(.95,.95,2.6),PI/2,false)
	sofa_visual.name="CorrectedSofaVisual"
	table(Vector3(4.5,0,0.3),1.7,0.9)
	model("res://assets/dusk/psx_prop_newspapers_01.glb",self,Vector3(4.1,0.81,0.2),Vector3(0.5,0.04,0.35))
	furniture("vase",Vector3(4.8,0.80,0.3),Vector3(0.18,0.31,0.18),0,false)
	chair = furniture("chair",Vector3(3.6,0,2.7),Vector3(0.65,0.95,0.65),PI)
	var lounge_shelf=model("res://assets/dusk/psx_prop_wall_shelf_01.glb",self,Vector3(6.0,1.1,-2.7),Vector3(1.5,0.75,0.28),0)
	lounge_shelf.name="LoungeWallShelf"
	var bottles=model("res://assets/dusk/psx_prop_bottles_01.glb",self,Vector3(5.9,surface_height(lounge_shelf,Vector3(5.9,0,-2.65)),-2.65),Vector3(0.4,0.36,0.2))
	bottles.name="LoungeShelfBottles"
	table(Vector3(3.2,0,-1.85),1.5,0.7)
	monitor(Vector3(3.2,1.13,-1.85),"television","NO SIGNAL\n\n23:17:08\n\nONE OCCUPANT")
	tv_light = lamp(Vector3(3.2,1.5,-1.1),cold,1.2,4)
	for piece in get_children():
		if not lounge_before.has(piece):piece.reparent(lounge_contents)
	fixture(Vector3(5,2.67,1.8),false)
	window_at(Vector3(7.37,0,2),-PI/2)
	# Kitchen and electrical fault. Not all rooms are lit before power restoration.
	model("res://assets/dusk/psx_prop_refrigerator_01.glb",self,Vector3(-6.8,0,3.48),Vector3(0.8,1.8,0.75),PI,true)
	for x in [-5.8,-4.8,-3.8]:
		var cabinet=model("res://assets/dusk/psx_prop_base_cabinet_01.glb",self,Vector3(x,0,3.55),Vector3(0.95,0.86,0.65),PI,true)
		cabinet.name="KitchenBase"+str(roundi(absf(x)*10))
		# Keep the established body/footprint, but not a second visible cabinet
		# underneath a compressed full sink unit.
		if is_equal_approx(x,-5.8):
			for mesh in all_meshes(cabinet):mesh.visible=false
	# Source rim y=.8865 and tap y=1.147283: rim meets the .86 m worktop.
	var sink=model("res://assets/dusk/psx_prop_sink_01.glb",self,Vector3(-5.8,0,3.55),Vector3(.95,1.113,.65),PI)
	sink.name="KitchenSink"
	var stove=model("res://assets/dusk/psx_prop_stove_01.glb",self,Vector3(-7.04,0,1.45),Vector3(0.75,0.88,0.7),PI/2,false)
	stove.name="KitchenStove"
	var cooktop:=surface_height(stove,stove.position)
	collision(stove,Vector3(0,cooktop/2,0),Vector3(.75,cooktop,.7))
	stove.set_meta("cooktop",cooktop)

	model("res://assets/dusk/psx_prop_calendar_01.glb",self,Vector3(-2.25,1.55,3.89),Vector3(0.42,0.55,0.03),PI)
	model("res://assets/dusk/psx_prop_wall_clock_01.glb",self,Vector3(-2.75,2.15,3.89),Vector3(0.4,0.4,0.05),PI)

	table(Vector3(-5.9,0,-0.8),1.6,0.8)
	furniture("chair",Vector3(-4.7,0,-0.6),Vector3(0.6,0.95,0.6),PI/2)
	# The former fixed counter vase is now owned by the shared portable system.
	ART.new().panel(self)
	fixture(Vector3(-4.5,2.67,1),false)
	window_at(Vector3(-7.37,0,1),PI/2)
	# The records office points toward the shed and personal stakes.
	load("res://scripts/interior_life.gd").new().desk(self,Vector3(5.6,0,-8.7),2.0,.85)
	monitor(Vector3(5.6,1.13,-8.7),"security","PROPERTY FILES\nS. WARD / 1998")
	security_light = lamp(Vector3(5.6,1.8,-8.1),cold,0.8,4)
	var office_chair: Node3D=furniture("chair",Vector3(6.65,0,-7.5),Vector3(0.65,1.0,0.65),PI*0.85)
	office_chair.name="OfficeTaskChair"
	for mesh in all_meshes(office_chair):mesh.visible=false
	var chair_visual: Node3D=model("res://assets/interiors/chairDesk.glb",office_chair,Vector3.ZERO,Vector3(.60,.98,.60))
	for mesh in all_meshes(chair_visual):
		for i in mesh.mesh.get_surface_count():
			var source: Material=mesh.get_active_material(i)
			mesh.set_surface_override_material(i,texture_mat("res://assets/original/work_canvas.png",Color("41483d") if source!=null and "carpet" in source.resource_name.to_lower() else Color("30362f")))
	load("res://scripts/interior_life.gd").new().desk(self,Vector3(3.3,0,-8.6),1.25,.8)
	paper(Vector3(3.4,1.5,-9.89),"record","PROPERTY 17\n\nOCCUPANCY\nRECORD\n\nDO NOT ERASE")
	fixture(Vector3(4,2.67,-6),false)
	# Utility shelves and a genuine loose fuse pickup.
	var rest_mattress:=furniture("mattress",Vector3(-6.6,0,-5.4),Vector3(0.9,0.18,1.9))
	rest_mattress.name="UtilityRestMattress"
	table(Vector3(-2.7,0,-9.4),1.6,0.75)
	var fuse_before:=get_children()
	fuse_mesh = ART.new().fuse(self)
	for piece in get_children():
		if not fuse_before.has(piece) and piece is Node3D:piece.position+=Vector3(.8,0,-.6)
	fixture(Vector3(-4.5,2.67,-7))
	build_service_route()
	build_basement()
	build_presence()
	var environment_repair := REPAIR.new()
	environment_repair.build(self)
	ART.new().details(self)
	load("res://scripts/house_polish.gd").new().build(self)
	load("res://scripts/interior_life.gd").new().build(self)
	load("res://scripts/room_finish.gd").new().build(self)
	var paving := box(self,Vector3(-8.5,-0.10,-12.75),Vector3(11,0.20,5.5),Color(0.20,0.23,0.21),true)
	paving.name="ServiceHardstanding"
	paving.material_override = texture_mat("res://assets/architecture/concrete.jpg",Color(0.37,0.40,0.35))
	# The approach is continuous ground; the old invisible spawn barrier is removed.
	ambience = AudioStreamPlayer.new()
	ambience.stream = load("res://assets/audio/hollow.wav")
	ambience.volume_db = -27
	ambience.bus = "Music"
	ambience.finished.connect(func(): ambience.play())
	add_child(ambience)
	ambience.play()
	roomtone = sound("hum",Vector3(3.2,1.2,-1.8),-28,true)
	roomtone.reparent(lounge_contents)
	sound("wind",Vector3(0,1,8),-24,true)
	var outdoor=load("res://scripts/exterior_world.gd").new()
	outdoor.game=self;add_child(outdoor)

func glazed_wall(pos: Vector3,width: float,angle: float,offset: float,half:=0.67) -> void:
	var tangent:=Vector3(cos(angle),0,-sin(angle))
	var left:=width/2+offset-half
	var right:=width/2-offset-half
	wall(pos+tangent*(-width/2+left/2),left,angle)
	wall(pos+tangent*(width/2-right/2),right,angle)
	wall(pos+tangent*offset,half*2,angle,1.0)
	wall(pos+tangent*offset+Vector3.UP*2.4,half*2,angle,0.4)
	var glass_collision:=collision(self,pos+tangent*offset+Vector3.UP*1.7,Vector3(half*2,1.4,0.10))
	glass_collision.rotation.y=angle;glass_collision.name="ClosedWindowGlass"
	glass_collision.set_meta("transparent_glass",true)

func window_glass_material() -> StandardMaterial3D:
	if materials.has("closed_window_glass"):return materials.closed_window_glass
	var material:=StandardMaterial3D.new()
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color=Color(0.16,0.21,0.23,0.08)
	material.roughness=0.38;material.metallic_specular=0.15
	materials.closed_window_glass=material
	return material

func window_at(pos: Vector3, angle: float) -> void:
	# Decorative recessed window over the wall, with cold moonlit spill.
	var node := Node3D.new()
	add_child(node)
	node.position = pos
	node.rotation.y = angle
	var glass:=box(node,Vector3(0,1.7,0.08),Vector3(1.25,1.25,0.02),Color.WHITE)
	glass.material_override=window_glass_material()
	for x in [-0.68,0.0,0.68]: box(node,Vector3(x,1.7,0.13),Vector3(0.075,1.45,0.12),Color(0.16,0.15,0.12))
	for y in [1.0,1.7,2.4]: box(node,Vector3(0,y,0.13),Vector3(1.45,0.075,0.12),Color(0.16,0.15,0.12))
	box(node,Vector3(0,0.97,0.2),Vector3(1.6,0.08,0.35),Color(0.19,0.17,0.14))
	lamp(pos + Vector3(0,1.8,0),cold,0.8,4)

func build_service_route() -> void:
	# A back porch leads to a fenced maintenance shed, keeping the exterior compact.
	floor_area(-6,-3,-11,-10)
	floor_area(-14,-3,-14,-11)
	# Centre the frame in the wall's actual opening, rather than 20 cm outside it.
	door("service",Vector3(-4.5,0,-10),0,true)
	floor_area(-20,-14,-17,-11)
	ceiling(-20,-14,-17,-11)
	wall(Vector3(-20,0,-14),6,PI/2)
	wall(Vector3(-17,0,-17),6)
	wall(Vector3(-17,0,-11),6)
	opening_wall(Vector3(-14,0,-14),6,PI/2)
	var shed_door:=door("shed",Vector3(-14,0,-14),PI/2,true)
	var padlock:=Node3D.new();shed_door.pivot.add_child(padlock)
	padlock.position=Vector3(1.11,1.02,0.14);shed_door.lock_visual=padlock
	box(padlock,Vector3(0,-0.03,0),Vector3(0.075,0.075,0.035),Color("625746"))
	var shackle:=MeshInstance3D.new();var ring:=TorusMesh.new()
	ring.inner_radius=0.018;ring.outer_radius=0.026;ring.rings=8;ring.ring_segments=6
	shackle.mesh=ring;shackle.material_override=mat(Color("454d49"));shackle.rotation.x=PI/2
	padlock.add_child(shackle)
	table(Vector3(-18,0,-16),2.5,0.9).name="ShedEquipmentBench"
	paper(Vector3(-18,1.45,-16.89),"shed_record","RELAY 17\n\nSERVICE PROCEDURE\nS. WARD / 1998\n\nREAD BEFORE ISOLATION")
	model("res://assets/machinery/generator.glb",self,Vector3(-18.8,0,-12.3),Vector3(1.0,1.4,2),PI/2,true)
	fixture(Vector3(-17,2.67,-14))
	lamp(Vector3(-9,2,-12.5),cold,1.0,6)

func build_basement() -> void:
	# Service ramp descends three metres; no teleport or fake basement transition.
	var ramp := Node3D.new()
	add_child(ramp)
	ramp.position = Vector3(0,-1.5,-12.5)
	ramp.rotation.x = -atan2(3,5)
	box(ramp,Vector3(0,-0.1,0),Vector3(3,0.2,sqrt(34.0)),Color(0.16,0.17,0.16),true)
	wall(Vector3(-1.5,-3,-12.5),5,PI/2,5.8)
	# A real inspection/air-return opening from the service crawl to the stairwell.
	# The sleeve and closely spaced grille are built by maintenance_store.
	wall(Vector3(1.5,-3,-14.75),.5,PI/2,5.8)
	wall(Vector3(1.5,-3,-11.25),2.5,PI/2,5.8)
	wall(Vector3(1.5,-3,-13.5),2,PI/2,.25)
	wall(Vector3(1.5,-.30,-13.5),2,PI/2,3.1)
	floor_area(-5,5,-24,-15,-3)
	ceiling(-5,5,-24,-15,-0.2)
	wall(Vector3(-5,-3,-19.5),9,PI/2)
	wall(Vector3(5,-3,-19.5),9,PI/2)
	wall(Vector3(0,-3,-24),10)
	opening_wall(Vector3(-3.25,-3,-15),3.5) # Real doorway beside the lower landing; new bay is fully backed.
	# Original north pier now has a real low service opening beside the ramp.
	wall(Vector3(1.95,-3,-15),.9)
	wall(Vector3(4.55,-3,-15),.9)
	box(self,Vector3(3.25,-.95,-15),Vector3(1.7,1.5,.18),Color("606457"),true)
	var repair := REPAIR.new()
	repair.g = self
	repair.relay_room()
	lamp(Vector3(0,-0.5,-18),Color(0.42,0.55,0.51),1.2,7)
	lamp(Vector3(0,-0.5,-22),warm,1.4,6)
	sound("hum",Vector3(3,-1.5,-21),-24,true)

func surveyor_model_path() -> String:
	# An art study must pass visual review before becoming the ordinary actor.
	# This switch is available only inside the isolated automated QA environment.
	if qa_mode and "--surveyor-revision" in OS.get_cmdline_user_args():
		return "res://assets/studies/surveyor_revision/candidate.glb"
	if qa_mode and "--surveyor-assets" in OS.get_cmdline_user_args():
		return "res://assets/studies/surveyor_asset/candidate.glb"
	if qa_mode and "--surveyor-reborn" in OS.get_cmdline_user_args():
		return "res://assets/original/surveyor_reborn_study.glb"
	if qa_mode and "--surveyor-study" in OS.get_cmdline_user_args():
		return "res://assets/original/surveyor_erasure_study.glb"
	return "res://assets/original/surveyor_presence.glb"

func build_presence() -> void:
	presence = CharacterBody3D.new()
	add_child(presence)
	presence.name = "Surveyor"
	presence.position = Vector3(0,0,-8)
	presence.collision_layer = 0
	presence.collision_mask = 1
	presence.floor_snap_length = 0.3
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 2.05
	shape.shape = capsule
	shape.position.y = 1.025
	presence.add_child(shape)
	var figure := load(surveyor_model_path()).instantiate() as Node3D
	presence.add_child(figure)
	figure.scale = Vector3.ONE*1.05
	figure.rotation.y = PI
	surveyor_actor = Node3D.new()
	surveyor_actor.set_script(load("res://scripts/surveyor_actor.gd"))
	surveyor_actor.game = self
	surveyor_actor.figure = figure
	presence.add_child(surveyor_actor)
	presence.visible = false

func sound(name_: String, pos: Vector3, db := -20.0, looping := false) -> AudioStreamPlayer3D:
	var path := "res://assets/audio/"+name_+".wav"
	if name_ in ["asset_cloth_1","asset_cloth_2"]:path="res://assets/studies/surveyor_asset/cloth_"+name_.right(1)+".wav"
	# Optional owner recordings replace individual cues without changing timing.
	var slot:=name_
	if name_ in ["surveyor_warning","surveyor_pursuit","surveyor_attack"]:path="res://assets/audio/foley/surveyor_inhale.ogg"
	if name_=="breath":path="res://assets/audio/foley/surveyor_inhale.ogg"
	if name_=="capture_contact":path="res://assets/audio/foley/capture_cloth.ogg"
	if name_ in ["surveyor_warning","surveyor_pursuit","surveyor_attack","capture_contact","capture_register"]:
		var replacement:="res://assets/audio/owner/"+name_+".ogg"
		if ResourceLoader.exists(replacement):path=replacement
	if name_ in ["step","prop_impact","door"]:
		var inside_house:=absf(pos.x)<7.4 and pos.z<4 and pos.z>-10.4
		var porch_deck:=absf(pos.x)<1.65 and pos.z>=4 and pos.z<6.4
		var wood := name_=="door" or (pos.y>-0.8 and (inside_house or porch_deck))
		var surface := "wood" if wood else "stone"
		var category := "walk" if name_=="step" else "drop"
		var key := category+"_"+surface
		var index: int = int(foley_index.get(key,0))%(4 if category=="walk" else 2)+1
		foley_index[key] = index
		name_ = "foley/"+key+"_"+str(index)
		path = "res://assets/audio/"+name_+".wav"
	# Selected physical recordings; old samples above remain an explicit fallback.
	var nearfield: Dictionary={"radio_switch":"radio_switch","radio_dial":"radio_dial","torch_cap":"torch_cap","transport_click":"transport_click","cloth_handling":"cloth_handling","prop_soft":"soft_contact"}
	if slot=="prop_metal":
		var variant: int=int(foley_index.get("small_metal",0))%2+1;foley_index.small_metal=variant
		nearfield[slot]="metal_light_"+str(variant)
	if nearfield.has(slot):
		var selected: String="res://assets/audio/sound_touch/"+str(nearfield[slot])+".ogg"
		var fallback: Dictionary={"transport_click":"relay","prop_metal":"foley/drop_stone_1","prop_soft":"foley/drop_wood_1","cloth_handling":"latch"}
		path=selected if ResourceLoader.exists(selected) else "res://assets/audio/"+str(fallback.get(slot,"latch"))+".wav"
	if not resources.has(path): resources[path] = load(path)
	var audio := AudioStreamPlayer3D.new()
	audio.set_meta("source_slot",slot)
	audio.stream = resources[path]
	audio.set_meta("sample",name_)
	if slot.begins_with("surveyor_") or slot.begins_with("capture_"):audio.set_meta("voice_slot",slot)
	audio.bus = "Ambience" if looping else "SFX"
	if not looping:
		if pos.y < -0.8:audio.bus = "HouseCellar"
		elif absf(pos.x)<7.4 and pos.z>-10.3 and pos.z<4:audio.bus = "HouseInterior"
	audio.volume_db = db
	audio.max_distance = 24
	audio.unit_size = 3
	if nearfield.has(slot):audio.unit_size=1.2 if slot.begins_with("prop_") else .65;audio.max_distance=12 if slot.begins_with("prop_") else 6
	add_child(audio)
	audio.position = pos
	if not looping:
		if not is_instance_valid(spatial_sound_field):
			spatial_sound_field=load("res://scripts/spatial_sound_field.gd").new();spatial_sound_field.game=self;add_child(spatial_sound_field)
		spatial_sound_field.track(audio,slot)
	if looping: audio.finished.connect(func(): audio.play())
	else: audio.finished.connect(audio.queue_free)
	audio.play()
	return audio

func build_ui() -> void:
	presentation = load("res://scenes/ui/presentation.tscn").instantiate()
	presentation.game = self
	add_child(presentation)
	hud = presentation
	objective = presentation.objective
	prompt = presentation.prompt
	subtitle = presentation.subtitle
	journal = presentation.note
	menu = presentation.body

func show_menu(_title: String, main := false) -> void:
	presentation.show_menu(main)
	menu = presentation.body

func show_settings() -> void:
	presentation.show_settings()
	menu = presentation.card_body

func show_credits() -> void:
	presentation.show_credits()

func new_game(cinematic_handoff:=false) -> void:
	if is_instance_valid(impossible_room):impossible_room.reset()
	if is_instance_valid(capture_director):capture_director.cancel()
	if is_instance_valid(capture_director):capture_director.repeats=0
	presentation.pending_notice = ""
	stage = 0
	fuse = false
	fuse_mesh.visible = true
	targets["fuse"].collision_layer = 1
	brass_key = false
	report_read = false
	shed_read = false
	isolated = false
	ended = false
	events.clear()
	events.case_v2=true
	events.case_v3=true
	events.case_v4=true
	events.house_answers=1
	events.vent_first_pass="armed" # Absent on legacy saves: never inserts a late surprise.
	events.arrival_check=true
	events.notes={"WHY I CAME":NOTES.WHY_I_CAME}
	PUZZLES.generate(events)
	for arg in OS.get_cmdline_user_args():
		if automated_qa and arg.begins_with("--puzzle-seed="):PUZZLES.generate(events,int(arg.trim_prefix("--puzzle-seed=")))
	refresh_puzzle_labels()
	equipment.new_case()
	storage_hide.restore()
	if is_instance_valid(chapter):chapter.restore()
	if is_instance_valid(witness):witness.restore()
	if is_instance_valid(service_exit):service_exit.restore()
	if is_instance_valid(field_tape):field_tape.restore()
	if is_instance_valid(last_call):last_call.restore()
	if is_instance_valid(maintenance):maintenance.restore()
	if is_instance_valid(dead_line):dead_line.restore()
	if is_instance_valid(spare_place):spare_place.restore()
	if is_instance_valid(investigation):investigation.restore()
	if is_instance_valid(recount):recount.restore_state()
	if is_instance_valid(final_account):final_account.restore()
	physical.restore()
	horror.reset()
	threat.reset()
	if is_instance_valid(ambient_director):ambient_director.restore()
	if is_instance_valid(property_memory):property_memory.restore()
	if is_instance_valid(recorder_memory):recorder_memory.restore()
	hint_until = 0
	valve_order.clear()
	for id in doors:
		doors[id].set_open(false,0.01)
		doors[id].locked = id in ["service","shed","basement"]
	chair.rotation = Vector3(0,PI,0)
	chair.position = Vector3(3.6,0,2.7)
	presence.visible = false
	for l in lamps: l.light_energy = 0
	player.crouch_latched=false;player.stamina=1.0;player.sprint_latched=false;player.sprinting=false;player.exhausted=false;player.stamina_delay=0
	player.position = Vector3(0,0.06,19.4)
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	started = true
	resume()
	player.camera.fov = 77
	for v in valve_visuals.values(): v.rotation.z = 0
	save_game()
	if not cinematic_handoff:presentation.moment("arrival")
	if presentation.prefs.data.reminders:presentation.notify("J  FIELD NOTES     H  OPTIONAL HINT")

func resume() -> void:
	presentation.resume_game()

func inspect_text(title_: String, body: String) -> void:
	var notes: Dictionary = events.get("notes",{})
	notes[title_] = body
	events["notes"] = notes
	presentation.inspect_document(title_, body)

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not started or menu_open: return
	if is_instance_valid(security_legend):security_legend.visible=stage>=3
	if is_instance_valid(security_screen):security_screen.material_override.emission_energy_multiplier=.6 if stage>=3 else 0.0
	time_in_game += delta
	if memory_receipt:memory_receipt.visible = events.get("memory_confirmed",false)
	if targets.has("source_copy"):targets.source_copy.collision_layer=1 if events.get("memory_confirmed",false) else 0
	for key in get_tree().get_nodes_in_group("record_keys"):key.visible = not get(key.get_meta("record_flag"))
	objective.text = current_objective()
	var hit: Dictionary = player.target()
	prompt.text = ""
	if physical.held:prompt.text = "Put down" if not physical.placement_ray().is_empty() else "Release"
	elif not hit.is_empty() and hit.collider.has_meta("loose_prop"):
		if physical.can_carry(hit.collider):prompt.text = "Carry "+str(hit.collider.get_meta("prop_label"))
	elif not hit.is_empty() and hit.collider.has_meta("interaction"):
		var id: String = hit.collider.get_meta("interaction")
		prompt.text = interaction_name(id)
	if time_in_game > caption_until: subtitle.text = ""
	if stage >= 3 and not events.has("chair") and player.position.x < 1.1 and player.position.z < 1:
		chair_event()
	if shed_read and not events.has("yard") and player.position.y > -0.3 and player.position.x > -10 and player.position.x < -3 and player.position.z < -10:
		yard_event()
	if isolated and not events.has("return") and player.position.y > -0.3 and player.position.z > -8:
		return_event()
	if presence.visible:
		pulse_time += delta


func current_objective() -> String:
	return NOTES.clue(self) if time_in_game < hint_until else ""

func request_hint() -> void:
	hint_until = time_in_game+10
	subtitle.text = ""
	caption_until = time_in_game

func open_casebook() -> void:
	var notes: Dictionary = events.get("notes",{})
	var text_ := "WORK ORDER 017 / ELI WARD\n17 BRIAR LANE\n\n"
	if isolated:
		text_ += "The service circuit is isolated.\n"
		if events.get("case_v2",false):text_ += "Dad left his original report in the service cabinet.\n" if not events.get("field_return_read",false) else "I have Dad's original. The office file contradicts it.\n"
		text_ += "Comparing my recorded footsteps with what I heard in the room could give dispatch a reason to investigate.\n\n"
	if brass_key:text_ += "KEYS HELD / brass service-yard key"+("; small cellar key" if shed_read else "")+"\n\n"
	if notes.is_empty():text_ += "No records examined.\n"
	for title_ in notes:text_ += title_+"\n"+str(notes[title_])+"\n\n"
	text_ += "D-pad Left asks for a hint while exploring." if controller.used else "H asks for a hint while exploring."
	presentation.inspect_document("FIELD NOTES / RECORDS EXAMINED",text_)

func interaction_name(id: String) -> String:
	if id=="lounge_curtains":return "Draw curtains" if not get_node("LivingRoomFinishes").curtains_closed() else "Open curtains"
	if id=="account_receipt":return "Take my receipt"
	if id=="account_compare":return "Compare the stock label"
	if id=="account_car":return "Stow the papers and leave" if final_account.phase()=="ready" else "Return to the receipt"
	if id=="order" and is_instance_valid(final_account) and final_account.phase() in ["ready","boarding"]:return "Receipt retained"
	if id=="hall_microphone":return "Inspect microphone"
	if id=="call_lightbox":return "Compare plans"
	if id=="call_niche":return "Close lining door" if doors.call_niche.opened else "Lift recessed latch"
	if id=="call_bridge":return "Disconnect speaker link"
	if id=="call_remote":return "Play upstairs recorder"
	if id=="call_page":return "Take folded page"
	if id=="test_reel":return "Take labelled reel"
	if id=="test_reel_deck":return "Use tape deck"
	if id=="exit_terminal":return "Inspect exit recorder"
	if id=="exit_receipt":return "Take printed slip"
	if id in ["exit_grille","exit_catch","exit_outer_handle"]:return "Close grille" if events.get("exit_open",false) else ("Try catch" if not events.get("exit_catch_free",false) else "Open grille")
	if id=="witness_cover":return "Close inspection cover" if events.get("witness_open",false) else "Slide inspection cover"
	if id=="witness_carbon":return "Take clearance copy"
	if id.begins_with("witness_fastener"):return "Turn fastener"
	if id=="storage_door":return "Close cupboard" if storage_hide.opened else "Open cupboard"
	if id=="inspection_kit":return "Fit UV torch attachment"
	if id.begins_with("battery_"):return "Take torch battery"
	if id=="spare_mirror":return "Inspect reflection"
	if id=="spare_cover":return "Pull back blanket"
	if id=="spare_card":return "Turn birthday card"
	if id=="line_feed":return "Switch test box on" if events.get("line_feed_off",false) else "Switch test box off"
	if id=="line_return":return "Plug in test cable" if events.get("line_return_out",false) else "Unplug test cable"
	if id=="line_strike":return "Tap test button"
	if id=="line_note":return "Read test note"
	if id=="line_strip":return "Read printed slip"
	if id=="archive_rack":return "Move shelving"
	if id=="underfloor_sheet":return "Read test sheet"
	if id=="test_joist":return "Tap timber"
	if id=="carbon_return":return "Inspect report sleeve"
	if id=="return_receiver":return "Tune radio"
	if id=="memory_drawer":return "Close drawer" if chapter.drawer_open else "Open drawer"
	if id=="memory_page":return "Take folded page"
	if id=="record" and events.get("case_v3",false):return "Read site-office notice"
	if id=="field_notebook":return "Take Simon's report"
	if id=="relay_record":return "Read field return"
	if id=="order" and isolated and recount.active:return "Listen"
	if id=="source_copy":return "Read comparison slip"
	if id in ["audition_source","audition_return","exclude_return"] and stage<3:return "Inspect tape recorder"
	if id=="front" and events.get("arrival_check",false) and not events.get("front_checked",false):return "Knock"
	if id=="front_gate":return "Close gate" if doors[id].opened else "Open gate"
	if id=="front" and events.get("arrival_check",false) and not events.get("front_checked",false):return "Knock"
	if doors.has(id): return "Try door" if doors[id].locked else ("Close door" if doors[id].opened else "Open door")
	return {"audition_source":"Review hall recording","audition_return":"Replay and listen","exclude_return":"Compare last footstep","order":"Read attendance register" if isolated else "Read call sheet", "television":"Inspect television", "fuse":"Take spare fuse", "breaker":"Restore power", "security":"Review security archive", "record":"Read occupancy record", "shed_record":"Read Simon's service note", "isolate":"Pull isolator", "valve0":"Turn RED valve", "valve1":"Turn BLUE valve", "valve2":"Turn WHITE valve"}.get(id,"Inspect")

func try_interact() -> void:
	if menu_open: return
	var hit: Dictionary = player.target()
	if not hit.is_empty() and hit.collider.has_meta("interaction"):
		interact(str(hit.collider.get_meta("interaction")))

func interact(id: String) -> void:
	if id=="lounge_curtains":get_node("LivingRoomFinishes").use_curtains();return
	if id.begins_with("account_"):final_account.use(id);return
	if id.begins_with("call_"):last_call.use(id);return
	if id.begins_with("exit_"):service_exit.use(id);return
	if id.begins_with("witness_"):witness.use(id);return
	if id=="storage_door":storage_hide.use();return
	if id=="inspection_kit" or id.begins_with("battery_"):equipment.collect(id);return
	if id=="spare_mirror":spare_mirror.touch();return
	if id.begins_with("spare_"):spare_place.use(id);return
	if id in ["test_reel","test_reel_deck"]:field_tape.use(id);return
	if id.begins_with("line_"):dead_line.use(id);return
	if id=="hall_microphone":inspect_text("HALL MICROPHONE",NOTES.HALL_MICROPHONE);save_game(true);return
	if id=="carbon_return":chapter.open_carbon();return
	if id=="return_receiver":chapter.open_receiver();return
	if id=="memory_drawer":chapter.use_drawer();return
	if id=="memory_page":chapter.take_page();return
	if id=="archive_rack":maintenance.push_rack();return
	if id=="underfloor_sheet":maintenance.read_sheet();return
	if id=="test_joist":maintenance.tap_joist();return
	if id=="record" and events.get("case_v3",false):inspect_text("BRIAR LANE / TEMPORARY OFFICE",NOTES.SITE);save_game();return
	if id in ["audition_source","audition_return","exclude_return"]:
		if stage<3:message("No power. The supply light is out.",2.5);return
		if id=="exclude_return":presentation.show_exclusion()
		else:horror.audition_channel("A" if id=="audition_source" else "B")
		return
	if doors.has(id):
		if id == "basement" and not shed_read:
			message("Locked. The brass key doesn't fit this one.")
			return
		doors[id].use()
		return
	match id:
		"field_notebook":investigation.read_original()
		"relay_record":
			if isolated:
				inspect_text("FIELD RETURN / 1998",NOTES.FIELD_RETURN)
				save_game()
		"source_copy":
			if events.get("memory_confirmed",false):inspect_text(NOTES.COMPARISON_TITLE,NOTES.SOURCE_COPY)
		"order":
			if is_instance_valid(final_account) and final_account.phase() in ["ready","boarding"]:return
			if isolated:
				if recount.request():presentation.show_register()
			else:
				stage = maxi(stage,1)
				inspect_text("NIGHT CALL / 17 BRIAR LANE",NOTES.CALL)
		"television":
			if stage < 3:inspect_text("DISCONNECTED SET","The lead ends in a loose plug behind the table. The set is humming.\n\nA drawing lies beside it: ELI / AGE 7. The chair in it is upside down.\n\nThis isn't a normal fault. I want the old job records before I touch anything else.")
			else:
				var observation := "A worker stands beside the office door."
				if events.get("memory_echo",false):
					observation = "He's walking the same route I took. Stopping where I stopped."
					events.memory_reviewed = true
				inspect_text("CAM 02 / HALL","That's the hall I just left. "+observation+"\n\nThe clock on the picture is stuck. There's no camera in that corner.\n\nMy drawing is beside the set. ELI / AGE 7.")

		"fuse":
			if not fuse:
				fuse = true
				fuse_mesh.visible = false
				stage = maxi(stage,2)
				targets["fuse"].collision_layer = 0
				message("A spare 13A fuse.",3)
				sound("latch",targets["fuse"].global_position,-23)
		"breaker":
			if not fuse: message("The fuse holder is empty. It takes a 13A fuse.")
			elif stage < 3:
				stage = 3
				for l in lamps: l.light_energy = 1.1
				var relay_sound=sound("relay",targets["breaker"].global_position,-18)
				horror.house_responds()
				sound_caption("A relay clicks shut.",3,"KITCHEN PANEL",relay_sound)
				sound("relay",targets.security.global_position,-28)
				events.notes["THE OFFICE SUPPLY"]=NOTES.OFFICE_POWER
				message("The file terminal's come on across the hall.",3)
				save_game()
			else: message("The supply is on. The service circuit is isolated." if isolated else "The meter is turning. Something downstairs is still drawing power.",3)
		"security", "record":
			if stage < 3: message("No power. I can't read the file while the house supply is off.")
			else:
				if not brass_key:presentation.pending_notice = "Brass service key taken"
				report_read = true
				brass_key = true
				doors["service"].locked = false
				doors["shed"].locked = false
				inspect_text("ARCHIVE / 23:17:08",NOTES.ARCHIVE+("\n\nTonight's call is here now. Same address, same television fault as Dad's." if isolated else ""))
				if not events.has("office"): office_event()
				save_game()
		"shed_record":
			if not shed_read:presentation.pending_notice = "Small stairwell key taken"
			shed_read = true
			doors["basement"].locked = false
			inspect_text("SIMON'S MANUAL OVERRIDE",NOTES.PROCEDURE)
			save_game()
		"valve0", "valve1", "valve2":
			if isolated:message("The wheels won't turn any further.",3);return
			if not shed_read:
				message("The three service lines have to be shut in the right order. There's a procedure sheet by the wheels.")
				return
			var index := int(id.right(1))
			valve_order.append(index)
			sound("valve",targets[id].global_position,-21)
			var expected: Array[int] = PUZZLES.sequence(events)
			if valve_order != expected.slice(0,valve_order.size()):
				valve_order.clear()
				for wheel in valve_visuals.values():wheel.rotation.z = 0
				sound("relay",targets[id].global_position,-21)
				message("The catch snapped back. All three wheels have reset.")
			else:
				var v: Node3D = valve_visuals[id]
				var t := create_tween()
				t.tween_property(v,"rotation:z",v.rotation.z+PI/2,0.45)
		"isolate":
			if valve_order != PUZZLES.sequence(events): message("The isolator won't move until all three service lines are closed.")
			elif not isolated:
				isolated = true
				for l in lamps: l.light_energy = 0.15
				var relay_sound=sound("relay",targets["isolate"].global_position,-18)
				sound_caption("The relay winds down.",3,"CELLAR",relay_sound)
				basement_event()
				save_game()

func message(text: String, seconds := 5.0, category := "observation", source := "ELI", audio: Node = null) -> void:
	# Explicit ownership stays available to the inspector even when accessibility
	# hides a category. Transient diagnostics never enter the story save schema.
	var audio_path := ""
	var playing := false
	if is_instance_valid(audio) and (audio is AudioStreamPlayer or audio is AudioStreamPlayer3D):
		playing = audio.playing
		if audio.stream:audio_path = audio.stream.resource_path
	message_info = {"category":category,"source":source,"text":text,"audio":audio_path,"audio_playing_at_trigger":playing,"time":time_in_game}
	message_history.append(message_info.duplicate(true))
	if message_history.size()>64:message_history.pop_front()
	if is_instance_valid(dev_tools):dev_tools.log_event("caption",message_info)
	var heading: String={"observation":"OBSERVATION","sound":"SOUND / "+source,"recording":"RECORDED / "+source,"dialogue":source,"status":"WORK ORDER"}.get(category,"OBSERVATION")
	subtitle.text = heading+"\n"+text.trim_prefix("[").trim_suffix("]")
	caption_until = time_in_game + seconds

func sound_caption(text: String, seconds: float, source: String, audio: Node, recorded := false) -> void:
	# A caption for sound must be tied to an actual playing stream, never an
	# imagined or missing effect. Observation text has its own distinct identity.
	if not is_instance_valid(audio) or not audio.playing:return
	if audio is AudioStreamPlayer3D:
		var listener: Camera3D=get_viewport().get_camera_3d()
		if is_instance_valid(listener) and listener.global_position.distance_to(audio.global_position)>audio.max_distance:return
	message(text,seconds,"recording" if recorded else "sound",source,audio)

func chair_event() -> void:
	events["chair"] = true
	var t := create_tween().set_parallel(true)
	t.tween_property(chair,"rotation:z",-1.5,0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(chair,"position:y",0.35,0.4)
	sound("impact",chair.position,-17)
	presentation.moment("chair")

func office_event() -> void:
	events["office"] = true
	presentation.pending_moment = "discovery"
	var d: Node3D = doors["office"]
	d.set_open(false,0.23)
	sound("impact",d.position,-19)
	if not reduced_flash:
		var t := create_tween()
		t.tween_property(security_light,"light_energy",0.0,0.2)
		t.tween_property(security_light,"light_energy",1.0,0.7)

func yard_event() -> void:
	events["yard"] = true
	horror.begin("watcher")

func basement_event() -> void:
	events["basement"] = true
	events.threat_pending = true
	events.threat_origin = "basement"
	presentation.moment("isolation")
	horror.begin("wrong_direction")

func return_event() -> void:
	events["return"] = true
	if not threat.active():presence.visible = false
	if not impossible_room.active:
		chair.rotation.z = 0
		chair.position = Vector3(0.65,0,-2.8)
	var footstep=sound("step",Vector3(0,0,1),-18)
	sound_caption("A single footstep.",3,"FRONT HALL",footstep)
	for l in lamps: l.light_energy = 0.6
	threat.arm()

func finish_attendance(outcome: String) -> bool:
	# Existing saves retain schema one. The evidence outcome is earned through the
	# optional listening comparison; the original acknowledgement remains available.
	if ended or not isolated or not report_read:return false
	if outcome not in ["accounted_for","on_record"]:return false
	if outcome=="on_record" and not events.get("memory_confirmed",false):return false
	if events.get("case_v3",false) and not events.get("bedroom_left",false):return false
	if events.get("case_v2",false):
		if not events.get("field_return_read",false) or not events.get("recount_complete",false):return false
		if events.get("case_v4",false) and not events.get("call_complete",false):return false
		if threat.active() or events.get("threat_pending",false):return false
		if not final_account.begin(outcome):return false
		presentation.resume_game();recount.update_sheet();save_game()
		return true
	events.ending=outcome
	finish_game()
	return true

func finish_game() -> void:
	horror.beat = ""
	threat.reset()
	presence.visible = false
	ended = true
	presentation.show_ending()
	if not qa_mode: save_game()

func refresh_puzzle_labels() -> void:
	for i in 3:
		if valve_labels.has(i):valve_labels[i].text=PUZZLES.plate(events,i)

func door_swing_states() -> Dictionary:
	var result := {}
	for id in doors:result[id] = doors[id].open_angle
	return result

func save_data() -> Dictionary:
	if is_instance_valid(recorder_memory):recorder_memory.snapshot()
	if is_instance_valid(horror):horror.snapshot_vent()
	if is_instance_valid(maintenance):events.archive_rack_x=maintenance.rack.position.x
	if is_instance_valid(physical):events["props"] = physical.snapshot()
	return {"schema":1,"stamina":player.stamina,"sprint_exhausted":player.exhausted,"stamina_delay":player.stamina_delay,"crouched":player.crouched,"stage":stage,"fuse":fuse,"key":brass_key,"report":report_read,"shed":shed_read,"isolated":isolated,"events":events,"valves":valve_order,"pos":[player.position.x,player.position.y,player.position.z],"yaw":player.rotation.y,"pitch":player.camera.rotation.x,"ended":ended,"doors":door_save_states(),"door_swing":door_swing_states()}

func door_save_states() -> Dictionary:
	var result := {}
	for id in doors: result[id] = doors[id].opened
	return result

func apply_save(data: Dictionary) -> void:
	if is_instance_valid(impossible_room):impossible_room.reset()
	if is_instance_valid(capture_director):capture_director.cancel()
	presentation.clear_transients()
	subtitle.text="";caption_until=time_in_game
	player.camera.fov=77
	presentation.pending_notice = ""
	presence.visible = false
	chair.rotation = Vector3(0,PI,0)
	chair.position = Vector3(3.6,0,2.7)
	for id in doors:
		doors[id].open_angle = float(data.get("door_swing",{}).get(id,-1.55))
		doors[id].set_open(data.get("doors",{}).get(id,false),0.01,true)
	for id in valve_visuals: valve_visuals[id].rotation.z = 0
	stage = int(data.get("stage",0))
	fuse = data.get("fuse",false)
	brass_key = data.get("key",false)
	report_read = data.get("report",false)
	shed_read = data.get("shed",false)
	isolated = data.get("isolated",false)
	events = data.get("events",{}).duplicate(true)
	if events.get("front_ajar",false) and not doors.front.opened:doors.front.restore_arrival()
	PUZZLES.ensure(events)
	refresh_puzzle_labels()
	NOTES.refresh_collected(events)
	if isolated and not events.get("return",false) and not events.get("threat_resolved",false) and not events.get("call_search_running",false):
		events.threat_pending = true
		events.threat_origin = "basement"
	physical.restore(events.get("props",{}))
	horror.reset()
	threat.reset()
	valve_order.assign(data.get("valves",[]))
	for i in range(3): valve_visuals["valve"+str(i)].rotation.z = PI/2 if valve_order.has(i) else 0
	var p: Array = data.get("pos",[0,0.1,9])
	player.position = Vector3(p[0],p[1],p[2])
	player.restore_stance(bool(data.get("crouched",false)))
	player.stamina=clampf(float(data.get("stamina",1.0)),0,1);player.sprint_latched=false;player.sprinting=false;player.exhausted=bool(data.get("sprint_exhausted",player.stamina<.01));player.stamina_delay=clampf(float(data.get("stamina_delay",.4)),0,.8)
	player.rotation.y = data.get("yaw",0.0)
	player.camera.rotation.x = data.get("pitch",0.0)
	player.velocity = Vector3.ZERO
	doors["service"].locked = not brass_key
	doors["shed"].locked = not (brass_key or shed_read)
	doors["basement"].locked = not shed_read
	for l in lamps: l.light_energy = 0.15 if isolated else (1.1 if stage >= 3 else 0.0)
	if events.has("chair"):
		chair.rotation.z = -1.5
		chair.position.y = 0.35
	if events.has("return"):
		chair.rotation.z = 0
		chair.position = Vector3(0.65,0,-2.8)
	impossible_room.restore_saved()
	targets["fuse"].collision_layer = 0 if fuse else 1
	fuse_mesh.visible = not fuse
	started = true
	ended = false
	resume()
	if data.get("ended",false): finish_game()
	if is_instance_valid(recount):recount.restore_state()
	if is_instance_valid(final_account):final_account.restore()
	if is_instance_valid(investigation):investigation.restore()
	if is_instance_valid(chapter):chapter.restore()
	if is_instance_valid(witness):witness.restore()
	if is_instance_valid(service_exit):service_exit.restore()
	if is_instance_valid(field_tape):field_tape.restore()
	if is_instance_valid(last_call):last_call.restore()
	if is_instance_valid(maintenance):maintenance.restore()
	if is_instance_valid(dead_line):dead_line.restore()
	if is_instance_valid(spare_place):spare_place.restore()
	if is_instance_valid(ambient_director):ambient_director.restore()
	if is_instance_valid(property_memory):property_memory.restore()
	if is_instance_valid(recorder_memory):recorder_memory.restore()
	if is_instance_valid(equipment):equipment.restore()
	if is_instance_valid(storage_hide):storage_hide.restore()
	horror.restore_vent()
	physical.restore_grip()

func save_game(quiet := false) -> void:
	if is_instance_valid(capture_director) and capture_director.active:return
	if qa_mode and checkpoint_path.begins_with("user://"): return
	var f := FileAccess.open(checkpoint_path+".tmp",FileAccess.WRITE)
	if f == null: message("Checkpoint could not be written."); return
	f.store_string(JSON.stringify(save_data()))
	f.close()
	var error := DirAccess.rename_absolute(checkpoint_path+".tmp",checkpoint_path)
	if error != OK: message("Checkpoint could not be replaced.")
	elif not quiet and is_instance_valid(presentation) and presentation.section == "game": presentation.notify("CHECKPOINT RECORDED")

func checkpoint_usable(data: Variant) -> bool:
	# Reject invalid core data before either menu availability or apply_save can
	# call typed methods/mutate live state. Missing legacy optional fields stay valid.
	if not data is Dictionary or data.get("schema",0)!=1:return false
	var position_: Variant=data.get("pos",null)
	if not position_ is Array or position_.size()!=3:return false
	for value in position_:
		if not (value is int or value is float) or not is_finite(float(value)):return false
	for key in ["events","doors","door_swing"]:
		if data.has(key) and not data[key] is Dictionary:return false
	var saved_events: Dictionary=data.get("events",{})
	if saved_events.has("curtains_manual") and not saved_events.curtains_manual is bool:return false
	if saved_events.has("carried_prop") and not saved_events.carried_prop is String:return false
	if saved_events.has("remembered_cup"):
		var remembered: Variant=saved_events.remembered_cup
		if not remembered is Array or remembered.size()!=3:return false
		if not remembered.all(func(v):return (v is int or v is float) and is_finite(float(v))):return false
	if saved_events.has("props"):
		if not saved_events.props is Dictionary:return false
		for value in saved_events.props.values():
			if not value is Array or value.size()!=6:return false
			for scalar in value:
				if not (scalar is int or scalar is float) or not is_finite(float(scalar)):return false
	for key in ["fuse","key","report","shed","isolated","ended","crouched","sprint_exhausted"]:
		if data.has(key) and not data[key] is bool:return false
	for key in ["stage","yaw","pitch","stamina","stamina_delay"]:
		if data.has(key) and (not (data[key] is int or data[key] is float) or not is_finite(float(data[key]))):return false
	if data.has("valves"):
		if not data.valves is Array:return false
		for value in data.valves:
			if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>2 or float(value)!=int(value):return false
	if data.has("events") and data.events.has("notes") and not data.events.notes is Dictionary:return false
	return true

func load_game() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(checkpoint_path))
	if not checkpoint_usable(data):
		message("The checkpoint could not be read. Your file has been left unchanged.")
		return
	apply_save(data)

func set_volume(value: float) -> void:
	volume = value
	if is_instance_valid(presentation):
		presentation.prefs.data.master = value
		presentation.prefs.apply_audio()

func save_settings() -> void:
	presentation.persist()

func load_settings() -> void:
	presentation.prefs.load_file()
	presentation.apply_preferences(false)

func prepare_automated_qa() -> void:
	if is_instance_valid(qa_input_guard):return
	qa_input_guard=load("res://scripts/qa_input_guard.gd").new()
	get_tree().root.add_child(qa_input_guard);qa_input_guard.attach(self)

func run_qa() -> void:
	if "--nightmare-qa" in OS.get_cmdline_user_args():
		prepare_automated_qa()
		var nightmare=load("res://scripts/next_nightmare_qa.gd").new();nightmare.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(nightmare)
		await nightmare.run(self);return
	if "--atmosphere-performance-qa" in OS.get_cmdline_user_args():
		prepare_automated_qa()
		var moving=load("res://scripts/atmosphere_performance_qa.gd").new();moving.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(moving)
		await moving.run(self);return
	if "--atmosphere-integration-qa" in OS.get_cmdline_user_args():
		prepare_automated_qa()
		var integration=load("res://scripts/atmosphere_integration_qa.gd").new();integration.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(integration)
		await integration.run(self);return
	if "--graphics-study-qa" in OS.get_cmdline_user_args():
		prepare_automated_qa()
		var study=load("res://scripts/graphics_study.gd").new();study.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(study)
		await study.run(self);return
	if "--stability-qa" in OS.get_cmdline_user_args():
		var probe=load("res://scripts/stability_qa.gd").new();probe.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(probe)
		await probe.run(self);return
	prepare_automated_qa()
	if "--missing-minute-qa" in OS.get_cmdline_user_args():
		var test=load("res://scripts/missing_minute_qa.gd").new();test.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(test)
		await test.run(self);return
	if "--investigation-qa" in OS.get_cmdline_user_args():
		var test=load("res://scripts/investigation_qa.gd").new();test.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(test)
		await test.run(self);return
	if "--interior-qa" in OS.get_cmdline_user_args():
		var test=load("res://scripts/interior_qa.gd").new();test.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(test)
		await test.run(self);return
	if "--recount-qa" in OS.get_cmdline_user_args():
		var test=load("res://scripts/recount_qa.gd").new();test.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(test)
		await test.run(self);return
	if "--service-room-qa" in OS.get_cmdline_user_args():
		var test=load("res://scripts/service_room_qa.gd").new();test.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(test)
		await test.run(self);return
	if "--impossible-qa" in OS.get_cmdline_user_args():
		var test=load("res://scripts/impossible_room_qa.gd").new();test.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(test)
		await test.run(self);return
	if "--presence-views" in OS.get_cmdline_user_args():
		var test = load("res://scripts/surveyor_presence_views.gd").new();test.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(test)
		await test.run(self);return
	if "--surveyor-assets-qa" in OS.get_cmdline_user_args():
		var test=load("res://scripts/surveyor_asset_qa.gd").new();test.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(test)
		await test.run(self);return
	if "--house-quality-qa" in OS.get_cmdline_user_args():
		var test=load("res://scripts/house_quality_qa.gd").new();test.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(test)
		await test.run(self);return
	if "--house-remembers-qa" in OS.get_cmdline_user_args():
		var test=load("res://scripts/house_remembers_qa.gd").new();test.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(test)
		await test.run(self);return
	if "--hands-qa" in OS.get_cmdline_user_args():
		var test = load("res://scripts/hands_qa.gd").new();test.process_mode=Node.PROCESS_MODE_ALWAYS;add_child(test)
		await test.run(self);return
	var path := "res://scripts/input_isolation_qa.gd" if "--input-isolation-qa" in OS.get_cmdline_user_args() else "res://scripts/exterior_views.gd" if "--exterior-views" in OS.get_cmdline_user_args() else "res://scripts/exterior_qa.gd" if "--exterior-qa" in OS.get_cmdline_user_args() else "res://scripts/door_repair_qa.gd" if "--door-repair-qa" in OS.get_cmdline_user_args() else "res://scripts/recording_repair_qa.gd" if "--recording-repair-qa" in OS.get_cmdline_user_args() else "res://scripts/polish_qa.gd" if "--polish-qa" in OS.get_cmdline_user_args() else "res://scripts/systems_qa.gd" if "--systems-qa" in OS.get_cmdline_user_args() else "res://scripts/threat_qa.gd" if "--threat-qa" in OS.get_cmdline_user_args() else "res://scripts/milestone_qa.gd" if "--milestone-qa" in OS.get_cmdline_user_args() else "res://scripts/presentation_qa.gd" if "--presentation-qa" in OS.get_cmdline_user_args() else "res://scripts/runtime_qa.gd"
	if "--storage-qa" in OS.get_cmdline_user_args():path="res://scripts/storage_hide_qa.gd"
	if "--inspection-qa" in OS.get_cmdline_user_args():path="res://scripts/inspection_qa.gd"
	if "--witness-qa" in OS.get_cmdline_user_args():path="res://scripts/witness_carbon_qa.gd"
	if "--last-call-qa" in OS.get_cmdline_user_args():path="res://scripts/last_call_qa.gd"
	if "--field-qa" in OS.get_cmdline_user_args():path="res://scripts/field_qa.gd"
	if "--exit-qa" in OS.get_cmdline_user_args():path="res://scripts/service_exit_qa.gd"
	if "--arrival-qa" in OS.get_cmdline_user_args():path="res://scripts/arrival_qa.gd"
	if "--ambient-qa" in OS.get_cmdline_user_args():path="res://scripts/ambient_qa.gd"
	if "--director-qa" in OS.get_cmdline_user_args():path="res://scripts/director_qa.gd"
	if "--production-views" in OS.get_cmdline_user_args():path="res://scripts/production_views.gd"
	if "--maintenance-qa" in OS.get_cmdline_user_args():path="res://scripts/maintenance_qa.gd"
	if "--final-account-qa" in OS.get_cmdline_user_args():path="res://scripts/final_account_qa.gd"
	if "--sound-touch-qa" in OS.get_cmdline_user_args():path="res://scripts/sound_touch_qa.gd"
	if "--night-arrival-qa" in OS.get_cmdline_user_args():path="res://scripts/night_arrival_qa.gd"
	if "--house-answers-qa" in OS.get_cmdline_user_args():path="res://scripts/house_answers_qa.gd"
	if "--vent-qa" in OS.get_cmdline_user_args():path="res://scripts/vent_sighting_qa.gd"
	if "--dead-line-qa" in OS.get_cmdline_user_args():path="res://scripts/dead_line_qa.gd"
	if "--spare-place-qa" in OS.get_cmdline_user_args():path="res://scripts/spare_place_qa.gd"
	if "--caption-qa" in OS.get_cmdline_user_args():path="res://scripts/caption_qa.gd"
	if "--capture-qa" in OS.get_cmdline_user_args():path="res://scripts/capture_qa.gd"
	var qa = load(path).new()
	qa.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(qa)
	await qa.run(self)

func qa_exit(code: int, via_menu := false) -> void:
	# Fast regression runs can end between the audio thread's mixer buffers.
	# Finish playbacks explicitly during test teardown, after every assertion/capture.
	for node in get_tree().root.find_children("*","",true,false):
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D:
			node.stop()
			node.stream = null
	await get_tree().process_frame
	OS.delay_msec(60)
	if via_menu and code==0:
		presentation.show_menu(true)
		print("QA_QUIT_CALLBACK actual title Quit button")
		presentation.buttons["Quit"].pressed.emit()
	else:get_tree().quit(code)
