extends RefCounted
# Deterministic policy, shared by runtime and seeded distribution simulations.
# Save the draw index, not an imprecise JSON representation of a 64-bit RNG state.
const EVENTS := [
	{"id":"window_taps","weight":1.0,"limit":2},
	{"id":"empty_room_steps","weight":.8,"limit":1},
	{"id":"kitchen_tin","weight":.6,"limit":1},
	{"id":"curtains_drawn","weight":1.0,"limit":1},
	{"id":"ceiling_return","weight":1.2,"limit":1}
]
var data: Dictionary={}
var rng:=RandomNumberGenerator.new()
func restore(saved: Dictionary,seed_: int) -> void:
	data={"seed":seed_,"draw":0,"used":{},"last":"","remaining":60.0,"since":{}}
	data.merge(saved.duplicate(true),true)
	if saved.is_empty():data.remaining=random_between(55,115)
	data.remaining=maxf(30,float(data.get("remaining",60)))
	data.used=data.get("used",{});data.since=data.get("since",{})
func random_between(a: float,b: float) -> float:
	rng.seed=int(data.seed)+int(data.get("draw",0))*104729
	data.draw=int(data.get("draw",0))+1
	return rng.randf_range(a,b)
func choose(eligible: Array[String]) -> String:
	var available: Array=[];var total:=.65 # Sometimes nothing happens.
	for event in EVENTS:
		if not event.id in eligible or event.id==data.last or int(data.used.get(event.id,0))>=event.limit:continue
		if float(data.since.get(event.id,1000))<240:continue
		available.append(event);total+=event.weight
	var draw:=random_between(0,total)
	for event in available:
		draw-=event.weight
		if draw<0:return event.id
	return ""
func tick(delta: float,eligible: Array[String],blocked: bool) -> String:
	for id in data.since:data.since[id]=float(data.since[id])+delta
	if blocked:
		data.remaining=maxf(float(data.remaining),30.0)
		return ""
	data.remaining=float(data.remaining)-delta
	if float(data.remaining)>0:return ""
	var id:=choose(eligible)
	data.remaining=random_between(82,160) if id!="" else random_between(38,85)
	return id
func consume(id: String) -> void:
	data.used[id]=int(data.used.get(id,0))+1
	data.last=id;data.since[id]=0.0
	data.remaining=random_between(82,160)
