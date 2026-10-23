extends RefCounted

const DEFAULTS := {"master":0.7,"music":0.65,"sfx":0.8,"ambience":0.7,"sensitivity":0.0022,"invert_y":false,"display_mode":0,"resolution":Vector2i(1280,720),"visibility":1.0,"subtitles":true,"reduced_flash":true,"reduced_motion":false,"retro":0.18,"visual_preset":1,"viewmodel":true,"reminders":true,"story_mode":false,"sound_captions":true,"observations":true,"subtitle_scale":1.0,"caption_backing":true,"pad_sensitivity":1.8,"pad_deadzone":0.20,"torch_contacts":true}
var data: Dictionary = DEFAULTS.duplicate()
var path := "user://settings.cfg"

func load_file() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK: return
	var defaults:=DEFAULTS.duplicate()
	for key in defaults: data[key] = cfg.get_value("presentation",key,defaults[key])
	if not cfg.has_section("presentation"):
		data.master = cfg.get_value("audio","volume",0.7)
		data.sensitivity = cfg.get_value("input","sensitivity",0.0022)
		data.reduced_flash = cfg.get_value("accessibility","reduced_flash",true)
	for key in ["master","music","sfx","ambience","retro"]: data[key] = clampf(float(data[key]),0,1)
	data.sensitivity = clampf(float(data.sensitivity),0.0005,0.006)
	data.pad_sensitivity=clampf(float(data.pad_sensitivity),.5,3.5)
	data.pad_deadzone=clampf(float(data.pad_deadzone),.10,.35)
	data.visibility = clampf(float(data.visibility),0.8,1.5)
	if not data.resolution is Vector2i: data.resolution = Vector2i(1280,720)
	data.visual_preset = clampi(int(data.visual_preset),0,2)
	data.display_mode = clampi(int(data.display_mode),0,1)
	data.subtitle_scale=clampf(float(data.subtitle_scale),0.8,1.4)

func save_file() -> Error:
	var cfg := ConfigFile.new()
	for key in data:cfg.set_value("presentation",key,data[key])
	# Keep the previous release's settings readable on rollback.
	cfg.set_value("audio","volume",data.master)
	cfg.set_value("input","sensitivity",data.sensitivity)
	cfg.set_value("accessibility","reduced_flash",data.reduced_flash)
	var error := cfg.save(path+".tmp")
	if error != OK:return error
	return DirAccess.rename_absolute(path+".tmp",path)

func ensure_buses() -> void:
	for name_ in ["Music","SFX","Ambience"]:
		if AudioServer.get_bus_index(name_) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count-1
			AudioServer.set_bus_name(idx,name_)
			AudioServer.set_bus_send(idx,"Master")
	for spec in [["HouseInterior",0.28,0.07],["HouseCellar",0.65,0.15]]:
		if AudioServer.get_bus_index(spec[0])>=0:continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count-1
		AudioServer.set_bus_name(index,spec[0])
		AudioServer.set_bus_send(index,"SFX")
		var reverb := AudioEffectReverb.new()
		reverb.room_size = spec[1]
		reverb.damping = 0.72
		reverb.wet = spec[2]
		reverb.dry = 0.95
		AudioServer.add_bus_effect(index,reverb)

func apply_audio() -> void:
	ensure_buses()
	for pair in [["Master","master"],["Music","music"],["SFX","sfx"],["Ambience","ambience"]]:
		var idx := AudioServer.get_bus_index(pair[0])
		var value: float = data[pair[1]]
		# Native pre-capture measurements confirmed a very low game-side mix.
		# Calibration trim is separate from the saved user volume and mute controls.
		var trim: float = {"Master":0.0,"Music":6.0,"SFX":10.0,"Ambience":8.0}[pair[0]]
		AudioServer.set_bus_volume_db(idx,linear_to_db(maxf(value,0.0001))+trim)
		AudioServer.set_bus_mute(idx,value <= 0)
