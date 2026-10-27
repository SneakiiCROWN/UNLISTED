extends RefCounted
# Selected once at world construction. Never replace live terrain or GPU rain
# resources while a case, cinematic, pause screen or ending is in progress.
const NAMES := ["Original PSX", "Balanced Atmosphere", "Enhanced Atmosphere"]
var active := 0
var report: Dictionary = {}

static func preferences_path(game: Node) -> String:
	if game.qa_mode:
		var dir := ProjectSettings.globalize_path("res://qa") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA")
		return dir.path_join("presentation_settings.cfg")
	return "user://development/settings.cfg" if game.dev_mode else "user://settings.cfg"

static func selected(game: Node) -> int:
	var prefs = load("res://scripts/preferences.gd").new()
	prefs.path = preferences_path(game)
	prefs.load_file()
	return int(prefs.data.atmosphere_mode)

func apply(game: Node3D, selection: int) -> void:
	active = clampi(selection, 0, 2)
	if active == 0:
		report = {"profile":"original", "terrain":"original", "runtime":true}
		return
	var id := "balanced" if active == 1 else "enhanced"
	var materials = load("res://scripts/graphics_phase2_profile.gd").new()
	materials.runtime = true
	report = materials.apply(game, id)
	report.property = load("res://scripts/graphics_phase3_property.gd").new().apply(game)
	report.atmosphere = load("res://scripts/graphics_phase4_atmosphere.gd").new().apply(game, id)
	report.runtime = true
	refresh_accessibility(game)

func refresh_accessibility(game: Node) -> void:
	if active == 0 or not is_instance_valid(game.presentation):return
	for mesh in game.find_children("*", "MeshInstance3D", true, false):
		var material: Material = mesh.material_override
		if material is ShaderMaterial and material.shader.resource_path == "res://shaders/phase2_window.gdshader":
			material.set_shader_parameter("motion", 0.0 if game.presentation.prefs.data.reduced_motion else 1.0)
			material.set_shader_parameter("reflection_strength", 0.0)
