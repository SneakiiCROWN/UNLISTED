extends RefCounted
func run(q: Node,g: Node3D) -> void:
 # New start fixture is explicit; crossings and interactions use actual inputs.
 g.player.position=Vector3(0,.04,6.1);g.player.velocity=Vector3.ZERO
 g.events.arrival_check=true;g.events.front_checked=false;g.events.erase("front_ajar")
 g.doors.front.set_open(false,.01,true);await q.wait(.2)
 await q.use("front");await q.wait(1.1)
 q.check("Phase4 first knock leaves actual door ajar",g.events.get("front_checked",false) and not g.doors.front.opened and absf(g.doors.front.pivot.rotation.y)>.1)
 await q.use("front");await q.wait(.8)
 q.check("Phase4 second interaction opens front door",g.doors.front.opened)
 await q.travel(Vector2(0,1.8),"Phase4 real front doorway inward")
 await q.travel(Vector2(0,6.1),"Phase4 real front doorway outward")
 await q.use("front");await q.wait(.8)
 q.check("Phase4 front door closes normally",not g.doors.front.opened)
 # Cover is actual architecture and the existing AI sight test, no invincibility
 # or new concealment flag. Keep it separate from naturally earned encounters.
 g.player.position=Vector3(-6.5,.04,-6.0);g.player.torch.visible=true
 g.presence.position=Vector3(-8.8,.04,-6.0);g.presence.look_at(g.player.position)
 await q.wait(.2)
 q.check("Phase4 solid house wall retains AI concealment",not g.threat.can_see_player())
 g.presence.visible=false;g.threat.reset()
