extends SceneTree
func _initialize() -> void:
 var directory:="C:/Users/Snkii/Documents/UNLISTED/Checkpoints/20261029_project_health"
 var cfg:=ConfigFile.new();cfg.set_value("presentation","master",{"bad":true});cfg.save(directory+"/malformed_before.cfg")
 var prefs=load(directory+"/preferences_before.gd").new();prefs.path=directory+"/malformed_before.cfg";prefs.load_file()
 print("BEFORE_VALUE_TYPE ",typeof(prefs.data.master))
 quit()
