extends Node3D
# One roof-aware field, not camera rain over the player's indoor view.
var game: Node3D
var outside: AudioStreamPlayer
var sheltered: AudioStreamPlayer
var mix_level:=0.0
var near_rain: GPUParticles3D

func _ready() -> void:
	name="BriarLaneWeather"
	var catchment:=GPUParticlesCollisionHeightField3D.new()
	catchment.name="RoofAndCanopyRainCatchment"
	catchment.size=Vector3(84,40,94);catchment.position=Vector3(-3,6,-2)
	catchment.resolution=GPUParticlesCollisionHeightField3D.RESOLUTION_1024
	catchment.update_mode=GPUParticlesCollisionHeightField3D.UPDATE_MODE_WHEN_MOVED
	catchment.heightfield_mask=1
	add_child(catchment)
	var rain:=GPUParticles3D.new();rain.name="WindDrivenDrizzle"
	rain.amount=6800;rain.lifetime=2.6;rain.preprocess=2.6
	rain.local_coords=false;rain.position=Vector3(-3,18,-2);rain.layers=8
	rain.visibility_aabb=AABB(Vector3(-45,-25,-50),Vector3(90,35,100))
	rain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var motion:=ParticleProcessMaterial.new()
	motion.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	motion.emission_box_extents=Vector3(39,0.15,44)
	motion.direction=Vector3(0.10,-1,0.04);motion.spread=3.0
	motion.initial_velocity_min=9;motion.initial_velocity_max=12
	motion.gravity=Vector3(0,-1.5,0)
	motion.collision_mode=ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	motion.collision_use_scale=false
	rain.process_material=motion
	var streak:=QuadMesh.new();streak.size=Vector2(0.013,0.24)
	var water:=StandardMaterial3D.new()
	water.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	water.albedo_color=Color(0.47,0.56,0.63,0.40)
	water.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	water.billboard_mode=BaseMaterial3D.BILLBOARD_FIXED_Y
	water.cull_mode=BaseMaterial3D.CULL_DISABLED
	streak.material=water;rain.draw_pass_1=streak;add_child(rain)
	# The property-wide field supplies depth, but spreads its drops over almost
	# 7,000 square metres. A roof-aware foreground field gives normal walking
	# views readable, fast rain streaks without turning the whole sky white.
	near_rain=GPUParticles3D.new();near_rain.name="ForegroundRain"
	near_rain.amount=1500;near_rain.lifetime=1.8;near_rain.preprocess=1.8
	near_rain.local_coords=false;near_rain.layers=8
	near_rain.position=Vector3(0,12,9)
	near_rain.visibility_aabb=AABB(Vector3(-18,-20,-20),Vector3(36,34,40))
	near_rain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var close_motion:=motion.duplicate() as ParticleProcessMaterial
	close_motion.emission_box_extents=Vector3(8,0.12,10)
	near_rain.process_material=close_motion
	var close_streak:=QuadMesh.new();close_streak.size=Vector2(.012,.21)
	var close_water:=water.duplicate() as StandardMaterial3D
	close_water.albedo_color=Color(.47,.56,.63,.30)
	close_streak.material=close_water;near_rain.draw_pass_1=close_streak
	add_child(near_rain)
	build_mist()
	# One quiet licensed rain recording, crossfaded by shelter and routed through
	# the existing ambience control. No thunder or new creature vocal design.
	var bus:="WeatherSheltered"
	if AudioServer.get_bus_index(bus)<0:
		AudioServer.add_bus();var index:=AudioServer.bus_count-1
		AudioServer.set_bus_name(index,bus);AudioServer.set_bus_send(index,"Ambience")
		var lowpass:=AudioEffectLowPassFilter.new();lowpass.cutoff_hz=1700
		AudioServer.add_bus_effect(index,lowpass)
	var stream: AudioStreamOggVorbis=load("res://assets/audio/foley/rain_window.ogg")
	stream.loop=true
	outside=AudioStreamPlayer.new();outside.stream=stream;outside.bus="Ambience";outside.volume_db=-24
	sheltered=AudioStreamPlayer.new();sheltered.stream=stream;sheltered.bus=bus;sheltered.volume_db=-65
	add_child(outside);add_child(sheltered);outside.play();sheltered.play()

func build_mist() -> void:
	var mist:=CPUParticles3D.new();mist.name="LowDriftingMist"
	mist.amount=22;mist.lifetime=16;mist.preprocess=16;mist.local_coords=false
	mist.emission_shape=CPUParticles3D.EMISSION_SHAPE_POINTS
	var points:=PackedVector3Array()
	for p in [Vector2(-12,0),Vector2(-12,8),Vector2(11,0),Vector2(11,10),Vector2(-10,-14),Vector2(-22,-20),Vector2(-22,-8),Vector2(-8,24),Vector2(10,24),Vector2(0,-28)]:
		points.append(Vector3(p.x,0.30,p.y))
	mist.emission_points=points
	mist.direction=Vector3(1,0.01,0.2);mist.spread=8;mist.gravity=Vector3.ZERO
	mist.initial_velocity_min=0.12;mist.initial_velocity_max=0.20
	mist.scale_amount_min=0.8;mist.scale_amount_max=1.4
	mist.layers=8;mist.visibility_aabb=AABB(Vector3(-35,-1,-40),Vector3(75,8,80))
	mist.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var gradient:=Gradient.new()
	gradient.set_color(0,Color(0.30,0.35,0.39,0.045));gradient.set_color(1,Color(0.30,0.35,0.39,0))
	var haze:=GradientTexture2D.new();haze.width=64;haze.height=64;haze.gradient=gradient
	haze.fill=GradientTexture2D.FILL_RADIAL;haze.fill_from=Vector2(0.5,0.5);haze.fill_to=Vector2(1,0.5)
	var mat:=StandardMaterial3D.new();mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_texture=haze
	mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;mat.no_depth_test=false
	var sheet:=QuadMesh.new();sheet.size=Vector2(6,0.70);sheet.material=mat;mist.mesh=sheet
	add_child(mist)

func _process(delta: float) -> void:
	if not is_instance_valid(game.player) or not is_instance_valid(outside):return
	var p: Vector3=game.player.position
	near_rain.position=Vector3(p.x,p.y+12,p.z)
	var inside:=absf(p.x)<7.6 and p.z>-10.1 and p.z<4.1
	var shed:=p.x>-20.1 and p.x< -13.9 and p.z>-17.1 and p.z< -10.9
	var roof:=absf(p.x)<1.8 and p.z>4 and p.z<6.5
	var cellar:=p.y< -0.5 or (absf(p.x)<1.9 and p.z< -10 and p.z> -16)
	mix_level=move_toward(mix_level,1.0 if inside or shed or roof or cellar else 0.0,delta*1.1)
	outside.volume_db=lerpf(-24,-65,mix_level)
	sheltered.volume_db=lerpf(-65,-37 if not cellar else -48,mix_level)
