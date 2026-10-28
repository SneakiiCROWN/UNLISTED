extends Node
# One bounded owner for selected physical one-shots. No new buses/effects,
# no voice/music/weather writers, and no changes to AI hearing or user gains.
var game: Node3D
var active: Array=[]
var clock:=0.0
const PHYSICAL: Array[String]=["step","door","prop_impact","prop_soft","prop_metal","cloth_handling","latch","foley/drop_wood_1","foley/drop_wood_2"]

func track(audio: AudioStreamPlayer3D,slot: String) -> void:
	if not slot in PHYSICAL or not game.started:return
	var entry: Dictionary={"audio":weakref(audio),"db":audio.volume_db,"cutoff":audio.attenuation_filter_cutoff_hz}
	active.append(entry)
	if active.size()>48:active.pop_front()
	mix_source(entry)

func mix_source(entry: Dictionary) -> void:
	var audio: AudioStreamPlayer3D=entry.audio.get_ref()
	if not is_instance_valid(audio):return
	var camera: Camera3D=game.get_viewport().get_camera_3d()
	if not is_instance_valid(camera):return
	var target:=audio.global_position+Vector3.UP*.08
	var direction:=target-camera.global_position
	var blocked:=false
	if direction.length()>.35:
		# End just before the emitting surface so a latch/floor does not occlude
		# its own sound. Only solid architecture/doors count, not tiny loose props.
		var ray:=PhysicsRayQueryParameters3D.create(camera.global_position,target-direction.normalized()*.12,1)
		ray.exclude=[game.player.get_rid()]
		blocked=not game.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
	var wanted: float=float(entry.db)-(4.0 if blocked else 0.0)
	var cutoff: float=minf(float(entry.cutoff),1500.0) if blocked else float(entry.cutoff)
	if audio.volume_db!=wanted:audio.volume_db=wanted
	if audio.attenuation_filter_cutoff_hz!=cutoff:audio.attenuation_filter_cutoff_hz=cutoff
	audio.set_meta("architecture_occluded",blocked)
	audio.set_meta("authored_db",entry.db)

func _process(delta: float) -> void:
	clock+=delta
	if clock<.18:return
	clock=0
	active=active.filter(func(e):return is_instance_valid(e.audio.get_ref()))
	if game.menu_open or not game.started:return
	for entry in active:mix_source(entry)
