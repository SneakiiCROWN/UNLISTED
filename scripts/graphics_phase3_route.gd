extends RefCounted
# Actual physics movement and focused interactions; fixtures explicitly labelled.
func run(q: Node,g: Node3D) -> void:
 g.player.position=Vector3(0,.04,19.4);g.player.velocity=Vector3.ZERO
 g.doors.front_gate.set_open(false,.01,true);await q.wait(.3)
 await q.travel(Vector2(0,19),"Phase3 approach closed gate")
 await q.use("front_gate");await q.wait(.8)
 await q.travel(Vector2(0,14.7),"Phase3 gate inward")
 await q.travel(Vector2(0,8),"Phase3 approach to porch")
 await q.travel(Vector2(-8.8,7),"Phase3 front west circulation")
 await q.travel(Vector2(-8.8,-8.8),"Phase3 west house route")
 await q.travel(Vector2(-8.8,-12.5),"Phase3 yard connection")
 await q.travel(Vector2(-12.4,-14),"Phase3 shed approach")
 await q.travel(Vector2(-16,-14),"Phase3 shed entrance")
 await q.travel(Vector2(-12.4,-14),"Phase3 shed exit")
 for p in [Vector2(-13.05,-17.8),Vector2(-21,-17.8),Vector2(-21,-10.3),Vector2(-21,-17.8),Vector2(-13.05,-17.8),Vector2(-12,-12.5),Vector2(-4.5,-12)]:
  await q.travel(p,"Phase3 shed perimeter "+str(p))
 await q.travel(Vector2(-4.5,-8.6),"Phase3 rear door inward")
 await q.travel(Vector2(-4.5,-12),"Phase3 rear door outward")
 var saved_position: Vector3=g.player.position
 g.save_game(true);g.player.position=Vector3(-8.8,.04,-12.5);g.load_game();await q.wait(.3)
 q.check("Phase3 yard save restores supported position",g.player.position.distance_to(saved_position)<.25,str(g.player.position))
 g.presentation.show_menu(false);await q.wait(.2)
 q.check("Phase3 pause suspends player",get_tree(g).paused and not g.player.active)
 g.presentation.resume_game();await q.wait(.2)
 q.check("Phase3 resume restores controls",not get_tree(g).paused and g.player.active)
 g.presentation.show_death(true);await q.wait(.2);g.presentation.restart_checkpoint();await q.wait(.4)
 q.check("Phase3 retry restores yard position",g.player.active and not g.menu_open and g.player.position.distance_to(saved_position)<.3)
 g.horror.set_process(false);g.horror.set_physics_process(false);g.threat.enabled=false
 await q.travel(Vector2(-8.8,-12.5),"Phase3 return to west circulation")
 await q.travel(Vector2(-8.8,7),"Phase3 west route reverse")
 await q.travel(Vector2(0,8),"Phase3 return front approach")
 await q.travel(Vector2(0,19.4),"Phase3 gate outward return")
 await q.travel(Vector2(-2.8,19.5),"Phase3 parked car approach")
 await q.shot("R01_car_return")
 # Ray checks use actual physics: new soil must not bridge either service cut.
 for spec in [[Vector3(0,.5,-12.5),Vector3(0,-4,-12.5),"basement"],[Vector3(8,.5,-8.35),Vector3(8,-4,-8.35),"service exit"]]:
  var hit: Dictionary=g.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(spec[0],spec[1],1))
  q.check("Phase3 open ground cut "+spec[2],not hit.is_empty() and hit.position.y<-.15,str(hit.get("position")))
 # Visibility uses the working AI sight function; not an invented fog detector.
 g.player.position=Vector3(-8.8,.04,-7);g.player.torch.visible=true;g.presence.position=Vector3(-8.8,.04,-1);g.presence.look_at(g.player.position)
 await q.wait(.2);q.check("Phase3 west route AI sees unobstructed player",g.threat.can_see_player())
 Input.action_press("crouch");await q.wait(.3)
 q.check("Phase3 crouch remains supported",g.player.crouched and g.player.position.y>-.08)
 Input.action_release("crouch");await q.wait(.3)
 q.check("Phase3 stand recovery",not g.player.crouched)
 g.player.position=Vector3(-8.8,.04,-9)
 g.presence.position=Vector3(-8.8,.04,-1);g.presence.visible=true;g.threat.set_collision(true)
 g.surveyor_actor.figure.visible=true;g.threat.route=PackedVector3Array([Vector3(-8.8,.04,-6.5)])
 var elapsed:=0.0
 while elapsed<5 and not g.threat.route.is_empty():
  await g.get_tree().physics_frame
  var dt: float=g.get_physics_process_delta_time();g.threat.move_route(dt,1.7,true);elapsed+=dt
 q.check("Phase3 actual Surveyor traverses west corridor",g.presence.position.z<-6.1,str(g.presence.position))
 g.player.camera.look_at(g.presence.position+Vector3.UP*1.4);await q.shot("R02_Surveyor_route")
 g.threat.reset();g.presence.visible=false
func get_tree(g: Node) -> SceneTree:return g.get_tree()
