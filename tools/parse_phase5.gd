extends SceneTree
func _initialize() -> void:
	var failed:=false
	for path in ["atmosphere_profile","atmosphere_integration_qa","atmosphere_performance_qa","preferences","presentation","world","exterior_weather","graphics_profile_study","graphics_phase2_profile"]:
		var resource=load("res://scripts/"+path+".gd")
		var okay: bool=resource!=null and resource.can_instantiate()
		print("PHASE5_PARSE ",path," ",okay)
		if not okay:failed=true
	quit(1 if failed else 0)
